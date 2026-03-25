-- Stitch Controller 연동: 활성 전략별 기본 TP/SL (%). AI 제안값 자동 반영용.

alter table public.active_strategies
  add column if not exists tp_percent double precision,
  add column if not exists sl_percent double precision;

comment on column public.active_strategies.tp_percent is '목표 익절 % (예: 3.5)';
comment on column public.active_strategies.sl_percent is '손절 % (양수, 예: 1.1)';
