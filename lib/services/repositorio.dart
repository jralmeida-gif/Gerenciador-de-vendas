import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

import '../models/models.dart';
import 'dados_iniciais.dart';

/// Camada única de acesso a dados.
/// Hoje grava no dispositivo (Hive). Trocar para nuvem no futuro
/// exige alterar apenas esta classe.
class Repositorio {
  static const _bVendas = 'vendas';
  static const _bPort = 'portabilidades';
  static const _bProsp = 'prospeccoes';
  static const _bProdutos = 'produtos';
  static const _bConvenios = 'convenios';
  static const _bMetas = 'metas';
  static const _bMetasMensais = 'metas_mensais';
  static const _bCampanhas = 'campanhas';
  static const _bClientes = 'clientes';
  static const _bConfig = 'config';
  static const _bBackupsInternos = 'backups_internos';

  late Box _vendas;
  late Box _port;
  late Box _prosp;
  late Box _produtos;
  late Box _convenios;
  late Box _metas;
  late Box _metasMensais;
  late Box _campanhas;
  late Box _clientes;
  late Box _config;
  late Box _backupsInternos;

  String _profile = 'guest';

  String _name(String base) => 'gv_${_profile}_$base';

  Future<void> init({String profile = 'guest'}) async {
    await Hive.initFlutter();
    await _openProfile(profile);
  }

  Future<void> _openProfile(String profile) async {
    _profile = profile.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    _vendas = await Hive.openBox(_name(_bVendas));
    _port = await Hive.openBox(_name(_bPort));
    _prosp = await Hive.openBox(_name(_bProsp));
    _produtos = await Hive.openBox(_name(_bProdutos));
    _convenios = await Hive.openBox(_name(_bConvenios));
    _metas = await Hive.openBox(_name(_bMetas));
    _metasMensais = await Hive.openBox(_name(_bMetasMensais));
    _campanhas = await Hive.openBox(_name(_bCampanhas));
    _clientes = await Hive.openBox(_name(_bClientes));
    _config = await Hive.openBox(_name(_bConfig));
    _backupsInternos = await Hive.openBox(_name(_bBackupsInternos));
    await _semearSePreciso();
    if (_profile != 'guest') await _migrarLegadoSeNecessario();
  }

  Future<void> switchProfile(String profile) async {
    if (_profile == profile) return;
    await _vendas.close();
    await _port.close();
    await _prosp.close();
    await _produtos.close();
    await _convenios.close();
    await _metas.close();
    await _metasMensais.close();
    await _campanhas.close();
    await _clientes.close();
    await _config.close();
    await _backupsInternos.close();
    await _openProfile(profile);
  }

  Future<void> _migrarLegadoSeNecessario() async {
    if (_config.get('migracaoLegadoConcluida') == true) return;
    final antigos = <String, Box>{
      _bVendas: await Hive.openBox(_bVendas),
      _bPort: await Hive.openBox(_bPort),
      _bProsp: await Hive.openBox(_bProsp),
      _bProdutos: await Hive.openBox(_bProdutos),
      _bConvenios: await Hive.openBox(_bConvenios),
      _bMetas: await Hive.openBox(_bMetas),
      _bMetasMensais: await Hive.openBox(_bMetasMensais),
      _bCampanhas: await Hive.openBox(_bCampanhas),
      _bClientes: await Hive.openBox(_bClientes),
      _bConfig: await Hive.openBox(_bConfig),
    };
    final destinos = <String, Box>{
      _bVendas: _vendas,
      _bPort: _port,
      _bProsp: _prosp,
      _bProdutos: _produtos,
      _bConvenios: _convenios,
      _bMetas: _metas,
      _bMetasMensais: _metasMensais,
      _bCampanhas: _campanhas,
      _bClientes: _clientes,
    };
    for (final entry in destinos.entries) {
      for (final key in antigos[entry.key]!.keys) {
        await entry.value.put(key, antigos[entry.key]!.get(key));
      }
    }
    final configAntiga = antigos[_bConfig]!;
    for (final key in ['gerentes', 'assistentes', 'nomeUsuario', 'telefoneUsuario', 'ultimoBackup', 'avatarData', 'avatarScale', 'avatarOffsetX', 'avatarOffsetY', 'idleTimeoutMinutes']) {
      final value = configAntiga.get(key);
      if (value != null) await _config.put(key, value);
    }
    await _config.put('migracaoLegadoConcluida', true);
  }

