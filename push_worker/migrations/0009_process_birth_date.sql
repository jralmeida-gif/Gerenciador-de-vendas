ALTER TABLE user_sales ADD COLUMN birth_date TEXT;
ALTER TABLE user_portabilidades ADD COLUMN birth_date TEXT;
ALTER TABLE user_prospeccoes ADD COLUMN birth_date TEXT;

CREATE INDEX IF NOT EXISTS idx_user_sales_birth_date ON user_sales(user_id, birth_date);
CREATE INDEX IF NOT EXISTS idx_user_port_birth_date ON user_portabilidades(user_id, birth_date);
CREATE INDEX IF NOT EXISTS idx_user_prosp_birth_date ON user_prospeccoes(user_id, birth_date);

UPDATE user_sales
SET birth_date = (
  SELECT birth_date FROM user_clients
  WHERE user_clients.user_id = user_sales.user_id
    AND user_clients.cpf = user_sales.cpf
)
WHERE birth_date IS NULL;

UPDATE user_portabilidades
SET birth_date = (
  SELECT birth_date FROM user_clients
  WHERE user_clients.user_id = user_portabilidades.user_id
    AND user_clients.cpf = user_portabilidades.cpf
)
WHERE birth_date IS NULL;

UPDATE user_prospeccoes
SET birth_date = (
  SELECT birth_date FROM user_clients
  WHERE user_clients.user_id = user_prospeccoes.user_id
    AND user_clients.cpf = user_prospeccoes.cpf
)
WHERE birth_date IS NULL;
