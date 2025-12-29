create table if not exists public.purchases (
    id uuid primary key default gen_random_uuid(),
    room_number text not null,
    total_amount numeric(12,2) not null default 0,
    purchaser_name text null,
    notes text null,
    created_at timestamptz default now()
);

alter table public.purchases add column if not exists purchaser_name text;
alter table public.purchases add column if not exists notes text;

create or replace function public.checkout_purchase(
    p_room_number text,
    p_cart jsonb,
    p_purchaser_name text default null,
    p_notes text default null
)
returns table (
    purchase_id uuid,
    total_amount numeric
)
language plpgsql
security definer
set search_path = public
as $$
declare
    v_item record;
    v_item_ids uuid[];
    v_qtys int[];
    v_prices numeric[];
    v_total numeric := 0;
    v_idx int;
    v_purchase_id uuid;
    v_price numeric;
    v_active boolean;
begin
    if p_room_number is null or btrim(p_room_number) = '' then
        raise exception 'Room number required';
    end if;
    if p_room_number !~ '^[0-9]+$' then
        raise exception 'Room number must be numeric';
    end if;
    if p_cart is null or jsonb_array_length(p_cart) = 0 then
        raise exception 'Cart is empty';
    end if;

    for v_item in
        select * from jsonb_to_recordset(p_cart) as (item_id uuid, qty int)
    loop
        if v_item.item_id is null then
            raise exception 'Item id required';
        end if;
        if v_item.qty is null or v_item.qty < 1 then
            raise exception 'Quantity must be at least 1';
        end if;
        select retail_price, is_active
        into v_price, v_active
        from public.items
        where id = v_item.item_id;
        if not found then
            raise exception 'Item not found';
        end if;
        if not v_active then
            raise exception 'Item inactive';
        end if;
        v_total := v_total + (v_price * v_item.qty);
        v_item_ids := array_append(v_item_ids, v_item.item_id);
        v_qtys := array_append(v_qtys, v_item.qty);
        v_prices := array_append(v_prices, v_price);
    end loop;

    insert into public.purchases (room_number, total_amount, purchaser_name, notes)
    values (btrim(p_room_number), v_total, nullif(btrim(p_purchaser_name), ''), nullif(btrim(p_notes), ''))
    returning id into v_purchase_id;

    for v_idx in 1..array_length(v_item_ids, 1) loop
        insert into public.purchase_items (
            purchase_id,
            item_id,
            quantity,
            unit_price_at_time,
            line_total
        )
        values (
            v_purchase_id,
            v_item_ids[v_idx],
            v_qtys[v_idx],
            v_prices[v_idx],
            v_prices[v_idx] * v_qtys[v_idx]
        );

        perform public.apply_stock_change(
            v_item_ids[v_idx],
            -v_qtys[v_idx],
            'sale',
            'Honesty store purchase',
            v_prices[v_idx]
        );
    end loop;

    return query select v_purchase_id, v_total;
end;
$$;

grant execute on function public.checkout_purchase(text, jsonb, text, text) to anon, authenticated;
