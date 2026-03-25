-- 키움 OpenAPI에서 읽은 계좌 목록 동기화 (active_strategies 와 분리)

create table if not exists public.kiwoom_accounts (
  id uuid primary key default gen_random_uuid(),
  account_no text not null,
  display_label text,
  is_active boolean not null default true,
  synced_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  constraint kiwoom_accounts_account_no_key unique (account_no)
);

create index if not exists idx_kiwoom_accounts_synced_at on public.kiwoom_accounts (synced_at desc);

alter table public.kiwoom_accounts disable row level security;

comment on table public.kiwoom_accounts is 'CommConnect 후 GetLoginInfo(ACCNO) 로 수집한 계좌번호';
