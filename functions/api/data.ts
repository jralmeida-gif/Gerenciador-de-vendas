import { getSession, type AuthEnv, json, optionsResponse } from '../_auth';

type DataBody = {
  config?: { nomeUsuario?: string; modeloMeta?: string };
  produtos?: Array<{ nome?: string; formato?: string }>;
  convenios?: Array<{ nome?: string; codigo?: string }>;
  metas?: Array<{ produto?: string; metaMes?: number }>;
  campanhas?: Array<{ id?: string; nome?: string; dataInicio?: string; dataFim?: string; metasPorProduto?: Record<string, number> }>;
  vendas?: Array<{ id?: string; data?: string; cpf?: string; nome?: string; telefone?: string; produto?: string; valorRealizado?: number; observacoes?: string }>;
  portabilidades?: Array<{ id?: string; data?: string; cpf?: string; nome?: string; telefone?: string; convenio?: string; saldoDevedor?: number; valorPrestacao?: number; qtdPrestacoes?: number; confirmado?: boolean; numeroContrato?: string; dataConfirmacao?: string | null; observacoes?: string }>;
  prospeccoes?: Array<{ id?: string; data?: string; cpf?: string; nome?: string; telefone?: string; produto?: string; dataRetorno?: string | null; observacao?: string; concluida?: boolean }>;
};

const text = (value: unknown) => value == null ? '' : String(value);
const num = (value: unknown) => typeof value === 'number' ? value : Number(value ?? 0);
const bool = (value: unknown) => value === true || value === 1;

export const onRequestOptions: PagesFunction<AuthEnv> = ({ request }) => optionsResponse(request);

export const onRequestGet: PagesFunction<AuthEnv> = async ({ request, env }) => {
  const user = await getSession(request, env);
  if (!user) return json(request, { error: 'Sessão expirada.' }, 401);
  const result = await env.DB.batch([
    env.DB.prepare('SELECT display_name FROM user_settings WHERE user_id = ?').bind(user.id),
    env.DB.prepare('SELECT name, format FROM user_products WHERE user_id = ? ORDER BY name').bind(user.id),
    env.DB.prepare('SELECT name, code FROM user_convenios WHERE user_id = ? ORDER BY name').bind(user.id),
    env.DB.prepare('SELECT product, target_month FROM user_metas WHERE user_id = ? ORDER BY product').bind(user.id),
    env.DB.prepare('SELECT id, name, start_date, end_date, targets_json FROM user_campaigns WHERE user_id = ? ORDER BY start_date DESC').bind(user.id),
    env.DB.prepare('SELECT id, data, cpf, name, phone, product, realized, notes FROM user_sales WHERE user_id = ? ORDER BY data DESC').bind(user.id),
    env.DB.prepare('SELECT id, data, cpf, name, phone, convenio, saldo_devedor, valor_prestacao, qtd_prestacoes, confirmado, numero_contrato, data_confirmacao, observacoes FROM user_portabilidades WHERE user_id = ? ORDER BY data DESC').bind(user.id),
    env.DB.prepare('SELECT id, data, cpf, name, phone, product, data_retorno, observacao, concluida FROM user_prospeccoes WHERE user_id = ? ORDER BY data DESC').bind(user.id),
  ]);
  const [settings, products, convenios, metas, campaigns, sales, ports, prospects] = result;
  return json(request, {
    ok: true,
    config: { nomeUsuario: settings?.results?.[0]?.display_name ?? user.username, modeloMeta: 'individual' },
    produtos: products.results.map((r: any) => ({ nome: r.name, formato: r.format })),
    convenios: convenios.results.map((r: any) => ({ nome: r.name, codigo: r.code })),
    metas: metas.results.map((r: any) => ({ produto: r.product, metaMes: r.target_month })),
    campanhas: campaigns.results.map((r: any) => ({ id: r.id, nome: r.name, dataInicio: r.start_date, dataFim: r.end_date, metasPorProduto: JSON.parse(r.targets_json || '{}') })),
    vendas: sales.results.map((r: any) => ({ id: r.id, data: r.data, cpf: r.cpf, nome: r.name, telefone: r.phone, produto: r.product, valorRealizado: r.realized, observacoes: r.notes })),
    portabilidades: ports.results.map((r: any) => ({ id: r.id, data: r.data, cpf: r.cpf, nome: r.name, telefone: r.phone, convenio: r.convenio, saldoDevedor: r.saldo_devedor, valorPrestacao: r.valor_prestacao, qtdPrestacoes: r.qtd_prestacoes, confirmado: !!r.confirmado, numeroContrato: r.numero_contrato, dataConfirmacao: r.data_confirmacao, observacoes: r.observacoes })),
    prospeccoes: prospects.results.map((r: any) => ({ id: r.id, data: r.data, cpf: r.cpf, nome: r.name, telefone: r.phone, produto: r.product, dataRetorno: r.data_retorno, observacao: r.observacao, concluida: !!r.concluida })),
  });
};

