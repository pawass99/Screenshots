-- Run this once in the Supabase SQL Editor.
-- Profile images are stored under: <auth.uid()>/<generated filename>.

alter table public.profiles enable row level security;

drop policy if exists "Users can read their profile" on public.profiles;
create policy "Users can read their profile"
on public.profiles for select
to authenticated
using (auth.uid() = id);

drop policy if exists "Users can create their profile" on public.profiles;
create policy "Users can create their profile"
on public.profiles for insert
to authenticated
with check (auth.uid() = id);

drop policy if exists "Users can update their profile" on public.profiles;
create policy "Users can update their profile"
on public.profiles for update
to authenticated
using (auth.uid() = id)
with check (auth.uid() = id);

insert into storage.buckets (id, name, public)
values
  ('avatars', 'avatars', true),
  ('banners', 'banners', true)
on conflict (id) do update set public = excluded.public;

drop policy if exists "Users can upload their avatars" on storage.objects;
create policy "Users can upload their avatars"
on storage.objects for insert
to authenticated
with check (
  bucket_id = 'avatars'
  and (storage.foldername(name))[1] = auth.uid()::text
);

drop policy if exists "Users can upload their banners" on storage.objects;
create policy "Users can upload their banners"
on storage.objects for insert
to authenticated
with check (
  bucket_id = 'banners'
  and (storage.foldername(name))[1] = auth.uid()::text
);
