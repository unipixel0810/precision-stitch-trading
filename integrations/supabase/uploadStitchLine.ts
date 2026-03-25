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

/**
 * 차트에서 선 생성/수정 시: 전략 확보 후 (strategy_id, line_type) 기준 upsert.
 * Realtime 리스너는 같은 테이블을 구독하면 갱신을 받습니다.
 */
export async function syncStitchToSupabase(
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

  const { error: lineError } = await client.from('trading_lines').upsert(
    {
      strategy_id: strategy.id,
      line_type: lineData.type,
      price: lineData.price,
      label: lineData.label ?? null,
      is_manual: true,
    },
    { onConflict: 'strategy_id,line_type' },
  );

  if (lineError) throw lineError;

  return { strategyId: strategy.id };
}

/** @deprecated 이름만 다름 — syncStitchToSupabase와 동일 */
export const uploadStitchLine = syncStitchToSupabase;