  Future<void> _semearSePreciso() async {
    if (_config.get('semeado') != true) {
      for (final p in DadosIniciais.produtos) {
        await _produtos.put(p.nome, p.toJson());
      }
      for (final c in DadosIniciais.convenios) {
        await _convenios.put(c.nome, c.toJson());
      }
      await _config.put('semeado', true);
      await _config.put('gerentes', 1);
      await _config.put('assistentes', 0);
      await _config.put('nomeUsuario', 'Usuário');
    }
  }

  // ---------------- Configurações gerais ----------------
  int get gerentes => (_config.get('gerentes') ?? 1) as int;
  int get assistentes => (_config.get('assistentes') ?? 0) as int;
  int get numFuncionarios {
    final n = gerentes + assistentes;
    return n <= 0 ? 1 : n;
  }

  String get nomeUsuario => (_config.get('nomeUsuario') ?? 'Usuário') as String;
  String get telefoneUsuario => (_config.get('telefoneUsuario') ?? '') as String;
  String get recoveryEmail => (_config.get('recoveryEmail') ?? '') as String;
  String get avatarData => (_config.get('avatarData') ?? '') as String;
  int get idleTimeoutMinutes => (_config.get('idleTimeoutMinutes') ?? 30) as int;
  double get avatarScale => ((_config.get('avatarScale') as num?) ?? 1.0).toDouble();
  double get avatarOffsetX => ((_config.get('avatarOffsetX') as num?) ?? 0.0).toDouble();
  double get avatarOffsetY => ((_config.get('avatarOffsetY') as num?) ?? 0.0).toDouble();
  DateTime? get ultimoBackup {
    final s = _config.get('ultimoBackup');
    return s == null ? null : DateTime.tryParse(s as String);
  }

  Future<void> salvarEquipe({
    required int gerentes,
    required int assistentes,
  }) async {
    await _config.put('gerentes', gerentes);
    await _config.put('assistentes', assistentes);
  }

  Future<void> salvarNomeUsuario(String nome) =>
      _config.put('nomeUsuario', nome);
  Future<void> salvarTelefoneUsuario(String telefone) =>
      _config.put('telefoneUsuario', telefone);
  Future<void> salvarRecoveryEmail(String email) =>
      _config.put('recoveryEmail', email.trim().toLowerCase());

  Future<void> salvarAvatarData(String value) => _config.put('avatarData', value);
  Future<void> salvarAvatarEnquadramento({required double escala, required double deslocamentoX, required double deslocamentoY}) async {
    await _config.put('avatarScale', escala.clamp(1.0, 3.0));
    await _config.put('avatarOffsetX', deslocamentoX.clamp(-1.0, 1.0));
    await _config.put('avatarOffsetY', deslocamentoY.clamp(-1.0, 1.0));
  }

  Future<void> salvarIdleTimeoutMinutes(int value) =>
      _config.put('idleTimeoutMinutes', value.clamp(15, 120));

  Future<void> marcarBackup() =>
      _config.put('ultimoBackup', DateTime.now().toIso8601String());

  List<Map<String, dynamic>> get backupsInternos {
    final lista = _backupsInternos.values
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    lista.sort((a, b) => (b['geradoEm'] as String).compareTo(a['geradoEm'] as String));
    return lista;
  }

