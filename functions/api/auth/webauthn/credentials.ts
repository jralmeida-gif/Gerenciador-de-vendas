import {
  getSession,
  json,
  optionsResponse,
  type AuthEnv,
} from '../../../_auth';

export const onRequestOptions: PagesFunction<AuthEnv> = ({ request }) => optionsResponse(request);

export const onRequestGet: PagesFunction<AuthEnv> = async ({ request, env }) => {
  const user = await getSession(request, env);
  if (!user) return json(request, { error: 'Sessão expirada.' }, 401);
  const result = await env.DB.prepare(
    'SELECT id, nickname, created_at, last_used_at FROM webauthn_credentials WHERE user_id = ? AND revoked_at IS NULL ORDER BY created_at DESC',
  ).bind(user.id).all();
  return json(request, { credentials: result.results });
};
