export interface AuthEnv {
  DB: D1Database;
}

export interface AuthUser {
  id: string;
  username: string;
  role: 'admin' | 'user';
  must_change_password: number;
  active: number;
}

const encoder = new TextEncoder();
const SESSION_DAYS = 14;
const PBKDF2_ITERATIONS = 100000;

export function corsHeaders(request: Request): Headers {
  const origin = request.headers.get('Origin');
  const headers = new Headers({
    'Content-Type': 'application/json; charset=utf-8',
    'Cache-Control': 'no-store',
    'Access-Control-Allow-Headers': 'Content-Type',
    'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
  });
  if (origin) {
    headers.set('Access-Control-Allow-Origin', origin);
    headers.set('Access-Control-Allow-Credentials', 'true');
    headers.set('Vary', 'Origin');
  }
  return headers;
}

export function optionsResponse(request: Request): Response {
  return new Response(null, { status: 204, headers: corsHeaders(request) });
}

export function json(request: Request, data: unknown, status = 200, extra?: HeadersInit) {
  const headers = corsHeaders(request);
  if (extra) new Headers(extra).forEach((value, key) => headers.set(key, value));
  return new Response(JSON.stringify(data), { status, headers });
}

export function normalizeUsername(value: unknown): string | null {
  if (typeof value !== 'string') return null;
  const raw = value.trim().toLowerCase();
  const username = raw.endsWith('@caixa.gov.br') ? raw.slice(0, -'@caixa.gov.br'.length) : raw;
  if (!/^[a-z0-9][a-z0-9._-]{1,63}$/.test(username)) return null;
  return username;
}

function bytesToBase64(bytes: Uint8Array): string {
  let binary = '';
  for (const byte of bytes) binary += String.fromCharCode(byte);
  return btoa(binary);
}

function base64ToBytes(value: string): Uint8Array {
  const binary = atob(value);
  return Uint8Array.from(binary, (character) => character.charCodeAt(0));
}

async function digestSha256(value: string): Promise<string> {
  const digest = await crypto.subtle.digest('SHA-256', encoder.encode(value));
  return bytesToBase64(new Uint8Array(digest));
}

export async function hashPassword(password: string, salt?: Uint8Array): Promise<{ hash: string; salt: string }> {
  const actualSalt = salt ?? crypto.getRandomValues(new Uint8Array(16));
  const baseKey = await crypto.subtle.importKey('raw', encoder.encode(password), 'PBKDF2', false, ['deriveBits']);
  const bits = await crypto.subtle.deriveBits(
    { name: 'PBKDF2', salt: actualSalt, iterations: PBKDF2_ITERATIONS, hash: 'SHA-256' },
    baseKey,
    256,
  );
  return { hash: bytesToBase64(new Uint8Array(bits)), salt: bytesToBase64(actualSalt) };
}

export async function verifyPassword(password: string, hash: string, salt: string): Promise<boolean> {
  const result = await hashPassword(password, base64ToBytes(salt));
  return result.hash === hash;
}

export function validPassword(value: unknown): value is string {
  return typeof value === 'string' && value.length >= 8 && value.length <= 128;
}

function parseCookies(request: Request): Record<string, string> {
  const result: Record<string, string> = {};
  for (const part of (request.headers.get('Cookie') ?? '').split(';')) {
    const separator = part.indexOf('=');
    if (separator < 0) continue;
    result[part.slice(0, separator).trim()] = decodeURIComponent(part.slice(separator + 1).trim());
  }
  return result;
}

export async function getSession(request: Request, env: AuthEnv): Promise<AuthUser | null> {
  const token = parseCookies(request).gv_session;
  if (!token) return null;
  const tokenHash = await digestSha256(token);
  const row = await env.DB.prepare(
    `SELECT u.id, u.username, u.role, u.must_change_password, u.active
     FROM sessions s JOIN users u ON u.id = s.user_id
     WHERE s.token_hash = ? AND s.expires_at > datetime('now') AND u.active = 1`,
  ).bind(tokenHash).first<AuthUser>();
  return row ?? null;
}

export async function createSession(request: Request, env: AuthEnv, userId: string): Promise<Headers> {
  const tokenBytes = crypto.getRandomValues(new Uint8Array(32));
  const token = bytesToBase64(tokenBytes).replaceAll('+', '-').replaceAll('/', '_').replaceAll('=', '');
  const tokenHash = await digestSha256(token);
  await env.DB.prepare(
    `INSERT INTO sessions (token_hash, user_id, expires_at)
     VALUES (?, ?, datetime('now', '+' || ? || ' days'))`,
  ).bind(tokenHash, userId, SESSION_DAYS).run();
  const headers = corsHeaders(request);
  headers.append('Set-Cookie', `gv_session=${encodeURIComponent(token)}; Path=/; Max-Age=${SESSION_DAYS * 86400}; HttpOnly; Secure; SameSite=Lax`);
  return headers;
}

export function clearSessionHeaders(request: Request): Headers {
  const headers = corsHeaders(request);
  headers.append('Set-Cookie', 'gv_session=; Path=/; Max-Age=0; HttpOnly; Secure; SameSite=Lax');
  return headers;
}

export async function removeSession(request: Request, env: AuthEnv): Promise<void> {
  const token = parseCookies(request).gv_session;
  if (!token) return;
  await env.DB.prepare('DELETE FROM sessions WHERE token_hash = ?').bind(await digestSha256(token)).run();
}

export function isAdmin(user: AuthUser | null): boolean {
  return user?.role === 'admin';
}