export const onRequestPost: PagesFunction<AuthEnv> = async ({ request, env }) => {
  const user = await getSession(request, env);
  if (!user) return json(request, { error: 'Sessão expirada.' }, 401);
  const body = await request.json().catch(() => ({})) as DataBody;
  const cfg = body.config ?? {};
  const displayName = text(cfg.nomeUsuario).trim() || user.username;
  const batch: D1PreparedStatement[] = [
    env.DB.prepare('DELETE FROM user_products WHERE user_id = ?').bind(user.id),
    env.DB.prepare('DELETE FROM user_convenios WHERE user_id = ?').bind(user.id),
    env.DB.prepare('DELETE FROM user_metas WHERE user_id = ?').bind(user.id),
    env.DB.prepare('DELETE FROM user_campaigns WHERE user_id = ?').bind(user.id),
    env.DB.prepare('DELETE FROM user_sales WHERE user_id = ?').bind(user.id),
    env.DB.prepare('DELETE FROM user_portabilidades WHERE user_id = ?').bind(user.id),
    env.DB.prepare('DELETE FROM user_prospeccoes WHERE user_id = ?').bind(user.id),
    env.DB.prepare(`INSERT INTO user_settings (user_id, display_name, updated_at) VALUES (?, ?, datetime('now'))
      ON CONFLICT(user_id) DO UPDATE SET display_name = excluded.display_name, updated_at = datetime('now')`).bind(user.id, displayName),
    env.DB.prepare(`UPDATE users SET display_name = ?, updated_at = datetime('now') WHERE id = ?`).bind(displayName, user.id),
  ];
  for (const p of body.produtos ?? []) if (text(p.nome)) batch.push(env.DB.prepare('INSERT INTO user_products (user_id, name, format) VALUES (?, ?, ?)').bind(user.id, text(p.nome), text(p.formato) || 'Valor'));
  for (const c of body.convenios ?? []) if (text(c.nome)) batch.push(env.DB.prepare('INSERT INTO user_convenios (user_id, name, code) VALUES (?, ?, ?)').bind(user.id, text(c.nome), text(c.codigo)));
  for (const m of body.metas ?? []) if (text(m.produto)) batch.push(env.DB.prepare('INSERT INTO user_metas (user_id, product, target_month) VALUES (?, ?, ?)').bind(user.id, text(m.produto), num(m.metaMes)));
  for (const c of body.campanhas ?? []) if (text(c.id) && text(c.nome) && text(c.dataInicio) && text(c.dataFim)) batch.push(env.DB.prepare('INSERT INTO user_campaigns (user_id, id, name, start_date, end_date, targets_json) VALUES (?, ?, ?, ?, ?, ?)').bind(user.id, text(c.id), text(c.nome), text(c.dataInicio), text(c.dataFim), JSON.stringify(c.metasPorProduto ?? {})));
  for (const v of body.vendas ?? []) if (text(v.id) && text(v.data)) batch.push(env.DB.prepare('INSERT INTO user_sales (user_id, id, data, cpf, name, phone, product, realized, notes) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)').bind(user.id, text(v.id), text(v.data), text(v.cpf), text(v.nome), text(v.telefone), text(v.produto), num(v.valorRealizado), text(v.observacoes)));
  for (const p of body.portabilidades ?? []) if (text(p.id) && text(p.data)) batch.push(env.DB.prepare('INSERT INTO user_portabilidades (user_id, id, data, cpf, name, phone, convenio, saldo_devedor, valor_prestacao, qtd_prestacoes, confirmado, numero_contrato, data_confirmacao, observacoes) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)').bind(user.id, text(p.id), text(p.data), text(p.cpf), text(p.nome), text(p.telefone), text(p.convenio), num(p.saldoDevedor), num(p.valorPrestacao), Math.trunc(num(p.qtdPrestacoes)), bool(p.confirmado) ? 1 : 0, text(p.numeroContrato), p.dataConfirmacao == null ? null : text(p.dataConfirmacao), text(p.observacoes)));
  for (const p of body.prospeccoes ?? []) if (text(p.id) && text(p.data)) batch.push(env.DB.prepare('INSERT INTO user_prospeccoes (user_id, id, data, cpf, name, phone, product, data_retorno, observacao, concluida) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)').bind(user.id, text(p.id), text(p.data), text(p.cpf), text(p.nome), text(p.telefone), text(p.produto), p.dataRetorno == null ? null : text(p.dataRetorno), text(p.observacao), bool(p.concluida) ? 1 : 0));
  await env.DB.batch(batch);
  return json(request, { ok: true, userId: user.id });
};
