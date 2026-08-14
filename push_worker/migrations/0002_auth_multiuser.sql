-- Multiusuário: cada registro pertence a uma identidade @caixa.gov.br.
CREATE TABLE IF NOT EXISTS users (
  id TEXT PRIMARY KEY,
  username TEXT NOT NULL UNIQUE,
  role TEXT NOT NULL CHECK (role IN ('admin', 'user')) DEFAULT 'user',
  password_hash TEXT NOT NULL,
  password_salt TEXT NOT NULL,
  must_change_password INTEGER NOT NULL DEFAULT 1,
  active INTEGER NOT NULL DEFAULT 1,
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  updated_at TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS app_settings (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS sessions (
  token_hash TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  expires_at TEXT NOT NULL,
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
);

ALTER TABLE push_subscriptions ADD COLUMN user_id TEXT;
ALTER TABLE portabilidades ADD COLUMN user_id TEXT;
ALTER TABLE prospeccoes ADD COLUMN user_id TEXT;
ALTER TABLE notifications_sent ADD COLUMN user_id TEXT;

CREATE INDEX IF NOT EXISTS idx_sessions_user_id ON sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_sessions_expires_at ON sessions(expires_at);
CREATE INDEX IF NOT EXISTS idx_push_subscriptions_user_id ON push_subscriptions(user_id);
CREATE INDEX IF NOT EXISTS idx_portabilidades_user_id ON portabilidades(user_id);
CREATE INDEX IF NOT EXISTS idx_prospeccoes_user_id ON prospeccoes(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_sent_user_id ON notifications_sent(user_id);

-- Registros que existiam antes da autenticação ficam marcados para serem
-- transferidos ao primeiro administrador, uma única vez, no bootstrap.
UPDATE push_subscriptions SET user_id = 'unassigned' WHERE user_id IS NULL;
UPDATE portabilidades SET user_id = 'unassigned' WHERE user_id IS NULL;
UPDATE prospeccoes SET user_id = 'unassigned' WHERE user_id IS NULL;
UPDATE notifications_sent SET user_id = 'unassigned' WHERE user_id IS NULL;
