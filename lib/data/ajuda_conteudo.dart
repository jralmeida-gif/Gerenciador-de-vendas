import 'package:flutter/material.dart';

class ItemFaq {
  final String pergunta;
  final String resposta;
  final IconData icone;
  const ItemFaq(this.pergunta, this.resposta, this.icone);
}

class CategoriaAjuda {
  final String titulo;
  final String descricao;
  final IconData icone;
  final List<ItemFaq> itens;
  const CategoriaAjuda(this.titulo, this.descricao, this.icone, this.itens);
}

class DicaTela {
  final String titulo;
  final String oQueFaz;
  final String comoUsar;
  final String? atencao;
  const DicaTela({required this.titulo, required this.oQueFaz, required this.comoUsar, this.atencao});
}

const categoriasAjuda = <CategoriaAjuda>[
  CategoriaAjuda('Acesso e segurança', 'Login, senhas, sessão e permissões.', Icons.lock_outline, [
    ItemFaq('Como faço o primeiro acesso?', 'Use o usuário e a senha temporária fornecidos pelo administrador. No primeiro acesso, crie uma senha pessoal.', Icons.login),
    ItemFaq('Esqueci minha senha. O que faço?', 'Usuários comuns devem solicitar ao administrador uma nova senha temporária. O administrador principal ainda depende do método de recuperação que será definido para o sistema.', Icons.help_outline),
    ItemFaq('Por que fui desconectado?', 'A sessão pode ter sido encerrada manualmente ou por inatividade. Entre novamente para continuar.', Icons.timer_outlined),
    ItemFaq('Qual é a diferença entre usuário comum e administrador?', 'O usuário comum trabalha com a própria base. O administrador gerencia acessos, enquanto os dados continuam separados por perfil.', Icons.admin_panel_settings_outlined),
  ]),
  CategoriaAjuda('Clientes', 'Cadastro consolidado, CPF e nascimento.', Icons.badge_outlined, [
    ItemFaq('Como o cliente é identificado?', 'O CPF é o principal identificador. Confira os dados antes de criar um novo cadastro.', Icons.fingerprint),
    ItemFaq('Posso cadastrar um cliente sem fazer uma venda?', 'Sim. Na Ficha Consolidada de Clientes, toque em Cadastrar. Informe o CPF, nome, telefone e, se quiser, a data de nascimento para acompanhar o aniversário.', Icons.person_add_alt_1_outlined),
    ItemFaq('Como corrijo a data de nascimento?', 'Abra Relatórios, entre na Ficha Consolidada de Clientes, localize o cliente e use a ação de edição da data.', Icons.cake_outlined),
    ItemFaq('O que faço quando há divergência de CPF ou telefone?', 'Pare antes de duplicar o cadastro. Revise a ficha consolidada e corrija os dados do cliente.', Icons.warning_amber_outlined),
  ]),
  CategoriaAjuda('Vendas', 'Lançamentos, duplicidade e WhatsApp.', Icons.point_of_sale_outlined, [
    ItemFaq('Como lanço uma venda?', 'Abra Vendas, toque em Nova venda, preencha cliente, produto, data e valores e revise antes de salvar.', Icons.add_shopping_cart),
    ItemFaq('Como funciona o aviso de possível duplicidade?', 'O sistema compara CPF, período/data, produto e valor. O alerta é uma conferência e não exclui o lançamento automaticamente.', Icons.content_copy_outlined),
    ItemFaq('Como vejo os produtos de um mesmo cliente?', 'A lista agrupa as vendas por cliente dentro do período selecionado e mostra os produtos abaixo do nome.', Icons.group_outlined),
  ]),
  CategoriaAjuda('Portabilidade', 'Pedidos, confirmações e prazos.', Icons.swap_horiz, [
    ItemFaq('Qual é a diferença entre pendente e confirmada?', 'Pendente é o pedido em acompanhamento. Confirmada é a operação que recebeu os dados finais.', Icons.pending_actions_outlined),
    ItemFaq('Como confirmo uma portabilidade?', 'Abra o pedido pendente, escolha Confirmar portabilidade e informe os dados finais solicitados.', Icons.verified_outlined),
  ]),
  CategoriaAjuda('Prospecção e follow-up', 'Interesse do cliente e próximos contatos.', Icons.phone_in_talk_outlined, [
    ItemFaq('Como registro uma prospecção?', 'Abra Prospecção, toque em Nova, preencha o cliente, produto de interesse e, se necessário, a data de retorno.', Icons.add_call),
    ItemFaq('Como funciona o retorno?', 'A data de retorno alimenta a Agenda e pode gerar avisos de follow-up conforme as regras de notificação.', Icons.event_repeat),
    ItemFaq('Como concluo uma prospecção?', 'Abra as ações do registro e escolha Marcar como concluída. O histórico permanece preservado.', Icons.check_circle_outline),
  ]),
  CategoriaAjuda('Agenda e notificações', 'Pendências, retornos e aniversários.', Icons.notifications_none, [
    ItemFaq('O que aparece na Agenda?', 'A Agenda reúne compromissos do dia escolhido, do dia seguinte e de uma janela maior, incluindo retornos, portabilidades pendentes e aniversários.', Icons.calendar_month_outlined),
    ItemFaq('Como consulto os próximos 30 dias?', 'Escolha uma data no calendário e selecione Próximos 30 dias na janela de visualização. O tipo de cada compromisso aparece destacado abaixo do nome.', Icons.date_range_outlined),
    ItemFaq('Por que não recebi uma notificação?', 'Confira a permissão de notificações, a conexão do dispositivo e se o cliente possui uma data válida cadastrada.', Icons.notifications_off_outlined),
    ItemFaq('Como reativo as notificações?', 'Reative a permissão nas configurações do navegador ou aparelho e abra novamente o PWA para atualizar a inscrição.', Icons.notification_add_outlined),
  ]),
  CategoriaAjuda('Metas e desempenho', 'Metas mensais, GAP e ritmo diário.', Icons.flag_outlined, [
    ItemFaq('Como cadastro uma meta?', 'Abra Metas, selecione o mês de competência e informe a meta individual por produto ou foco.', Icons.edit_calendar_outlined),
    ItemFaq('O que é GAP?', 'É a diferença entre a meta e o realizado. Quando ainda falta atingir a meta, o GAP mostra o quanto precisa ser buscado.', Icons.compare_arrows),
    ItemFaq('O que significa ritmo necessário?', 'É a média que precisa ser realizada em cada dia útil restante para alcançar a meta do mês.', Icons.speed),
    ItemFaq('O que é projeção?', 'É uma estimativa do resultado ao final do mês se o ritmo atual continuar.', Icons.trending_up),
  ]),
  CategoriaAjuda('Relatórios', 'Filtros, agrupamentos e ficha consolidada.', Icons.assessment_outlined, [
    ItemFaq('Como escolho um relatório?', 'Abra Relatórios, escolha o tipo e configure período, foco e filtros antes de gerar.', Icons.description_outlined),
    ItemFaq('O que significa agrupar pelo cliente?', 'Todos os produtos negociados com o mesmo cliente aparecem juntos dentro do período escolhido.', Icons.account_tree_outlined),
    ItemFaq('Posso gerar a ficha de um cliente?', 'Sim. Use a Ficha Consolidada, pesquise por nome ou CPF e selecione o cliente desejado.', Icons.person_search_outlined),
  ]),
  CategoriaAjuda('Backup e dados', 'Exportação, restauração e separação por usuário.', Icons.backup_outlined, [
    ItemFaq('Como faço um backup?', 'Use a exportação nas Configurações, escolha onde salvar e mantenha o arquivo em local seguro.', Icons.file_download_outlined),
    ItemFaq('Por que o backup tem data e hora?', 'Para evitar que um novo arquivo substitua acidentalmente um backup anterior.', Icons.schedule),
    ItemFaq('O backup é por usuário?', 'Sim. Cada usuário deve exportar e proteger a própria base.', Icons.person_pin_outlined),
  ]),
  CategoriaAjuda('WhatsApp', 'Mensagens e abertura do aplicativo.', Icons.chat_outlined, [
    ItemFaq('Como envio mensagem?', 'Abra uma ação de cliente em Vendas, Portabilidade ou Prospecção e toque no logo do WhatsApp.', Icons.send_outlined),
    ItemFaq('Por que o WhatsApp não abriu?', 'Confira se o telefone está completo e se o aparelho permite abrir links externos.', Icons.open_in_new),
  ]),
];

