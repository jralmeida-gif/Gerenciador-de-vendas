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
function maskEmail(value: string): string {
  const [local, domain] = value.trim().toLowerCase().split('@');
  const visible = local.slice(0, Math.min(2, local.length));
  return `${visible}${'*'.repeat(Math.max(1, Math.min(4, local.length)))}@${domain}`;
}
function mailjetStateReason(stateId?: number): string | undefined {
  const reasons: Record<number, string> = {
    1: 'destinatário inexistente', 2: 'caixa postal inativa', 3: 'cota da caixa postal excedida', 4: 'domínio inválido',
    6: 'servidor do destinatário recusou a entrega', 7: 'remetente bloqueado por spam', 8: 'conteúdo bloqueado',
    9: 'problema de política do servidor destinatário', 14: 'destinatário pré-bloqueado pela Mailjet', 16: 'mensagem pré-bloqueada como spam',
    20: 'destinatário em lista de bloqueio',
  };
  return stateId == null ? undefined : reasons[stateId] ?? `falha de entrega (código ${stateId})`;
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
  const envRecord = env as unknown as Record<string, unknown>;
  const readEnv = (...names: string[]) => names.map((name) => envRecord[name]).find((value) => typeof value === 'string' && value.trim() !== '') as string | undefined;
  const apiKey = readEnv('MAILJET_API_KEY', 'mailjetapikey', 'Mailjetapikey', 'MJ_APIKEY_PUBLIC');
  const secretKey = readEnv('MAILJET_SECRET_KEY', 'mailjetsecretkey', 'Mailjetsecretkey', 'MJ_APIKEY_PRIVATE');
  const fromEmail = 'recuperarsenha.gestordevendas@gmail.com';
  if (!apiKey || !secretKey) {
    const missing = [!apiKey ? 'chave pública (MAILJET_API_KEY)' : '', !secretKey ? 'chave privada (MAILJET_SECRET_KEY)' : ''].filter(Boolean).join(', ');
    const detectedBindings = Object.keys(envRecord).filter((key) => key.toLowerCase().includes('mailjet'));
    return json(request, { error: `O serviço de recuperação está incompleto: falta configurar ${missing}.`, detectedBindings }, 503);
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
      From: { Email: fromEmail, Name: fromName },
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
  const mailBody = await mail.json().catch(() => null) as {
    Messages?: Array<{ Status?: string; ErrorInfo?: string; To?: Array<{ MessageID?: number; MessageUUID?: string }> }>
  } | null;
  const mailMessage = mailBody?.Messages?.[0];
  const mailStatus = mailMessage?.Status?.toLowerCase();
  if (!mail.ok || mailStatus !== 'success') {
    await env.DB.prepare('DELETE FROM password_reset_tokens WHERE token_hash = ?').bind(tokenHash).run();
    const detail = mailBody?.Messages?.[0]?.ErrorInfo;
    return json(request, { error: detail ? `A Mailjet recusou o envio: ${detail}` : 'Não foi possível enviar o e-mail de recuperação.' }, 502);
  }
  let deliveryStatus = 'queued';
  let deliveryReason: string | undefined;
  const messageId = mailMessage?.To?.[0]?.MessageID;
  if (messageId) {
    const statusResponse = await fetch(`https://api.mailjet.com/v3/REST/message/${messageId}`, {
      headers: { Authorization: `Basic ${auth}` },
    });
    const statusBody = await statusResponse.json().catch(() => null) as { Data?: Array<{ Status?: string; StateID?: number }> } | null;
    const statusRecord = statusBody?.Data?.[0];
    deliveryStatus = statusRecord?.Status?.toLowerCase() ?? deliveryStatus;
    deliveryReason = mailjetStateReason(statusRecord?.StateID);

    const historyResponse = await fetch(`https://api.mailjet.com/v3/REST/messagehistory/${messageId}`, {
      headers: { Authorization: `Basic ${auth}` },
    });
    const historyBody = await historyResponse.json().catch(() => null) as { Data?: Array<{ EventType?: string; State?: string; Comment?: string }> } | null;
    const latestEvent = historyBody?.Data?.[historyBody.Data.length - 1];
    if (latestEvent?.EventType) {
      deliveryStatus = latestEvent.EventType.toLowerCase();
      deliveryReason = latestEvent.State || latestEvent.Comment || deliveryReason;
    }
  }
  const statusText = deliveryStatus === 'queued'
    ? 'A Mailjet aceitou e colocou a mensagem na fila.'
    : deliveryStatus === 'sent'
      ? 'A mensagem foi enviada e aceita pelo servidor do destinatário.'
      : deliveryStatus === 'bounce' || deliveryStatus === 'hardbounced' || deliveryStatus === 'softbounced' || deliveryStatus === 'blocked'
        ? `A Mailjet registrou o status “${deliveryStatus}”.${deliveryReason ? ` Motivo: ${deliveryReason}.` : ''}`
        : 'A Mailjet aceitou a mensagem; a entrega ainda está sendo processada.';
  return json(request, {
    ok: true,
    message: statusText,
    delivery: {
      recipient: maskEmail(user.recovery_email),
      status: deliveryStatus,
      messageId: messageId?.toString() ?? null,
      reason: deliveryReason ?? null,
    },
  });
};
