import 'package:flutter_test/flutter_test.dart';
import 'package:gestor_vendas/utils/formatters.dart';

void main() {
  group('Formatação brasileira', () {
    test('CPF é formatado corretamente', () {
      expect(Fmt.cpf('11144477735'), '111.444.777-35');
    });

    test('Validação de CPF', () {
      expect(cpfValido('11144477735'), isTrue);
      expect(cpfValido('11111111111'), isFalse);
      expect(cpfValido('123'), isFalse);
    });

    test('Telefone com 11 dígitos', () {
      expect(Fmt.telefone('21987654321'), '(21) 98765-4321');
    });

    test('Contrato no formato 0000000-00', () {
      expect(Fmt.contrato('123456789'), '1234567-89');
    });

    test('Parse de número em formato brasileiro', () {
      expect(Fmt.parseNumero('1.234,56'), 1234.56);
      expect(Fmt.parseNumero('R\$ 890,00'), 890.0);
    });
  });

  group('Cálculo de dias úteis', () {
    test('Retorna sempre pelo menos 1 dia', () {
      expect(diasUteisRestantes(DateTime(2025, 1, 31)), greaterThanOrEqualTo(1));
    });
  });
}
