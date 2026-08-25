# Operação e segurança

Este documento é destinado a administradores do projeto e colaboradores que precisem operar produção. Ele complementa a arquitetura: aqui estão os cuidados para não expor credenciais, não misturar dados de usuários e responder a falhas de publicação, sincronização, backup ou notificações.

> **Princípio de contenção:** se uma operação pode apagar dados, alterar identidade, mudar catálogo global ou publicar em produção, pare, confirme o escopo e registre o que foi feito.

## Ambientes e responsabilidades

| Recurso | Função | Fonte de configuração |
|---|---|---|
| Flutter/PWA | Interface e armazenamento local do usuário | Código Dart em `lib/` e arquivos `web/`. |
| Pages Functions | API, sessão, D1, Mailjet e regras administrativas | `functions/` e secrets/variáveis do projeto Pages. |
| Pages | Hospedagem do build web e Functions | Projeto `gestor-vendas-agencia-v3`. |
| Worker | Notificações agendadas | `push_worker/src/index.ts` e `push_worker/wrangler-v3.toml`. |
| D1 | Dados remotos e migrations | Banco `gestor-vendas-push-v3`, ID registrado no TOML. |
| GitHub Actions | Validação e publicação | `.github/workflows/ci-cd-v3.yml`, ambiente `production`. |

O acesso ao GitHub não deve ser confundido com acesso ao Cloudflare. Um colaborador pode revisar código sem poder ler secrets ou executar operações destrutivas.

## Secrets

### GitHub Actions

O ambiente `production` do repositório usa secrets para o pipeline:

```text
CLOUDFLARE_API_TOKEN
VAPID_PRIVATE_KEY
VAPID_PUBLIC_KEY
```

O token Cloudflare deve ser um API Token restrito à conta correta e com permissões de edição para Pages, Workers Scripts e D1. A conta-alvo do projeto é identificada pelo ID `2b8edd465196defbd06a224e278fc748`.

Nunca use a Global API Key como substituto automático, não copie o token para uma issue e não o coloque no `wrangler-v3.toml`. A documentação de upload contínuo do Pages descreve o uso de Wrangler e credenciais de CI [1].

### Pages Functions

No projeto Pages, configure os secrets de produção necessários para as Functions:

```text
MAILJET_API_KEY
MAILJET_SECRET_KEY
MAILJET_FROM_EMAIL
MAILJET_FROM_NAME
GLOBAL_CLEANUP_MASTER_PASSWORD
VAPID_PUBLIC_KEY
```

A senha mestra é um segredo operacional escolhido pelo administrador. Ela não deve ser compartilhada por chat, armazenada em D1, embutida no Flutter ou registrada em log. Se houver rotação, atualize o valor no ambiente correto e faça uma nova publicação para garantir que a versão ativa receba a configuração.

### Worker

O Worker usa:

```text
VAPID_SUBJECT
VAPID_PUBLIC_KEY
VAPID_PRIVATE_KEY
```

`VAPID_PRIVATE_KEY` deve ser secret do Worker e nunca deve aparecer em `wrangler-v3.toml`. O subject e a chave pública podem ser configurados como variáveis conforme o arquivo TOML; a chave privada não.

## Rotação de credenciais

Ao suspeitar de vazamento, revogue ou substitua a credencial na origem, não apenas no código. Depois:

1. Crie o novo token ou chave no provedor.
2. Atualize o secret no GitHub, Cloudflare Pages ou Worker conforme o tipo.
3. Execute a validação e publique uma nova versão.
4. Verifique login, sincronização, push e recuperação de senha.
5. Registre a data e o motivo da rotação sem registrar o valor secreto.

Se o token Cloudflare retornar `Invalid access token`, confira validade, conta-alvo, permissões e o nome do secret. Não contorne o problema adicionando permissões administrativas indiscriminadamente.

## D1 e migrações

As migrações são arquivos SQL numerados em `push_worker/migrations/`. Cada nova mudança estrutural deve criar o próximo arquivo. O Wrangler aplica as migrações pendentes e o D1 registra as que já foram aplicadas [2].

Antes de aplicar uma migração remota:

- leia o SQL inteiro;
- confirme se a migration é compatível com dados existentes;
- verifique chaves estrangeiras e tabelas dependentes;
- avalie backup e reversão;
- não renomeie nem edite uma migration que já foi aplicada;
- valide o pipeline em uma branch antes de fazer merge.

O workflow atual só executa `wrangler d1 migrations apply` quando o commit altera arquivos em `push_worker/migrations/`. Essa condição evita consultas desnecessárias ao D1 em deploys somente de código, mas não substitui a revisão SQL.

## Backup e restauração

O app possui backup interno e exportação para arquivo. A cópia interna é namespaced por perfil e não deve ser considerada a única proteção para dados importantes. O backup externo deve ser salvo em local controlado, com nome e data compreensíveis, sem ser enviado para um destino público.

Antes de uma mudança de schema, limpeza, operação de catálogo ou correção em lote:

1. Faça um backup externo recente.
2. Confirme que o arquivo pode ser localizado e aberto.
3. Não substitua automaticamente um backup anterior.
4. Registre qual versão do app produziu o arquivo.
5. Faça uma restauração de teste quando a alteração for estrutural.

Um backup contém dados potencialmente pessoais. Não o anexe a issues, pull requests ou mensagens públicas. Ao restaurar, confirme o perfil ativo e o escopo da operação para não importar dados de uma pessoa em outra.

## Autenticação e recuperação de senha

O primeiro usuário registrado torna-se administrador. Usuários posteriores são criados pelo administrador. O login aceita o identificador normalizado conforme `functions/_auth.ts`; não há dependência de um domínio empresarial fixo.

