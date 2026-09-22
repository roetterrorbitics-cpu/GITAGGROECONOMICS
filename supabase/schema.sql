create table if not exists public.subscriptions (
id uuid primary key default gen_random_uuid(),
user_id uuid not null references auth.users(id) on delete cascade,
plan text not null check (plan in ('creator','pro')),
provider text not null default 'paypal',
provider_subscription_id text unique,
status text not null default 'pending',
created_at timestamptz not null default now(),
updated_at timestamptz not null default now()
);
alter table public.subscriptions enable row level security;
drop policy if exists "Users can read own subscriptions" on public.subscriptions;
create policy "Users can read own subscriptions" on public.subscriptions for select to authenticated using (auth.uid()=user_id);
drop policy if exists "Users cannot write subscriptions directly" on public.subscriptions;
create policy "Users cannot write subscriptions directly" on public.subscriptions for insert to authenticated with check (false);
create index if not exists subscriptions_user_id_idx on public.subscriptions(user_id);