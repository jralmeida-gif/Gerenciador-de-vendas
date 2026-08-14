CREATE TABLE IF NOT EXISTS user_clients (
  user_id TEXT NOT NULL,
  cpf TEXT NOT NULL,
  name TEXT NOT NULL,
  phone TEXT NOT NULL DEFAULT '',
  birth_date TEXT,
  notes TEXT NOT NULL DEFAULT '',
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  updated_at TEXT NOT NULL DEFAULT (datetime('now')),
  PRIMARY KEY (user_id, cpf),
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_user_clients_birth_date ON user_clients(user_id, birth_date);

INSERT OR IGNORE INTO user_clients (user_id, cpf, name, phone)
SELECT user_id, cpf, MAX(name), MAX(phone)
FROM user_sales
WHERE cpf IS NOT NULL AND cpf <> ''
GROUP BY user_id, cpf;

INSERT OR IGNORE INTO user_clients (user_id, cpf, name, phone)
SELECT user_id, cpf, MAX(name), MAX(phone)
FROM user_portabilidades
WHERE cpf IS NOT NULL AND cpf <> ''
GROUP BY user_id, cpf;

INSERT OR IGNORE INTO user_clients (user_id, cpf, name, phone)
SELECT user_id, cpf, MAX(name), MAX(phone)
FROM user_prospeccoes
WHERE cpf IS NOT NULL AND cpf <> ''
GROUP BY user_id, cpf;
