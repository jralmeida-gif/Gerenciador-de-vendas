import { getSession, type AuthEnv, json, optionsResponse } from '../../_auth';

interface PortabilidadeRecord {
  id: string;
  data: string;
  nome: string;
  convenio: string;
  confirmado: boolean;
}

interface ProspeccaoRecord {
  id: string;
  dataRetorno?: string | null;
  nome: string;
  produto: string;
  concluida: boolean;
}

interface ClienteRecord {
  cpf: string;
  nome: string;
  telefone: string;
  dataNascimento?: string | null;
  observacoes?: string;
}

interface RecordsBody {
  portabilidades?: PortabilidadeRecord[];
  prospeccoes?: ProspeccaoRecord[];
  clientes?: ClienteRecord[];
}

export const onRequestOptions: PagesFunction<AuthEnv> = ({ request }) => optionsResponse(request);

export const onRequestPost: PagesFunction<AuthEnv> = async ({ request, env }) => {
  const user = await getSession(request, env);
  if (!user) return json(request, { error: 'Sessão expirada.' }, 401);
  const body = (await request.json().catch(() => ({}))) as RecordsBody;
  const portabilidades = body.portabilidades ?? [];
  const prospeccoes = body.prospeccoes ?? [];
  const clientes = body.clientes ?? [];
  const batch: D1PreparedStatement[] = [];

  for (const p of portabilidades) {
    if (!p.id || !p.data || !p.nome) continue;
    batch.push(env.DB.prepare(
      `INSERT INTO portabilidades (id, user_id, data, nome, convenio, confirmado, updated_at)
       VALUES (?, ?, ?, ?, ?, ?, datetime('now'))
       ON CONFLICT(id) DO UPDATE SET
        data = excluded.data, nome = excluded.nome, convenio = excluded.convenio,
        confirmado = excluded.confirmado, updated_at = datetime('now')
       WHERE portabilidades.user_id = excluded.user_id`,
    ).bind(p.id, user.id, p.data, p.nome, p.convenio ?? '', p.confirmado ? 1 : 0));
  }

  for (const p of prospeccoes) {
    if (!p.id || !p.nome) continue;
    batch.push(env.DB.prepare(
      `INSERT INTO prospeccoes (id, user_id, data_retorno, nome, produto, concluida, updated_at)
       VALUES (?, ?, ?, ?, ?, ?, datetime('now'))
       ON CONFLICT(id) DO UPDATE SET
        data_retorno = excluded.data_retorno, nome = excluded.nome, produto = excluded.produto,
        concluida = excluded.concluida, updated_at = datetime('now')
       WHERE prospeccoes.user_id = excluded.user_id`,
    ).bind(p.id, user.id, p.dataRetorno ?? null, p.nome, p.produto ?? '', p.concluida ? 1 : 0));
  }

  for (const c of clientes) {
    if (!c.cpf || !c.nome) continue;
    batch.push(env.DB.prepare(
      `INSERT INTO user_clients (user_id, cpf, name, phone, birth_date, notes, updated_at)
       VALUES (?, ?, ?, ?, ?, ?, datetime('now'))
       ON CONFLICT(user_id, cpf) DO UPDATE SET
        name = excluded.name, phone = excluded.phone, birth_date = excluded.birth_date,
        notes = excluded.notes, updated_at = datetime('now')`,
    ).bind(user.id, c.cpf, c.nome, c.telefone ?? '', c.dataNascimento ?? null, c.observacoes ?? ''));
  }

  if (batch.length > 0) await env.DB.batch(batch);
  return json(request, { ok: true, userId: user.id });
};