  Future<void> salvarBackupInterno(String conteudo) async {
    final agora = DateTime.now();
    final id = agora.microsecondsSinceEpoch.toString();
    await _backupsInternos.put(id, {
      'id': id,
      'geradoEm': agora.toIso8601String(),
      'tamanho': utf8.encode(conteudo).length,
      'conteudo': conteudo,
    });
    final todos = backupsInternos;
    var total = todos.fold<int>(0, (s, b) => s + ((b['tamanho'] as num?)?.toInt() ?? 0));
    for (final backup in todos.skip(10).toList()) {
      await _backupsInternos.delete(backup['id']);
    }
    total = backupsInternos.fold<int>(0, (s, b) => s + ((b['tamanho'] as num?)?.toInt() ?? 0));
    for (final backup in backupsInternos.reversed.toList()) {
      if (total <= 50 * 1024 * 1024) break;
      await _backupsInternos.delete(backup['id']);
      total -= ((backup['tamanho'] as num?)?.toInt() ?? 0);
    }
  }

  String? conteudoBackupInterno(String id) {
    final item = _backupsInternos.get(id);
    if (item is! Map) return null;
    return item['conteudo'] as String?;
  }

  Future<void> excluirBackupInterno(String id) => _backupsInternos.delete(id);

  // ---------------- Produtos ----------------
  List<Produto> get produtos {
    final l = _produtos.values
        .map((e) => Produto.fromJson(Map<dynamic, dynamic>.from(e as Map)))
        .toList();
    l.sort((a, b) => a.nome.toLowerCase().compareTo(b.nome.toLowerCase()));
    return l;
  }

  Produto? produtoPorNome(String nome) {
    final e = _produtos.get(nome);
    if (e == null) return null;
    return Produto.fromJson(Map<dynamic, dynamic>.from(e as Map));
  }

  String formatoDoProduto(String nome) =>
      produtoPorNome(nome)?.formato ?? 'Valor';

  Future<void> salvarProduto(Produto p) => _produtos.put(p.nome, p.toJson());
  Future<void> excluirProduto(String nome) => _produtos.delete(nome);

  // ---------------- Convênios ----------------
  List<Convenio> get convenios {
    final l = _convenios.values
        .map((e) => Convenio.fromJson(Map<dynamic, dynamic>.from(e as Map)))
        .toList();
    l.sort((a, b) => a.nome.toLowerCase().compareTo(b.nome.toLowerCase()));
    return l;
  }

  Future<void> salvarConvenio(Convenio c) => _convenios.put(c.nome, c.toJson());
  Future<void> excluirConvenio(String nome) => _convenios.delete(nome);

  // ---------------- Vendas ----------------
  List<Venda> get vendas {
    final l = _vendas.values
        .map((e) => Venda.fromJson(Map<dynamic, dynamic>.from(e as Map)))
        .toList();
    l.sort((a, b) => b.data.compareTo(a.data));
    return l;
  }

  Future<void> salvarVenda(Venda v) => _vendas.put(v.id, v.toJson());
  Future<void> excluirVenda(String id) => _vendas.delete(id);

  // ---------------- Portabilidades ----------------
  List<Portabilidade> get portabilidades {
    final l = _port.values
        .map(
          (e) => Portabilidade.fromJson(Map<dynamic, dynamic>.from(e as Map)),
        )
        .toList();
    l.sort((a, b) => b.data.compareTo(a.data));
    return l;
  }

  List<Portabilidade> get portabilidadesPendentes =>
      portabilidades.where((p) => !p.confirmado).toList();
  List<Portabilidade> get portabilidadesConfirmadas =>
      portabilidades.where((p) => p.confirmado).toList();

  Future<void> salvarPortabilidade(Portabilidade p) =>
      _port.put(p.id, p.toJson());
  Future<void> excluirPortabilidade(String id) => _port.delete(id);

  // ---------------- Prospecções ----------------
  List<Prospeccao> get prospeccoes {
    final l = _prosp.values
        .map((e) => Prospeccao.fromJson(Map<dynamic, dynamic>.from(e as Map)))
        .toList();
    l.sort((a, b) => b.data.compareTo(a.data));
    return l;
  }

  Future<void> salvarProspeccao(Prospeccao p) => _prosp.put(p.id, p.toJson());
  Future<void> excluirProspeccao(String id) => _prosp.delete(id);

