-- Produtos excluídos permanecem preservados como inativos.
-- O estado ativo controla apenas a disponibilidade para novos cadastros.
ALTER TABLE catalog_products ADD COLUMN active INTEGER NOT NULL DEFAULT 1;
ALTER TABLE user_products ADD COLUMN active INTEGER NOT NULL DEFAULT 1;

CREATE INDEX IF NOT EXISTS idx_catalog_products_active ON catalog_products(active, name);

-- O produto excluído continua no catálogo mestre como histórico inativo.
INSERT OR IGNORE INTO catalog_products (name, format, active, updated_at)
VALUES ('Limite Cartão Ultra', 'Valor', 0, strftime('%Y-%m-%dT%H:%M:%fZ', 'now'));
UPDATE catalog_products
SET active = 0,
    updated_at = strftime('%Y-%m-%dT%H:%M:%fZ', 'now')
WHERE name = 'Limite Cartão Ultra';

-- Mantém o espelho inativo para cada usuário sem apagar dados de catálogo.
INSERT OR IGNORE INTO user_products (user_id, name, format, active, updated_at)
SELECT id, 'Limite Cartão Ultra', 'Valor', 0, strftime('%Y-%m-%dT%H:%M:%fZ', 'now')
FROM users;
UPDATE user_products
SET active = 0,
    updated_at = strftime('%Y-%m-%dT%H:%M:%fZ', 'now')
WHERE name = 'Limite Cartão Ultra';

-- Todos os demais cadastros existentes continuam ativos, salvo aqueles que
-- já foram explicitamente preservados como inativos acima.
UPDATE catalog_products
SET active = 1
WHERE name <> 'Limite Cartão Ultra' AND active IS NULL;
UPDATE user_products
SET active = 1
WHERE name <> 'Limite Cartão Ultra' AND active IS NULL;
