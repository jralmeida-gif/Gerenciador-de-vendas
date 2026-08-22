import { getSession, type AuthEnv, json, optionsResponse } from '../_auth';

export const onRequestOptions: PagesFunction<AuthEnv> = ({ request }) => optionsResponse(request);

export const onRequestGet: PagesFunction<AuthEnv> = async ({ request, env }) => {
  const user = await getSession(request, env);
  if (!user) return json(request, { error: 'Sessão expirada.' }, 401);
  const [products, convenios, version, cleanup] = await env.DB.batch([
    env.DB.prepare('SELECT name, format, active FROM catalog_products ORDER BY active DESC, name'),
    env.DB.prepare('SELECT name, code FROM catalog_convenios ORDER BY name'),
    env.DB.prepare("SELECT MAX(updated_at) AS version FROM (SELECT updated_at FROM catalog_products UNION ALL SELECT updated_at FROM catalog_convenios) AS versions"),
    env.DB.prepare("SELECT value FROM app_settings WHERE key = 'global_cleanup_marker'"),
  ]);
  let limpezaGlobal: Record<string, unknown> | null = null;
  const cleanupValue = (cleanup.results?.[0] as { value?: string } | undefined)?.value;
  if (cleanupValue) {
    try {
      const parsed = JSON.parse(cleanupValue) as unknown;
      if (parsed && typeof parsed === 'object') limpezaGlobal = parsed as Record<string, unknown>;
    } catch (_) {
      limpezaGlobal = null;
    }
  }
  return json(request, {
    ok: true,
    versao: (version.results?.[0] as { version?: string } | undefined)?.version ?? '',
    limpezaGlobal,
    produtos: products.results ?? [],
    convenios: convenios.results ?? [],
  });
};
