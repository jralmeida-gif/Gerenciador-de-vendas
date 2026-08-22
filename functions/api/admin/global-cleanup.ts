import {
  getSession,
  isAdmin,
  type AuthEnv,
  json,
  optionsResponse,
  verifyPassword,
} from '../../_auth';

type GlobalCleanupBody = {
  password?: unknown;
  masterPassword?: unknown;
  catalogo?: unknown;
  dadosUsuario?: unknown;
};

type GlobalCleanupMarker = {
  versao: string;
  dadosNegocio: true;
  catalogo: boolean;
  dadosUsuario: boolean;
  usuariosRemovidos: string[];
};

const text = (value: unknown) => value == null ? '' : String(value).trim();

async function requireAdmin(request: Request, env: AuthEnv) {
  const user = await getSession(request, env);
  return isAdmin(user) ? user : null;
}

function marker(versao: string, catalogo: boolean, dadosUsuario: boolean, usuariosRemovidos: string[]): GlobalCleanupMarker {
  return {
    versao,
    dadosNegocio: true,
    catalogo,
    dadosUsuario,
    usuariosRemovidos,
  };
}

export const onRequestOptions: PagesFunction<AuthEnv> = ({ request }) => optionsResponse(request);

export const onRequestPost: PagesFunction<AuthEnv> = async ({ request, env }) => {
  const admin = await requireAdmin(request, env);
  if (!admin) return json(request, { error: 'Acesso restrito aos administradores.' }, 403);

  const body = await request.json().catch(() => null) as GlobalCleanupBody | null;
  const password = text(body?.password);
  const masterPassword = text(body?.masterPassword);
  const catalogo = body?.catalogo === true;
  const dadosUsuario = body?.dadosUsuario === true;

  if (!password || !masterPassword) {
    return json(request, { error: 'A senha do administrador e a senha mestra são obrigatórias.' }, 400);
  }
  if (!env.GLOBAL_CLEANUP_MASTER_PASSWORD) {
    return json(request, { error: 'A senha mestra ainda não foi configurada no ambiente de produção.' }, 503);
  }

  const stored = await env.DB.prepare(
    'SELECT password_hash, password_salt FROM users WHERE id = ? AND role = \'admin\' AND active = 1',
  ).bind(admin.id).first<{ password_hash: string; password_salt: string }>();
  if (!stored || !(await verifyPassword(password, stored.password_hash, stored.password_salt))) {
    return json(request, { error: 'Senha do administrador inválida.' }, 401);
  }
  if (masterPassword !== env.GLOBAL_CLEANUP_MASTER_PASSWORD) {
    return json(request, { error: 'Senha mestra inválida.' }, 401);
  }

  const usuariosRemovidos = dadosUsuario
    ? ((await env.DB.prepare("SELECT id FROM users WHERE role = 'user'").all<{ id: string }>()).results ?? []).map((row) => row.id)
    : [];
  const versao = `${new Date().toISOString()}-${crypto.randomUUID()}`;
  const globalMarker = marker(versao, catalogo, dadosUsuario, usuariosRemovidos);
  const statements: D1PreparedStatement[] = [];

  // Dados de negócio: esta categoria é obrigatória e sempre vem incluída.
  statements.push(
    env.DB.prepare('DELETE FROM user_metas'),
    env.DB.prepare('DELETE FROM user_monthly_metas'),
    env.DB.prepare('DELETE FROM user_campaigns'),
    env.DB.prepare('DELETE FROM user_sales'),
    env.DB.prepare('DELETE FROM user_portabilidades'),
    env.DB.prepare('DELETE FROM user_prospeccoes'),
    env.DB.prepare('DELETE FROM user_clients'),
    // Estas duas tabelas legadas alimentam os avisos de portabilidade e prospecção.
    env.DB.prepare('DELETE FROM portabilidades'),
    env.DB.prepare('DELETE FROM prospeccoes'),
    env.DB.prepare('DELETE FROM notifications_sent'),
    env.DB.prepare('DELETE FROM notifications_attempts'),
  );

  if (catalogo) {
    statements.push(
      env.DB.prepare('DELETE FROM user_products'),
      env.DB.prepare('DELETE FROM user_convenios'),
      env.DB.prepare('DELETE FROM catalog_products'),
      env.DB.prepare('DELETE FROM catalog_convenios'),
    );
  }

  if (dadosUsuario) {
    // Remove apenas usuários comuns e tudo o que lhes pertence. Todas as
    // contas administrativas permanecem disponíveis para acesso.
    statements.push(
      env.DB.prepare('DELETE FROM sessions WHERE user_id IN (SELECT id FROM users WHERE role = \'user\')'),
      env.DB.prepare('DELETE FROM password_reset_tokens WHERE user_id IN (SELECT id FROM users WHERE role = \'user\')'),
      env.DB.prepare('DELETE FROM push_subscriptions WHERE user_id IN (SELECT id FROM users WHERE role = \'user\')'),
      env.DB.prepare('DELETE FROM notifications_sent WHERE user_id IN (SELECT id FROM users WHERE role = \'user\')'),
      env.DB.prepare('DELETE FROM notifications_attempts WHERE user_id IN (SELECT id FROM users WHERE role = \'user\')'),
      env.DB.prepare('DELETE FROM portabilidades WHERE user_id IN (SELECT id FROM users WHERE role = \'user\')'),
      env.DB.prepare('DELETE FROM prospeccoes WHERE user_id IN (SELECT id FROM users WHERE role = \'user\')'),
      env.DB.prepare('DELETE FROM user_settings WHERE user_id IN (SELECT id FROM users WHERE role = \'user\')'),
      env.DB.prepare('DELETE FROM user_products WHERE user_id IN (SELECT id FROM users WHERE role = \'user\')'),
      env.DB.prepare('DELETE FROM user_convenios WHERE user_id IN (SELECT id FROM users WHERE role = \'user\')'),
      env.DB.prepare('DELETE FROM user_metas WHERE user_id IN (SELECT id FROM users WHERE role = \'user\')'),
      env.DB.prepare('DELETE FROM user_monthly_metas WHERE user_id IN (SELECT id FROM users WHERE role = \'user\')'),
      env.DB.prepare('DELETE FROM user_campaigns WHERE user_id IN (SELECT id FROM users WHERE role = \'user\')'),
      env.DB.prepare('DELETE FROM user_sales WHERE user_id IN (SELECT id FROM users WHERE role = \'user\')'),
      env.DB.prepare('DELETE FROM user_portabilidades WHERE user_id IN (SELECT id FROM users WHERE role = \'user\')'),
      env.DB.prepare('DELETE FROM user_prospeccoes WHERE user_id IN (SELECT id FROM users WHERE role = \'user\')'),
      env.DB.prepare('DELETE FROM user_clients WHERE user_id IN (SELECT id FROM users WHERE role = \'user\')'),
      env.DB.prepare('DELETE FROM users WHERE role = \'user\''),
    );
  }

  statements.push(
    env.DB.prepare(
      `INSERT INTO app_settings (key, value) VALUES ('global_cleanup_marker', ?)
       ON CONFLICT(key) DO UPDATE SET value = excluded.value`,
    ).bind(JSON.stringify(globalMarker)),
  );

  await env.DB.batch(statements);
  return json(request, {
    ok: true,
    marker: globalMarker,
    preservado: {
      contasAdministrativas: true,
      catalogo: !catalogo,
    },
  });
};

export const onRequestGet: PagesFunction<AuthEnv> = ({ request }) =>
  json(request, { error: 'Método não permitido.' }, 405);