const problemasAjuda = <ItemFaq>[
  ItemFaq('Estou vendo uma versão antiga', 'Feche completamente o PWA, remova-o dos aplicativos recentes, abra o endereço atual e faça uma atualização forçada.', Icons.refresh),
  ItemFaq('A foto voltou para a anterior', 'Confirme se o salvamento terminou antes de fechar o PWA. Abra novamente com conexão ativa para restaurar o perfil do servidor.', Icons.photo_camera_back_outlined),
  ItemFaq('O menu não troca de tela', 'Feche e reabra o PWA. Se continuar, use a barra inferior e confirme que está no endereço atual da v3.', Icons.touch_app_outlined),
  ItemFaq('O relatório abriu e não sei voltar', 'Use a seta do cabeçalho para retornar à lista de Relatórios ou toque diretamente em outro item da barra inferior.', Icons.arrow_back),
  ItemFaq('Não encontro um cliente', 'Revise o período e os filtros. Pesquise pelo CPF completo ou pelo nome sem acentos quando necessário.', Icons.search),
];

const dicasContextuais = <String, DicaTela>{
  'Início': DicaTela(titulo: 'Painel inicial', oQueFaz: 'Mostra metas, desempenho e pendências do período atual.', comoUsar: 'Toque nos cartões para abrir os detalhes. No painel de desempenho, compare realizado, GAP, ritmo necessário e projeção.'),
  'Vendas': DicaTela(titulo: 'Lista de vendas', oQueFaz: 'Agrupa os lançamentos por cliente dentro do período escolhido.', comoUsar: 'Use a busca e os filtros. Toque no cliente para ver os produtos e as ações disponíveis.', atencao: 'O aviso de possível duplicidade é uma conferência; revise antes de confirmar.'),
  'Portabilidade': DicaTela(titulo: 'Acompanhamento de portabilidade', oQueFaz: 'Separa pedidos pendentes de operações confirmadas.', comoUsar: 'Abra o pedido para editar, confirmar, enviar WhatsApp ou acompanhar o prazo.'),
  'Prospecção': DicaTela(titulo: 'Follow-up', oQueFaz: 'Registra o interesse e organiza o próximo contato.', comoUsar: 'Cadastre a data de retorno para que o registro seja acompanhado na Agenda.'),
  'Agenda': DicaTela(titulo: 'Agenda de pendências', oQueFaz: 'Reúne o que exige atenção hoje, nos próximos dias e os aniversários próximos.', comoUsar: 'Use cada seção para abrir o registro correspondente e agir sobre a pendência.'),
  'Metas': DicaTela(titulo: 'Metas mensais', oQueFaz: 'Compara o planejado com o realizado por competência mensal.', comoUsar: 'Selecione o mês antes de editar a meta. O dashboard calcula GAP e ritmo a partir desses valores.'),
  'Relatórios': DicaTela(titulo: 'Relatórios', oQueFaz: 'Consulta e organiza os dados sem alterar os lançamentos.', comoUsar: 'Escolha o relatório, período, foco e filtros. Use a ficha consolidada para pesquisar clientes.'),
  'Configurações': DicaTela(titulo: 'Configurações', oQueFaz: 'Administra perfil, foto, notificações, usuários, backup e ajuda.', comoUsar: 'Escolha uma opção e salve as alterações. Usuários administradores possuem ações adicionais.'),
};

