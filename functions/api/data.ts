import { getSession, type AuthEnv, json, optionsResponse } from '../_auth';

type DataBody = {
  config?: { nomeUsuario?: string; modeloMeta?: string; avatarData?: string; avatarScale?: number; avatarOffsetX?: number; avatarOffsetY?: number; idleTimeoutMinutes?: number; recoveryEmail?: string };
  produtos?: Array<{ nome?: string; formato?: string; ativo?: boolean }>;
  convenios?: Array<{ nome?: string; codigo?: string }>;
  metas?: Array<{ produto?: string; metaMes?: number }>;
  metasMensais?: Array<{ produto?: string; mes?: string; valor?: number }>;
  campanhas?: Array<{ id?: string; nome?: string; dataInicio?: string; dataFim?: string; metasPorProduto?: Record<string, number> }>;
  vendas?: Array<{ id?: string; data?: string; cpf?: string; nome?: string; telefone?: string; dataNascimento?: string | null; produto?: string; valorRealizado?: number; observacoes?: string }>;
  portabilidades?: Array<{ id?: string; data?: string; cpf?: string; nome?: string; telefone?: string; dataNascimento?: string | null; convenio?: string; saldoDevedor?: number; valorPrestacao?: number; qtdPrestacoes?: number; confirmado?: boolean; numeroContrato?: string; dataConfirmacao?: string | null; observacoes?: string }>;
  prospeccoes?: Array<{ id?: string; data?: string; cpf?: string; nome?: string; telefone?: string; dataNascimento?: string | null; produto?: string; dataRetorno?: string | null; observacao?: string; concluida?: boolean }>;
  clientes?: Array<{ cpf?: string; nome?: string; telefone?: string; dataNascimento?: string | null; observacoes?: string }>;
};

const text = (value: unknown) => value == null ? '' : String(value);
const num = (value: unknown) => typeof value === 'number' ? value : Number(value ?? 0);
const bool = (value: unknown) => value === true || value === 1;

export const onRequestOptions: PagesFunction<AuthEnv> = ({ request }) => optionsResponse(request);

