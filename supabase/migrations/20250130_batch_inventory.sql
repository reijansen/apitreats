create extension if not exists pgcrypto;

create table if not exists public.profiles (
    id uuid primary key references auth.users(id) on delete cascade,
    role text not null default 'officer' check (role in ('officer', 'admin')),
    created_at timestamptz default now()
);

create table if not exists public.item_categories (
    id uuid primary key default gen_random_uuid(),
    name text not null unique,
    created_at timestamptz default now()
);

create table if not exists public.items (
    id uuid primary key default gen_random_uuid(),
    name text not null,
    category_id uuid references public.item_categories(id) on delete set null,
    unit text default 'pcs',
    retail_price numeric(12,2) not null default 0,
    is_active boolean default true,
    created_at timestamptz default now()
);

create table if not exists public.inventory_batches (
    id uuid primary key default gen_random_uuid(),
    item_id uuid not null references public.items(id) on delete cascade,
    purchased_at timestamptz default now(),
    qty_received int not null check (qty_received >= 0),
    qty_remaining int not null check (qty_remaining >= 0),
    total_cost numeric(12,2) not null default 0,
    unit_cost numeric(12,4) generated always as (
        case when qty_received = 0 then 0 else total_cost / qty_received end
    ) stored,
    supplier text null,
    expiry_date date null,
    notes text null
);

create table if not exists public.stock_movements (
    id uuid primary key default gen_random_uuid(),
    item_id uuid not null references public.items(id) on delete cascade,
    batch_id uuid null references public.inventory_batches(id) on delete set null,
    type text not null check (type in ('purchase', 'sale', 'adjustment', 'spoilage')),
    qty_delta int not null,
    unit_price_at_time numeric(12,2) null,
    unit_cost_at_time numeric(12,4) null,
    reason text null,
    actor_id uuid null references auth.users(id),
    created_at timestamptz default now()
);

create index if not exists items_category_id_idx on public.items (category_id);
create index if not exists inventory_batches_item_id_idx on public.inventory_batches (item_id);
create index if not exists inventory_batches_item_purchased_at_idx on public.inventory_batches (item_id, purchased_at);
create index if not exists stock_movements_item_id_idx on public.stock_movements (item_id);

create or replace view public.item_stock_view as
select
    i.id,
    i.name,
    i.category_id,
    c.name as category_name,
    i.unit,
    i.retail_price,
    i.is_active,
    i.created_at,
    coalesce(sum(b.qty_remaining), 0) as stock
from public.items i
left join public.inventory_batches b on b.item_id = i.id
left join public.item_categories c on c.id = i.category_id
group by i.id, c.name;

create or replace function public.is_officer(p_user uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
    select exists (
        select 1
        from public.profiles
        where id = p_user and role in ('officer', 'admin')
    );
$$;

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
    if not public.is_officer(auth.uid()) then
        raise exception 'Not authorized';
    end if;

    if p_qty_delta >= 0 then
        raise exception 'qty_delta must be negative for this function';
    end if;

    if p_type not in ('sale', 'adjustment', 'spoilage') then
        raise exception 'Invalid movement type for negative change';
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

alter table public.profiles enable row level security;
alter table public.items enable row level security;
alter table public.item_categories enable row level security;
alter table public.inventory_batches enable row level security;
alter table public.stock_movements enable row level security;

drop policy if exists "items_select_authenticated" on public.items;
drop policy if exists "items_insert_officers" on public.items;
drop policy if exists "items_update_officers" on public.items;
drop policy if exists "items_delete_officers" on public.items;
drop policy if exists "item_categories_select_authenticated" on public.item_categories;
drop policy if exists "item_categories_insert_officers" on public.item_categories;
drop policy if exists "item_categories_update_officers" on public.item_categories;
drop policy if exists "item_categories_delete_officers" on public.item_categories;
drop policy if exists "inventory_batches_select_officers" on public.inventory_batches;
drop policy if exists "inventory_batches_insert_officers" on public.inventory_batches;
drop policy if exists "stock_movements_select_officers" on public.stock_movements;
drop policy if exists "stock_movements_insert_officers" on public.stock_movements;
drop policy if exists "profiles_select_own" on public.profiles;

grant select on public.item_stock_view to authenticated;

create policy "items_select_authenticated"
on public.items
for select
to authenticated
using (true);

create policy "profiles_select_own"
on public.profiles
for select
to authenticated
using (auth.uid() = id);

create policy "items_insert_officers"
on public.items
for insert
to authenticated
with check (public.is_officer(auth.uid()));

create policy "items_update_officers"
on public.items
for update
to authenticated
using (public.is_officer(auth.uid()))
with check (public.is_officer(auth.uid()));

create policy "items_delete_officers"
on public.items
for delete
to authenticated
using (public.is_officer(auth.uid()));

create policy "item_categories_select_authenticated"
on public.item_categories
for select
to authenticated
using (true);

create policy "item_categories_insert_officers"
on public.item_categories
for insert
to authenticated
with check (public.is_officer(auth.uid()));

create policy "item_categories_update_officers"
on public.item_categories
for update
to authenticated
using (public.is_officer(auth.uid()))
with check (public.is_officer(auth.uid()));

create policy "item_categories_delete_officers"
on public.item_categories
for delete
to authenticated
using (public.is_officer(auth.uid()));

create policy "inventory_batches_select_officers"
on public.inventory_batches
for select
to authenticated
using (public.is_officer(auth.uid()));

create policy "inventory_batches_insert_officers"
on public.inventory_batches
for insert
to authenticated
with check (public.is_officer(auth.uid()));

create policy "stock_movements_select_officers"
on public.stock_movements
for select
to authenticated
using (public.is_officer(auth.uid()));

create policy "stock_movements_insert_officers"
on public.stock_movements
for insert
to authenticated
with check (public.is_officer(auth.uid()));
