import {
  getSession,
  isAdmin,
  json,
  optionsResponse,
  type AuthEnv,
} from '../../_auth';

export const onRequestOptions: PagesFunction<AuthEnv> = ({ request }) =>
  optionsResponse(request);

export const onRequestGet: PagesFunction<AuthEnv> = async ({ request, env }) => {
  const admin = await getSession(request, env);
  if (!isAdmin(admin)) {
    return json(request, {
      error: 'Acesso restrito aos administradores.',
    }, 403);
  }

  const rawLimit = Number(
    new URL(request.url).searchParams.get('limit') ?? '100',
  );
  const limit = Number.isFinite(rawLimit)
    ? Math.min(200, Math.max(1, Math.trunc(rawLimit)))
    : 100;
  const rows = await env.DB.prepare(
    `SELECT id, actor_username, actor_role,
            activity, result, created_at
       FROM admin_activity_log
      ORDER BY created_at DESC
      LIMIT ?`,
  ).bind(limit).all();

  return json(request, {
    ok: true,
    activities: rows.results ?? [],
  });
};

export const onRequestPost: PagesFunction<AuthEnv> = ({ request }) =>
  json(request, { error: 'Método não permitido.' }, 405);

export const onRequestPatch: PagesFunction<AuthEnv> = ({ request }) =>
  json(request, { error: 'Método não permitido.' }, 405);

export const onRequestDelete: PagesFunction<AuthEnv> = ({ request }) =>
  json(request, { error: 'Método não permitido.' }, 405);
