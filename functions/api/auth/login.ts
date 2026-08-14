import {
  type AuthEnv,
  createSession,
  json,
  normalizeUsername,
  optionsResponse,
  verifyPassword,
} from '../../_auth';

export const onRequestOptions: PagesFunction<AuthEnv> = ({ request }) => optionsResponse(request);

export const onRequestPost: PagesFunction<AuthEnv> = async ({ request, env }) => {
  const body = await request.json().catch(() => null) as { username?: unknown; password?: unknown } | null;
  const username = normalizeUsername(body?.username);
  if (!username || typeof body?.password !== 'string') {
    return json(request, { error: 'Usuário ou senha inválidos.' }, 401);
  }

  const user = await env.DB.prepare(
    `SELECT id, username, role, password_hash, password_salt, must_change_password, active
     FROM users WHERE username = ?`,
  ).bind(username).first<{
    id: string;
    username: string;
    role: 'admin' | 'user';
    password_hash: string;
    password_salt: string;
    must_change_password: number;
    active: number;
  }>();
  if (!user || user.active !== 1 || !(await verifyPassword(body.password, user.password_hash, user.password_salt))) {
    return json(request, { error: 'Usuário ou senha inválidos.' }, 401);
  }

  const headers = await createSession(request, env, user.id);
  headers.set('Content-Type', 'application/json; charset=utf-8');
  return new Response(JSON.stringify({
    ok: true,
    user: {
      id: user.id,
      username: user.username,
      role: user.role,
      mustChangePassword: user.must_change_password === 1,
    },
  }), { headers });
};
