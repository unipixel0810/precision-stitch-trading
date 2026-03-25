import { createClient, type SupabaseClient } from '@supabase/supabase-js';

export type StitchLineType = 'BUY' | 'STOP' | 'BASE' | string;

export type StitchLinePayload = {
  type: StitchLineType;
  /** 틱 스냅 등 최종 가격 */
  price: number;
  label?: string;
};

function requireEnv(name: string): string {
  const v = typeof process !== 'undefined' ? process.env[name] : undefined;
  if (!v) throw new Error(`Missing env: ${name}`);
  return v;
}

/**
 * SUPABASE_SERVICE_ROLE_KEY가 있으면 우선 사용 (단일 테넌트 + RLS off 전제에서 서버 전용 권장).
 * 없으면 SUPABASE_ANON_KEY — 로컬만 쓰고 운영 브라우저에는 넣지 마세요.
 */
export function createStitchSupabaseClient(): SupabaseClient {
  const url = requireEnv('SUPABASE_URL');
  const key =
    process.env.SUPABASE_SERVICE_ROLE_KEY?.trim() ||
    requireEnv('SUPABASE_ANON_KEY');
  return createClient(url, key);
}

/** 단일 테넌트: 종목당 활성 전략 1개 upsert 후 라인 insert */
export async function uploadStitchLine(
  client: SupabaseClient,
  stockCode: string,
  lineData: StitchLinePayload,
): Promise<{ strategyId: string }> {
  const { data: strategy, error: strategyError } = await client
    .from('active_strategies')
    .upsert(
      {
        stock_code: stockCode,
        is_active: true,
        updated_at: new Date().toISOString(),
      },
      { onConflict: 'stock_code' },
    )
    .select('id')
    .single();

  if (strategyError) throw strategyError;
  if (!strategy?.id) throw new Error('active_strategies upsert returned no id');

  const { error: lineError } = await client.from('trading_lines').insert({
    strategy_id: strategy.id,
    line_type: lineData.type,
    price: lineData.price,
    is_manual: true,
    label: lineData.label ?? null,
  });

  if (lineError) throw lineError;

  return { strategyId: strategy.id };
}
