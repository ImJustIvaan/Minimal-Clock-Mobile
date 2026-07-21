-- Minimal Clock — Countdowns schema
-- Run this in the Supabase SQL editor (Project -> SQL Editor -> New query)

create extension if not exists "pgcrypto";

create table if not exists public.countdowns (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users (id) on delete cascade,
  title text not null,
  target_date timestamptz not null,
  created_at timestamptz not null default now()
);

create table if not exists public.countdown_follows (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  countdown_id uuid not null references public.countdowns (id) on delete cascade,
  notify boolean not null default false,
  created_at timestamptz not null default now(),
  unique (user_id, countdown_id)
);

alter table public.countdowns enable row level security;
alter table public.countdown_follows enable row level security;

-- Countdowns: anyone can read by id (shareable links), only the owner can write.
create policy "Countdowns are readable by anyone"
  on public.countdowns for select
  using (true);

create policy "Owners can insert their own countdowns"
  on public.countdowns for insert
  with check (auth.uid() = owner_id);

create policy "Owners can update their own countdowns"
  on public.countdowns for update
  using (auth.uid() = owner_id);

create policy "Owners can delete their own countdowns"
  on public.countdowns for delete
  using (auth.uid() = owner_id);

-- Follows: users can only see and manage their own follow rows.
create policy "Users can read their own follows"
  on public.countdown_follows for select
  using (auth.uid() = user_id);

create policy "Users can insert their own follows"
  on public.countdown_follows for insert
  with check (auth.uid() = user_id);

create policy "Users can update their own follows"
  on public.countdown_follows for update
  using (auth.uid() = user_id);

create policy "Users can delete their own follows"
  on public.countdown_follows for delete
  using (auth.uid() = user_id);

create index if not exists countdowns_owner_id_idx on public.countdowns (owner_id);
create index if not exists countdown_follows_user_id_idx on public.countdown_follows (user_id);
create index if not exists countdown_follows_countdown_id_idx on public.countdown_follows (countdown_id);

-- TV sign-in pairing (Apple TV and Android TV both use this): the TV shows
-- a short random code (+ QR code linking to time.ivaan.cc/pair?code=...).
-- The user opens that link signed in on their phone/computer, confirms, and
-- the site fills in this row with their session tokens. The TV polls for
-- that code and picks the tokens up.
-- The code itself is the capability/secret (like a password-reset link) —
-- anyone who has it can claim the tokens once, which is why rows expire
-- quickly and get deleted right after being claimed.
create table if not exists public.tv_pairing_codes (
  code text primary key,
  access_token text,
  refresh_token text,
  created_at timestamptz not null default now()
);

alter table public.tv_pairing_codes enable row level security;

-- Anyone holding the exact code can read/complete that one row (the code
-- itself, not RLS, is what limits access — same trust model as a
-- password-reset link). Never exposed via a listing query.
create policy "Anyone with the code can read that row"
  on public.tv_pairing_codes for select
  using (true);

create policy "Signed-in users can create a pairing row"
  on public.tv_pairing_codes for insert
  with check (true);

create policy "Signed-in users can fill in their tokens for a pairing row"
  on public.tv_pairing_codes for update
  using (true);

create policy "Anyone with the code can delete that row once claimed"
  on public.tv_pairing_codes for delete
  using (true);

-- Codes are single-use and short-lived; sweep anything older than 10 minutes.
create index if not exists tv_pairing_codes_created_at_idx on public.tv_pairing_codes (created_at);
