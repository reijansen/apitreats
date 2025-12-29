create table if not exists public.purchases (
    id uuid primary key default gen_random_uuid(),
    room_number text not null,
    total_amount numeric(12,2) not null default 0,
    created_at timestamptz default now()
);

create table if not exists public.purchase_items (
    id uuid primary key default gen_random_uuid(),
    purchase_id uuid not null references public.purchases(id) on delete cascade,
    item_id uuid not null references public.items(id) on delete restrict,
    quantity int not null check (quantity >= 1),
    unit_price_at_time numeric(12,2) not null,
    line_total numeric(12,2) not null
);

create index if not exists purchases_created_at_idx on public.purchases (created_at desc);
create index if not exists purchase_items_purchase_id_idx on public.purchase_items (purchase_id);
create index if not exists purchase_items_item_id_idx on public.purchase_items (item_id);

alter table public.purchases enable row level security;
alter table public.purchase_items enable row level security;

drop policy if exists "purchases_select_authenticated" on public.purchases;
drop policy if exists "purchase_items_select_authenticated" on public.purchase_items;

create policy "purchases_select_authenticated"
on public.purchases
for select
to authenticated
using (true);

create policy "purchase_items_select_authenticated"
on public.purchase_items
for select
to authenticated
using (true);

create or replace function public.get_public_items()
returns table (
    id uuid,
    name text,
    category_name text,
    unit text,
    retail_price numeric,
    stock int
)
language sql
security definer
set search_path = public
as $$
    select
        i.id,
        i.name,
        c.name as category_name,
        i.unit,
        i.retail_price,
        coalesce(sum(b.qty_remaining), 0) as stock
    from public.items i
    left join public.inventory_batches b on b.item_id = i.id
    left join public.item_categories c on c.id = i.category_id
    where i.is_active = true
    group by i.id, c.name;
$$;

grant execute on function public.get_public_items() to anon, authenticated;

create or replace function public.apply_stock_change(
    p_item_id uuid,
    p_qty_delta int,
    p_type text,
    p_reason text,
    p_unit_price_at_time numeric
)
returns int
language plpgsql
security definer
set search_path = public
as $$
declare
    remaining int := -p_qty_delta;
    batch record;
    consume_qty int;
    updated_stock int;
begin
    if p_qty_delta >= 0 then
        raise exception 'qty_delta must be negative for this function';
    end if;

    if p_type not in ('sale', 'adjustment', 'spoilage') then
        raise exception 'Invalid movement type for negative change';
    end if;

    if p_type in ('adjustment', 'spoilage') and not public.is_officer(auth.uid()) then
        raise exception 'Not authorized';
    end if;

    for batch in
        select *
        from public.inventory_batches
        where item_id = p_item_id and qty_remaining > 0
        order by purchased_at asc, id asc
        for update
    loop
        exit when remaining <= 0;
        consume_qty := least(remaining, batch.qty_remaining);

        update public.inventory_batches
        set qty_remaining = qty_remaining - consume_qty
        where id = batch.id;

        insert into public.stock_movements (
            item_id,
            batch_id,
            type,
            qty_delta,
            unit_price_at_time,
            unit_cost_at_time,
            reason,
            actor_id
        )
        values (
            p_item_id,
            batch.id,
            p_type,
            -consume_qty,
            p_unit_price_at_time,
            batch.unit_cost,
            p_reason,
            auth.uid()
        );

        remaining := remaining - consume_qty;
    end loop;

    if remaining > 0 then
        raise exception 'Insufficient stock for item %', p_item_id;
    end if;

    select coalesce(sum(qty_remaining), 0)
    into updated_stock
    from public.inventory_batches
    where item_id = p_item_id;

    return updated_stock;
end;
$$;

create or replace function public.checkout_purchase(
    p_room_number text,
    p_cart jsonb
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

    insert into public.purchases (room_number, total_amount)
    values (btrim(p_room_number), v_total)
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

grant execute on function public.checkout_purchase(text, jsonb) to anon, authenticated;
