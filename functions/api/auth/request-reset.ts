import {
  type AuthEnv,
  createRecoveryToken,
  digestSha256,
  json,
  normalizeUsername,
  optionsResponse,
} from '../../_auth';

const GENERIC_MESSAGE = 'Se houver uma conta elegível, enviaremos as instruções para o e-mail de recuperação cadastrado.';

function validEmail(value: unknown): value is string {
  return typeof value === 'string' && /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(value.trim()) && value.trim().length <= 254;
}

export const onRequestOptions: PagesFunction<AuthEnv> = ({ request }) => optionsResponse(request);

export const onRequestPost: PagesFunction<AuthEnv> = async ({ request, env }) => {
  const body = await request.json().catch(() => null) as { username?: unknown } | null;
  const username = normalizeUsername(body?.username);
  if (!username) return json(request, { ok: true, message: GENERIC_MESSAGE });

  const user = await env.DB.prepare(
    `SELECT u.id, u.username, s.recovery_email
     FROM users u JOIN user_settings s ON s.user_id = u.id
     WHERE u.username = ? AND u.active = 1 AND s.recovery_email <> ''`,
  ).bind(username).first<{ id: string; username: string; recovery_email: string }>();
  if (!user || !validEmail(user.recovery_email)) return json(request, { ok: true, message: GENERIC_MESSAGE });
  const apiKey = env.MAILJET_API_KEY ?? env.mailjetapikey;
  const secretKey = env.MAILJET_SECRET_KEY ?? env.mailjetsecretkey;
  if (!apiKey || !secretKey || !env.MAILJET_FROM_EMAIL) {
    return json(request, { error: 'O serviço de recuperação ainda não está configurado.' }, 503);
  }

  const token = createRecoveryToken();
  const tokenHash = await digestSha256(token);
  await env.DB.batch([
    env.DB.prepare("DELETE FROM password_reset_tokens WHERE user_id = ? OR expires_at <= datetime('now')").bind(user.id),
    env.DB.prepare("INSERT INTO password_reset_tokens (token_hash, user_id, expires_at) VALUES (?, ?, datetime('now', '+30 minutes'))").bind(tokenHash, user.id),
  ]);

  const origin = new URL(request.url).origin;
  const link = `${origin}/?reset_token=${encodeURIComponent(token)}`;
  const fromName = env.MAILJET_FROM_NAME || 'Gestor de Vendas';
  const payload = {
    Messages: [{
      From: { Email: env.MAILJET_FROM_EMAIL, Name: fromName },
      To: [{ Email: user.recovery_email }],
      Subject: 'Redefinição de senha — Gestor de Vendas',
      TextPart: `Solicitação de redefinição de senha\n\nAbra este link em até 30 minutos para criar uma nova senha:\n${link}\n\nSe você não fez esta solicitação, ignore este e-mail.`,
      HTMLPart: `<p>Recebemos uma solicitação de redefinição de senha.</p><p><a href="${link}">Criar uma nova senha</a></p><p>O link expira em 30 minutos. Se você não fez esta solicitação, ignore este e-mail.</p>`,
    }],
  };
  const auth = btoa(`${apiKey}:${secretKey}`);
  const mail = await fetch('https://api.mailjet.com/v3.1/send', {
    method: 'POST',
    headers: { Authorization: `Basic ${auth}`, 'Content-Type': 'application/json' },
    body: JSON.stringify(payload),
  });
  if (!mail.ok) {
    await env.DB.prepare('DELETE FROM password_reset_tokens WHERE token_hash = ?').bind(tokenHash).run();
    return json(request, { error: 'Não foi possível enviar o e-mail de recuperação.' }, 502);
  }
  return json(request, { ok: true, message: GENERIC_MESSAGE });
};
