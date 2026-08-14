import { clearSessionHeaders, json, optionsResponse, removeSession, type AuthEnv } from '../../_auth';

export const onRequestOptions: PagesFunction<AuthEnv> = ({ request }) => optionsResponse(request);

export const onRequestPost: PagesFunction<AuthEnv> = async ({ request, env }) => {
  await removeSession(request, env);
  const headers = clearSessionHeaders(request);
  headers.set('Content-Type', 'application/json; charset=utf-8');
  return new Response(JSON.stringify({ ok: true }), { headers });
};
