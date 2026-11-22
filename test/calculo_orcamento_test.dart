import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_jl_serralheria/shared/calculo_orcamento.dart';

void main() {
  test('total de um item e descontos válido, integral e excessivo', () {
    final subtotal = CalculoOrcamento.centavosLinha(1.25, 10);
    expect(CalculoOrcamento.total(subtotal, 0), 12.5);
    expect(CalculoOrcamento.total(subtotal, 0.25), 12.25);
    expect(CalculoOrcamento.total(subtotal, 12.5), 0);
    for (final invalido in [-0.01, 12.51, double.infinity, double.nan]) {
      expect(
        () => CalculoOrcamento.total(subtotal, invalido),
        throwsStateError,
      );
    }
  });

  test('precisão e limites são verificados antes de gravar', () {
    for (final texto in [
      '0',
      '-1',
      '1.000',
      '1,1234567',
      '1,2,3',
      '1 2',
      '1000000000',
    ]) {
      expect(CalculoOrcamento.lerQuantidade(texto), isNull);
    }
    expect(CalculoOrcamento.lerQuantidade(' 0,000001 '), 0.000001);
    expect(CalculoOrcamento.lerValor('0,123'), isNull);
    expect(CalculoOrcamento.lerValor('999999999,99'), 999999999.99);
    expect(CalculoOrcamento.valorValido(double.nan), isFalse);
    expect(CalculoOrcamento.quantidadeValida(double.infinity), isFalse);
    expect(
      () => CalculoOrcamento.total(
        CalculoOrcamento.centavosLinha(999999999, 999999999),
        0,
      ),
      throwsStateError,
    );
  });

  test('agrupamento brasileiro exige separador decimal explícito', () {
    expect(CalculoOrcamento.lerValor('1.234,56'), 1234.56);
    expect(CalculoOrcamento.lerValor('12.34,56'), isNull);
  });
}
