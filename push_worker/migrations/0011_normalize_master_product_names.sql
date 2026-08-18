-- Padronização de nomes solicitada pelo administrador.
-- Nenhum lançamento ou resultado é excluído: somente o texto do produto é atualizado.
-- As exclusões abaixo atingem apenas o catálogo mestre e seus espelhos, quando o
-- nome de destino já existe como cadastro ativo.

-- Rapidex passou a se chamar MICROSSEGUROS.
DELETE FROM catalog_products
WHERE name = 'Rapidex'
  AND EXISTS (SELECT 1 FROM catalog_products WHERE name = 'MICROSSEGUROS');

UPDATE catalog_products
SET name = 'MICROSSEGUROS',
    updated_at = strftime('%Y-%m-%dT%H:%M:%fZ', 'now')
WHERE name = 'Rapidex'
  AND NOT EXISTS (SELECT 1 FROM catalog_products WHERE name = 'MICROSSEGUROS');

DELETE FROM user_products
WHERE name = 'Rapidex'
  AND EXISTS (
    SELECT 1 FROM user_products target
    WHERE target.user_id = user_products.user_id
      AND target.name = 'MICROSSEGUROS'
  );

UPDATE user_products
SET name = 'MICROSSEGUROS',
    updated_at = strftime('%Y-%m-%dT%H:%M:%fZ', 'now')
WHERE name = 'Rapidex';

-- Consignado passou a se chamar CONSIGNADO.
DELETE FROM catalog_products
WHERE name = 'Consignado'
  AND EXISTS (SELECT 1 FROM catalog_products WHERE name = 'CONSIGNADO');

UPDATE catalog_products
SET name = 'CONSIGNADO',
    updated_at = strftime('%Y-%m-%dT%H:%M:%fZ', 'now')
WHERE name = 'Consignado'
  AND NOT EXISTS (SELECT 1 FROM catalog_products WHERE name = 'CONSIGNADO');

DELETE FROM user_products
WHERE name = 'Consignado'
  AND EXISTS (
    SELECT 1 FROM user_products target
    WHERE target.user_id = user_products.user_id
      AND target.name = 'CONSIGNADO'
  );

UPDATE user_products
SET name = 'CONSIGNADO',
    updated_at = strftime('%Y-%m-%dT%H:%M:%fZ', 'now')
WHERE name = 'Consignado';

-- Atualiza somente os textos nos históricos, sem DELETE nessas tabelas.
UPDATE user_sales
SET product = CASE product
  WHEN 'Rapidex' THEN 'MICROSSEGUROS'
  WHEN 'Consignado' THEN 'CONSIGNADO'
  ELSE product
END,
updated_at = datetime('now')
WHERE product IN ('Rapidex', 'Consignado');

UPDATE user_prospeccoes
SET product = CASE product
  WHEN 'Rapidex' THEN 'MICROSSEGUROS'
  WHEN 'Consignado' THEN 'CONSIGNADO'
  ELSE product
END,
updated_at = datetime('now')
WHERE product IN ('Rapidex', 'Consignado');

-- Em metas, renomeia apenas quando não houver uma meta já existente com o destino
-- para o mesmo usuário; assim nenhum resultado é apagado por conflito de chave.
UPDATE user_metas
SET product = CASE product
  WHEN 'Rapidex' THEN 'MICROSSEGUROS'
  WHEN 'Consignado' THEN 'CONSIGNADO'
  ELSE product
END,
updated_at = datetime('now')
WHERE product IN ('Rapidex', 'Consignado')
  AND NOT EXISTS (
    SELECT 1 FROM user_metas target
    WHERE target.user_id = user_metas.user_id
      AND target.product = CASE user_metas.product
        WHEN 'Rapidex' THEN 'MICROSSEGUROS'
        WHEN 'Consignado' THEN 'CONSIGNADO'
      END
  );

UPDATE user_monthly_metas
SET product = CASE product
  WHEN 'Rapidex' THEN 'MICROSSEGUROS'
  WHEN 'Consignado' THEN 'CONSIGNADO'
  ELSE product
END,
updated_at = datetime('now')
WHERE product IN ('Rapidex', 'Consignado')
  AND NOT EXISTS (
    SELECT 1 FROM user_monthly_metas target
    WHERE target.user_id = user_monthly_metas.user_id
      AND target.product = CASE user_monthly_metas.product
        WHEN 'Rapidex' THEN 'MICROSSEGUROS'
        WHEN 'Consignado' THEN 'CONSIGNADO'
      END
  );

-- Atualiza eventuais chaves de campanhas sem alterar vendas, prospecções ou metas.
UPDATE user_campaigns
SET targets_json = replace(replace(targets_json, '"Rapidex"', '"MICROSSEGUROS"'), '"Consignado"', '"CONSIGNADO"'),
    updated_at = datetime('now')
WHERE targets_json LIKE '%"Rapidex"%'
   OR targets_json LIKE '%"Consignado"%';

-- Garante que as sessões abertas detectem a mudança do catálogo e recarreguem os dados.
UPDATE catalog_products
SET updated_at = strftime('%Y-%m-%dT%H:%M:%fZ', 'now')
WHERE name IN ('MICROSSEGUROS', 'CONSIGNADO');
