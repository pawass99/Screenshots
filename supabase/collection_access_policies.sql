alter table public.collections enable row level security;
alter table public.collection_items enable row level security;

drop policy if exists "Users can read their collections" on public.collections;
create policy "Users can read their collections"
on public.collections for select
to authenticated
using (auth.uid() = user_id);

drop policy if exists "Users can create their collections" on public.collections;
create policy "Users can create their collections"
on public.collections for insert
to authenticated
with check (auth.uid() = user_id);

drop policy if exists "Users can read their collection items" on public.collection_items;
create policy "Users can read their collection items"
on public.collection_items for select
to authenticated
using (
  exists (
    select 1
    from public.collections
    where collections.id = collection_items.collection_id
      and collections.user_id = auth.uid()
  )
);

drop policy if exists "Users can add their collection items" on public.collection_items;
create policy "Users can add their collection items"
on public.collection_items for insert
to authenticated
with check (
  exists (
    select 1
    from public.collections
    where collections.id = collection_items.collection_id
      and collections.user_id = auth.uid()
  )
);

drop policy if exists "Users can remove their collection items" on public.collection_items;
create policy "Users can remove their collection items"
on public.collection_items for delete
to authenticated
using (
  exists (
    select 1
    from public.collections
    where collections.id = collection_items.collection_id
      and collections.user_id = auth.uid()
  )
);
