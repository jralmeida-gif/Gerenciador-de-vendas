-- Mensagens enviadas pelos usuários para sugestões e relatos de falhas.
-- O conteúdo fica separado do histórico administrativo e vinculado ao autor.
CREATE TABLE IF NOT EXISTS user_feedback (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  username TEXT NOT NULL DEFAULT '',
  kind TEXT NOT NULL CHECK (kind IN ('sugestao', 'falha')),
  subject TEXT NOT NULL DEFAULT '',
  message TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'aberto' CHECK (status IN ('aberto', 'em_analise', 'resolvido')),
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE INDEX IF NOT EXISTS idx_user_feedback_created_at
  ON user_feedback(created_at DESC);

CREATE INDEX IF NOT EXISTS idx_user_feedback_user
  ON user_feedback(user_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_user_feedback_status
  ON user_feedback(status, created_at DESC);
