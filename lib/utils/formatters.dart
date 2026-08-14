import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// Formatação e máscaras no padrão brasileiro.
class Fmt {
  static final NumberFormat _moeda = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$',
    decimalDigits: 2,
  );
  static final NumberFormat _numero = NumberFormat.decimalPattern('pt_BR')
    ..maximumFractionDigits = 0;
  static final NumberFormat _decimal = NumberFormat('#,##0.00', 'pt_BR');
  static final DateFormat _data = DateFormat('dd/MM/yyyy');
  static final DateFormat _dataCurta = DateFormat('dd/MM');
  static final DateFormat _mesAno = DateFormat("MMMM 'de' yyyy", 'pt_BR');

  static String moeda(num v) => _moeda.format(v);
  static String decimal(num v) => _decimal.format(v);
  static String inteiro(num v) => _numero.format(v);
  static String data(DateTime d) => _data.format(d);
  static String dataHora(DateTime d) => DateFormat('dd/MM/yyyy HH:mm', 'pt_BR').format(d);
  static String dataCurta(DateTime d) => _dataCurta.format(d);
  static String mesAno(DateTime d) => _mesAno.format(d);
  static String percentual(double v) =>
      '${(v * 100).toStringAsFixed(1).replaceAll('.', ',')}%';

  /// Exibe o valor conforme o formato do produto (Valor ou Quantidade).
  static String valorPorFormato(num v, String formato) {
    return formato.toLowerCase() == 'quantidade' ? inteiro(v) : moeda(v);
  }

  static String cpf(String digits) {
    final d = somenteDigitos(digits).padRight(11).substring(0, 11).trim();
    if (d.length != 11) return digits;
    return '${d.substring(0, 3)}.${d.substring(3, 6)}.${d.substring(6, 9)}-${d.substring(9)}';
  }

  static String telefone(String digits) {
    final d = somenteDigitos(digits);
    if (d.length == 11) {
      return '(${d.substring(0, 2)}) ${d.substring(2, 7)}-${d.substring(7)}';
    }
    if (d.length == 10) {
      return '(${d.substring(0, 2)}) ${d.substring(2, 6)}-${d.substring(6)}';
    }
    return digits;
  }

  static String contrato(String digits) {
    final d = somenteDigitos(digits);
    if (d.length < 3) return d;
    final corpo = d.substring(0, d.length - 2);
    final dv = d.substring(d.length - 2);
    return '$corpo-$dv';
  }

  static String somenteDigitos(String s) => s.replaceAll(RegExp(r'\D'), '');

  /// Converte texto digitado (1.234,56 ou 1234.56) para double.
  static double parseNumero(String s) {
    if (s.trim().isEmpty) return 0;
    var t = s.replaceAll(RegExp(r'[^\d,.\-]'), '');
    if (t.contains(',')) {
      t = t.replaceAll('.', '').replaceAll(',', '.');
    }
    return double.tryParse(t) ?? 0;
  }
}

/// Máscara genérica baseada em padrão com '#'.
class MaskInputFormatter extends TextInputFormatter {
  final String mask;
  MaskInputFormatter(this.mask);

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = Fmt.somenteDigitos(newValue.text);
    final buffer = StringBuffer();
    var di = 0;
    for (var i = 0; i < mask.length && di < digits.length; i++) {
      if (mask[i] == '#') {
        buffer.write(digits[di]);
        di++;
      } else {
        buffer.write(mask[i]);
      }
    }
    final text = buffer.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

class CpfInputFormatter extends MaskInputFormatter {
  CpfInputFormatter() : super('###.###.###-##');
}

/// Telefone com 10 ou 11 dígitos.
class TelefoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var d = Fmt.somenteDigitos(newValue.text);
    if (d.length > 11) d = d.substring(0, 11);
    final b = StringBuffer();
    for (var i = 0; i < d.length; i++) {
      if (i == 0) b.write('(');
      if (i == 2) b.write(') ');
      if ((d.length == 11 && i == 7) || (d.length == 10 && i == 6)) {
        b.write('-');
      }
      b.write(d[i]);
    }
    final t = b.toString();
    return TextEditingValue(
      text: t,
      selection: TextSelection.collapsed(offset: t.length),
    );
  }
}

/// Digitação de moeda estilo caixa eletrônico (centavos da direita p/ esquerda).
class MoedaInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final d = Fmt.somenteDigitos(newValue.text);
    if (d.isEmpty) {
      return const TextEditingValue(text: '');
    }
    final valor = int.parse(d) / 100.0;
    final t = Fmt.decimal(valor);
    return TextEditingValue(
      text: t,
      selection: TextSelection.collapsed(offset: t.length),
    );
  }
}

/// Data dd/MM/yyyy.
class DataInputFormatter extends MaskInputFormatter {
  DataInputFormatter() : super('##/##/####');
}

/// Valida CPF pelos dígitos verificadores.
bool cpfValido(String entrada) {
  final cpf = Fmt.somenteDigitos(entrada);
  if (cpf.length != 11) return false;
  if (RegExp(r'^(\d)\1{10}$').hasMatch(cpf)) return false;
  int soma = 0;
  for (var i = 0; i < 9; i++) {
    soma += int.parse(cpf[i]) * (10 - i);
  }
  var d1 = (soma * 10) % 11;
  if (d1 == 10) d1 = 0;
  if (d1 != int.parse(cpf[9])) return false;
  soma = 0;
  for (var i = 0; i < 10; i++) {
    soma += int.parse(cpf[i]) * (11 - i);
  }
  var d2 = (soma * 10) % 11;
  if (d2 == 10) d2 = 0;
  return d2 == int.parse(cpf[10]);
}

/// Conta dias úteis (seg-sex) restantes no mês, incluindo hoje.
int diasUteisRestantes(DateTime hoje) {
  final ultimoDia = DateTime(hoje.year, hoje.month + 1, 0).day;
  var count = 0;
  for (var dia = hoje.day; dia <= ultimoDia; dia++) {
    final d = DateTime(hoje.year, hoje.month, dia);
    if (d.weekday != DateTime.saturday && d.weekday != DateTime.sunday) {
      count++;
    }
  }
  return count;
}

bool mesmoDia(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
