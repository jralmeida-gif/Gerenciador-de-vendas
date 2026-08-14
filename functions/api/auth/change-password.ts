import {
  type AuthEnv,
  getSession,
  hashPassword,
  json,
  optionsResponse,
  validPassword,
  verifyPassword,
} from '../../_auth';

export const onRequestOptions: PagesFunction<AuthEnv> = ({ request }) => optionsResponse(request);

export const onRequestPost: PagesFunction<AuthEnv> = async ({ request, env }) => {
  const user = await getSession(request, env);
  if (!user) return json(request, { error: 'Sessão expirada.' }, 401);
  const body = await request.json().catch(() => null) as { currentPassword?: unknown; newPassword?: unknown } | null;
  if (!validPassword(body?.newPassword)) {
    return json(request, { error: 'A nova senha deve ter entre 8 e 128 caracteres.' }, 400);
  }
  if (typeof body?.currentPassword === 'string') {
    const stored = await env.DB.prepare('SELECT password_hash, password_salt FROM users WHERE id = ?').bind(user.id).first<{ password_hash: string; password_salt: string }>();
    if (!stored || !(await verifyPassword(body.currentPassword, stored.password_hash, stored.password_salt))) {
      return json(request, { error: 'Senha atual inválida.' }, 401);
    }
  }
  const password = await hashPassword(body.newPassword);
  await env.DB.prepare(
    `UPDATE users SET password_hash = ?, password_salt = ?, must_change_password = 0, updated_at = datetime('now') WHERE id = ?`,
  ).bind(password.hash, password.salt, user.id).run();
  return json(request, { ok: true });
};
