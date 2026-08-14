-- Perfil e segurança de sessão por usuário.
ALTER TABLE user_settings ADD COLUMN avatar_data TEXT NOT NULL DEFAULT '';
ALTER TABLE user_settings ADD COLUMN idle_timeout_minutes INTEGER NOT NULL DEFAULT 30;
