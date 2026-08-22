import { type AuthEnv, json, optionsResponse } from '../_auth';

export const onRequestOptions: PagesFunction<AuthEnv> = ({ request }) => optionsResponse(request);

export const onRequestGet: PagesFunction<AuthEnv> = async ({ request, env }) => {
  const row = await env.DB.prepare(
    "SELECT value FROM app_settings WHERE key = 'global_cleanup_marker'",
  ).first<{ value: string }>();
  let marker: Record<string, unknown> | null = null;
  if (row?.value) {
    try {
      const parsed = JSON.parse(row.value) as unknown;
      if (parsed && typeof parsed === 'object') marker = parsed as Record<string, unknown>;
    } catch (_) {
      marker = null;
    }
  }
  return json(request, { ok: true, marker });
};
