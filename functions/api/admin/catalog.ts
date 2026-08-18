import {
  getSession,
  isAdmin,
  type AuthEnv,
  json,
  optionsResponse,
} from '../../_auth';

type CatalogEntity = 'produto' | 'convenio';
type CatalogAction = 'upsert' | 'rename' | 'delete';

type CatalogBody = {
  entity?: unknown;
  action?: unknown;
  oldName?: unknown;
  name?: unknown;
  format?: unknown;
  code?: unknown;
};

const text = (value: unknown) => value == null ? '' : String(value).trim();

async function requireAdmin(request: Request, env: AuthEnv) {
  const user = await getSession(request, env);
  return isAdmin(user) ? user : null;
}

export const onRequestOptions: PagesFunction<AuthEnv> = ({ request }) => optionsResponse(request);

export const onRequestGet: PagesFunction<AuthEnv> = async ({ request, env }) => {
  if (!await requireAdmin(request, env)) return json(request, { error: 'Acesso restrito aos administradores.' }, 403);
  const [products, convenios] = await env.DB.batch([
    env.DB.prepare('SELECT name, format, active FROM catalog_products ORDER BY active DESC, name'),
    env.DB.prepare('SELECT name, code FROM catalog_convenios ORDER BY name'),
  ]);
  return json(request, {
    products: products.results ?? [],
    convenios: convenios.results ?? [],
  });
};

