import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/models.dart';
import '../utils/formatters.dart';
import 'repositorio.dart';
import 'push_client.dart';
import 'cloud_data_client.dart';
import 'auth_client.dart';

/// Estado global do app + motor de cálculo de metas
/// (equivalente ao módulo VBA modmetas da planilha original).
class AppState extends ChangeNotifier {
  final Repositorio repo;
  final _uuid = const Uuid();
  final _cloud = CloudDataClient();
  AuthUser? _authUser;
  VoidCallback? onAbrirAgenda;
  VoidCallback? onAbrirConfiguracoes;
  VoidCallback? onAbrirAjuda;
  VoidCallback? onVoltarGlobal;
  ValueChanged<Widget>? onAbrirRelatorio;

  AppState(this.repo);

  AuthUser? get authUser => _authUser;
  void configurarNavegacaoGlobal({VoidCallback? agenda, VoidCallback? configuracoes, VoidCallback? ajuda, VoidCallback? voltar, ValueChanged<Widget>? relatorio}) {
    onAbrirAgenda = agenda;
    onAbrirConfiguracoes = configuracoes;
    onAbrirAjuda = ajuda;
    onVoltarGlobal = voltar;
    onAbrirRelatorio = relatorio;
  }
  void definirUsuarioAutenticado(AuthUser? user) {
    _authUser = user;
    notifyListeners();
  }

  String novoId() => _uuid.v4();

  // ------------------- Configurações -------------------
  int get gerentes => repo.gerentes;
  int get assistentes => repo.assistentes;
  int get numFuncionarios => repo.numFuncionarios;
  String get nomeUsuario => repo.nomeUsuario;
  String get telefoneUsuario => repo.telefoneUsuario;
  String get recoveryEmail => repo.recoveryEmail;
  String get avatarData => repo.avatarData;
  double get avatarScale => repo.avatarScale;
  double get avatarOffsetX => repo.avatarOffsetX;
  double get avatarOffsetY => repo.avatarOffsetY;
  int get idleTimeoutMinutes => repo.idleTimeoutMinutes;
  DateTime? get ultimoBackup => repo.ultimoBackup;
  List<Map<String, dynamic>> get backupsInternos => repo.backupsInternos;

  Future<void> mudarPerfilLocal(String profile) async {
    await repo.switchProfile(profile);
    notifyListeners();
  }

  Future<void> salvarEquipe(int g, int a) async {
    await repo.salvarEquipe(gerentes: g, assistentes: a);
    notifyListeners();
  }

  Future<void> salvarNomeUsuario(String nome) async {
    await repo.salvarNomeUsuario(nome);
    notifyListeners();
    unawaited(sincronizarNuvem());
  }

  Future<void> salvarTelefoneUsuario(String telefone) async {
    await repo.salvarTelefoneUsuario(telefone);
    notifyListeners();
    unawaited(sincronizarNuvem());
  }

  Future<void> salvarRecoveryEmail(String email) async {
    await repo.salvarRecoveryEmail(email);
    notifyListeners();
    await sincronizarNuvem();
  }

  Future<void> salvarAvatarData(String value) async {
    await repo.salvarAvatarData(value);
    notifyListeners();
    await sincronizarNuvem();
  }

  Future<void> salvarAvatarEnquadramento({required double escala, required double deslocamentoX, required double deslocamentoY}) async {
    await repo.salvarAvatarEnquadramento(escala: escala, deslocamentoX: deslocamentoX, deslocamentoY: deslocamentoY);
    notifyListeners();
    await sincronizarNuvem();
  }

  Future<void> salvarIdleTimeoutMinutes(int value) async {
    await repo.salvarIdleTimeoutMinutes(value);
    notifyListeners();
    unawaited(sincronizarNuvem());
  }

  // ------------------- Listas -------------------
  List<Produto> get produtos => repo.produtos;
  List<Convenio> get convenios => repo.convenios;
  List<Venda> get vendas => repo.vendas;
  List<Portabilidade> get portabilidades => repo.portabilidades;
  List<Portabilidade> get portPendentes => repo.portabilidadesPendentes;
  List<Portabilidade> get portConfirmadas => repo.portabilidadesConfirmadas;
  List<Prospeccao> get prospeccoes => repo.prospeccoes;
  List<Campanha> get campanhas => repo.campanhas;

