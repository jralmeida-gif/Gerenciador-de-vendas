// Modelos de dados espelhando as tabelas da planilha original.
// Persistência em JSON (Hive box de mapas) — sem code generation.

DateTime _dt(dynamic v) =>
    v == null ? DateTime.now() : DateTime.parse(v as String);
DateTime? _dtNull(dynamic v) =>
    v == null ? null : DateTime.tryParse(v as String);
double _d(dynamic v) => v == null ? 0 : (v as num).toDouble();
int _i(dynamic v) => v == null ? 0 : (v as num).toInt();
String _s(dynamic v) => v == null ? '' : v.toString();

/// tblVendas: Data | CPF | Nome | Telefone | Produto | Valor Realizado | Obs
class Venda {
  final String id;
  final DateTime data;
  final String cpf;
  final String nome;
  final String telefone;
  final DateTime? dataNascimento;
  final String produto;
  final double valorRealizado;
  final String observacoes;

  Venda({
    required this.id,
    required this.data,
    required this.cpf,
    required this.nome,
    required this.telefone,
    this.dataNascimento,
    required this.produto,
    required this.valorRealizado,
    this.observacoes = '',
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'data': data.toIso8601String(),
    'cpf': cpf,
    'nome': nome,
    'telefone': telefone,
    'dataNascimento': dataNascimento?.toIso8601String(),
    'produto': produto,
    'valorRealizado': valorRealizado,
    'observacoes': observacoes,
  };

  factory Venda.fromJson(Map<dynamic, dynamic> j) => Venda(
    id: _s(j['id']),
    data: _dt(j['data']),
    cpf: _s(j['cpf']),
    nome: _s(j['nome']),
    telefone: _s(j['telefone']),
    dataNascimento: _dtNull(j['dataNascimento']),
    produto: _s(j['produto']),
    valorRealizado: _d(j['valorRealizado']),
    observacoes: _s(j['observacoes']),
  );

  Venda copyWith({
    DateTime? data,
    String? cpf,
    String? nome,
    String? telefone,
    DateTime? dataNascimento,
    String? produto,
    double? valorRealizado,
    String? observacoes,
  }) => Venda(
    id: id,
    data: data ?? this.data,
    cpf: cpf ?? this.cpf,
    nome: nome ?? this.nome,
    telefone: telefone ?? this.telefone,
    dataNascimento: dataNascimento ?? this.dataNascimento,
    produto: produto ?? this.produto,
    valorRealizado: valorRealizado ?? this.valorRealizado,
    observacoes: observacoes ?? this.observacoes,
  );
}

/// tblPortabilidade: Data | CPF | Nome | Telefone | Convênio | Saldo Devedor |
/// Valor Prestação | Qtd Prest | Confirmado? | Contrato | Obs | Data Confirmação
class Portabilidade {
  final String id;
  final DateTime data;
  final String cpf;
  final String nome;
  final String telefone;
  final DateTime? dataNascimento;
  final String convenio;
  final double saldoDevedor;
  final double valorPrestacao;
  final int qtdPrestacoes;
  final bool confirmado;
  final String numeroContrato;
  final DateTime? dataConfirmacao;
  final String observacoes;

