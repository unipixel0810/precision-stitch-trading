-- 체결/매매 히스토리 (엑셀 → Bulk insert, AI 분석 소스)

create extension if not exists "pgcrypto";

create table if not exists public.trade_history (
  id uuid primary key default gen_random_uuid(),
  trade_date date,
  stock_name text not null,
  return_pct numeric not null,
  status text not null,
  volume numeric,
  volume_ref numeric,
  is_volume_cliff boolean not null default false,
  notes text,
  created_at timestamptz not null default now()
);

create index if not exists idx_trade_history_trade_date on public.trade_history (trade_date desc);
create index if not exists idx_trade_history_stock_name on public.trade_history (stock_name);

alter table public.trade_history disable row level security;