export const onRequestGet: PagesFunction<AuthEnv> = async ({ request, env }) => {
  const user = await getSession(request, env);
  if (!user) return json(request, { error: 'Sessão expirada.' }, 401);
  const result = await env.DB.batch([
    env.DB.prepare('SELECT display_name, avatar_data, avatar_scale, avatar_offset_x, avatar_offset_y, idle_timeout_minutes, recovery_email FROM user_settings WHERE user_id = ?').bind(user.id),
    env.DB.prepare('SELECT name, format, active FROM catalog_products ORDER BY active DESC, name'),
    env.DB.prepare('SELECT name, code FROM catalog_convenios ORDER BY name'),
    env.DB.prepare('SELECT product, target_month FROM user_metas WHERE user_id = ? ORDER BY product').bind(user.id),
    env.DB.prepare('SELECT product, month_ref, target FROM user_monthly_metas WHERE user_id = ? ORDER BY month_ref, product').bind(user.id),
    env.DB.prepare('SELECT id, name, start_date, end_date, targets_json FROM user_campaigns WHERE user_id = ? ORDER BY start_date DESC').bind(user.id),
    env.DB.prepare('SELECT id, data, cpf, name, phone, birth_date, product, realized, notes FROM user_sales WHERE user_id = ? ORDER BY data DESC').bind(user.id),
    env.DB.prepare('SELECT id, data, cpf, name, phone, birth_date, convenio, saldo_devedor, valor_prestacao, qtd_prestacoes, confirmado, numero_contrato, data_confirmacao, observacoes FROM user_portabilidades WHERE user_id = ? ORDER BY data DESC').bind(user.id),
    env.DB.prepare('SELECT id, data, cpf, name, phone, birth_date, product, data_retorno, observacao, concluida FROM user_prospeccoes WHERE user_id = ? ORDER BY data DESC').bind(user.id),
    env.DB.prepare('SELECT cpf, name, phone, birth_date, notes FROM user_clients WHERE user_id = ? ORDER BY name').bind(user.id),
  ]);
  const [settings, products, convenios, metas, metasMensais, campaigns, sales, ports, prospects, clients] = result;
  const settingsRow = settings.results?.[0] as Record<string, unknown> | undefined;
  const cleanupRow = await env.DB.prepare(
    "SELECT value FROM app_settings WHERE key = 'global_cleanup_marker'",
  ).first<{ value: string }>();
  let limpezaGlobal: Record<string, unknown> | null = null;
  if (cleanupRow?.value) {
    try {
      const parsed = JSON.parse(cleanupRow.value) as unknown;
      if (parsed && typeof parsed === 'object') limpezaGlobal = parsed as Record<string, unknown>;
    } catch (_) {
      limpezaGlobal = null;
    }
  }
  return json(request, {
    ok: true,
    limpezaGlobal,
    config: {
      nomeUsuario: settingsRow?.display_name ?? user.username,
      modeloMeta: 'individual',
      avatarData: settingsRow?.avatar_data ?? '',
      avatarScale: Number(settingsRow?.avatar_scale ?? 1),
      avatarOffsetX: Number(settingsRow?.avatar_offset_x ?? 0),
      avatarOffsetY: Number(settingsRow?.avatar_offset_y ?? 0),
      idleTimeoutMinutes: Number(settingsRow?.idle_timeout_minutes ?? 30),
      recoveryEmail: settingsRow?.recovery_email ?? '',
    },
    produtos: products.results.map((r: any) => ({ nome: r.name, formato: r.format, ativo: r.active !== 0 })),
    convenios: convenios.results.map((r: any) => ({ nome: r.name, codigo: r.code })),
    metas: metas.results.map((r: any) => ({ produto: r.product, metaMes: r.target_month })),
    metasMensais: metasMensais.results.map((r: any) => ({ produto: r.product, mes: r.month_ref, valor: r.target })),
    campanhas: campaigns.results.map((r: any) => ({ id: r.id, nome: r.name, dataInicio: r.start_date, dataFim: r.end_date, metasPorProduto: JSON.parse(r.targets_json || '{}') })),
    vendas: sales.results.map((r: any) => ({ id: r.id, data: r.data, cpf: r.cpf, nome: r.name, telefone: r.phone, dataNascimento: r.birth_date, produto: r.product, valorRealizado: r.realized, observacoes: r.notes })),
    portabilidades: ports.results.map((r: any) => ({ id: r.id, data: r.data, cpf: r.cpf, nome: r.name, telefone: r.phone, dataNascimento: r.birth_date, convenio: r.convenio, saldoDevedor: r.saldo_devedor, valorPrestacao: r.valor_prestacao, qtdPrestacoes: r.qtd_prestacoes, confirmado: !!r.confirmado, numeroContrato: r.numero_contrato, dataConfirmacao: r.data_confirmacao, observacoes: r.observacoes })),
    prospeccoes: prospects.results.map((r: any) => ({ id: r.id, data: r.data, cpf: r.cpf, nome: r.name, telefone: r.phone, dataNascimento: r.birth_date, produto: r.product, dataRetorno: r.data_retorno, observacao: r.observacao, concluida: !!r.concluida })),
    clientes: clients.results.map((r: any) => ({ cpf: r.cpf, nome: r.name, telefone: r.phone, dataNascimento: r.birth_date, observacoes: r.notes })),
  });
};

