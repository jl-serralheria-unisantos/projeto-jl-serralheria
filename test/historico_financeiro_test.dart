import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_jl_serralheria/data/models/orcamento_model.dart';
import 'package:projeto_jl_serralheria/data/models/produto_model.dart';
import 'package:projeto_jl_serralheria/data/models/servico_model.dart';
import 'package:projeto_jl_serralheria/features/pdf/services/pdf_service.dart';
import 'package:projeto_jl_serralheria/shared/calculo_orcamento.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final tipo in ['produto', 'serviço']) {
    test('$tipo preserva preço histórico na leitura e na serialização', () {
      for (final bruto in [
        r'R$ 125,50',
        r'R$ 1.234,56',
        0,
        'ilegível',
        '0.125',
        null,
        {'invalido': true},
      ]) {
        final doc = {'valor_base': bruto};
        final double preco;
        final Map<String, dynamic> mapa;
        if (tipo == 'produto') {
          final produto = Produto.fromMap('historico', doc);
          preco = produto.valorBase;
          mapa = produto.toFirestore();
        } else {
          final servico = Servico.fromMap('historico', doc);
          preco = servico.valorBase;
          mapa = servico.toFirestore();
        }
        if (bruto == r'R$ 125,50') {
          expect(preco, 125.5);
        } else if (bruto == r'R$ 1.234,56') {
          expect(preco, 1234.56);
        } else if (bruto == 0) {
          expect(preco, 0);
        } else {
          expect(preco.isFinite, isFalse);
        }
        expect(mapa.containsKey('valor_base'), isTrue);
        expect(mapa['valor_base'], bruto);
      }
      expect(CalculoOrcamento.lerValor(r'R$ 125,50'), isNull);
    });
  }

  test(
    'total binário equivalente permite PDF e preserva o valor bruto',
    () async {
      final doc = Orcamento.fromMap('o', {
        'valor_total': 0.1 + 0.2,
        'itens': [
          {'quantidade': 3, 'valor_unitario': 0.1},
        ],
      });
      expect(doc.requerRevisao, isFalse);
      expect(doc.toFirestore()['valor_total'], 0.1 + 0.2);
      expect(
        (await const PdfService().gerarOrcamento(
          orcamento: doc,
          cliente: null,
        )).isNotEmpty,
        isTrue,
      );
    },
  );

  test(
    'total ilegível preserva a origem e bloqueia PDF, inclusive sem itens',
    () async {
      for (final bruto in [
        'ilegível',
        null,
        double.infinity,
        {'valor': 1},
      ]) {
        final doc = Orcamento.fromMap('o', {'valor_total': bruto});
        expect(doc.valorTotal.isFinite, isFalse);
        expect(
          doc.copyWith(status: 'enviado').toFirestore()['valor_total'],
          bruto,
        );
        await expectLater(
          const PdfService().gerarOrcamento(orcamento: doc, cliente: null),
          throwsStateError,
        );
      }
    },
  );

  test('total ausente exige linhas suficientes para cálculo histórico', () {
    for (final campos in <Map<String, dynamic>>[
      {},
      {
        'itens': [
          {'quantidade': 1},
        ],
      },
    ]) {
      final doc = Orcamento.fromMap('sem-total', campos);
      expect(doc.totalRegistradoCentavos, isNull);
      expect(doc.toFirestore().containsKey('valor_total'), isFalse);
    }
    final doc = Orcamento.fromMap('antigo', {'valor_total': '0,30'});
    expect(
      doc
          .copyWith(observacoes: 'Revisado', valorTotal: 0.3)
          .toFirestore(preservarTotalOriginal: true)['valor_total'],
      '0,30',
    );
  });
}
