-- 기존 DB에 이미 trading_lines 테이블만 있고 unique가 없을 때 1회 적용
do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'trading_lines_strategy_line_type_uniq'
      and conrelid = 'public.trading_lines'::regclass
  ) then
    alter table public.trading_lines
      add constraint trading_lines_strategy_line_type_uniq
      unique (strategy_id, line_type);
  end if;
exception
  when duplicate_object then null;
end $$;
