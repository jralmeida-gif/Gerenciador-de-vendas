CREATE TABLE IF NOT EXISTS notifications_attempts (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  dedupe_key TEXT NOT NULL,
  user_id TEXT NOT NULL,
  endpoint TEXT NOT NULL,
  attempted_at TEXT NOT NULL DEFAULT (datetime('now')),
  status_code INTEGER,
  accepted INTEGER NOT NULL DEFAULT 0,
  error TEXT
);

CREATE INDEX IF NOT EXISTS idx_notifications_attempts_user_time
  ON notifications_attempts(user_id, attempted_at);

CREATE INDEX IF NOT EXISTS idx_notifications_attempts_key
  ON notifications_attempts(dedupe_key);
