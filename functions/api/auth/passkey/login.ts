import { server as webauthnServer } from '@passwordless-id/webauthn';
import {
  createSession,
  json,
  normalizeUsername,
  optionsResponse,
  recordActivity,
  type AuthEnv,
  webAuthnOrigin,
  webAuthnRpId,
} from '../../../_auth';

export const onRequestOptions: PagesFunction<AuthEnv> = ({ request }) => optionsResponse(request);

export const onRequestPost: PagesFunction<AuthEnv> = async ({ request, env }) => {
  const body = await request.json().catch(() => null) as {
    username?: unknown;
    challengeId?: unknown;
    authentication?: any;
  } | null;
  const username = normalizeUsername(body?.username);
  const user = username
    ? await env.DB.prepare(
        'SELECT id, username, role, must_change_password, active FROM users WHERE username = ? AND active = 1',
      ).bind(username).first<{
        id: string; username: string; role: 'admin' | 'user'; must_change_password: number; active: number;
      }>()
    : null;
  const challenge = user
    ? await env.DB.prepare(
        "SELECT id, challenge FROM webauthn_challenges WHERE id = ? AND user_id = ? AND purpose = 'authentication' AND used_at IS NULL AND expires_at > datetime('now')",
      ).bind(String(body?.challengeId ?? ''), user.id).first<{ id: string; challenge: string }>()
    : null;
  const authentication = body?.authentication;
  const credentialId = String(authentication?.id ?? authentication?.rawId ?? '');
  const credential = user && credentialId
    ? await env.DB.prepare(
        'SELECT * FROM webauthn_credentials WHERE user_id = ? AND credential_id = ? AND revoked_at IS NULL',
      ).bind(user.id, credentialId).first<any>()
    : null;
  if (!user || !challenge || !credential || !authentication) {
    return json(request, { error: 'Biometria inválida ou expirada.' }, 401);
  }
  try {
    const verified = await webauthnServer.verifyAuthentication(authentication, {
      id: credential.credential_id,
      publicKey: credential.public_key,
      algorithm: credential.algorithm,
      transports: JSON.parse(credential.transports_json || '[]'),
    }, {
      challenge: challenge.challenge,
      origin: webAuthnOrigin(request),
      domain: webAuthnRpId(request, env),
      userVerified: true,
      counter: Number(credential.sign_count || 0),
    });
    await env.DB.batch([
      env.DB.prepare('UPDATE webauthn_challenges SET used_at = datetime(\'now\') WHERE id = ?').bind(challenge.id),
      env.DB.prepare(
        'UPDATE webauthn_credentials SET sign_count = ?, last_used_at = datetime(\'now\') WHERE id = ?',
      ).bind(verified.counter, credential.id),
    ]);
    const headers = await createSession(request, env, user.id);
    await recordActivity(env, user, 'login_biometria', 'dispositivo=passkey');
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
  } catch (error) {
    console.error('[webauthn] authentication failed', error);
    return json(request, { error: 'A confirmação biométrica não pôde ser validada.' }, 401);
  }
};
