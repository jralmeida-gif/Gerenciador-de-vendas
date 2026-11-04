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
  const challenge = await env.DB.prepare(
    username
      ? "SELECT id, challenge FROM webauthn_challenges WHERE id = ? AND user_id = (SELECT id FROM users WHERE username = ? AND active = 1) AND purpose = 'authentication' AND used_at IS NULL AND expires_at > datetime('now')"
      : "SELECT id, challenge FROM webauthn_challenges WHERE id = ? AND user_id IS NULL AND purpose = 'authentication' AND used_at IS NULL AND expires_at > datetime('now')",
  ).bind(...(username ? [String(body?.challengeId ?? ''), username] : [String(body?.challengeId ?? '')])).first<{ id: string; challenge: string }>();
  const authentication = body?.authentication;
  const credentialId = String(authentication?.id ?? authentication?.rawId ?? '');
  const credential = credentialId
    ? await env.DB.prepare(
        `SELECT c.*, u.id AS user_id, u.username, u.role, u.must_change_password, u.active
         FROM webauthn_credentials c JOIN users u ON u.id = c.user_id
         WHERE c.credential_id = ? AND c.revoked_at IS NULL AND u.active = 1${username ? ' AND u.username = ?' : ''}`,
      ).bind(...(username ? [credentialId, username] : [credentialId])).first<any>()
    : null;
  const user = credential
    ? {
        id: credential.user_id as string,
        username: credential.username as string,
        role: credential.role as 'admin' | 'user',
        must_change_password: Number(credential.must_change_password),
        active: Number(credential.active),
      }
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
