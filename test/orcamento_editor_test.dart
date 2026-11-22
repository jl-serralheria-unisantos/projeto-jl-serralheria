import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_jl_serralheria/app_state.dart';
import 'package:projeto_jl_serralheria/data/models/cliente_model.dart';
import 'package:projeto_jl_serralheria/data/models/orcamento_model.dart';
import 'package:projeto_jl_serralheria/data/models/produto_model.dart';
import 'package:projeto_jl_serralheria/data/models/servico_model.dart';
import 'package:projeto_jl_serralheria/features/orcamentos/pages/orcamento_form_page.dart';

class _EstadoDeTeste extends ChangeNotifier implements AppState {
  @override
  final clientes = [Cliente(id: 'c', nome: 'Cliente', telefone: '')];
  @override
  final produtosAtivos = <Produto>[];
  @override
  final servicosAtivos = <Servico>[];
  @override
  Orcamento orcamentoPorId(String id) => Orcamento.fromMap(id, {
    'cliente_id': 'c',
    'valor_total': 0.13,
    'itens': [
      {
        'tipo': 'manual',
        'descricao': 'Perfil',
        'quantidade': 0.125,
        'valor_unitario': 1,
        'unidade': 'm',
      },
    ],
  });
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets(
    'editar somente a descrição preserva 0,125 m e rejeita desconto excessivo',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final estado = _EstadoDeTeste();
      await tester.pumpWidget(
        MaterialApp(
          home: AppStateScope(
            state: estado,
            child: const OrcamentoFormPage(orcamentoId: 'teste'),
          ),
        ),
      );
      final editar = find.byTooltip('Editar item');
      await tester.ensureVisible(editar);
      await tester.tap(editar);
      await tester.pumpAndSettle();
      expect(find.text('0,125'), findsOneWidget);
      final descricao = find.widgetWithText(TextFormField, 'Descrição do item');
      await tester.enterText(descricao, 'Perfil atualizado');
      await tester.tap(find.text('Aplicar'));
      await tester.pumpAndSettle();
      expect(find.text('Perfil atualizado'), findsOneWidget);
      expect(find.textContaining('0,125 m ×'), findsOneWidget);
      final desconto = find.widgetWithText(TextFormField, 'Desconto');
      await tester.ensureVisible(desconto);
      await tester.enterText(desconto, '0,14');
      final salvar = find.widgetWithText(FilledButton, 'Salvar alterações');
      await tester.ensureVisible(salvar);
      await tester.tap(salvar);
      await tester.pumpAndSettle();
      expect(
        find.text('O desconto não pode superar o subtotal.'),
        findsOneWidget,
      );
    },
  );
}
