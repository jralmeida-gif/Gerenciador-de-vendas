# Guia de integração rápida

Este roteiro foi escrito para uma pessoa que acabou de receber acesso ao repositório e precisa entender o Gestor de Vendas sem depender de conhecimento prévio do projeto. A sequência evita que o colaborador comece pela parte errada ou altere dados sensíveis antes de compreender as fronteiras do sistema.

## O mapa mental em cinco minutos

O Gestor de Vendas é um PWA Flutter executado no navegador. O aplicativo mantém uma cópia local namespaced por perfil e sincroniza os dados de negócio com APIs hospedadas em Cloudflare Pages Functions. O D1 é a persistência remota multiusuário. Um Worker separado executa as notificações push por cron.

| Camada | Diretório ou recurso | Responsabilidade |
|---|---|---|
| Interface Flutter | `lib/screens/`, `lib/widgets/`, `lib/theme/` | Telas, navegação, componentes compartilhados e identidade visual. |
| Estado local | `lib/services/app_state.dart` | Estado observável, catálogos, configurações e sincronização disparada pela interface. |
| Persistência local | `lib/services/repositorio.dart` | Caixas Hive namespaced por perfil, backups internos e preferências locais. |
| Clientes HTTP | `lib/services/auth_client.dart`, `cloud_data_client.dart`, `push_client*.dart` | Comunicação autenticada com Pages Functions e configuração de push. |
| Backend Pages | `functions/` | Sessão, autenticação, sincronização D1, catálogo, recuperação de senha e operações administrativas. |
| Worker | `push_worker/src/index.ts` | Alertas de aniversário, portabilidade e retorno de prospecção. |
| Schema remoto | `push_worker/migrations/` | Evolução versionada do D1. |
| Publicação | `.github/workflows/ci-cd-v3.yml` | Validação e deploy automático para Pages e Worker. |

## Primeiro dia

### 1. Confirmar o acesso correto