class RecursoAjuda {
  final String nome;
  final String? descricao;
  final IconData icone;
  final String explicacao;
  final List<String> passos;
  final String? atencao;

  const RecursoAjuda({
    required this.nome,
    required this.descricao,
    required this.icone,
    required this.explicacao,
    required this.passos,
    this.atencao,
  });
}

/// Recursos exibidos na Central de Ajuda em ordem alfabética.
/// Descrições nulas são intencionais: o cartão mostra somente o nome.
const recursosAjuda = <RecursoAjuda>[
  RecursoAjuda(
    nome: 'Acessar ficha de clientes',
    descricao: 'Consultar, pesquisar e editar a ficha consolidada.',
    icone: Icons.badge_outlined,
    explicacao: 'A ficha reúne clientes com negócios, cadastro direto ou prospecção.',
    passos: [
      'Abra Relatórios e escolha Ficha Consolidada de Clientes.',
      'Use o nome ou o CPF para localizar uma pessoa.',
      'Escolha a aba Negócios, Cadastro ou Prospecção.',
      'Toque no cartão para consultar os dados e as ações disponíveis.',
    ],
  ),
  RecursoAjuda(
    nome: 'Agenda',
    descricao: 'Acompanhar retornos, pendências e aniversários.',
    icone: Icons.calendar_month_outlined,
    explicacao: 'A Agenda organiza compromissos a partir de uma data escolhida no calendário.',
    passos: [
      'Abra Agenda pelo cabeçalho ou pelo menu correspondente.',
      'Toque em um dia do calendário.',
      'Escolha a janela de visualização: dia seguinte, 7, 30 ou 60 dias.',
      'Leia os compromissos reunidos por período, com o tipo destacado abaixo do nome.',
    ],
  ),
  RecursoAjuda(
    nome: 'Aniversários',
    descricao: 'Acompanhar datas de nascimento dos clientes.',
    icone: Icons.cake_outlined,
    explicacao: 'A data de nascimento da ficha pode alimentar a Agenda e os avisos de aniversário.',
    passos: [
      'Abra a ficha do cliente.',
      'Edite a data de nascimento no campo correspondente.',
      'Salve a alteração e mantenha as notificações permitidas no aparelho.',
      'Consulte a Agenda para acompanhar os aniversários próximos.',
    ],
    atencao: 'O aviso depende de uma data válida e das permissões de notificação do aparelho.',
  ),
  RecursoAjuda(
    nome: 'Ativar notificações',
    descricao: 'Permitir avisos de retornos e aniversários.',
    icone: Icons.notifications_active_outlined,
    explicacao: 'As notificações ajudam a lembrar retornos, pendências e aniversários cadastrados.',
    passos: [
      'Abra Configurações no aplicativo.',
      'Entre na opção de notificações.',
      'Ative a permissão quando o aparelho solicitar.',
      'Se a permissão tiver sido bloqueada, abra as configurações do sistema e permita notificações para o Gestor de Vendas.',
    ],
    atencao: 'O sistema operacional pode exigir que a permissão seja liberada fora do aplicativo.',
  ),
  RecursoAjuda(
    nome: 'Backup automático',
    descricao: 'Manter uma cópia interna atualizada da base do usuário.',
    icone: Icons.backup_outlined,
    explicacao: 'O aplicativo mantém um backup interno associado ao perfil local do usuário.',
    passos: [
      'Use o aplicativo normalmente com a sessão autenticada.',
      'Confira em Configurações a data do último backup automático.',
      'Não apague os dados do navegador ou do aparelho sem manter também um arquivo externo.',
    ],
    atencao: 'O backup automático não substitui a guarda de um arquivo externo em local seguro.',
  ),
  RecursoAjuda(
    nome: 'Cadastrar campanha',
    descricao: 'Criar campanhas e acompanhar o andamento no painel.',
    icone: Icons.campaign_outlined,
    explicacao: 'Campanhas agrupam produtos e permitem acompanhar o progresso no painel inicial.',
    passos: [
      'Abra Campanhas pelo painel ou pelo menu correspondente.',
      'Toque em Nova campanha.',
      'Informe o nome, o período e os produtos participantes.',
      'Salve e acompanhe o andamento no painel inicial.',
    ],
  ),
  RecursoAjuda(
    nome: 'Cadastrar metas',
    descricao: 'Definir metas mensais por produto ou foco.',
    icone: Icons.flag_outlined,
    explicacao: 'As metas são cadastradas por mês de competência e comparadas com o realizado.',
    passos: [
      'Abra Metas.',
      'Selecione o mês e o ano da competência.',
      'Informe a meta dos produtos ou focos disponíveis.',
      'Salve e consulte o desempenho no painel inicial.',
    ],
  ),
  RecursoAjuda(
    nome: 'Cadastrar portabilidade',
    descricao: 'Registrar pedidos e acompanhar confirmações.',
    icone: Icons.swap_horiz,
    explicacao: 'A portabilidade começa como um pedido pendente e pode ser confirmada quando os dados finais estiverem disponíveis.',
    passos: [
      'Abra Portabilidade e toque em Nova portabilidade.',
      'Preencha o cliente, convênio, valores e datas solicitados.',
      'Salve o pedido e acompanhe seu status na lista.',
      'Quando houver os dados finais, abra o pedido e confirme a portabilidade.',
    ],
  ),
  RecursoAjuda(
    nome: 'Cadastro de cliente',
    descricao: 'Incluir um cliente mesmo sem cadastrar uma venda.',
    icone: Icons.person_add_alt_1_outlined,
    explicacao: 'Permite manter uma ficha para relacionamento, futuras ofertas e acompanhamento de aniversário.',
    passos: [
      'Abra Clientes ou a Ficha Consolidada de Clientes.',
      'Toque em Cadastrar.',
      'Informe o CPF e confira se o sistema encontrou uma ficha existente.',
      'Preencha nome, telefone, nascimento e observações, se desejar.',
      'Salve para incluir o cliente na aba Cadastro.',
    ],
    atencao: 'O CPF evita a criação de fichas duplicadas para o mesmo cliente.',
  ),
  RecursoAjuda(
    nome: 'Cadastro de venda',
    descricao: 'Registrar uma venda com produto, data e valores.',
    icone: Icons.point_of_sale_outlined,
    explicacao: 'O lançamento de venda registra o negócio e atualiza os indicadores do usuário.',
    passos: [
      'Abra Vendas e toque em Nova venda.',
      'Informe o cliente, o produto, a data e os valores.',
      'Leia o aviso de possível duplicidade, quando aparecer.',
      'Revise os dados e salve o lançamento.',
    ],
  ),
  RecursoAjuda(
    nome: 'Catálogo',
    descricao: null,
    icone: Icons.inventory_2_outlined,
    explicacao: 'O catálogo reúne os produtos e convênios administrados pelo responsável pelo sistema.',
    passos: [
      'O administrador abre Configurações e acessa Produtos ou Convênios.',
      'Use as ações de cadastro, edição ou exclusão permitidas.',
      'As alterações do catálogo ficam disponíveis para os demais usuários.',
    ],
    atencao: 'A alteração do catálogo não deve apagar o histórico dos lançamentos já realizados.',
  ),
  RecursoAjuda(
    nome: 'Enviar WhatsApp',
    descricao: 'Abrir uma mensagem para o cliente pelo WhatsApp.',
    icone: Icons.chat_outlined,
    explicacao: 'O aplicativo prepara a abertura do WhatsApp com o telefone do cliente e, quando aplicável, uma saudação.',
    passos: [
      'Abra o cartão ou a ficha do cliente.',
      'Toque no ícone do WhatsApp.',
      'Confira o número e a mensagem no aplicativo externo.',
      'Envie a mensagem pelo próprio WhatsApp.',
    ],
    atencao: 'O telefone precisa estar completo e o aparelho deve permitir a abertura de links externos.',
  ),
  RecursoAjuda(
    nome: 'Fazer backup externo',
    descricao: 'Gerar um arquivo de backup para guardar fora do aplicativo.',
    icone: Icons.file_download_outlined,
    explicacao: 'O backup externo cria um arquivo com data e hora para reduzir o risco de sobrescrever cópias anteriores.',
    passos: [
      'Abra Configurações e escolha a opção de exportar backup.',
      'Selecione o destino oferecido pelo aparelho.',
      'Guarde o arquivo em local seguro e, se possível, em mais de um local.',
      'Confira em Configurações a data do último arquivo externo preparado.',
    ],
    atencao: 'O aplicativo confirma a preparação da exportação, mas o sistema operacional pode controlar a pasta final do arquivo.',
  ),
  RecursoAjuda(
    nome: 'Histórico administrativo',
    descricao: null,
    icone: Icons.history_outlined,
    explicacao: 'Administradores consultam acessos e operações técnicas ou operacionais do sistema.',
    passos: [
      'Entre com uma conta administradora.',
      'Abra Configurações e acesse Acessos e atividades.',
      'Consulte usuário, perfil, operação, quantidade afetada, resultado e horário.',
    ],
    atencao: 'O histórico não exibe CPF, nome, telefone, produto, valor ou conteúdo de cliente.',
  ),
  RecursoAjuda(
    nome: 'Login e sessão',
    descricao: null,
    icone: Icons.lock_outline,
    explicacao: 'Controla o acesso ao aplicativo e a permanência da sessão autenticada.',
    passos: [
      'Abra o endereço do Gestor de Vendas.',
      'Informe usuário e senha.',
      'No primeiro acesso, troque a senha temporária quando solicitado.',
      'Saia manualmente ou aguarde o bloqueio por inatividade quando configurado.',
    ],
    atencao: 'Nunca compartilhe sua senha ou uma senha mestra com outra pessoa.',
  ),
  RecursoAjuda(
    nome: 'Prospecção e follow-up',
    descricao: 'Registrar interesse e organizar o próximo contato.',
    icone: Icons.phone_in_talk_outlined,
    explicacao: 'A prospecção registra uma oportunidade ainda não convertida e sua data de retorno.',
    passos: [
      'Abra Prospecção e toque em Nova prospecção.',
      'Preencha o cliente, o produto de interesse e a data de retorno.',
      'Acompanhe o retorno pela Agenda.',
      'Marque a prospecção como concluída quando o contato terminar.',
    ],
  ),
  RecursoAjuda(
    nome: 'Tirar relatórios',
    descricao: 'Consultar dados e gerar relatórios em PDF.',
    icone: Icons.assessment_outlined,
    explicacao: 'Os relatórios organizam os lançamentos por período, foco, grupo ou cliente sem alterar os dados.',
    passos: [
      'Abra Relatórios.',
      'Escolha o tipo de relatório.',
      'Defina período, foco e filtros desejados.',
      'Confira a prévia completa e toque em Gerar PDF.',
    ],
  ),
  RecursoAjuda(
    nome: 'Usuários',
    descricao: null,
    icone: Icons.manage_accounts_outlined,
    explicacao: 'Administradores gerenciam acessos, perfis, senhas temporárias e status dos usuários.',
    passos: [
      'Entre com uma conta administradora.',
      'Abra Configurações e acesse Usuários.',
      'Use Novo usuário ou as ações do cartão para editar, redefinir senha ou excluir um acesso permitido.',
    ],
    atencao: 'A administração de usuários não permite consultar o conteúdo comercial privado de outro perfil.',
  ),
];