  Portabilidade({
    required this.id,
    required this.data,
    required this.cpf,
    required this.nome,
    required this.telefone,
    this.dataNascimento,
    required this.convenio,
    required this.saldoDevedor,
    required this.valorPrestacao,
    required this.qtdPrestacoes,
    this.confirmado = false,
    this.numeroContrato = '',
    this.dataConfirmacao,
    this.observacoes = '',
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'data': data.toIso8601String(),
    'cpf': cpf,
    'nome': nome,
    'telefone': telefone,
    'dataNascimento': dataNascimento?.toIso8601String(),
    'convenio': convenio,
    'saldoDevedor': saldoDevedor,
    'valorPrestacao': valorPrestacao,
    'qtdPrestacoes': qtdPrestacoes,
    'confirmado': confirmado,
    'numeroContrato': numeroContrato,
    'dataConfirmacao': dataConfirmacao?.toIso8601String(),
    'observacoes': observacoes,
  };

  factory Portabilidade.fromJson(Map<dynamic, dynamic> j) => Portabilidade(
    id: _s(j['id']),
    data: _dt(j['data']),
    cpf: _s(j['cpf']),
    nome: _s(j['nome']),
    telefone: _s(j['telefone']),
    dataNascimento: _dtNull(j['dataNascimento']),
    convenio: _s(j['convenio']),
    saldoDevedor: _d(j['saldoDevedor']),
    valorPrestacao: _d(j['valorPrestacao']),
    qtdPrestacoes: _i(j['qtdPrestacoes']),
    confirmado: j['confirmado'] == true,
    numeroContrato: _s(j['numeroContrato']),
    dataConfirmacao: _dtNull(j['dataConfirmacao']),
    observacoes: _s(j['observacoes']),
  );

  Portabilidade copyWith({
    DateTime? data,
    String? cpf,
    String? nome,
    String? telefone,
    DateTime? dataNascimento,
    String? convenio,
    double? saldoDevedor,
    double? valorPrestacao,
    int? qtdPrestacoes,
    bool? confirmado,
    String? numeroContrato,
    DateTime? dataConfirmacao,
    String? observacoes,
  }) => Portabilidade(
    id: id,
    data: data ?? this.data,
    cpf: cpf ?? this.cpf,
    nome: nome ?? this.nome,
    telefone: telefone ?? this.telefone,
    dataNascimento: dataNascimento ?? this.dataNascimento,
    convenio: convenio ?? this.convenio,
    saldoDevedor: saldoDevedor ?? this.saldoDevedor,
    valorPrestacao: valorPrestacao ?? this.valorPrestacao,
    qtdPrestacoes: qtdPrestacoes ?? this.qtdPrestacoes,
    confirmado: confirmado ?? this.confirmado,
    numeroContrato: numeroContrato ?? this.numeroContrato,
    dataConfirmacao: dataConfirmacao ?? this.dataConfirmacao,
    observacoes: observacoes ?? this.observacoes,
  );
}

/// tblprospec: DATA | CPF | NOME | TELEFONE | PRODUTO | DATARETORNO | OBSERVAÇÃO
class Prospeccao {
  final String id;
  final DateTime data;
  final String cpf;
  final String nome;
  final String telefone;
  final DateTime? dataNascimento;
  final String produto;
  final DateTime? dataRetorno;
  final String observacao;
  final bool concluida;

  Prospeccao({
    required this.id,
    required this.data,
    required this.cpf,
    required this.nome,
    required this.telefone,
    this.dataNascimento,
    required this.produto,
    this.dataRetorno,
    this.observacao = '',
    this.concluida = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'data': data.toIso8601String(),
    'cpf': cpf,
    'nome': nome,
    'telefone': telefone,
    'dataNascimento': dataNascimento?.toIso8601String(),
    'produto': produto,
    'dataRetorno': dataRetorno?.toIso8601String(),
    'observacao': observacao,
    'concluida': concluida,
  };

  factory Prospeccao.fromJson(Map<dynamic, dynamic> j) => Prospeccao(
    id: _s(j['id']),
    data: _dt(j['data']),
    cpf: _s(j['cpf']),
    nome: _s(j['nome']),
    telefone: _s(j['telefone']),
    dataNascimento: _dtNull(j['dataNascimento']),
    produto: _s(j['produto']),
    dataRetorno: _dtNull(j['dataRetorno']),
    observacao: _s(j['observacao']),
    concluida: j['concluida'] == true,
  );

  Prospeccao copyWith({
    DateTime? data,
    String? cpf,
    String? nome,
    String? telefone,
    DateTime? dataNascimento,
    String? produto,
    DateTime? dataRetorno,
    String? observacao,
    bool? concluida,
  }) => Prospeccao(
    id: id,
    data: data ?? this.data,
    cpf: cpf ?? this.cpf,
    nome: nome ?? this.nome,
    telefone: telefone ?? this.telefone,
    dataNascimento: dataNascimento ?? this.dataNascimento,
    produto: produto ?? this.produto,
    dataRetorno: dataRetorno ?? this.dataRetorno,
    observacao: observacao ?? this.observacao,
    concluida: concluida ?? this.concluida,
  );
}

/// tblprod: PRODUTOS | FORMATO (Valor | Quantidade)
class Produto {
  final String nome;
  final String formato;
  Produto({required this.nome, required this.formato});

  bool get ehQuantidade => formato.toLowerCase() == 'quantidade';

  Map<String, dynamic> toJson() => {'nome': nome, 'formato': formato};
  factory Produto.fromJson(Map<dynamic, dynamic> j) =>
      Produto(nome: _s(j['nome']), formato: _s(j['formato']));
}

/// tblconv: Convênio | Cod Conv
class Convenio {
  final String nome;
  final String codigo;
  Convenio({required this.nome, required this.codigo});

  Map<String, dynamic> toJson() => {'nome': nome, 'codigo': codigo};
  factory Convenio.fromJson(Map<dynamic, dynamic> j) =>
      Convenio(nome: _s(j['nome']), codigo: _s(j['codigo']));
}

/// Cadastro consolidado do cliente, compartilhado pelos três processos do usuário.
class Cliente {
  final String cpf;
  final String nome;
  final String telefone;
  final DateTime? dataNascimento;
  final String observacoes;

