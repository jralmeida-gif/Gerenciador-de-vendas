-- Persistência operacional completa, isolada por usuário.
ALTER TABLE users ADD COLUMN display_name TEXT NOT NULL DEFAULT '';

CREATE TABLE IF NOT EXISTS user_settings (
  user_id TEXT PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  display_name TEXT NOT NULL DEFAULT '',
  updated_at TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS user_products (
  user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  format TEXT NOT NULL DEFAULT 'Valor',
  updated_at TEXT NOT NULL DEFAULT (datetime('now')),
  PRIMARY KEY (user_id, name)
);

CREATE TABLE IF NOT EXISTS user_convenios (
  user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  code TEXT NOT NULL DEFAULT '',
  updated_at TEXT NOT NULL DEFAULT (datetime('now')),
  PRIMARY KEY (user_id, name)
);

CREATE TABLE IF NOT EXISTS user_metas (
  user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  product TEXT NOT NULL,
  target_month REAL NOT NULL DEFAULT 0,
  updated_at TEXT NOT NULL DEFAULT (datetime('now')),
  PRIMARY KEY (user_id, product)
);

CREATE TABLE IF NOT EXISTS user_campaigns (
  user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  id TEXT NOT NULL,
  name TEXT NOT NULL,
  start_date TEXT NOT NULL,
  end_date TEXT NOT NULL,
  targets_json TEXT NOT NULL DEFAULT '{}',
  updated_at TEXT NOT NULL DEFAULT (datetime('now')),
  PRIMARY KEY (user_id, id)
);

CREATE TABLE IF NOT EXISTS user_sales (
  user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  id TEXT NOT NULL,
  data TEXT NOT NULL,
  cpf TEXT NOT NULL DEFAULT '',
  name TEXT NOT NULL DEFAULT '',
  phone TEXT NOT NULL DEFAULT '',
  product TEXT NOT NULL DEFAULT '',
  realized REAL NOT NULL DEFAULT 0,
  notes TEXT NOT NULL DEFAULT '',
  updated_at TEXT NOT NULL DEFAULT (datetime('now')),
  PRIMARY KEY (user_id, id)
);

CREATE TABLE IF NOT EXISTS user_portabilidades (
  user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  id TEXT NOT NULL,
  data TEXT NOT NULL,
  cpf TEXT NOT NULL DEFAULT '',
  name TEXT NOT NULL DEFAULT '',
  phone TEXT NOT NULL DEFAULT '',
  convenio TEXT NOT NULL DEFAULT '',
  saldo_devedor REAL NOT NULL DEFAULT 0,
  valor_prestacao REAL NOT NULL DEFAULT 0,
  qtd_prestacoes INTEGER NOT NULL DEFAULT 0,
  confirmado INTEGER NOT NULL DEFAULT 0,
  numero_contrato TEXT NOT NULL DEFAULT '',
  data_confirmacao TEXT,
  observacoes TEXT NOT NULL DEFAULT '',
  updated_at TEXT NOT NULL DEFAULT (datetime('now')),
  PRIMARY KEY (user_id, id)
);

CREATE TABLE IF NOT EXISTS user_prospeccoes (
  user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  id TEXT NOT NULL,
  data TEXT NOT NULL,
  cpf TEXT NOT NULL DEFAULT '',
  name TEXT NOT NULL DEFAULT '',
  phone TEXT NOT NULL DEFAULT '',
  product TEXT NOT NULL DEFAULT '',
  data_retorno TEXT,
  observacao TEXT NOT NULL DEFAULT '',
  concluida INTEGER NOT NULL DEFAULT 0,
  updated_at TEXT NOT NULL DEFAULT (datetime('now')),
  PRIMARY KEY (user_id, id)
);

CREATE INDEX IF NOT EXISTS idx_user_sales_user_date ON user_sales(user_id, data);
CREATE INDEX IF NOT EXISTS idx_user_sales_user_cpf ON user_sales(user_id, cpf);
CREATE INDEX IF NOT EXISTS idx_user_sales_user_product ON user_sales(user_id, product);
CREATE INDEX IF NOT EXISTS idx_user_port_user_date ON user_portabilidades(user_id, data);
CREATE INDEX IF NOT EXISTS idx_user_port_user_cpf ON user_portabilidades(user_id, cpf);
CREATE INDEX IF NOT EXISTS idx_user_prosp_user_return ON user_prospeccoes(user_id, data_retorno);
CREATE INDEX IF NOT EXISTS idx_user_prosp_user_cpf ON user_prospeccoes(user_id, cpf);
CREATE INDEX IF NOT EXISTS idx_user_metas_user_product ON user_metas(user_id, product);
CREATE INDEX IF NOT EXISTS idx_user_campaigns_user_dates ON user_campaigns(user_id, start_date, end_date);

INSERT OR IGNORE INTO user_settings (user_id, display_name)
SELECT id, display_name FROM users;

UPDATE users SET display_name = username WHERE display_name = '';
UPDATE user_settings SET display_name = (SELECT display_name FROM users WHERE users.id = user_settings.user_id)
WHERE display_name = '';
