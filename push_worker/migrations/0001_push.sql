CREATE TABLE IF NOT EXISTS push_subscriptions (
  endpoint TEXT PRIMARY KEY,
  p256dh TEXT NOT NULL,
  auth TEXT NOT NULL,
  expiration_time INTEGER,
  updated_at TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS portabilidades (
  id TEXT PRIMARY KEY,
  data TEXT NOT NULL,
  nome TEXT NOT NULL,
  convenio TEXT NOT NULL DEFAULT '',
  confirmado INTEGER NOT NULL DEFAULT 0,
  updated_at TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS prospeccoes (
  id TEXT PRIMARY KEY,
  data_retorno TEXT,
  nome TEXT NOT NULL,
  produto TEXT NOT NULL DEFAULT '',
  concluida INTEGER NOT NULL DEFAULT 0,
  updated_at TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS notifications_sent (
  dedupe_key TEXT PRIMARY KEY,
  sent_at TEXT NOT NULL DEFAULT (datetime('now'))
);