  const Cliente({
    required this.cpf,
    required this.nome,
    required this.telefone,
    this.dataNascimento,
    this.observacoes = '',
  });

  Map<String, dynamic> toJson() => {
        'cpf': cpf,
        'nome': nome,
        'telefone': telefone,
        'dataNascimento': dataNascimento?.toIso8601String(),
        'observacoes': observacoes,
      };

  factory Cliente.fromJson(Map<dynamic, dynamic> j) => Cliente(
        cpf: _s(j['cpf']),
        nome: _s(j['nome']),
        telefone: _s(j['telefone']),
        dataNascimento: _dtNull(j['dataNascimento']),
        observacoes: _s(j['observacoes']),
      );

  Cliente copyWith({String? nome, String? telefone, DateTime? dataNascimento, String? observacoes}) => Cliente(
        cpf: cpf,
        nome: nome ?? this.nome,
        telefone: telefone ?? this.telefone,
        dataNascimento: dataNascimento ?? this.dataNascimento,
        observacoes: observacoes ?? this.observacoes,
      );
}

/// Meta mensal da agência por produto (coluna C da aba RealizadoxMetas).
class MetaProduto {
  final String produto;
  final double metaMes;
  MetaProduto({required this.produto, required this.metaMes});

  Map<String, dynamic> toJson() => {'produto': produto, 'metaMes': metaMes};
  factory MetaProduto.fromJson(Map<dynamic, dynamic> j) =>
      MetaProduto(produto: _s(j['produto']), metaMes: _d(j['metaMes']));
}

/// Meta individual de um produto para um mês específico.
class MetaMensal {
  final String produto;
  final String mes;
  final double valor;

  const MetaMensal({required this.produto, required this.mes, required this.valor});

  String get chave => '${produto}_$mes';

  Map<String, dynamic> toJson() => {'produto': produto, 'mes': mes, 'valor': valor};

  factory MetaMensal.fromJson(Map<dynamic, dynamic> j) => MetaMensal(
        produto: _s(j['produto']),
        mes: _s(j['mes']),
        valor: _d(j['valor']),
      );
}

/// Tabela1 (Base Campanhas): Campanha | DataInício | DataFim | Produto | Meta
class Campanha {
  final String id;
  final String nome;
  final DateTime dataInicio;
  final DateTime dataFim;
  final Map<String, double> metasPorProduto;

  Campanha({
    required this.id,
    required this.nome,
    required this.dataInicio,
    required this.dataFim,
    required this.metasPorProduto,
  });

  bool get ativa {
    final hoje = DateTime.now();
    final d = DateTime(hoje.year, hoje.month, hoje.day);
    return !d.isBefore(
          DateTime(dataInicio.year, dataInicio.month, dataInicio.day),
        ) &&
        !d.isAfter(DateTime(dataFim.year, dataFim.month, dataFim.day));
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'nome': nome,
    'dataInicio': dataInicio.toIso8601String(),
    'dataFim': dataFim.toIso8601String(),
    'metasPorProduto': metasPorProduto,
  };

  factory Campanha.fromJson(Map<dynamic, dynamic> j) => Campanha(
    id: _s(j['id']),
    nome: _s(j['nome']),
    dataInicio: _dt(j['dataInicio']),
    dataFim: _dt(j['dataFim']),
    metasPorProduto: ((j['metasPorProduto'] ?? {}) as Map).map(
      (k, v) => MapEntry(k.toString(), _d(v)),
    ),
  );
}

/// Linha calculada do painel Metas x Realizado.
class LinhaMeta {
  final String produto;
  final String formato;
  final double metaMes;
  final double metaIndividual;
  final double realizadoMes;
  final double realizadoHoje;
  final double percRealizado;
  final double gap;
  final double metaDia;
  final double ritmoAtual;
  final double projecaoMes;
  final double percentualEsperado;
  final double percentualProjecao;
  final double eficiencia;
  final int diasUteisDecorridos;

  LinhaMeta({
    required this.produto,
    required this.formato,
    required this.metaMes,
    required this.metaIndividual,
    required this.realizadoMes,
    required this.realizadoHoje,
    required this.percRealizado,
    required this.gap,
    required this.metaDia,
    required this.ritmoAtual,
    required this.projecaoMes,
    required this.percentualEsperado,
    required this.percentualProjecao,
    required this.eficiencia,
    required this.diasUteisDecorridos,
  });

  bool get semMeta => metaIndividual <= 0;
}