  /// União dos clientes salvos explicitamente com os clientes presentes nos
  /// três processos, incluindo prospecções antigas sem venda.
  List<Cliente> get clientes {
    final mapa = <String, Cliente>{};

    void incorporar({required String cpf, required String nome, required String telefone, DateTime? dataNascimento}) {
      if (cpf.isEmpty) return;
      final atual = mapa[cpf];
      mapa[cpf] = Cliente(
        cpf: cpf,
        nome: nome.trim().isEmpty ? (atual?.nome ?? '') : nome.trim(),
        telefone: telefone.isEmpty ? (atual?.telefone ?? '') : telefone,
        dataNascimento: dataNascimento ?? atual?.dataNascimento,
        observacoes: atual?.observacoes ?? '',
      );
    }

    for (final c in repo.clientes) {
      incorporar(cpf: c.cpf, nome: c.nome, telefone: c.telefone, dataNascimento: c.dataNascimento);
    }
    for (final v in repo.vendas) {
      incorporar(cpf: v.cpf, nome: v.nome, telefone: v.telefone, dataNascimento: v.dataNascimento);
    }
    for (final p in repo.portabilidades) {
      incorporar(cpf: p.cpf, nome: p.nome, telefone: p.telefone, dataNascimento: p.dataNascimento);
    }
    for (final p in repo.prospeccoes) {
      incorporar(cpf: p.cpf, nome: p.nome, telefone: p.telefone, dataNascimento: p.dataNascimento);
    }

    final lista = mapa.values.toList()
      ..sort((a, b) => a.nome.toLowerCase().compareTo(b.nome.toLowerCase()));
    return lista;
  }

  Cliente? clientePorCpf(String cpf) {
    for (final cliente in clientes) {
      if (cliente.cpf == cpf) return cliente;
    }
    return null;
  }

  String formatoDoProduto(String p) => repo.formatoDoProduto(p);
  double metaDoProduto(String p) => repo.metaDoProduto(p);
  List<MetaMensal> get metasMensais => repo.metasMensais;
  double metaMensalDoProduto(String produto, String mes) => repo.metaMensalDoProduto(produto, mes);

  Venda? encontrarVendaDuplicada(Venda candidata) {
    for (final existente in vendas) {
      if (existente.id == candidata.id) continue;
      final mesmaData = existente.data.year == candidata.data.year &&
          existente.data.month == candidata.data.month &&
          existente.data.day == candidata.data.day;
      final mesmoCpf = existente.cpf == candidata.cpf;
      final mesmoProduto = existente.produto.trim().toLowerCase() == candidata.produto.trim().toLowerCase();
      final mesmoValor = (existente.valorRealizado - candidata.valorRealizado).abs() < 0.005;
      if (mesmaData && mesmoCpf && mesmoProduto && mesmoValor) return existente;
    }
    return null;
  }

  // ------------------- CRUD -------------------
  Future<void> salvarCliente(Cliente c) async {
    await repo.salvarCliente(c);
    notifyListeners();
    unawaited(sincronizarNuvem());
  }

  /// Cria ou atualiza o cadastro consolidado a partir de qualquer processo.
  /// Campos vazios não apagam informações já preenchidas.
  Future<void> atualizarClienteConsolidado({
    required String cpf,
    required String nome,
    required String telefone,
    DateTime? dataNascimento,
  }) async {
    final atual = clientePorCpf(cpf);
    final cliente = Cliente(
      cpf: cpf,
      nome: nome.trim().isEmpty ? (atual?.nome ?? '') : nome.trim(),
      telefone: telefone.isEmpty ? (atual?.telefone ?? '') : telefone,
      dataNascimento: dataNascimento ?? atual?.dataNascimento,
      observacoes: atual?.observacoes ?? '',
    );
    await salvarCliente(cliente);
  }

  Future<void> salvarVenda(Venda v) async {
    await repo.salvarVenda(v);
    notifyListeners();
    unawaited(sincronizarNuvem());
  }

  Future<void> excluirVenda(String id) async {
    await repo.excluirVenda(id);
    notifyListeners();
    unawaited(sincronizarNuvem());
  }

  Future<void> salvarPortabilidade(Portabilidade p) async {
    await repo.salvarPortabilidade(p);
    if (p.confirmado) {
      await _registrarVendaDaPortabilidade(p);
    }
    notifyListeners();
    unawaited(sincronizarNuvem());
    await sincronizarPrazosPush();
  }

