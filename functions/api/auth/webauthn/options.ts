import {
  getSession,
  json,
  optionsResponse,
  randomChallenge,
  type AuthEnv,
  webAuthnOrigin,
  webAuthnRpId,
} from '../../../_auth';

export const onRequestOptions: PagesFunction<AuthEnv> = ({ request }) => optionsResponse(request);

export const onRequestPost: PagesFunction<AuthEnv> = async ({ request, env }) => {
  const user = await getSession(request, env);
  if (!user) return json(request, { error: 'Sessão expirada.' }, 401);
  const body = await request.json().catch(() => null) as { force?: unknown } | null;
  const existing = await env.DB.prepare(
    'SELECT id FROM webauthn_credentials WHERE user_id = ? AND revoked_at IS NULL LIMIT 1',
  ).bind(user.id).first<{ id: string }>();
  if (existing && body?.force !== true) return json(request, { alreadyRegistered: true });
  const challengeId = crypto.randomUUID();
  const challenge = randomChallenge();
  await env.DB.prepare(
    "INSERT INTO webauthn_challenges (id, user_id, challenge, purpose, expires_at) VALUES (?, ?, ?, 'registration', datetime('now', '+5 minutes'))",
  ).bind(challengeId, user.id, challenge).run();
  return json(request, {
    challengeId,
    challenge,
    rpId: webAuthnRpId(request, env),
    origin: webAuthnOrigin(request),
    user: { id: user.id, name: user.username, displayName: user.username },
    timeout: 60000,
    userVerification: 'required',
  });
};
