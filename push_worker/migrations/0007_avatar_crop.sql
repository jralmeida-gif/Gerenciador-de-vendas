ALTER TABLE user_settings ADD COLUMN avatar_scale REAL NOT NULL DEFAULT 1.0;
ALTER TABLE user_settings ADD COLUMN avatar_offset_x REAL NOT NULL DEFAULT 0.0;
ALTER TABLE user_settings ADD COLUMN avatar_offset_y REAL NOT NULL DEFAULT 0.0;

UPDATE user_settings
SET avatar_scale = 1.0,
    avatar_offset_x = 0.0,
    avatar_offset_y = 0.0
WHERE avatar_scale IS NULL OR avatar_offset_x IS NULL OR avatar_offset_y IS NULL;

-- Migração v3: o enquadramento acompanha o avatar e permanece isolado por usuário.

