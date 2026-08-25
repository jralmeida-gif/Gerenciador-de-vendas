# Contribuindo com o Gestor de Vendas

Este documento define o fluxo técnico recomendado para alterar o Gestor de Vendas com segurança. O projeto possui dados reais de clientes e uma infraestrutura de produção ativa; por isso, uma alteração pequena de interface também deve ser tratada como uma mudança potencialmente sensível.

## Princípios obrigatórios

Todo código deve preservar o isolamento entre usuários, a validação de sessão no servidor, a navegação de retorno das telas e a compatibilidade com os dados já existentes. Não se deve confiar em um identificador de usuário enviado pelo navegador quando a informação puder ser obtida do cookie de sessão.

Não são permitidos commits contendo senhas, tokens, chaves privadas, cookies, arquivos `.env`, backups reais ou dados identificáveis de clientes. Para exemplos e testes, use valores fictícios.

Alterações de schema devem ser feitas por uma nova migração SQL numerada em `push_worker/migrations/`. Não edite uma migração já aplicada em produção para corrigir seu conteúdo; crie a próxima migração e documente a compatibilidade.

## Preparação do ambiente

Clone o repositório oficial e entre no diretório:

```bash
gh repo clone jralmeida-gif/Gerenciador-de-vendas
cd Gerenciador-de-vendas
```

Instale o Flutter 3.47.0 no canal stable e Node.js 22. O requisito do Dart está em `pubspec.yaml`; o Worker declara as versões de TypeScript, Wrangler e tipos Cloudflare em `push_worker/package.json`.

Na primeira preparação local:

```bash
flutter pub get
cd push_worker
npm install
cd ..
```

Para desenvolvimento web, o Flutter exige um navegador compatível. O comando padrão recomendado pelo Flutter é `flutter run -d chrome` [1].

## Desenvolvimento diário

Execute o PWA localmente com:

```bash
flutter run -d chrome
```

Para encerrar, use `q` no terminal ou pare o processo pelo ambiente de desenvolvimento. Alterações em Dart normalmente são refletidas pelo hot reload.

Ao trabalhar no Worker, faça a validação TypeScript dentro de `push_worker`:

```bash
cd push_worker
npx tsc --noEmit --skipLibCheck
cd ..
```

Para validar também as Pages Functions com tipagem estrita:

```bash
cd push_worker
npx tsc --noEmit \
  --target ES2022 \
  --module ESNext \
  --moduleResolution Bundler \
  --strict \
  --skipLibCheck \
  --types @cloudflare/workers-types \
  $(find ../functions -name '*.ts' -print)
cd ..
```

## Branches e commits

Não faça alterações diretamente na `main`, salvo operações administrativas muito específicas. Crie uma branch curta e descritiva:

```bash
git switch main
git pull --ff-only origin main
git switch -c feat/nome-da-alteracao
```

Use mensagens de commit curtas, no imperativo e com prefixo coerente. Exemplos:

```text
feat: adicionar filtro por período no relatório
fix: impedir mistura de perfis ao restaurar sessão
refactor: separar cliente de sincronização D1
chore: atualizar documentação de integração
```

Antes de abrir o pull request, confira o diff e o estado do repositório:

```bash
git diff --check
git status --short
git diff --stat
```

Arquivos locais, como `push_worker/node_modules/`, `build/` e documentos pessoais, não devem entrar no commit.

## Checklist de validação

Execute todos os comandos abaixo na raiz antes de abrir o pull request:

```bash
flutter analyze
flutter test
flutter build web --release

cd push_worker
npm install
npx tsc --noEmit --skipLibCheck
npx tsc --noEmit \
  --target ES2022 \
  --module ESNext \
  --moduleResolution Bundler \
  --strict \
  --skipLibCheck \
  --types @cloudflare/workers-types \
  $(find ../functions -name '*.ts' -print)
cd ..
```

Uma alteração de interface deve ser verificada no navegador. Uma alteração de autenticação, sincronização, D1, backup ou push deve ter, além da validação estática, um cenário de sucesso e um cenário de erro descritos no pull request.

## Pull request

O pull request deve explicar o problema, a solução, os arquivos relevantes, os riscos e os testes executados. Inclua capturas de tela apenas quando ajudarem a revisar a interface; nunca inclua dados reais de usuários.

A revisão deve responder, no mínimo, às seguintes perguntas:

| Pergunta | O que verificar |
|---|---|
| Isolamento | A operação usa o usuário da sessão e filtra as tabelas por `user_id`? |
| Segurança | Alguma senha, token ou operação administrativa foi exposta no cliente? |
| Dados | A mudança exige nova migração ou altera a compatibilidade do snapshot? |
| Navegação | A tela possui menu, botão de voltar e estados de carregamento/erro? |
| Offline/local | O Hive pode ficar diferente da nuvem ou reintroduzir dados apagados? |
| Produção | A mudança depende de secret, binding, cron ou configuração manual? |

