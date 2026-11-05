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

function decodeBase64UrlText(value: unknown): string | null {
  if (typeof value !== 'string' || !value) return null;
  try {
    const normalized = value.replace(/-/g, '+').replace(/_/g, '/')
      .padEnd(Math.ceil(value.length / 4) * 4, '=');
    const bytes = Uint8Array.from(atob(normalized), (char) => char.charCodeAt(0));
    return new TextDecoder().decode(bytes);
  } catch (_) {
    return null;
  }
}

export const onRequestPost: PagesFunction<AuthEnv> = async ({ request, env }) => {
  const body = await request.json().catch(() => null) as {
    username?: unknown;
    challengeId?: unknown;
    authentication?: any;
  } | null;
  const username = normalizeUsername(body?.username);
  const authentication = body?.authentication;
  const credentialId = String(authentication?.id ?? authentication?.rawId ?? '');
  const userHandle = decodeBase64UrlText(authentication?.response?.userHandle);
  let credential = credentialId
    ? await env.DB.prepare(
        `SELECT c.*, u.id AS user_id, u.username, u.role, u.must_change_password, u.active
         FROM webauthn_credentials c JOIN users u ON u.id = c.user_id
         WHERE c.credential_id IN (?, ?) AND c.revoked_at IS NULL AND u.active = 1${username ? ' AND u.username = ?' : ''}`,
      ).bind(...(username ? [credentialId, String(authentication?.rawId ?? ''), username] : [credentialId, String(authentication?.rawId ?? '')])).first<any>()
    : null;
  if (!credential && userHandle) {
    credential = await env.DB.prepare(
      `SELECT c.*, u.id AS user_id, u.username, u.role, u.must_change_password, u.active
       FROM webauthn_credentials c JOIN users u ON u.id = c.user_id
       WHERE c.user_id = ? AND c.revoked_at IS NULL AND u.active = 1${username ? ' AND u.username = ?' : ''}
       ORDER BY c.created_at DESC LIMIT 1`,
    ).bind(...(username ? [userHandle, username] : [userHandle])).first<any>();
  }
  const user = credential
    ? {
        id: credential.user_id as string,
        username: credential.username as string,
        role: credential.role as 'admin' | 'user',
        must_change_password: Number(credential.must_change_password),
        active: Number(credential.active),
      }
    : null;
  const resolvedUserId = user?.id ?? userHandle;
  const challenge = resolvedUserId
    ? await env.DB.prepare(
        "SELECT id, challenge FROM webauthn_challenges WHERE id = ? AND (user_id IS NULL OR user_id = ?) AND purpose = 'authentication' AND used_at IS NULL AND expires_at > datetime('now')",
      ).bind(String(body?.challengeId ?? ''), resolvedUserId).first<{ id: string; challenge: string }>()
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
