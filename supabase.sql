-- ESK8 mapa povrchů – Supabase databáze + oprávnění
-- Spusť v Supabase SQL Editoru.

create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text,
  display_name text,
  role text not null default 'user' check (role in ('user', 'admin')),
  created_at timestamptz not null default now()
);

create table if not exists public.map_features (
  id uuid primary key default gen_random_uuid(),
  geom jsonb not null,
  properties jsonb not null default '{}'::jsonb,
  feature_type text not null default 'Feature',
  status text not null default 'approved' check (status in ('pending','approved','rejected')),
  created_by uuid default auth.uid() references public.profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, email, display_name)
  values (new.id, new.email, coalesce(new.raw_user_meta_data->>'display_name', split_part(new.email, '@', 1)))
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_user();

create or replace function public.is_admin(uid uuid)
returns boolean
language sql
security definer
set search_path = public
stable
as $$
  select exists(select 1 from public.profiles where id = uid and role = 'admin');
$$;

create or replace function public.touch_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists touch_map_features_updated_at on public.map_features;
create trigger touch_map_features_updated_at
before update on public.map_features
for each row execute function public.touch_updated_at();

alter table public.profiles enable row level security;
alter table public.map_features enable row level security;

drop policy if exists "profiles readable by authenticated" on public.profiles;
create policy "profiles readable by authenticated"
on public.profiles for select to authenticated using (true);

drop policy if exists "users can update own profile except role" on public.profiles;
create policy "users can update own profile except role"
on public.profiles for update to authenticated
using (id = auth.uid())
with check (id = auth.uid() and role = (select role from public.profiles where id = auth.uid()));

drop policy if exists "approved map features public readable" on public.map_features;
create policy "approved map features public readable"
on public.map_features for select to anon, authenticated
using (status = 'approved' or created_by = auth.uid() or public.is_admin(auth.uid()));

drop policy if exists "authenticated users can insert approved features" on public.map_features;
create policy "authenticated users can insert approved features"
on public.map_features for insert to authenticated
with check (created_by = auth.uid() and status = 'approved');

drop policy if exists "admins can update all features" on public.map_features;
create policy "admins can update all features"
on public.map_features for update to authenticated
using (public.is_admin(auth.uid()))
with check (public.is_admin(auth.uid()));

drop policy if exists "admins can delete all features" on public.map_features;
create policy "admins can delete all features"
on public.map_features for delete to authenticated
using (public.is_admin(auth.uid()));

-- Po registraci svého účtu nastav admin roli:
-- update public.profiles set role = 'admin' where email = 'tvuj@email.cz';
--
-- V Supabase Dashboardu ještě zapni Realtime pro public.map_features:
-- Database > Replication / Publications > supabase_realtime > map_features
