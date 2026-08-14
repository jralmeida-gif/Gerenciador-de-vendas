CREATE TABLE IF NOT EXISTS user_monthly_metas (
  user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  product TEXT NOT NULL,
  month_ref TEXT NOT NULL,
  target REAL NOT NULL DEFAULT 0,
  updated_at TEXT NOT NULL DEFAULT (datetime('now')),
  PRIMARY KEY (user_id, product, month_ref)
);

CREATE INDEX IF NOT EXISTS idx_user_monthly_metas_period ON user_monthly_metas(user_id, month_ref);
