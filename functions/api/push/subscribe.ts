import { getSession, type AuthEnv, json, optionsResponse } from '../../_auth';

interface SubscriptionBody {
  endpoint?: string;
  expirationTime?: number | null;
  keys?: { p256dh?: string; auth?: string };
}

export const onRequestOptions: PagesFunction<AuthEnv> = ({ request }) => optionsResponse(request);

export const onRequestDelete: PagesFunction<AuthEnv> = async ({ request, env }) => {
  const user = await getSession(request, env);
  if (!user) return json(request, { error: 'Sessão expirada.' }, 401);
  const body = (await request.json().catch(() => ({}))) as SubscriptionBody;
  const endpoint = body.endpoint?.trim();
  if (!endpoint) return json(request, { error: 'Endpoint de push ausente.' }, 400);
  await env.DB.prepare('DELETE FROM push_subscriptions WHERE endpoint = ? AND user_id = ?').bind(endpoint, user.id).run();
  return json(request, { ok: true });
};

export const onRequestPost: PagesFunction<AuthEnv> = async ({ request, env }) => {
  const user = await getSession(request, env);
  if (!user) return json(request, { error: 'Sessão expirada.' }, 401);
  const body = (await request.json().catch(() => ({}))) as SubscriptionBody;
  const endpoint = body.endpoint?.trim();
  const p256dh = body.keys?.p256dh?.trim();
  const auth = body.keys?.auth?.trim();
  if (!endpoint || !p256dh || !auth) return json(request, { error: 'Inscrição de push inválida.' }, 400);

  await env.DB.prepare(
    `INSERT INTO push_subscriptions (endpoint, user_id, p256dh, auth, expiration_time, updated_at)
     VALUES (?, ?, ?, ?, ?, datetime('now'))
     ON CONFLICT(endpoint) DO UPDATE SET
      user_id = excluded.user_id, p256dh = excluded.p256dh, auth = excluded.auth,
      expiration_time = excluded.expiration_time, updated_at = datetime('now')`,
  ).bind(endpoint, user.id, p256dh, auth, body.expirationTime ?? null).run();
  return json(request, { ok: true });
};