  Future<void> _registrarVendaDaPortabilidade(Portabilidade p) async {
    final id = 'portabilidade-venda-${p.id}';
    final correspondentes = vendas.where((v) => v.id == id).toList();
    final existente = correspondentes.isEmpty ? null : correspondentes.first;
    final venda = Venda(
      id: id,
      data: p.data,
      cpf: p.cpf,
      nome: p.nome,
      telefone: p.telefone,
      dataNascimento: p.dataNascimento,
      produto: 'Portabilidade',
      valorRealizado: p.saldoDevedor,
      observacoes: 'Gerada automaticamente a partir da confirmação da portabilidade ${p.numeroContrato}.',
    );
    if (existente == null) {
      await repo.salvarVenda(venda);
    } else if (existente.data != venda.data || existente.valorRealizado != venda.valorRealizado || existente.nome != venda.nome || existente.telefone != venda.telefone || existente.dataNascimento != venda.dataNascimento) {
      await repo.salvarVenda(venda);
    }
  }

  Future<void> excluirPortabilidade(String id) async {
    await repo.excluirPortabilidade(id);
    notifyListeners();
    unawaited(sincronizarNuvem());
    await sincronizarPrazosPush();
  }

  Future<void> salvarProspeccao(Prospeccao p) async {
    await repo.salvarProspeccao(p);
    notifyListeners();
    unawaited(sincronizarNuvem());
    await sincronizarPrazosPush();
  }

  Future<void> excluirProspeccao(String id) async {
    await repo.excluirProspeccao(id);
    notifyListeners();
    unawaited(sincronizarNuvem());
    await sincronizarPrazosPush();
  }

  Future<void> sincronizarPrazosPush() async {
    await PushClient.syncRecords(
      portabilidades: portabilidades
          .map(
            (p) => {
              'id': p.id,
              'data': p.data.toIso8601String(),
              'nome': p.nome,
              'convenio': p.convenio,
              'confirmado': p.confirmado,
            },
          )
          .toList(),
      prospeccoes: prospeccoes
          .map(
            (p) => {
              'id': p.id,
              'dataRetorno': p.dataRetorno?.toIso8601String(),
              'nome': p.nome,
              'produto': p.produto,
              'concluida': p.concluida,
            },
          )
          .toList(),
    );
  }

  Future<void> salvarProduto(Produto p) async {
    await repo.salvarProduto(p);
    notifyListeners();
    unawaited(sincronizarNuvem());
  }

  Future<void> excluirProduto(String nome) async {
    await repo.excluirProduto(nome);
    notifyListeners();
    unawaited(sincronizarNuvem());
  }

  Future<void> salvarConvenio(Convenio c) async {
    await repo.salvarConvenio(c);
    notifyListeners();
    unawaited(sincronizarNuvem());
  }

  Future<void> excluirConvenio(String nome) async {
    await repo.excluirConvenio(nome);
    notifyListeners();
    unawaited(sincronizarNuvem());
  }

  Future<void> salvarMeta(String produto, double valor) async {
    await repo.salvarMeta(produto, valor);
    notifyListeners();
    unawaited(sincronizarNuvem());
  }

  Future<void> salvarMetaMensal(String produto, String mes, double valor) async {
    await repo.salvarMetaMensal(produto, mes, valor);
    notifyListeners();
    unawaited(sincronizarNuvem());
  }

  Future<void> salvarCampanha(Campanha c) async {
    await repo.salvarCampanha(c);
    notifyListeners();
    unawaited(sincronizarNuvem());
  }

  Future<void> excluirCampanha(String id) async {
    await repo.excluirCampanha(id);
    notifyListeners();
    unawaited(sincronizarNuvem());
  }

  Future<void> limparBase(String nome) async {
    await repo.limparBase(nome);
    notifyListeners();
    unawaited(sincronizarNuvem());
  }

  Future<void> importarBackup(String json) async {
    await repo.importarJson(json);
    notifyListeners();
    await sincronizarNuvem();
  }

  Future<void> carregarDaNuvem() async {
    final json = await _cloud.load();
    if (json == null) return;
    final mapa = jsonDecode(json) as Map<String, dynamic>;
    final temDados = (mapa['vendas'] as List? ?? []).isNotEmpty ||
        (mapa['produtos'] as List? ?? []).isNotEmpty ||
        (mapa['portabilidades'] as List? ?? []).isNotEmpty ||
        (mapa['prospeccoes'] as List? ?? []).isNotEmpty ||
        (mapa['metas'] as List? ?? []).isNotEmpty ||
        (mapa['campanhas'] as List? ?? []).isNotEmpty;
    if (temDados) {
      await repo.importarJson(json);
      notifyListeners();
    } else {
      // D1 vazio: preserva e envia a base local deste usuário, sem misturar perfis.
      await sincronizarNuvem();
    }
  }

