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
  final produtosAtivos = [
    Produto(
      id: 'p',
      nome: 'Perfil do catálogo',
      categoria: 'Teste',
      unidade: 'm',
      valorBase: 1,
      observacoes: 'Nota interna do produto',
    ),
    Produto(
      id: 'p2',
      nome: 'Chapa',
      categoria: 'Teste',
      unidade: 'm²',
      valorBase: 2,
    ),
  ];
  @override
  final servicosAtivos = [
    Servico(
      id: 's',
      nome: 'Instalação',
      unidade: 'un',
      valorBase: 1,
      observacoes: 'Nota interna do serviço',
    ),
  ];
  @override
  Produto produtoPorId(String id) =>
      produtosAtivos.singleWhere((produto) => produto.id == id);
  @override
  Servico servicoPorId(String id) => servicosAtivos.single;
  @override
  int nextTempItemId() => -1;
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
        'observacoes': 'Nota interna do histórico',
      },
    ],
  });
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('reseleção preserva detalhes e troca exige confirmação', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: AppStateScope(
          state: _EstadoDeTeste(),
          child: const OrcamentoFormPage(orcamentoId: 'teste'),
        ),
      ),
    );
    final adicionar = find.text('Adicionar item');
    await tester.ensureVisible(adicionar);
    await tester.tap(adicionar);
    await tester.pumpAndSettle();
    final detalhes = find.widgetWithText(
      TextFormField,
      'Detalhes para o cliente',
    );
    String texto() => tester.widget<TextFormField>(detalhes).controller!.text;
    Future<void> escolher(String atual, String proximo) async {
      await tester.tap(find.text(atual).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text(proximo).last);
      await tester.pumpAndSettle();
    }

    Future<void> decidir(String acao) async {
      expect(find.text('Descartar detalhes do item?'), findsOneWidget);
      await tester.tap(find.text(acao));
      await tester.pumpAndSettle();
    }

    await tester.enterText(detalhes, 'Acabamento aprovado');
    await escolher('Perfil do catálogo • Teste', 'Perfil do catálogo • Teste');
    expect(texto(), 'Acabamento aprovado');
    await escolher('Perfil do catálogo • Teste', 'Chapa • Teste');
    await decidir('Manter item');
    expect(texto(), 'Acabamento aprovado');
    expect(find.text('Perfil do catálogo • Teste'), findsOneWidget);
    await escolher('Perfil do catálogo • Teste', 'Chapa • Teste');
    await decidir('Trocar item');
    expect(texto(), isEmpty);
    expect(find.text('Chapa • Teste'), findsOneWidget);

    await tester.enterText(detalhes, 'Detalhe da chapa');
    await escolher('Produto do catálogo', 'Serviço recorrente');
    await decidir('Manter item');
    expect(texto(), 'Detalhe da chapa');
    expect(find.text('Chapa • Teste'), findsOneWidget);
    await escolher('Produto do catálogo', 'Serviço recorrente');
    await decidir('Trocar item');
    expect(texto(), isEmpty);
    await tester.enterText(detalhes, 'Detalhe da instalação');
    await escolher('Instalação', 'Instalação');
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Quantidade'),
      '2',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Valor unitário'),
      '7,50',
    );
    expect(texto(), 'Detalhe da instalação');
    await tester.tap(find.text('Aplicar'));
    await tester.pumpAndSettle();
    final editar = find.byTooltip('Editar item').last;
    await tester.ensureVisible(editar);
    await tester.tap(editar);
    await tester.pumpAndSettle();
    expect(texto(), 'Detalhe da instalação');
  });

  testWidgets(
    'catálogos e item histórico não preenchem o campo compartilhado',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          home: AppStateScope(
            state: _EstadoDeTeste(),
            child: const OrcamentoFormPage(orcamentoId: 'teste'),
          ),
        ),
      );
      final detalhes = find.widgetWithText(
        TextFormField,
        'Detalhes para o cliente',
      );
      final editar = find.byTooltip('Editar item');
      await tester.ensureVisible(editar);
      await tester.tap(editar);
      await tester.pumpAndSettle();
      expect(tester.widget<TextFormField>(detalhes).controller!.text, isEmpty);
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Cancelar'),
        ),
      );
      await tester.pumpAndSettle();

      final adicionar = find.text('Adicionar item');
      await tester.ensureVisible(adicionar);
      await tester.tap(adicionar);
      await tester.pumpAndSettle();
      expect(find.text('Perfil do catálogo'), findsOneWidget);
      expect(tester.widget<TextFormField>(detalhes).controller!.text, isEmpty);
      await tester.tap(find.text('Produto do catálogo'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Serviço recorrente').last);
      await tester.pumpAndSettle();
      expect(tester.widget<TextFormField>(detalhes).controller!.text, isEmpty);
      await tester.enterText(detalhes, 'Acabamento aprovado');
      await tester.tap(find.text('Aplicar'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(editar.last);
      await tester.tap(editar.last);
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextFormField>(detalhes).controller!.text,
        'Acabamento aprovado',
      );
      expect(tester.takeException(), isNull);
    },
  );

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
