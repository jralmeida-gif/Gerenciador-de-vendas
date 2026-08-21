import {
  type AuthEnv,
  getSession,
  json,
  optionsResponse,
  verifyPassword,
} from '../../_auth';

export const onRequestOptions: PagesFunction<AuthEnv> = ({ request }) => optionsResponse(request);

export const onRequestPost: PagesFunction<AuthEnv> = async ({ request, env }) => {
  const user = await getSession(request, env);
  if (!user) return json(request, { error: 'Sessão expirada.' }, 401);

  const body = await request.json().catch(() => null) as { password?: unknown } | null;
  if (typeof body?.password !== 'string' || body.password.length === 0) {
    return json(request, { error: 'Informe sua senha.' }, 400);
  }

  const stored = await env.DB.prepare(
    'SELECT password_hash, password_salt FROM users WHERE id = ?',
  ).bind(user.id).first<{ password_hash: string; password_salt: string }>();
  if (!stored || !(await verifyPassword(body.password, stored.password_hash, stored.password_salt))) {
    return json(request, { error: 'Senha inválida.' }, 401);
  }

  return json(request, { ok: true });
};

export const onRequestGet: PagesFunction<AuthEnv> = ({ request }) =>
  json(request, { error: 'Método não permitido.' }, 405);
