import {
  getSession,
  json,
  optionsResponse,
  recordActivity,
  type AuthEnv,
} from '../../../../_auth';

export const onRequestOptions: PagesFunction<AuthEnv> = ({ request }) => optionsResponse(request);

export const onRequestDelete: PagesFunction<AuthEnv> = async ({ request, env, params }) => {
  const user = await getSession(request, env);
  if (!user) return json(request, { error: 'Sessão expirada.' }, 401);
  const id = String(params.id ?? '');
  const result = await env.DB.prepare(
    'UPDATE webauthn_credentials SET revoked_at = datetime(\'now\') WHERE id = ? AND user_id = ? AND revoked_at IS NULL',
  ).bind(id, user.id).run();
  if (!result.meta.changes) return json(request, { error: 'Dispositivo biométrico não encontrado.' }, 404);
  await recordActivity(env, user, 'passkey_revogada', 'dispositivo=passkey');
  return json(request, { ok: true });
};
