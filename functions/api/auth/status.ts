import { type AuthEnv, json, optionsResponse } from '../../_auth';

export const onRequestOptions: PagesFunction<AuthEnv> = ({ request }) => optionsResponse(request);

export const onRequestGet: PagesFunction<AuthEnv> = async ({ request, env }) => {
  const row = await env.DB.prepare('SELECT COUNT(*) AS count FROM users').first<{ count: number }>();
  return json(request, { setupRequired: (row?.count ?? 0) === 0 });
};