O repositório é [jralmeida-gif/Gerenciador-de-vendas](https://github.com/jralmeida-gif/Gerenciador-de-vendas). A branch de integração é `main`. O ambiente de produção é o projeto Pages `gestor-vendas-agencia-v3`, acessível em [gestor-vendas-agencia-v3.pages.dev](https://gestor-vendas-agencia-v3.pages.dev/).

Antes de clonar, confirme que o colaborador recebeu apenas as permissões necessárias no GitHub. Acesso ao código não implica automaticamente acesso aos secrets, ao D1 ou ao painel Cloudflare.

### 2. Preparar a máquina

Instale Flutter 3.47.0 no canal stable, Node.js 22, Git e um navegador. O Flutter recomenda ter o SDK e um navegador instalados para construir aplicações web [1].

Clone o projeto:

```bash
gh repo clone jralmeida-gif/Gerenciador-de-vendas
cd Gerenciador-de-vendas
```

Instale as dependências:

```bash
flutter pub get
cd push_worker
npm install
cd ..
```

### 3. Fazer o primeiro build

```bash
flutter analyze
flutter test
flutter build web --release
```

Depois valide o Worker e as Functions:

```bash
cd push_worker
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

Se esses comandos passarem, o ambiente local está preparado para começar uma alteração. Para visualizar a aplicação, execute:

```bash
flutter run -d chrome
```

### 4. Fazer a leitura orientada

A ordem de leitura recomendada é:

1. Este documento, para obter o mapa geral.
2. [`README.md`](../README.md), para comandos e links operacionais.
3. [`docs/ARQUITETURA.md`](ARQUITETURA.md), para dados, autenticação e rotas.
4. [`docs/OPERACAO-E-SEGURANCA.md`](OPERACAO-E-SEGURANCA.md), antes de tocar em secrets, backup, push ou limpeza.
5. `lib/screens/inicio.dart`, para entender o shell de navegação.
6. `lib/screens/auth_gate.dart`, para entender a abertura, a sessão e o logout.
7. `lib/services/app_state.dart`, `lib/services/repositorio.dart` e `lib/services/cloud_data_client.dart`, para entender o estado, o Hive e a nuvem.
8. `functions/_auth.ts` e `functions/api/data.ts`, para entender o servidor e o isolamento.
9. `push_worker/src/index.ts`, para entender notificações e cron.
10. `.github/workflows/ci-cd-v3.yml`, para entender como a mudança chega à produção.

## Como localizar uma funcionalidade

Comece pela tela que o usuário vê e siga o fluxo até o armazenamento. O padrão usual é:

```text
Tela Flutter
  → AppState
    → Repositorio e/ou cliente HTTP
      → Pages Function
        → D1
```

| Se a demanda mencionar... | Comece por... |
|---|---|
| Login, senha, sessão ou logout | `lib/screens/auth_gate.dart`, `lib/services/auth_client.dart`, `functions/_auth.ts` e `functions/api/auth/`. |
| Vendas, portabilidade ou prospecção | A tela correspondente em `lib/screens/`, `lib/services/app_state.dart` e `functions/api/data.ts`. |
| Clientes e CPF | `lib/screens/relatorios.dart`, formulários de processo e `lib/services/app_state.dart`. |
| Produtos ou convênios | `lib/screens/configuracoes.dart`, `functions/api/admin/catalog.ts` e `functions/api/catalog.ts`. |
| Metas e painel | `lib/screens/dashboard.dart`, `lib/screens/metas_editar.dart` e `AppState`. |
| Agenda ou notificações | `lib/screens/agenda.dart`, `lib/services/push_client*.dart`, `functions/api/push/` e `push_worker/src/index.ts`. |
| Backup | `lib/services/backup_saver*.dart`, `lib/services/repositorio.dart` e as telas de Configurações. |
| Foto, alias ou cabeçalho | `lib/widgets/comuns.dart`, `lib/screens/configuracoes.dart` e `user_settings` em D1. |

## Receita para uma alteração de tela

Antes de editar, descreva o estado atual, a mudança desejada e o impacto nos dados. Em seguida:

1. Localize a tela e o widget reutilizável mais próximo.
2. Verifique se a tela já está dentro do shell `TelaInicio` ou se foi aberta via `Navigator.push`.
3. Preserve o cabeçalho, o alias, o avatar, os atalhos globais e a possibilidade de retorno.
4. Adicione estados de carregamento, vazio, erro e sucesso.
5. Se houver dados, altere também o estado local, a sincronização e o endpoint correspondente.
6. Se o campo receber CPF, data ou telefone, reutilize os formatadores existentes.
7. Teste em janela estreita e em uma largura semelhante à tela do iPhone.

Uma tela nova nunca deve criar uma rota sem uma saída clara. O menu inferior ou um botão de voltar deve continuar disponível.

## Receita para uma alteração de dados

Primeiro decida se o dado é local, sincronizado por usuário, global de catálogo ou técnico de notificações. Essa decisão determina onde a alteração deve ocorrer.

Para um novo campo de negócio sincronizado:

1. Acrescente a coluna em uma nova migração SQL.
2. Atualize as tabelas `user_*` de negócio e as rotas `GET`/`POST` de `functions/api/data.ts`.
3. Atualize os modelos Dart e o `Repositorio`.
4. Atualize o formulário, a edição, a ficha do cliente, o relatório e o backup.
5. Verifique se o Worker de notificações precisa do campo.
6. Teste um usuário comum e o administrador separadamente.

Para um dado de catálogo, não o coloque no snapshot comum do usuário. Use as rotas de catálogo e mantenha a propagação para espelhos e o tratamento de itens inativos.

## Cenários mínimos de teste

Todo pull request deve registrar os cenários aplicáveis:

| Cenário | Resultado esperado |
|---|---|
| Login válido | Abre o perfil correto e carrega apenas seus dados. |
| Login inválido | Não revela detalhes desnecessários e não monta a tela autenticada. |
| Usuário comum | Não acessa rotas administrativas nem catálogo mestre. |
| Dois perfis no mesmo navegador | A troca de perfil não mistura caixas Hive nem snapshots D1. |
| Sem rede | A interface não apaga silenciosamente dados remotos e informa a falha quando necessário. |
| Reabertura após inatividade | A sessão é validada antes de mostrar o shell autenticado. |
| Dados vazios | A tela mostra estado vazio sem quebrar o layout. |
| Mudança de catálogo | O histórico preserva nomes válidos e itens inativos não são oferecidos para novos lançamentos. |
| Push | A assinatura pertence ao usuário correto e a deduplicação evita repetição. |

## Ao finalizar a tarefa

Execute a suíte local, revise o diff, faça commit em uma branch de trabalho e abra um pull request. Não faça publicação manual para “testar” uma ideia que ainda não passou pela validação local. O pipeline será disparado pelo GitHub e o deploy para `main` ocorrerá somente depois da etapa de validação.

## Referências

[1]: https://docs.flutter.dev/platform-integration/web/building "Flutter — Building a web application"
