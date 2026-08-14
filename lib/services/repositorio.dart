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
  static const _bCampanhas = 'campanhas';
  static const _bConfig = 'config';

  late Box _vendas;
  late Box _port;
  late Box _prosp;
  late Box _produtos;
  late Box _convenios;
  late Box _metas;
  late Box _campanhas;
  late Box _config;

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
    _campanhas = await Hive.openBox(_name(_bCampanhas));
    _config = await Hive.openBox(_name(_bConfig));
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
    await _campanhas.close();
    await _config.close();
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
      _bCampanhas: await Hive.openBox(_bCampanhas),
      _bConfig: await Hive.openBox(_bConfig),
    };
    final destinos = <String, Box>{
      _bVendas: _vendas,
      _bPort: _port,
      _bProsp: _prosp,
      _bProdutos: _produtos,
      _bConvenios: _convenios,
      _bMetas: _metas,
      _bCampanhas: _campanhas,
    };
    for (final entry in destinos.entries) {
      for (final key in antigos[entry.key]!.keys) {
        await entry.value.put(key, antigos[entry.key]!.get(key));
      }
    }
    final configAntiga = antigos[_bConfig]!;
    for (final key in ['gerentes', 'assistentes', 'nomeUsuario', 'ultimoBackup', 'avatarData', 'idleTimeoutMinutes']) {
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
  String get avatarData => (_config.get('avatarData') ?? '') as String;
  int get idleTimeoutMinutes => (_config.get('idleTimeoutMinutes') ?? 30) as int;
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

  Future<void> salvarAvatarData(String value) => _config.put('avatarData', value);

  Future<void> salvarIdleTimeoutMinutes(int value) =>
      _config.put('idleTimeoutMinutes', value.clamp(15, 120));

  Future<void> marcarBackup() =>
      _config.put('ultimoBackup', DateTime.now().toIso8601String());

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

  // ---------------- Metas ----------------
  List<MetaProduto> get metas => _metas.values
      .map((e) => MetaProduto.fromJson(Map<dynamic, dynamic>.from(e as Map)))
      .toList();

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
        'modeloMeta': 'individual',
        'avatarData': avatarData,
        'idleTimeoutMinutes': idleTimeoutMinutes,
      },
      'produtos': produtos.map((e) => e.toJson()).toList(),
      'convenios': convenios.map((e) => e.toJson()).toList(),
      'metas': metas.map((e) => e.toJson()).toList(),
      'vendas': vendas.map((e) => e.toJson()).toList(),
      'portabilidades': portabilidades.map((e) => e.toJson()).toList(),
      'prospeccoes': prospeccoes.map((e) => e.toJson()).toList(),
      'campanhas': campanhas.map((e) => e.toJson()).toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(mapa);
  }

  /// Importa um backup. Se [substituir] for true, apaga os dados atuais.
  Future<void> importarJson(String conteudo, {bool substituir = true}) async {
    final mapa = jsonDecode(conteudo) as Map<String, dynamic>;
    if (substituir) {
      await _vendas.clear();
      await _port.clear();
      await _prosp.clear();
      await _produtos.clear();
      await _convenios.clear();
      await _metas.clear();
      await _campanhas.clear();
    }
    final cfg = mapa['config'] as Map<String, dynamic>?;
    if (cfg != null) {
      await _config.put('gerentes', cfg['gerentes'] ?? 1);
      await _config.put('assistentes', cfg['assistentes'] ?? 0);
      await _config.put('nomeUsuario', cfg['nomeUsuario'] ?? 'Usuário');
      await _config.put('avatarData', cfg['avatarData'] ?? '');
      await _config.put('idleTimeoutMinutes', cfg['idleTimeoutMinutes'] ?? 30);
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