export const onRequestPost: PagesFunction<AuthEnv> = async ({ request, env }) => {
  const admin = await requireAdmin(request, env);
  if (!admin) return json(request, { error: 'Acesso restrito aos administradores.' }, 403);

  const body = await request.json().catch(() => null) as CatalogBody | null;
  const entity = body?.entity === 'produto' || body?.entity === 'convenio' ? body.entity : null;
  const action = body?.action === 'upsert' || body?.action === 'rename' || body?.action === 'delete' ? body.action : null;
  const name = text(body?.name);
  const oldName = text(body?.oldName);
  if (!entity || !action) return json(request, { error: 'Tipo e operação do catálogo são obrigatórios.' }, 400);

  const table = entity === 'produto' ? 'catalog_products' : 'catalog_convenios';
  const mirror = entity === 'produto' ? 'user_products' : 'user_convenios';
  const column = entity === 'produto' ? 'format' : 'code';
  const value = entity === 'produto' ? text(body?.format) || 'Valor' : text(body?.code);
  const activeColumn = entity === 'produto' ? ', active' : '';
  const activeValue = entity === 'produto' ? ', 1' : '';
  const activeUpdate = entity === 'produto' ? ', active = 1' : '';
  const inactiveUpdate = entity === 'produto' ? 'active = 0, ' : '';
  const activePredicate = entity === 'produto' ? ' AND active = 1' : '';

  if (action === 'delete') {
    if (!name) return json(request, { error: 'Informe o nome a excluir.' }, 400);
    const existing = await env.DB.prepare(`SELECT name FROM ${table} WHERE name = ?`).bind(name).first<{ name: string }>();
    if (!existing) return json(request, { error: 'Cadastro não encontrado.' }, 404);
    await env.DB.batch([
      env.DB.prepare(`UPDATE ${table} SET ${inactiveUpdate}updated_at = strftime('%Y-%m-%dT%H:%M:%fZ','now') WHERE name = ?`).bind(name),
      env.DB.prepare(`UPDATE ${mirror} SET ${inactiveUpdate}updated_at = strftime('%Y-%m-%dT%H:%M:%fZ','now') WHERE name = ?`).bind(name),
    ]);
    return json(request, { ok: true, action: 'delete', name });
  }

  if (!name) return json(request, { error: 'Informe um nome válido.' }, 400);
  if (action === 'rename' && !oldName) return json(request, { error: 'Informe o nome anterior para renomear.' }, 400);
  if (action === 'rename' && oldName === name) {
    return json(request, { error: 'O nome novo deve ser diferente do nome anterior.' }, 400);
  }

  if (action === 'rename') {
    const [oldRow, newRow] = await env.DB.batch([
      env.DB.prepare(`SELECT name FROM ${table} WHERE name = ?`).bind(oldName),
      env.DB.prepare(`SELECT name FROM ${table} WHERE name = ?`).bind(name),
    ]);
    if (!oldRow.results?.length) return json(request, { error: 'Cadastro anterior não encontrado.' }, 404);
    if (newRow.results?.length) return json(request, { error: 'Já existe um cadastro com o novo nome.' }, 409);

    const statements: D1PreparedStatement[] = [
      env.DB.prepare(`UPDATE ${table} SET name = ?, ${column} = ?${activeUpdate}, updated_at = strftime('%Y-%m-%dT%H:%M:%fZ','now') WHERE name = ?`).bind(name, value, oldName),
      // Remove espelhos eventualmente antigos com o novo nome para evitar
      // conflito na chave composta antes de propagar a renomeação.
      env.DB.prepare(`DELETE FROM ${mirror} WHERE name = ?${activePredicate}`).bind(name),
      env.DB.prepare(`UPDATE ${mirror} SET name = ?, ${column} = ?${activeUpdate}, updated_at = strftime('%Y-%m-%dT%H:%M:%fZ','now') WHERE name = ?`).bind(name, value, oldName),
    ];

    if (entity === 'produto') {
      statements.push(
        env.DB.prepare('UPDATE user_sales SET product = ?, updated_at = datetime(\'now\') WHERE product = ?').bind(name, oldName),
        env.DB.prepare('UPDATE user_prospeccoes SET product = ?, updated_at = datetime(\'now\') WHERE product = ?').bind(name, oldName),
        env.DB.prepare('UPDATE user_metas SET product = ?, updated_at = datetime(\'now\') WHERE product = ?').bind(name, oldName),
        env.DB.prepare('UPDATE user_monthly_metas SET product = ?, updated_at = datetime(\'now\') WHERE product = ?').bind(name, oldName),
      );

      const campaigns = await env.DB.prepare('SELECT user_id, id, targets_json FROM user_campaigns').all<{ user_id: string; id: string; targets_json: string }>();
      for (const campaign of campaigns.results ?? []) {
        let targets: Record<string, unknown>;
        try {
          targets = JSON.parse(campaign.targets_json || '{}') as Record<string, unknown>;
        } catch (_) {
          continue;
        }
        if (!Object.prototype.hasOwnProperty.call(targets, oldName)) continue;
        const next = { ...targets, [name]: targets[oldName] };
        delete next[oldName];
        statements.push(
          env.DB.prepare('UPDATE user_campaigns SET targets_json = ?, updated_at = datetime(\'now\') WHERE user_id = ? AND id = ?').bind(JSON.stringify(next), campaign.user_id, campaign.id),
        );
      }
    } else {
      statements.push(
        env.DB.prepare('UPDATE user_portabilidades SET convenio = ?, updated_at = datetime(\'now\') WHERE convenio = ?').bind(name, oldName),
      );
    }

    await env.DB.batch(statements);
    return json(request, { ok: true, action: 'rename', oldName, name });
  }

  const existing = await env.DB.prepare(`SELECT name FROM ${table} WHERE name = ?`).bind(name).first<{ name: string }>();
  const statements: D1PreparedStatement[] = [
    env.DB.prepare(`INSERT INTO ${table} (name, ${column}${activeColumn}, updated_at) VALUES (?, ?${activeValue}, strftime('%Y-%m-%dT%H:%M:%fZ','now'))
      ON CONFLICT(name) DO UPDATE SET ${column} = excluded.${column}${activeUpdate}, updated_at = strftime('%Y-%m-%dT%H:%M:%fZ','now')`).bind(name, value),
    // Reativação deve substituir o espelho inativo pelo espelho ativo.
    env.DB.prepare(`DELETE FROM ${mirror} WHERE name = ?`).bind(name),
    env.DB.prepare(`INSERT INTO ${mirror} (user_id, name, ${column}${activeColumn}, updated_at)
      SELECT id, ?, ?${activeValue}, strftime('%Y-%m-%dT%H:%M:%fZ','now') FROM users`).bind(name, value),
  ];
  await env.DB.batch(statements);
  return json(request, { ok: true, action: existing ? 'update' : 'create', name });
};
