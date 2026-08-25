-- Histórico administrativo e de acesso.
-- Não armazena CPF, nome, telefone, produto, valor ou conteúdo de cliente.
CREATE TABLE IF NOT EXISTS admin_activity_log (
  id TEXT PRIMARY KEY,
  actor_user_id TEXT,
  actor_username TEXT NOT NULL DEFAULT '',
  actor_role TEXT NOT NULL DEFAULT '',
  activity TEXT NOT NULL,
  result TEXT NOT NULL DEFAULT 'success',
  details TEXT NOT NULL DEFAULT '',
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE INDEX IF NOT EXISTS idx_admin_activity_log_created_at
  ON admin_activity_log(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_admin_activity_log_actor
  ON admin_activity_log(actor_user_id, created_at DESC);
