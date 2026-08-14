import {
  type AuthEnv,
  createSession,
  hashPassword,
  json,
  normalizeUsername,
  optionsResponse,
  validPassword,
} from '../../_auth';

export const onRequestOptions: PagesFunction<AuthEnv> = ({ request }) => optionsResponse(request);

export const onRequestPost: PagesFunction<AuthEnv> = async ({ request, env }) => {
  const body = await request.json().catch(() => null) as { username?: unknown; password?: unknown } | null;
  const username = normalizeUsername(body?.username);
  if (!username || !validPassword(body?.password)) {
    return json(request, { error: 'Informe usuário válido e senha com pelo menos 8 caracteres.' }, 400);
  }

  const hash = await hashPassword(body!.password as string);
  const userId = crypto.randomUUID();
  try {
    const result = await env.DB.batch([
      env.DB.prepare("INSERT OR IGNORE INTO app_settings (key, value) VALUES ('bootstrap_complete', '1')"),
      env.DB.prepare(
        `INSERT INTO users (id, username, role, password_hash, password_salt, must_change_password)
         SELECT ?, ?, 'admin', ?, ?, 0
         WHERE NOT EXISTS (SELECT 1 FROM users)`,
      ).bind(userId, username, hash.hash, hash.salt),
    ]);
    const inserted = result[1]?.meta?.changes ?? 0;
    if (inserted !== 1) return json(request, { error: 'O primeiro administrador já foi cadastrado.' }, 409);

    await env.DB.batch([
      env.DB.prepare("UPDATE push_subscriptions SET user_id = ? WHERE user_id = 'unassigned'").bind(userId),
      env.DB.prepare("UPDATE portabilidades SET user_id = ? WHERE user_id = 'unassigned'").bind(userId),
      env.DB.prepare("UPDATE prospeccoes SET user_id = ? WHERE user_id = 'unassigned'").bind(userId),
      env.DB.prepare("UPDATE notifications_sent SET user_id = ? WHERE user_id = 'unassigned'").bind(userId),
    ]);

    const headers = await createSession(request, env, userId);
    headers.set('Content-Type', 'application/json; charset=utf-8');
    return new Response(JSON.stringify({ ok: true, user: { id: userId, username, role: 'admin', mustChangePassword: false } }), { headers });
  } catch (error) {
    console.error('Falha no bootstrap do administrador', error);
    return json(request, { error: 'Não foi possível criar o administrador.' }, 500);
  }
};
