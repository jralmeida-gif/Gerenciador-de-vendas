import {
  json,
  normalizeUsername,
  optionsResponse,
  randomChallenge,
  type AuthEnv,
  webAuthnRpId,
} from '../../../_auth';

export const onRequestOptions: PagesFunction<AuthEnv> = ({ request }) => optionsResponse(request);

export const onRequestPost: PagesFunction<AuthEnv> = async ({ request, env }) => {
  const body = await request.json().catch(() => null) as {
    username?: unknown;
    discoverable?: unknown;
  } | null;
  const username = normalizeUsername(body?.username);
  const discoverable = body?.discoverable === true || !username;
  const user = username
    ? await env.DB.prepare(
        'SELECT id, username FROM users WHERE username = ? AND active = 1',
      ).bind(username).first<{ id: string; username: string }>()
    : null;
  if (username && !user) return json(request, { error: 'Usuário ou biometria inválidos.' }, 401);
  const credentials = user
    ? await env.DB.prepare(
        'SELECT credential_id, transports_json FROM webauthn_credentials WHERE user_id = ? AND revoked_at IS NULL',
      ).bind(user.id).all<{ credential_id: string; transports_json: string }>()
    : { results: [] as { credential_id: string; transports_json: string }[] };
  if (!discoverable && credentials.results.length === 0) {
    return json(request, { error: 'Não há biometria cadastrada para este usuário neste dispositivo.' }, 404);
  }
  const challengeId = crypto.randomUUID();
  const challenge = randomChallenge();
  await env.DB.prepare(
    "INSERT INTO webauthn_challenges (id, user_id, challenge, purpose, expires_at) VALUES (?, ?, ?, 'authentication', datetime('now', '+5 minutes'))",
  ).bind(challengeId, user?.id ?? null, challenge).run();
  return json(request, {
    challengeId,
    challenge,
    rpId: webAuthnRpId(request, env),
    timeout: 60000,
    userVerification: 'required',
    allowCredentials: discoverable ? [] : credentials.results.map((item) => ({
      id: item.credential_id,
      type: 'public-key',
      transports: JSON.parse(item.transports_json || '[]'),
    })),
  });
};
