import '../models/models.dart';

/// Produtos e convênios extraídos da planilha original (aba
/// "Bases de configuração", tabelas tblprod e tblconv).
class DadosIniciais {
  static List<Produto> get produtos => [
    Produto(nome: 'Limite Cartão Ultra', formato: 'Valor'),
    Produto(nome: 'Limite Cartão Novo', formato: 'Valor'),
    Produto(nome: 'Tag Caixa', formato: 'Quantidade'),
    Produto(nome: 'CDB', formato: 'Valor'),
    Produto(nome: 'LCI', formato: 'Valor'),
    Produto(nome: 'Fundos', formato: 'Valor'),
    Produto(nome: 'Previdência', formato: 'Valor'),
    Produto(nome: 'Vida PM', formato: 'Valor'),
    Produto(nome: 'Vida PU', formato: 'Valor'),
    Produto(nome: 'Residencial', formato: 'Valor'),
    Produto(nome: 'CAP PM', formato: 'Valor'),
    Produto(nome: 'Consórcio', formato: 'Valor'),
    Produto(nome: 'Consignado', formato: 'Valor'),
    Produto(nome: 'Rapidex', formato: 'Valor'),
    Produto(nome: 'Expansão de Base', formato: 'Quantidade'),
    Produto(nome: 'CROT', formato: 'Valor'),
    Produto(nome: 'Prestamista', formato: 'Valor'),
    Produto(nome: 'Previdência PM', formato: 'Valor'),
    Produto(nome: 'Antecipação FGTS', formato: 'Valor'),
    Produto(nome: 'Poupança', formato: 'Valor'),
    Produto(nome: 'CDC', formato: 'Valor'),
    Produto(nome: 'Recuperação de Prejuízo', formato: 'Valor'),
  ];

  static List<Convenio> get convenios => [
    Convenio(nome: 'INSS', codigo: '11605'),
    Convenio(nome: 'Prefeitura Magé', codigo: '11698'),
    Convenio(nome: 'Ministério da Saúde', codigo: '17513'),
  ];

  static const List<String> formatos = ['Valor', 'Quantidade'];

  static const List<String> tiposRelatorio = [
    'Venda do dia',
    'Venda por Cliente/Período',
    'Venda por Produto/Período',
    'Prospecção/Período',
    'Portabilidades Efetivadas/Período',
    'Listagem de Contato de Clientes/Produto',
  ];
}
