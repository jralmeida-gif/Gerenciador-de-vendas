import 'package:url_launcher/url_launcher.dart';

class WhatsApp {
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
