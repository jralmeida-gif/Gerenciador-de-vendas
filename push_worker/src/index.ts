import { buildPushPayload, type PushSubscription, type VapidKeys } from '@block65/webcrypto-web-push';

interface Env {
  DB: D1Database;
  VAPID_SUBJECT: string;
  VAPID_PUBLIC_KEY: string;
  VAPID_PRIVATE_KEY: string;
}
interface SubscriptionRow { endpoint: string; user_id: string; p256dh: string; auth: string; expiration_time: number | null; }
interface DeadlineRow { id: string; user_id: string; data: string; nome: string; convenio: string; }
interface ProspectRow { id: string; user_id: string; data_retorno: string; nome: string; produto: string; }
const timeZone = 'America/Sao_Paulo';

function localParts(date: Date) {
  const parts = new Intl.DateTimeFormat('en-CA', { timeZone, year: 'numeric', month: '2-digit', day: '2-digit', hour: '2-digit', minute: '2-digit', hour12: false }).formatToParts(date);
  const value = (type: string) => parts.find((p) => p.type === type)?.value ?? '';
  return { year: Number(value('year')), month: Number(value('month')), day: Number(value('day')), hour: Number(value('hour')), minute: Number(value('minute')) };
}
function localDateKey(date: Date) { const p = localParts(date); return `${p.year}-${String(p.month).padStart(2, '0')}-${String(p.day).padStart(2, '0')}`; }
function dateOnly(value: string | null) { if (!value) return null; const date = new Date(value); if (Number.isNaN(date.valueOf())) return null; const p = localParts(date); return Date.UTC(p.year, p.month - 1, p.day); }
function daysBetween(from: string, now: Date) { const start = dateOnly(from); const current = dateOnly(now.toISOString()); if (start === null || current === null) return null; return Math.floor((current - start) / 86400000); }
async function alreadySent(env: Env, key: string) { return Boolean(await env.DB.prepare('SELECT dedupe_key FROM notifications_sent WHERE dedupe_key = ? AND user_id = ?').bind(key.split('|')[0], key.split('|')[1]).first()); }
async function markSent(env: Env, key: string, userId: string) { await env.DB.prepare('INSERT OR IGNORE INTO notifications_sent (dedupe_key, user_id) VALUES (?, ?)').bind(key, userId).run(); }

async function sendToUser(env: Env, userId: string, payload: { title: string; body: string; tag: string; url: string }) {
  const rows = await env.DB.prepare('SELECT endpoint, user_id, p256dh, auth, expiration_time FROM push_subscriptions WHERE user_id = ?').bind(userId).all<SubscriptionRow>();
  const vapid: VapidKeys = { subject: env.VAPID_SUBJECT, publicKey: env.VAPID_PUBLIC_KEY, privateKey: env.VAPID_PRIVATE_KEY };
  for (const row of rows.results ?? []) {
    const subscription: PushSubscription = { endpoint: row.endpoint, expirationTime: row.expiration_time, keys: { p256dh: row.p256dh, auth: row.auth } };
    try {
      const requestInit = await buildPushPayload({ data: JSON.stringify(payload), options: { ttl: 86400 } }, subscription, vapid);
      const response = await fetch(row.endpoint, requestInit as RequestInit);
      if (response.status === 404 || response.status === 410) await env.DB.prepare('DELETE FROM push_subscriptions WHERE endpoint = ? AND user_id = ?').bind(row.endpoint, userId).run();
    } catch (error) { console.error('Falha ao enviar push', row.endpoint, error); }
  }
}

async function scheduleAlerts(env: Env, now: Date) {
  const parts = localParts(now); const dateKey = localDateKey(now); const slot = parts.hour === 14 ? '14' : '09';
  if (parts.minute !== 0 || (parts.hour !== 9 && parts.hour !== 14)) return;
  const portabilidades = await env.DB.prepare('SELECT id, user_id, data, nome, convenio FROM portabilidades WHERE confirmado = 0 AND user_id IS NOT NULL AND user_id != \'unassigned\'').all<DeadlineRow>();
  for (const p of portabilidades.results ?? []) {
    const elapsed = daysBetween(p.data, now);
    if (elapsed === null || elapsed <= 0 || elapsed % 5 !== 0 || parts.hour !== 9) continue;
    const key = `portabilidade:${p.id}:${dateKey}:09`;
    if (await alreadySent(env, `${key}|${p.user_id}`)) continue;
    await sendToUser(env, p.user_id, { title: 'Portabilidade pendente', body: `${p.nome} — pedido de ${p.convenio || 'portabilidade'} está pendente há ${elapsed} dias.`, tag: `portabilidade-${p.id}`, url: '/#/portabilidades' });
    await markSent(env, key, p.user_id);
  }
  const prospeccoes = await env.DB.prepare('SELECT id, user_id, data_retorno, nome, produto FROM prospeccoes WHERE concluida = 0 AND data_retorno IS NOT NULL AND user_id IS NOT NULL AND user_id != \'unassigned\'').all<ProspectRow>();
  for (const p of prospeccoes.results ?? []) {
    const target = dateOnly(p.data_retorno); const today = dateOnly(now.toISOString()); if (target === null || today === null) continue;
    const daysUntil = Math.floor((target - today) / 86400000);
    const alert = (daysUntil === 1 && parts.hour === 9) || (daysUntil === 0 && (parts.hour === 9 || parts.hour === 14));
    if (!alert) continue;
    const key = `prospeccao:${p.id}:${dateKey}:${slot}`;
    if (await alreadySent(env, `${key}|${p.user_id}`)) continue;
    const quando = daysUntil === 1 ? 'amanhã' : parts.hour === 9 ? 'hoje às 9h' : 'hoje às 14h';
    await sendToUser(env, p.user_id, { title: 'Retorno de prospecção', body: `${p.nome} — retorno de ${p.produto} ${quando}.`, tag: `prospeccao-${p.id}-${slot}`, url: '/#/prospeccao' });
    await markSent(env, key, p.user_id);
  }
}
export default { async scheduled(_controller: ScheduledController, env: Env, ctx: ExecutionContext) { ctx.waitUntil(scheduleAlerts(env, new Date())); } };
