import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_jl_serralheria/app_state.dart';
import 'package:projeto_jl_serralheria/data/models/cliente_model.dart';
import 'package:projeto_jl_serralheria/features/clientes/pages/clientes_list_page.dart';

class _Estado extends ChangeNotifier implements AppState {
  @override
  final clientes = <Cliente>[];
  final gravacoes = <Cliente>[];
  Completer<void>? espera;

  @override
  Future<String> salvarCliente(Cliente cliente) async {
    gravacoes.add(cliente);
    await espera?.future;
    const id = 'cliente-teste';
    clientes
      ..clear()
      ..add(
        Cliente(
          id: id,
          nome: cliente.nome,
          telefone: cliente.telefone,
          endereco: cliente.endereco,
          observacoes: cliente.observacoes,
        ),
      );
    notifyListeners();
    return id;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<_Estado> _abrir(WidgetTester tester) async {
  final estado = _Estado();
  await tester.pumpWidget(
    AppStateScope(
      state: estado,
      child: const MaterialApp(home: ClientesListPage()),
    ),
  );
  await tester.tap(find.text('Novo cliente').first);
  await tester.pumpAndSettle();
  return estado;
}

Finder _campo(String rotulo) => find.widgetWithText(TextFormField, rotulo);

Future<void> _preencher(WidgetTester tester, String campo, String valor) async {
  final finder = _campo(campo);
  await tester.ensureVisible(finder);
  await tester.enterText(finder, valor);
}

void main() {
  testWidgets(
    'criação e edição preservam as notas internas e fecham com foco',
    (tester) async {
      final estado = await _abrir(tester);
      estado.espera = Completer<void>();
      await _preencher(tester, 'Nome', 'João');
      await _preencher(tester, 'Telefone', '0000-0000');
      await _preencher(tester, 'Observações internas', 'Uso interno');
      final salvar = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Salvar'),
      );
      final cancelar = tester.widget<TextButton>(
        find.widgetWithText(TextButton, 'Cancelar'),
      );
      salvar.onPressed!();
      salvar.onPressed!();
      cancelar.onPressed!();
      await tester.pumpAndSettle();
      expect(estado.gravacoes, hasLength(1));
      expect(find.text('Salvando...'), findsOneWidget);
      expect(
        tester
            .widget<TextButton>(find.widgetWithText(TextButton, 'Cancelar'))
            .onPressed,
        isNull,
      );
      estado.espera!.complete();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(estado.clientes.single.nome, 'João');
      expect(estado.clientes.single.observacoes, 'Uso interno');

      await tester.tap(find.byTooltip('Ações do cliente'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Editar'));
      await tester.pumpAndSettle();
      expect(find.text('Uso interno'), findsWidgets);
      await _preencher(tester, 'Nome', 'João da Silva');
      await tester.tap(find.text('Salvar'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(estado.gravacoes.last.id, estado.clientes.single.id);
      expect(estado.clientes.single.nome, 'João da Silva');
      expect(estado.clientes.single.observacoes, 'Uso interno');
    },
  );

  testWidgets('gravação pendente permite saída explícita e bloqueia reenvio', (
    tester,
  ) async {
    final estado = await _abrir(tester);
    estado.espera = Completer<void>();
    await _preencher(tester, 'Nome', 'Cliente pendente');
    await _preencher(tester, 'Telefone', '0000');
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.tapAt(const Offset(2, 2));
    await tester.pump(const Duration(seconds: 8));
    await tester.pumpAndSettle();
    expect(find.textContaining('ela poderá concluir depois'), findsOneWidget);
    await tester.tap(find.text('Sair e aguardar'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    await tester.tap(find.text('Novo cliente').first);
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(
      find.textContaining('Ainda existe uma gravação pendente'),
      findsOneWidget,
    );
    expect(estado.gravacoes, hasLength(1));
    estado.espera!.complete();
    await tester.pumpAndSettle();
    expect(estado.clientes.single.nome, 'Cliente pendente');
    expect(tester.takeException(), isNull);
  });

  testWidgets('erro preserva o rascunho e permite nova tentativa', (
    tester,
  ) async {
    final estado = await _abrir(tester);
    estado.espera = Completer<void>();
    await _preencher(tester, 'Nome', 'Rascunho pendente');
    await _preencher(tester, 'Telefone', '0000');
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();
    estado.espera!.completeError(StateError('Falha sintética'));
    await tester.pumpAndSettle();
    expect(find.text('Rascunho pendente'), findsOneWidget);
    expect(find.textContaining('Erro ao salvar cliente'), findsOneWidget);
    estado.espera = null;
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(estado.gravacoes, hasLength(2));
    expect(estado.clientes.single.nome, 'Rascunho pendente');
  });

  testWidgets(
    'desmontar durante a gravação libera controladores e ignora resultado tardio',
    (tester) async {
      final estado = await _abrir(tester);
      estado.espera = Completer<void>();
      await _preencher(tester, 'Nome', 'Cliente');
      await _preencher(tester, 'Telefone', '0000');
      final controller = tester
          .widget<TextFormField>(_campo('Nome'))
          .controller!;
      await tester.tap(find.text('Salvar'));
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      expect(() => controller.addListener(() {}), throwsFlutterError);
      estado.espera!.completeError(StateError('Falha após a desmontagem'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(estado.gravacoes, hasLength(1));
    },
  );

  testWidgets('cancelar durante a edição de um campo descarta o rascunho', (
    tester,
  ) async {
    final estado = await _abrir(tester);
    await _preencher(tester, 'Nome', 'Rascunho');
    await tester.tap(find.text('Cancelar'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(estado.gravacoes, isEmpty);
    await tester.tap(find.text('Novo cliente').first);
    await tester.pumpAndSettle();
    expect(find.text('Rascunho'), findsNothing);
  });
}
