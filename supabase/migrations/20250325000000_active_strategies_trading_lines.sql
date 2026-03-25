-- Stitch 매수선 / 활성 전략 (단일 테넌트)
-- 종목당 active_strategies 1행. RLS 비활성 → API 서버에서 service role로 호출하는 구성을 권장.
-- (anon 키를 브라우저에 두면 누구나 쓰기 가능하므로 운영에서는 비권장)
--
-- 이전 버전(user_id + RLS)을 이미 적용한 DB는 직접 정리하거나 retrofit 마이그레이션을 추가해야 합니다.

create extension if not exists "pgcrypto";

create table if not exists public.active_strategies (
  id uuid primary key default gen_random_uuid(),
  stock_code text not null,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint active_strategies_stock_code_key unique (stock_code)
);

create table if not exists public.trading_lines (
  id uuid primary key default gen_random_uuid(),
  strategy_id uuid not null references public.active_strategies (id) on delete cascade,
  line_type text not null,
  price numeric not null,
  is_manual boolean not null default true,
  label text,
  created_at timestamptz not null default now()
);

create index if not exists idx_trading_lines_strategy_id
  on public.trading_lines (strategy_id);

create index if not exists idx_active_strategies_stock_code
  on public.active_strategies (stock_code)
  where is_active = true;

alter table public.active_strategies disable row level security;
alter table public.trading_lines disable row level security;