  // ---------------- Clientes ----------------
  List<Cliente> get clientes {
    final l = _clientes.values
        .map((e) => Cliente.fromJson(Map<dynamic, dynamic>.from(e as Map)))
        .toList();
    l.sort((a, b) => a.nome.toLowerCase().compareTo(b.nome.toLowerCase()));
    return l;
  }

  Cliente? clientePorCpf(String cpf) {
    final e = _clientes.get(cpf);
    return e == null ? null : Cliente.fromJson(Map<dynamic, dynamic>.from(e as Map));
  }

  Future<void> salvarCliente(Cliente c) => _clientes.put(c.cpf, c.toJson());
  Future<void> excluirCliente(String cpf) => _clientes.delete(cpf);

  // ---------------- Metas ----------------
  List<MetaProduto> get metas => _metas.values
      .map((e) => MetaProduto.fromJson(Map<dynamic, dynamic>.from(e as Map)))
      .toList();

  List<MetaMensal> get metasMensais => _metasMensais.values
      .map((e) => MetaMensal.fromJson(Map<dynamic, dynamic>.from(e as Map)))
      .toList();

  double metaMensalDoProduto(String produto, String mes) {
    final e = _metasMensais.get('${produto}_$mes');
    if (e != null) return MetaMensal.fromJson(Map<dynamic, dynamic>.from(e as Map)).valor;
    return metaDoProduto(produto);
  }

  Future<void> salvarMetaMensal(String produto, String mes, double valor) => _metasMensais.put(
        '${produto}_$mes',
        MetaMensal(produto: produto, mes: mes, valor: valor).toJson(),
      );

  double metaDoProduto(String produto) {
    final e = _metas.get(produto);
    if (e == null) return 0;
    return MetaProduto.fromJson(Map<dynamic, dynamic>.from(e as Map)).metaMes;
  }

  Future<void> salvarMeta(String produto, double valor) => _metas.put(
    produto,
    MetaProduto(produto: produto, metaMes: valor).toJson(),
  );

  // ---------------- Campanhas ----------------
  List<Campanha> get campanhas {
    final l = _campanhas.values
        .map((e) => Campanha.fromJson(Map<dynamic, dynamic>.from(e as Map)))
        .toList();
    l.sort((a, b) => b.dataInicio.compareTo(a.dataInicio));
    return l;
  }

  Future<void> salvarCampanha(Campanha c) => _campanhas.put(c.id, c.toJson());
  Future<void> excluirCampanha(String id) => _campanhas.delete(id);

