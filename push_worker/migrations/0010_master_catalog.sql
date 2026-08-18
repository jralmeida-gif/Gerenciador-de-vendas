-- Catálogos mestres administrados exclusivamente pelos administradores.
-- Os lançamentos continuam armazenando o texto do produto/convênio no momento
-- do registro, portanto exclusões nunca removem o histórico.
CREATE TABLE IF NOT EXISTS catalog_products (
  name TEXT PRIMARY KEY,
  format TEXT NOT NULL DEFAULT 'Valor',
  updated_at TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS catalog_convenios (
  name TEXT PRIMARY KEY,
  code TEXT NOT NULL DEFAULT '',
  updated_at TEXT NOT NULL DEFAULT (datetime('now'))
);

-- Na primeira implantação, prioriza o catálogo do primeiro administrador e
-- depois completa eventuais itens que só existam em outros perfis.
INSERT OR IGNORE INTO catalog_products (name, format)
SELECT p.name, p.format
FROM user_products p
JOIN users u ON u.id = p.user_id
WHERE u.role = 'admin'
ORDER BY u.id, p.name;

INSERT OR IGNORE INTO catalog_products (name, format)
SELECT name, format
FROM user_products
ORDER BY user_id, name;

INSERT OR IGNORE INTO catalog_convenios (name, code)
SELECT c.name, c.code
FROM user_convenios c
JOIN users u ON u.id = c.user_id
WHERE u.role = 'admin'
ORDER BY u.id, c.name;

INSERT OR IGNORE INTO catalog_convenios (name, code)
SELECT name, code
FROM user_convenios
ORDER BY user_id, name;

-- Mantém os espelhos locais existentes coerentes com o catálogo inicial.
INSERT OR IGNORE INTO user_products (user_id, name, format)
SELECT u.id, p.name, p.format
FROM users u CROSS JOIN catalog_products p;

INSERT OR IGNORE INTO user_convenios (user_id, name, code)
SELECT u.id, c.name, c.code
FROM users u CROSS JOIN catalog_convenios c;
