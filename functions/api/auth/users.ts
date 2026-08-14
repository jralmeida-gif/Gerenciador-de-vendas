import {
  type AuthEnv,
  getSession,
  hashPassword,
  isAdmin,
  json,
  normalizeUsername,
  optionsResponse,
  validPassword,
} from '../../_auth';

export const onRequestOptions: PagesFunction<AuthEnv> = ({ request }) => optionsResponse(request);

async function requireAdmin(request: Request, env: AuthEnv) {
  const user = await getSession(request, env);
  return isAdmin(user) ? user : null;
}

export const onRequestGet: PagesFunction<AuthEnv> = async ({ request, env }) => {
  if (!await requireAdmin(request, env)) return json(request, { error: 'Acesso restrito aos administradores.' }, 403);
  const rows = await env.DB.prepare(
    `SELECT id, username, role, must_change_password, active, created_at, updated_at
     FROM users ORDER BY username`,
  ).all();
  return json(request, { users: rows.results ?? [] });
};

export const onRequestPost: PagesFunction<AuthEnv> = async ({ request, env }) => {
  const admin = await requireAdmin(request, env);
  if (!admin) return json(request, { error: 'Acesso restrito aos administradores.' }, 403);
  const body = await request.json().catch(() => null) as { username?: unknown; password?: unknown; role?: unknown } | null;
  const username = normalizeUsername(body?.username);
  const role = body?.role === 'admin' ? 'admin' : body?.role === 'user' ? 'user' : null;
  if (!username || !role || !validPassword(body?.password)) {
    return json(request, { error: 'Usuário, perfil e senha temporária são obrigatórios.' }, 400);
  }
  const password = await hashPassword(body!.password as string);
  const id = crypto.randomUUID();
  try {
    await env.DB.prepare(
      `INSERT INTO users (id, username, role, password_hash, password_salt, must_change_password)
       VALUES (?, ?, ?, ?, ?, 1)`,
    ).bind(id, username, role, password.hash, password.salt).run();
    return json(request, { ok: true, user: { id, username, role, mustChangePassword: true } }, 201);
  } catch (error) {
    const message = String(error).toLowerCase().includes('unique')
      ? 'Já existe um usuário com esse identificador.'
      : 'Não foi possível cadastrar o usuário.';
    return json(request, { error: message }, 400);
  }
};

export const onRequestPatch: PagesFunction<AuthEnv> = async ({ request, env }) => {
  const admin = await requireAdmin(request, env);
  if (!admin) return json(request, { error: 'Acesso restrito aos administradores.' }, 403);
  const body = await request.json().catch(() => null) as { id?: unknown; role?: unknown; active?: unknown; password?: unknown } | null;
  if (typeof body?.id !== 'string') return json(request, { error: 'Usuário inválido.' }, 400);
  const target = await env.DB.prepare('SELECT id, role, active FROM users WHERE id = ?').bind(body.id).first<{ id: string; role: 'admin' | 'user'; active: number }>();
  if (!target) return json(request, { error: 'Usuário não encontrado.' }, 404);
  if (target.id === admin.id && body.active === false) return json(request, { error: 'Você não pode desativar a própria conta.' }, 400);
  const statements: D1PreparedStatement[] = [];
  if (body?.role === 'admin' || body?.role === 'user') {
    if (body.id === admin.id && body.role !== 'admin') return json(request, { error: 'Você não pode remover seu próprio perfil de administrador.' }, 400);
    statements.push(env.DB.prepare('UPDATE users SET role = ?, updated_at = datetime(\'now\') WHERE id = ?').bind(body.role, body.id));
  }
  if (typeof body?.active === 'boolean') statements.push(env.DB.prepare('UPDATE users SET active = ?, updated_at = datetime(\'now\') WHERE id = ?').bind(body.active ? 1 : 0, body.id));
  if (validPassword(body?.password)) {
    const password = await hashPassword(body.password as string);
    statements.push(env.DB.prepare('UPDATE users SET password_hash = ?, password_salt = ?, must_change_password = 1, updated_at = datetime(\'now\') WHERE id = ?').bind(password.hash, password.salt, body.id));
  }
  if (statements.length === 0) return json(request, { error: 'Nenhuma alteração informada.' }, 400);
  await env.DB.batch(statements);
  return json(request, { ok: true });
};
