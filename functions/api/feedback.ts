import {
  type AuthEnv,
  getSession,
  json,
  optionsResponse,
} from '../_auth';

const MAX_SUBJECT_LENGTH = 120;
const MAX_MESSAGE_LENGTH = 2000;

type FeedbackKind = 'sugestao' | 'falha';

type FeedbackBody = {
  tipo?: unknown;
  assunto?: unknown;
  mensagem?: unknown;
};

const normalizeText = (value: unknown): string =>
  typeof value === 'string' ? value.trim() : '';

function isFeedbackKind(value: unknown): value is FeedbackKind {
  return value === 'sugestao' || value === 'falha';
}

function appearsToContainSensitiveData(value: string): boolean {
  const digitsOnly = value.replace(/\D/g, '');
  const hasCpf = /\b\d{3}\.?\d{3}\.?\d{3}-?\d{2}\b/.test(value);
  const hasPhone = digitsOnly.length >= 10 && digitsOnly.length <= 13;
  const hasSecretLabel = /\b(senha|senha\s+mestra|token|chave\s+(?:api|secreta|única))\b\s*[:=]\s*\S+/i.test(value);
  const hasCustomerLabel = /\b(cpf|telefone|celular|nome\s+do\s+cliente|dados\s+do\s+cliente)\b\s*[:=]\s*\S+/i.test(value);
  return hasCpf || hasPhone || hasSecretLabel || hasCustomerLabel;
}

export const onRequestOptions: PagesFunction<AuthEnv> = ({ request }) =>
  optionsResponse(request);

export const onRequestPost: PagesFunction<AuthEnv> = async ({ request, env }) => {
  const user = await getSession(request, env);
  if (!user) return json(request, { error: 'Sessão expirada.' }, 401);

  const body = await request.json().catch(() => null) as FeedbackBody | null;
  const tipo = body?.tipo;
  if (!isFeedbackKind(tipo)) {
    return json(request, { error: 'Escolha se a mensagem é uma sugestão ou uma falha.' }, 400);
  }

  const subject = normalizeText(body?.assunto);
  const message = normalizeText(body?.mensagem);
  if (subject.length > MAX_SUBJECT_LENGTH) {
    return json(request, { error: `O assunto deve ter no máximo ${MAX_SUBJECT_LENGTH} caracteres.` }, 400);
  }
  if (message.length < 10) {
    return json(request, { error: 'Descreva a sugestão ou a falha com pelo menos 10 caracteres.' }, 400);
  }
  if (message.length > MAX_MESSAGE_LENGTH) {
    return json(request, { error: `A descrição deve ter no máximo ${MAX_MESSAGE_LENGTH} caracteres.` }, 400);
  }
  if (appearsToContainSensitiveData(`${subject}\n${message}`)) {
    return json(request, {
      error: 'Não inclua CPF, telefone, dados de clientes, senha, token ou chave nesta mensagem.',
    }, 400);
  }

  await env.DB.prepare(
    `INSERT INTO user_feedback
      (id, user_id, username, kind, subject, message)
     VALUES (?, ?, ?, ?, ?, ?)`,
  ).bind(
    crypto.randomUUID(),
    user.id,
    user.username,
    tipo,
    subject,
    message,
  ).run();

  return json(request, {
    ok: true,
    message: 'Mensagem recebida. Obrigado por contribuir com a melhoria do sistema.',
  }, 201);
};

export const onRequestGet: PagesFunction<AuthEnv> = ({ request }) =>
  json(request, { error: 'Método não permitido.' }, 405);