  // ---------------- Backup ----------------
  String exportarJson() {
    final mapa = {
      'versao': 2,
      'geradoEm': DateTime.now().toIso8601String(),
      'config': {
        'gerentes': gerentes,
        'assistentes': assistentes,
        'nomeUsuario': nomeUsuario,
        'telefoneUsuario': telefoneUsuario,
        'recoveryEmail': recoveryEmail,
        'modeloMeta': 'individual',
        'avatarData': avatarData,
        'avatarScale': avatarScale,
        'avatarOffsetX': avatarOffsetX,
        'avatarOffsetY': avatarOffsetY,
        'idleTimeoutMinutes': idleTimeoutMinutes,
      },
      'produtos': produtos.map((e) => e.toJson()).toList(),
      'convenios': convenios.map((e) => e.toJson()).toList(),
      'metas': metas.map((e) => e.toJson()).toList(),
      'metasMensais': metasMensais.map((e) => e.toJson()).toList(),
      'vendas': vendas.map((e) => e.toJson()).toList(),
      'portabilidades': portabilidades.map((e) => e.toJson()).toList(),
      'prospeccoes': prospeccoes.map((e) => e.toJson()).toList(),
      'campanhas': campanhas.map((e) => e.toJson()).toList(),
      'clientes': clientes.map((e) => e.toJson()).toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(mapa);
  }

  /// Importa um backup. Se [substituir] for true, apaga os dados atuais.
  ///
  /// O limite de inatividade é uma configuração de segurança da sessão local.
  /// Ao carregar dados da nuvem, ele não deve ser trocado por um valor antigo
  /// guardado no backup remoto; na restauração manual, porém, continua sendo
  /// possível restaurá-lo junto com o restante da configuração.
  Future<void> importarJson(
    String conteudo, {
    bool substituir = true,
    bool preservarTimeoutSessao = false,
  }) async {
    final mapa = jsonDecode(conteudo) as Map<String, dynamic>;
    final timeoutSessaoLocal = idleTimeoutMinutes;
    if (substituir) {
      await _vendas.clear();
      await _port.clear();
      await _prosp.clear();
      await _produtos.clear();
      await _convenios.clear();
      await _metas.clear();
      await _metasMensais.clear();
      await _campanhas.clear();
      await _clientes.clear();
    }
    final cfg = mapa['config'] as Map<String, dynamic>?;
    if (cfg != null) {
      await _config.put('gerentes', cfg['gerentes'] ?? 1);
      await _config.put('assistentes', cfg['assistentes'] ?? 0);
      await _config.put('nomeUsuario', cfg['nomeUsuario'] ?? 'Usuário');
      await _config.put('telefoneUsuario', cfg['telefoneUsuario'] ?? '');
      await _config.put('recoveryEmail', cfg['recoveryEmail'] ?? '');
      await _config.put('avatarData', cfg['avatarData'] ?? '');
      await _config.put('avatarScale', cfg['avatarScale'] ?? 1.0);
      await _config.put('avatarOffsetX', cfg['avatarOffsetX'] ?? 0.0);
      await _config.put('avatarOffsetY', cfg['avatarOffsetY'] ?? 0.0);
      if (preservarTimeoutSessao) {
        await _config.put('idleTimeoutMinutes', timeoutSessaoLocal);
      } else {
        await _config.put('idleTimeoutMinutes', cfg['idleTimeoutMinutes'] ?? 30);
      }
    }
    for (final e in (mapa['produtos'] as List? ?? [])) {
      final p = Produto.fromJson(e as Map);
      await _produtos.put(p.nome, p.toJson());
    }
    for (final e in (mapa['convenios'] as List? ?? [])) {
      final c = Convenio.fromJson(e as Map);
      await _convenios.put(c.nome, c.toJson());
    }
    for (final e in (mapa['metas'] as List? ?? [])) {
      final m = MetaProduto.fromJson(e as Map);
      await _metas.put(m.produto, m.toJson());
    }
    for (final e in (mapa['metasMensais'] as List? ?? [])) {
      final m = MetaMensal.fromJson(e as Map);
      await _metasMensais.put(m.chave, m.toJson());
    }
    for (final e in (mapa['vendas'] as List? ?? [])) {
      final v = Venda.fromJson(e as Map);
      await _vendas.put(v.id, v.toJson());
    }
    for (final e in (mapa['portabilidades'] as List? ?? [])) {
      final p = Portabilidade.fromJson(e as Map);
      await _port.put(p.id, p.toJson());
    }
    for (final e in (mapa['prospeccoes'] as List? ?? [])) {
      final p = Prospeccao.fromJson(e as Map);
      await _prosp.put(p.id, p.toJson());
    }
    for (final e in (mapa['campanhas'] as List? ?? [])) {
      final c = Campanha.fromJson(e as Map);
      await _campanhas.put(c.id, c.toJson());
    }
    for (final e in (mapa['clientes'] as List? ?? [])) {
      final c = Cliente.fromJson(e as Map);
      if (c.cpf.isNotEmpty) await _clientes.put(c.cpf, c.toJson());
    }
    await _config.put('semeado', true);
  }

  Future<void> limparBase(String nome) async {
    switch (nome) {
      case 'vendas':
        await _vendas.clear();
        break;
      case 'portabilidades':
        await _port.clear();
        break;
      case 'prospeccoes':
        await _prosp.clear();
        break;
      case 'campanhas':
        await _campanhas.clear();
        break;
      case 'tudo':
        await _vendas.clear();
        await _port.clear();
        await _prosp.clear();
        await _campanhas.clear();
        await _metas.clear();
        await _produtos.clear();
        await _convenios.clear();
        await _config.clear();
        await _semearSePreciso();
        break;
    }
  }
}