  Future<void> sincronizarNuvem() async {
    final backup = exportarBackup();
    await repo.salvarBackupInterno(backup);
    await _cloud.save(backup);
  }

  String exportarBackup() => repo.exportarJson();

  Future<void> marcarBackup() async {
    await repo.marcarBackup();
    notifyListeners();
  }

  Future<void> criarBackupInterno() async {
    await repo.salvarBackupInterno(exportarBackup());
    await repo.marcarBackup();
    notifyListeners();
  }

  Future<void> restaurarBackupInterno(String id) async {
    final conteudo = repo.conteudoBackupInterno(id);
    if (conteudo == null) throw StateError('Backup interno não encontrado.');
    await importarBackup(conteudo);
  }

  Future<void> excluirBackupInterno(String id) async {
    await repo.excluirBackupInterno(id);
    notifyListeners();
  }

  // ------------------- Motor de metas -------------------

  /// Soma o realizado de um produto no intervalo [ini, fim] (inclusive).
  double realizadoProduto(String produto, DateTime ini, DateTime fim) {
    final a = DateTime(ini.year, ini.month, ini.day);
    final b = DateTime(fim.year, fim.month, fim.day, 23, 59, 59);
    return vendas
        .where(
          (v) =>
              v.produto.toLowerCase() == produto.toLowerCase() &&
              !v.data.isBefore(a) &&
              !v.data.isAfter(b),
        )
        .fold<double>(0, (s, v) => s + v.valorRealizado);
  }

  int _diasUteisDecorridos(DateTime hoje) {
    final inicio = DateTime(hoje.year, hoje.month, 1);
    final fim = DateTime(hoje.year, hoje.month, hoje.day);
    var total = 0;
    for (var d = inicio; !d.isAfter(fim); d = d.add(const Duration(days: 1))) {
      if (d.weekday >= DateTime.monday && d.weekday <= DateTime.friday) total++;
    }
    return total;
  }

  int _diasUteisNoMes(DateTime hoje) {
    final inicio = DateTime(hoje.year, hoje.month, 1);
    final fim = DateTime(hoje.year, hoje.month + 1, 0);
    var total = 0;
    for (var d = inicio; !d.isAfter(fim); d = d.add(const Duration(days: 1))) {
      if (d.weekday >= DateTime.monday && d.weekday <= DateTime.friday) total++;
    }
    return total;
  }

  /// Calcula o realizado comparando diretamente com a meta individual cadastrada.
  /// A composição da equipe não altera mais o valor da meta.
  List<LinhaMeta> calcularMetas({DateTime? referencia}) {
    final hoje = referencia ?? DateTime.now();
    final inicioMes = DateTime(hoje.year, hoje.month, 1);
    final fimMes = DateTime(hoje.year, hoje.month + 1, 0);
    final diasUteis = diasUteisRestantes(hoje);
    final diasDecorridos = _diasUteisDecorridos(hoje);
    final diasTotais = _diasUteisNoMes(hoje);
    final percentualEsperado = diasTotais > 0 ? diasDecorridos / diasTotais : 0.0;
    final linhas = <LinhaMeta>[];
    for (final p in produtos) {
      final metaIndiv = metaDoProduto(p.nome);
      final metaMes = metaIndiv;
      final realMes = realizadoProduto(p.nome, inicioMes, fimMes);
      final realHoje = realizadoProduto(p.nome, hoje, hoje);
      final perc = metaIndiv > 0 ? realMes / metaIndiv : 0.0;
      final gap = metaIndiv > 0 ? (metaIndiv - realMes) : 0.0;
      final gapPositivo = gap > 0 ? gap : 0.0;
      final metaDia = (metaIndiv > 0 && diasUteis > 0) ? gapPositivo / diasUteis : 0.0;
      final ritmoAtual = diasDecorridos > 0 ? realMes / diasDecorridos : 0.0;
      final percentualProjecao = percentualEsperado > 0 ? perc / percentualEsperado : 0.0;
      final projecaoMes = percentualProjecao * metaIndiv;
      final eficiencia = percentualEsperado > 0 ? perc / percentualEsperado : 0.0;

      linhas.add(
        LinhaMeta(
          produto: p.nome,
          formato: p.formato,
          metaMes: metaMes,
          metaIndividual: metaIndiv,
          realizadoMes: realMes,
          realizadoHoje: realHoje,
          percRealizado: perc,
          gap: gap,
          metaDia: metaDia,
          ritmoAtual: ritmoAtual,
          projecaoMes: projecaoMes,
          percentualEsperado: percentualEsperado,
          percentualProjecao: percentualProjecao,
          eficiencia: eficiencia,
          diasUteisDecorridos: diasDecorridos,
        ),
      );
    }

    // Produtos com meta primeiro, ordenados por menor atingimento.
    linhas.sort((a, b) {
      if (a.semMeta != b.semMeta) return a.semMeta ? 1 : -1;
      return a.percRealizado.compareTo(b.percRealizado);
    });
    return linhas;
  }