O merge só deve ocorrer depois de o workflow do GitHub Actions terminar verde e de existir revisão adequada.

## CI/CD

O arquivo `.github/workflows/ci-cd-v3.yml` é a fonte oficial do pipeline. Ele é disparado por pull requests para `main`, pushes para `main` e manualmente por `workflow_dispatch`, conforme a sintaxe de workflows do GitHub [2].

O job de validação instala o Flutter 3.47.0, executa análise, testes, build web, instalação do Worker e TypeScript. O job de deploy depende da validação, usa o ambiente GitHub `production`, aplica migrações D1 somente quando o commit altera `push_worker/migrations/`, publica o Worker e envia `build/web` para o Pages.

Para executar manualmente:

1. Abra **Actions** no repositório.
2. Selecione **Gestor de Vendas v3**.
3. Clique em **Run workflow**.
4. Selecione a branch `main`.
5. Clique novamente em **Run workflow**.
6. Aguarde os jobs **Validar Flutter e Worker** e **Publicar v3 no Cloudflare**.

Um círculo vermelho em uma execução antiga não representa necessariamente o estado da versão atual. Sempre abra a execução mais recente do commit que será analisado.

## Secrets e configurações

Os secrets do GitHub Actions ficam no ambiente `production`. Os nomes usados pelo workflow são:

```text
CLOUDFLARE_API_TOKEN
VAPID_PRIVATE_KEY
VAPID_PUBLIC_KEY
```

O token Cloudflare precisa ter permissão para publicar Pages, publicar Workers Scripts e aplicar D1 na conta correta. Nunca registre o valor no código ou em uma issue.

As Pages Functions usam variáveis e secrets configurados no ambiente de produção do projeto Pages. Entre os nomes esperados estão:

```text
MAILJET_API_KEY
MAILJET_SECRET_KEY
MAILJET_FROM_EMAIL
MAILJET_FROM_NAME
GLOBAL_CLEANUP_MASTER_PASSWORD
VAPID_PUBLIC_KEY
```

O segredo `GLOBAL_CLEANUP_MASTER_PASSWORD` é usado somente pela rota administrativa de limpeza global. Ele não deve ser colocado no GitHub, no Flutter, em um arquivo TOML ou na base D1. Os nomes canônicos devem ser preferidos; aliases antigos aparecem no contrato de compatibilidade de `functions/_auth.ts`, mas não devem ser usados em novas configurações.

## Migrações D1

Crie uma nova migração com o próximo número disponível. Escreva SQL idempotente quando possível, revise chaves estrangeiras e considere o comportamento de dados já existentes. As migrações são versionadas em arquivos `.sql` e o Wrangler registra as aplicadas na tabela de migrações do D1 [3].

O pipeline usa o nome do banco `gestor-vendas-push-v3` com a configuração `push_worker/wrangler-v3.toml`. Não execute uma migração remota em produção sem verificar o diff, o backup e o plano de reversão.

## Regras para alterações por área

### Flutter e Hive

A persistência local é namespaced por perfil. Use os métodos de `Repositorio` e `AppState`; não abra manualmente uma caixa sem seguir o padrão `gv_<perfil>_<caixa>`. Ao alterar o snapshot, verifique importação de backup, sincronização e troca de perfil.

### Pages Functions

As Functions devem derivar o usuário de `getSession(request, env)`. Rotas administrativas devem confirmar `isAdmin`. Respostas devem usar o helper `json` e tratar CORS conforme o padrão existente. Erros de autenticação não devem revelar se um usuário específico existe quando isso não for necessário.

### Catálogo

Produtos e convênios são mantidos pelo administrador. Produtos excluídos permanecem inativos para preservar históricos. Renomeações precisam considerar vendas, prospecções, metas, campanhas, espelhos e relatórios.

### Push

O Worker é agendado a cada hora pelo cron `0 * * * *`. A função usa o horário local de São Paulo para decidir os slots de 9h e 14h, registra tentativas e usa chaves de deduplicação para evitar notificações repetidas. Não crie uma segunda tabela ou uma segunda rotina sem entender as tabelas legadas de lembretes.

## Referências

[1]: https://docs.flutter.dev/platform-integration/web/building "Flutter — Building a web application"

[2]: https://docs.github.com/actions/using-workflows/workflow-syntax-for-github-actions "GitHub — Workflow syntax for GitHub Actions"

[3]: https://developers.cloudflare.com/d1/reference/migrations/ "Cloudflare D1 — Migrations"
