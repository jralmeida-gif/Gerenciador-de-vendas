import { server as webauthnServer } from '@passwordless-id/webauthn';
import {
  getSession,
  json,
  optionsResponse,
  recordActivity,
  type AuthEnv,
  webAuthnOrigin,
  webAuthnRpId,
} from '../../../_auth';

export const onRequestOptions: PagesFunction<AuthEnv> = ({ request }) => optionsResponse(request);

export const onRequestPost: PagesFunction<AuthEnv> = async ({ request, env }) => {
  const user = await getSession(request, env);
  if (!user) return json(request, { error: 'Sessão expirada.' }, 401);
  const body = await request.json().catch(() => null) as {
    challengeId?: unknown;
    registration?: unknown;
    nickname?: unknown;
  } | null;
  const challengeId = typeof body?.challengeId === 'string' ? body.challengeId : '';
  const challenge = await env.DB.prepare(
    "SELECT id, challenge FROM webauthn_challenges WHERE id = ? AND user_id = ? AND purpose = 'registration' AND used_at IS NULL AND expires_at > datetime('now')",
  ).bind(challengeId, user.id).first<{ id: string; challenge: string }>();
  if (!challenge || !body?.registration) {
    return json(request, { error: 'Desafio de biometria expirado. Tente novamente.' }, 400);
  }
  try {
    const verified = await webauthnServer.verifyRegistration(body.registration as any, {
      challenge: challenge.challenge,
      origin: webAuthnOrigin(request),
      domain: webAuthnRpId(request, env),
      userVerified: true,
    });
    const duplicate = await env.DB.prepare(
      'SELECT id FROM webauthn_credentials WHERE credential_id = ?',
    ).bind(verified.credential.id).first();
    if (duplicate) return json(request, { error: 'Esta biometria já está cadastrada neste Gestor.' }, 409);
    await env.DB.batch([
      env.DB.prepare(
        'INSERT INTO webauthn_credentials (id, user_id, credential_id, public_key, algorithm, sign_count, transports_json, nickname) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
      ).bind(
        crypto.randomUUID(),
        user.id,
        verified.credential.id,
        verified.credential.publicKey,
        verified.credential.algorithm,
        verified.authenticator.counter,
        JSON.stringify(verified.credential.transports ?? []),
        typeof body.nickname === 'string' && body.nickname.trim() ? body.nickname.trim().slice(0, 80) : 'Este dispositivo',
      ),
      env.DB.prepare('UPDATE webauthn_challenges SET used_at = datetime(\'now\') WHERE id = ?').bind(challenge.id),
    ]);
    await recordActivity(env, user, 'passkey_cadastrada', 'dispositivo=atual');
    return json(request, { ok: true, registered: true });
  } catch (error) {
    console.error('[webauthn] registration failed', error);
    return json(request, { error: 'Não foi possível validar a biometria deste dispositivo.' }, 400);
  }
};