  /// Resumo consolidado para o dashboard (apenas produtos com meta).
  ResumoDashboard resumo({DateTime? referencia}) {
    final hoje = referencia ?? DateTime.now();
    final linhas = calcularMetas(referencia: hoje);
    final comMeta = linhas.where((l) => !l.semMeta).toList();

    // Consolidação justa: cada produto contribui no máximo com 100%.
    double somaPerc = 0;
    for (final l in comMeta) {
      somaPerc += l.percRealizado.clamp(0.0, 1.0).toDouble();
    }
    final percGeral = comMeta.isEmpty ? 0.0 : somaPerc / comMeta.length;

    final inicioMes = DateTime(hoje.year, hoje.month, 1);
    final vendasMes = vendas.where(
      (v) =>
          !v.data.isBefore(inicioMes) &&
          v.data.isBefore(DateTime(hoje.year, hoje.month + 1, 1)),
    );
    final vendasHoje = vendas.where((v) => mesmoDia(v.data, hoje)).toList();

    return ResumoDashboard(
      percGeral: percGeral,
      produtosComMeta: comMeta.length,
      produtosAtingidos: comMeta.where((l) => l.percRealizado >= 1).length,
      qtdVendasMes: vendasMes.length,
      qtdVendasHoje: vendasHoje.length,
      diasUteis: diasUteisRestantes(hoje),
      portPendentes: portPendentes.length,
      retornosHoje: prospeccoes
          .where(
            (p) =>
                !p.concluida &&
                p.dataRetorno != null &&
                !p.dataRetorno!.isAfter(
                  DateTime(hoje.year, hoje.month, hoje.day),
                ),
          )
          .length,
      linhas: linhas,
    );
  }

  /// Campanhas ativas com progresso calculado.
  List<ProgressoCampanha> progressoCampanhas() {
    final result = <ProgressoCampanha>[];
    for (final c in campanhas.where((c) => c.ativa)) {
      final itens = <ItemCampanha>[];
      for (final e in c.metasPorProduto.entries) {
        final real = realizadoProduto(e.key, c.dataInicio, c.dataFim);
        itens.add(
          ItemCampanha(
            produto: e.key,
            meta: e.value,
            realizado: real,
            formato: formatoDoProduto(e.key),
          ),
        );
      }
      itens.sort((a, b) => a.perc.compareTo(b.perc));
      result.add(ProgressoCampanha(campanha: c, itens: itens));
    }
    return result;
  }
}

class ResumoDashboard {
  final double percGeral;
  final int produtosComMeta;
  final int produtosAtingidos;
  final int qtdVendasMes;
  final int qtdVendasHoje;
  final int diasUteis;
  final int portPendentes;
  final int retornosHoje;
  final List<LinhaMeta> linhas;

  ResumoDashboard({
    required this.percGeral,
    required this.produtosComMeta,
    required this.produtosAtingidos,
    required this.qtdVendasMes,
    required this.qtdVendasHoje,
    required this.diasUteis,
    required this.portPendentes,
    required this.retornosHoje,
    required this.linhas,
  });
}

class ItemCampanha {
  final String produto;
  final double meta;
  final double realizado;
  final String formato;
  ItemCampanha({
    required this.produto,
    required this.meta,
    required this.realizado,
    required this.formato,
  });
  double get perc => meta > 0 ? realizado / meta : 0;
}

class ProgressoCampanha {
  final Campanha campanha;
  final List<ItemCampanha> itens;
  ProgressoCampanha({required this.campanha, required this.itens});

  double get percGeral {
    if (itens.isEmpty) return 0;
    return itens.fold<double>(0, (s, i) => s + i.perc.clamp(0, 2)) /
        itens.length;
  }
}
