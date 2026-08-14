import 'package:url_launcher/url_launcher.dart';

class WhatsApp {
  static String saudacao(String nome, {String? complemento}) {
    final agora = DateTime.now();
    final periodo = agora.hour < 12
        ? 'bom dia'
        : agora.hour < 18
            ? 'boa tarde'
            : 'boa noite';
    final primeiroNome = nome.trim().split(RegExp(r'\s+')).first;
    final detalhe = complemento == null || complemento.trim().isEmpty ? '' : ' ${complemento.trim()}';
    return 'Oi $primeiroNome, $periodo! Tudo bem?$detalhe';
  }

  static Future<bool> abrir({required String telefone, String? mensagem}) async {
    var digits = telefone.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('0')) digits = digits.substring(1);
    if (digits.length == 10 || digits.length == 11) digits = '55$digits';
    if (digits.length < 12) return false;

    final params = <String, String>{};
    if (mensagem != null && mensagem.isNotEmpty) params['text'] = mensagem;
    final uri = Uri.https('wa.me', digits, params);
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
