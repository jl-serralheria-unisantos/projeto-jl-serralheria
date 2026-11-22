import 'package:projeto_jl_serralheria/features/pdf/services/pdf_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_jl_serralheria/data/models/orcamento_model.dart';
import 'package:projeto_jl_serralheria/shared/formatters.dart';

ItemOrcamentoEmbutido linha(double qtd, double preco) => ItemOrcamentoEmbutido(
  tipo: 'manual',
  descricao: 'Perfil',
  quantidade: qtd,
  unidade: 'm',
  valorUnitario: preco,
);

void main() {
  test('meio centavo arredonda para cima por linha', () {
    expect(linha(0.125, 1).subtotal, 0.13);
    expect(linha(0.1, 0.15).subtotal, 0.02);
  });
  test('200 linhas de 0,125 m somam 26 reais', () {
    final orcamento = Orcamento(
      clienteId: 'teste',
      dataCriacao: DateTime(2026),
      desconto: 0,
      valorTotal: 26,
      itens: List.generate(200, (_) => linha(0.125, 1)),
    );
    expect(orcamento.subtotal, 26);
    expect(orcamento.valorFinal, 26);
  });
  test('entradas coladas devem ser validadas por inteiro', () {
    for (final text in ['12abc34', '0.125', '1e300', '9' * 400]) {
      expect(parseDecimalOrNull(text), isNull, reason: text);
    }
  });

  test('Firestore e dados entregues ao PDF fecham com as 200 linhas', () async {
    final itens = List.generate(200, (_) => linha(0.125, 1).toMap());
    final dados = {'itens': itens, 'valor_total': 24.75, 'desconto': 1.25};
    final salvo = Orcamento.fromMap('id', dados);
    expect(salvo.requerRevisao, isFalse);
    final tabela = PdfService.linhasDosItens(salvo);
    expect(tabela.length, 200);
    for (final row in tabela) {
      expect(row.sublist(2), ['0,125', 'm', formatMoney(1), formatMoney(0.13)]);
    }
    expect(salvo.subtotal, 26);
    expect(salvo.toFirestore()['valor_total'], 24.75);
    final bytes = await const PdfService().gerarOrcamento(
      orcamento: salvo,
      cliente: null,
    );
    expect(bytes.take(4), [37, 80, 68, 70]); // %PDF
  });

  test(
    'leitura histórica preserva total gravado e exige revisão de divergências',
    () async {
      final itens = [linha(0.125, 1).toMap(), linha(0.125, 1).toMap()];
      final antigo = Orcamento.fromMap('id', {
        'itens': itens,
        'valor_total': '0,25',
      });
      expect(antigo.valorFinal, 0.25);
      expect(
        antigo.copyWith(status: 'enviado').toFirestore()['valor_total'],
        0.25,
      );
      expect(antigo.subtotal, 0.26);
      expect(antigo.requerRevisao, isTrue);
      await expectLater(
        const PdfService().gerarOrcamento(orcamento: antigo, cliente: null),
        throwsStateError,
      );
      expect(Orcamento.fromMap('id', {'itens': itens}).valorFinal, 0.25);
      expect(
        Orcamento.fromMap('id', {'valor_total': '1.234,56'}).valorFinal,
        1234.56,
      );
      for (final desconto in [-1, 2]) {
        final antigo = Orcamento.fromMap('id', {
          'itens': itens,
          'valor_total': 0,
          'desconto': desconto,
        });
        expect(antigo.desconto, desconto);
        expect(antigo.requerRevisao, isTrue);
      }
    },
  );

  test('um preço histórico não finito não vira um item gratuito', () async {
    final antigo = Orcamento.fromMap('id', {
      'valor_total': 0,
      'itens': [
        {'quantidade': 1, 'valor_unitario': double.infinity},
      ],
    });
    expect(antigo.itens.single.valorUnitario, double.infinity);
    expect(antigo.requerRevisao, isTrue);
    expect(antigo.subtotal.isNaN, isTrue);
    await expectLater(
      const PdfService().gerarOrcamento(orcamento: antigo, cliente: null),
      throwsStateError,
    );
  });
}