export const onRequestPost: PagesFunction<AuthEnv> = async ({ request, env }) => {
  const user = await getSession(request, env);
  if (!user) return json(request, { error: 'Sessão expirada.' }, 401);
  const body = await request.json().catch(() => ({})) as DataBody;
  const cfg = body.config ?? {};
  const displayName = text(cfg.nomeUsuario).trim() || user.username;
  const avatarData = text(cfg.avatarData);
  const avatarScale = Math.min(3, Math.max(1, num(cfg.avatarScale || 1)));
  const avatarOffsetX = Math.min(1, Math.max(-1, num(cfg.avatarOffsetX || 0)));
  const avatarOffsetY = Math.min(1, Math.max(-1, num(cfg.avatarOffsetY || 0)));
  const idleTimeoutMinutes = Math.min(120, Math.max(15, Math.trunc(num(cfg.idleTimeoutMinutes || 30))));
  const recoveryEmail = cfg.recoveryEmail == null
    ? ((await env.DB.prepare('SELECT recovery_email FROM user_settings WHERE user_id = ?').bind(user.id).first<{ recovery_email?: string }>())?.recovery_email ?? '')
    : text(cfg.recoveryEmail).trim().toLowerCase();
  const batch: D1PreparedStatement[] = [
    env.DB.prepare('DELETE FROM user_metas WHERE user_id = ?').bind(user.id),
    env.DB.prepare('DELETE FROM user_monthly_metas WHERE user_id = ?').bind(user.id),
    env.DB.prepare('DELETE FROM user_campaigns WHERE user_id = ?').bind(user.id),
    env.DB.prepare('DELETE FROM user_sales WHERE user_id = ?').bind(user.id),
    env.DB.prepare('DELETE FROM user_portabilidades WHERE user_id = ?').bind(user.id),
    env.DB.prepare('DELETE FROM user_prospeccoes WHERE user_id = ?').bind(user.id),
    env.DB.prepare('DELETE FROM user_clients WHERE user_id = ?').bind(user.id),
    env.DB.prepare(`INSERT INTO user_settings (user_id, display_name, avatar_data, avatar_scale, avatar_offset_x, avatar_offset_y, idle_timeout_minutes, recovery_email, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, datetime('now'))
      ON CONFLICT(user_id) DO UPDATE SET display_name = excluded.display_name, avatar_data = excluded.avatar_data, avatar_scale = excluded.avatar_scale, avatar_offset_x = excluded.avatar_offset_x, avatar_offset_y = excluded.avatar_offset_y, idle_timeout_minutes = excluded.idle_timeout_minutes, recovery_email = excluded.recovery_email, updated_at = datetime('now')`).bind(user.id, displayName, avatarData, avatarScale, avatarOffsetX, avatarOffsetY, idleTimeoutMinutes, recoveryEmail),
    env.DB.prepare(`UPDATE users SET display_name = ?, updated_at = datetime('now') WHERE id = ?`).bind(displayName, user.id),
  ];
  // Produtos e convênios são catálogos mestres. Eles só podem ser alterados
  // pelo endpoint administrativo; a sincronização comum não os aceita.
  for (const m of body.metas ?? []) if (text(m.produto)) batch.push(env.DB.prepare('INSERT INTO user_metas (user_id, product, target_month) VALUES (?, ?, ?)').bind(user.id, text(m.produto), num(m.metaMes)));
  for (const m of body.metasMensais ?? []) if (text(m.produto) && text(m.mes)) batch.push(env.DB.prepare('INSERT INTO user_monthly_metas (user_id, product, month_ref, target) VALUES (?, ?, ?, ?)').bind(user.id, text(m.produto), text(m.mes), num(m.valor)));
  for (const c of body.campanhas ?? []) if (text(c.id) && text(c.nome) && text(c.dataInicio) && text(c.dataFim)) batch.push(env.DB.prepare('INSERT INTO user_campaigns (user_id, id, name, start_date, end_date, targets_json) VALUES (?, ?, ?, ?, ?, ?)').bind(user.id, text(c.id), text(c.nome), text(c.dataInicio), text(c.dataFim), JSON.stringify(c.metasPorProduto ?? {})));
  for (const v of body.vendas ?? []) if (text(v.id) && text(v.data)) batch.push(env.DB.prepare('INSERT INTO user_sales (user_id, id, data, cpf, name, phone, birth_date, product, realized, notes) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)').bind(user.id, text(v.id), text(v.data), text(v.cpf), text(v.nome), text(v.telefone), v.dataNascimento == null ? null : text(v.dataNascimento), text(v.produto), num(v.valorRealizado), text(v.observacoes)));
  for (const p of body.portabilidades ?? []) if (text(p.id) && text(p.data)) batch.push(env.DB.prepare('INSERT INTO user_portabilidades (user_id, id, data, cpf, name, phone, birth_date, convenio, saldo_devedor, valor_prestacao, qtd_prestacoes, confirmado, numero_contrato, data_confirmacao, observacoes) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)').bind(user.id, text(p.id), text(p.data), text(p.cpf), text(p.nome), text(p.telefone), p.dataNascimento == null ? null : text(p.dataNascimento), text(p.convenio), num(p.saldoDevedor), num(p.valorPrestacao), Math.trunc(num(p.qtdPrestacoes)), bool(p.confirmado) ? 1 : 0, text(p.numeroContrato), p.dataConfirmacao == null ? null : text(p.dataConfirmacao), text(p.observacoes)));
  for (const p of body.prospeccoes ?? []) if (text(p.id) && text(p.data)) batch.push(env.DB.prepare('INSERT INTO user_prospeccoes (user_id, id, data, cpf, name, phone, birth_date, product, data_retorno, observacao, concluida) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)').bind(user.id, text(p.id), text(p.data), text(p.cpf), text(p.nome), text(p.telefone), p.dataNascimento == null ? null : text(p.dataNascimento), text(p.produto), p.dataRetorno == null ? null : text(p.dataRetorno), text(p.observacao), bool(p.concluida) ? 1 : 0));
  for (const c of body.clientes ?? []) if (text(c.cpf)) batch.push(env.DB.prepare('INSERT INTO user_clients (user_id, cpf, name, phone, birth_date, notes) VALUES (?, ?, ?, ?, ?, ?)').bind(user.id, text(c.cpf), text(c.nome), text(c.telefone), c.dataNascimento == null ? null : text(c.dataNascimento), text(c.observacoes)));
  await env.DB.batch(batch);
  return json(request, { ok: true, userId: user.id });
};
