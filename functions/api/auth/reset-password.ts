import {
  type AuthEnv,
  digestSha256,
  hashPassword,
  json,
  optionsResponse,
  validPassword,
} from '../../_auth';

export const onRequestOptions: PagesFunction<AuthEnv> = ({ request }) => optionsResponse(request);

export const onRequestPost: PagesFunction<AuthEnv> = async ({ request, env }) => {
  const body = await request.json().catch(() => null) as { token?: unknown; newPassword?: unknown } | null;
  if (typeof body?.token !== 'string' || body.token.length < 32 || !validPassword(body.newPassword)) {
    return json(request, { error: 'Token ou senha inválidos.' }, 400);
  }
  const tokenHash = await digestSha256(body.token);
  const token = await env.DB.prepare(
    `SELECT token_hash, user_id FROM password_reset_tokens
     WHERE token_hash = ? AND used_at IS NULL AND expires_at > datetime('now')`,
  ).bind(tokenHash).first<{ token_hash: string; user_id: string }>();
  if (!token) return json(request, { error: 'O link é inválido, já foi usado ou expirou.' }, 400);

  const claimed = await env.DB.prepare("UPDATE password_reset_tokens SET used_at = datetime('now') WHERE token_hash = ? AND used_at IS NULL AND expires_at > datetime('now')").bind(tokenHash).run();
  if (!claimed.success || (claimed.meta?.changes ?? 0) !== 1) return json(request, { error: 'O link é inválido, já foi usado ou expirou.' }, 400);

  const password = await hashPassword(body.newPassword);
  const result = await env.DB.prepare(
    `UPDATE users SET password_hash = ?, password_salt = ?, must_change_password = 0, updated_at = datetime('now')
     WHERE id = ? AND active = 1`,
  ).bind(password.hash, password.salt, token.user_id).run();
  if (!result.success || (result.meta?.changes ?? 0) !== 1) return json(request, { error: 'Não foi possível redefinir a senha.' }, 400);
  await env.DB.prepare('DELETE FROM sessions WHERE user_id = ?').bind(token.user_id).run();
  return json(request, { ok: true });
};