A recuperação de senha envia um link para o e-mail de recuperação do usuário por Mailjet. O token deve ser tratado como credencial temporária. Não copie links de recuperação para logs ou tickets. Depois de redefinir a senha, a sessão antiga deve ser revalidada; se o PWA já estiver aberto, feche e reabra ou aguarde a verificação de sessão para confirmar o novo estado.

O endpoint `/api/auth/verify-password` valida a senha atual sem alterá-la. Ele é utilizado em operações de risco e não deve ser substituído por uma comparação feita apenas no cliente.

## Isolamento multiusuário

Toda operação de negócio deve ser associada ao `user_id` obtido da sessão no backend. Os dados locais seguem um namespace por perfil e o `AppState` troca o perfil quando o login muda.

Ao testar isolamento, use dois usuários fictícios e execute:

| Teste | Resultado esperado |
|---|---|
| Usuário A cadastra uma venda | A venda aparece apenas para A. |
| Usuário B abre Vendas | A venda de A não aparece. |
| B cadastra uma prospecção | A prospecção aparece apenas para B. |
| A acessa ficha de clientes | Clientes de B não aparecem. |
| B tenta rota administrativa | Recebe acesso negado. |
| A troca de sessão no mesmo navegador | Caixas locais e snapshot são trocados sem mistura. |

Não utilize a conta administrativa real para gerar dados de teste que depois precisem ser apagados em massa.

## Zona de Risco

### Limpeza individual

As opções individuais continuam restritas ao usuário conectado. A senha do usuário é solicitada antes da limpeza. A operação não deve atingir linhas de outro `user_id`, o catálogo mestre ou contas de usuários diferentes.

### Limpeza global

A limpeza global aparece somente para administradores. Ela tem três categorias:

| Categoria | Regra |
|---|---|
| Dados de negócio | Sempre marcada e não editável; inclui vendas, portabilidades, prospecções, clientes, metas, metas mensais e campanhas. |
| Catálogo de produtos e convênios | Opcional; se marcada, remove catálogo mestre e espelhos. |
| Dados de usuário | Opcional; se marcada, remove usuários comuns e dados associados, preservando contas administrativas. |

O fluxo exige alerta, senha atual do administrador, senha mestra e execução server-side. A rota grava um `global_cleanup_marker` para que os dispositivos limpem caches locais e não repovoem a nuvem com dados já excluídos.

Nunca faça uma limpeza global para testar a interface. Para testar o fluxo, use um ambiente de teste ou uma base explicitamente descartável e verifique o backup antes.

## Notificações push

O Worker executa o handler `scheduled()` de hora em hora. Cron Triggers do Cloudflare executam em UTC, enquanto o código converte o horário para `America/Sao_Paulo` para decidir os slots de negócio [3].

Quando uma notificação não chega:

1. Verifique se o usuário permitiu notificações no navegador e no sistema operacional.
2. Confirme se existe assinatura em `push_subscriptions` para o usuário.
3. Confira se a chave pública do Pages corresponde à chave usada na assinatura.
4. Verifique `notifications_attempts` para status HTTP e erro do provedor.
5. Confira `notifications_sent` para entender se a deduplicação já marcou o evento.
6. Verifique os eventos do cron do Worker e o fuso horário.
7. Não crie um novo registro de assinatura sem remover o endpoint inválido quando o provedor retornar 404 ou 410.

As notificações de aniversário dependem de data de nascimento válida. As notificações de prospecção dependem de `data_retorno` e de a prospecção ainda não estar concluída.

## Monitoramento de publicação

No GitHub, abra **Actions → Gestor de Vendas v3**. Uma execução normal tem dois jobs:

```text
Validar Flutter e Worker
Publicar v3 no Cloudflare
```

A publicação não deve ser considerada concluída somente porque o commit foi enviado. Confirme o círculo verde na execução mais recente e, depois, valide a URL de produção. O upload direto do Pages publica o diretório construído pelo Flutter, e o Wrangler também pode publicar o Worker conforme a configuração [1].

## Resposta a incidentes

### Build ou análise falhou

Leia a primeira etapa vermelha, reproduza o comando localmente e corrija na branch. Não faça deploy manual para esconder uma falha de validação.

### Deploy falhou por token

Não altere o código primeiro. Confirme se `CLOUDFLARE_API_TOKEN` existe no ambiente `production`, se não expirou e se tem acesso à conta correta. Depois de atualizar o secret, execute o workflow manualmente.

### Dados parecem misturados

Pare novas gravações, preserve evidências sem copiar dados pessoais para tickets, confirme o usuário da sessão e examine as cláusulas `WHERE user_id` em `functions/api/data.ts` e rotas relacionadas. Não execute uma limpeza para “corrigir” mistura antes de fazer backup e entender a causa.

### Push parou

Verifique cron, VAPID, assinaturas, status dos provedores e tabelas de tentativa. Uma correção de push não deve alterar dados de negócio.

### Credencial exposta

Revogue a credencial imediatamente, gere outra, atualize o secret, publique e registre o incidente. Remover o texto de um commit não torna uma chave já exposta segura.

## Referências

[1]: https://developers.cloudflare.com/pages/how-to/use-direct-upload-with-continuous-integration/ "Cloudflare Pages — Use Direct Upload with continuous integration"

[2]: https://developers.cloudflare.com/d1/reference/migrations/ "Cloudflare D1 — Migrations"

[3]: https://developers.cloudflare.com/workers/configuration/cron-triggers/ "Cloudflare Workers — Cron Triggers"
