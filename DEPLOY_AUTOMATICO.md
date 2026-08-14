# Publicação automática do Gestor de Vendas v3

O repositório `Gerenciador-de-vendas` é a fonte da versão multiusuário. A versão original e a infraestrutura v2 não fazem parte do fluxo de deploy da v3.

## Fluxo normal

As alterações devem ser feitas em uma branch de trabalho e enviadas por Pull Request para `main`. O GitHub Actions executa `flutter analyze`, os testes Flutter, o build web e a verificação TypeScript do Worker. O deploy não ocorre em Pull Requests.

Quando o Pull Request for revisado e mesclado em `main`, o workflow de produção aplica as migrações pendentes no D1 `gestor-vendas-push-v3`, atualiza os secrets VAPID, publica o Worker `gestor-vendas-push-v3` e publica o Pages `gestor-vendas-agencia-v3` na branch `production`.

## Secrets necessários no GitHub

Os secrets devem ser cadastrados no ambiente `production` do repositório. Nunca devem ser colocados em arquivos versionados, no código Flutter, no `wrangler.toml` ou em mensagens.

| Secret | Uso |
|---|---|
| `CLOUDFLARE_API_TOKEN` | Autoriza o GitHub Actions a aplicar migrações e publicar Pages/Worker. |
| `CLOUDFLARE_ACCOUNT_ID` | Identifica a conta Cloudflare do projeto. |
| `VAPID_PRIVATE_KEY` | Chave privada usada pelo Worker para assinar Web Push. |
| `VAPID_PUBLIC_KEY` | Chave pública usada pelo Pages e pelo navegador para assinar a inscrição. |

O token Cloudflare deve ter somente as permissões necessárias para o projeto v3: Workers Scripts, Pages e D1, preferencialmente limitadas à conta correta. A versão original não deve ser incluída no workflow.

## Migrações D1

As migrações ficam em `push_worker/migrations`. Cada alteração estrutural deve receber um número novo, como `0004_descricao.sql`, e ser revisada antes do merge. O GitHub Actions aplica apenas migrações ainda não registradas pelo Wrangler; não é necessário repetir manualmente o processo no PowerShell.

## Rollback

A versão anterior permanece disponível no Pages v2. Caso uma publicação v3 apresente problema, o workflow pode ser interrompido e o Pages v2 continua sendo o endereço de contingência. Migrações D1 devem ser aditivas e compatíveis; não se deve apagar colunas ou tabelas em produção sem uma estratégia de migração reversível.

## Regra de dados

O D1 v3 é compartilhado tecnicamente, mas todas as tabelas operacionais têm `user_id`. Backups, importações, leituras e gravações devem sempre usar a sessão do usuário autenticado. O administrador gerencia contas, mas não recebe acesso automático aos dados operacionais dos demais usuários.
