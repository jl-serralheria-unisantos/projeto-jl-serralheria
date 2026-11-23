import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_jl_serralheria/main.dart';
import 'package:projeto_jl_serralheria/app_state.dart';
import 'package:projeto_jl_serralheria/data/models/cliente_model.dart';
import 'package:projeto_jl_serralheria/data/models/produto_model.dart';
import 'package:projeto_jl_serralheria/data/models/servico_model.dart';
import 'package:projeto_jl_serralheria/data/models/orcamento_model.dart';
import 'package:projeto_jl_serralheria/data/repositories/cliente_repository.dart';
import 'package:projeto_jl_serralheria/data/repositories/produto_repository.dart';
import 'package:projeto_jl_serralheria/data/repositories/servico_repository.dart';
import 'package:projeto_jl_serralheria/data/repositories/orcamento_repository.dart';

class _Clientes extends Fake implements ClienteRepository {
  final leitura = Completer<List<Cliente>>();
  final gravacao = Completer<String>();
  @override
  Future<List<Cliente>> listarTodos() => leitura.future;
  @override
  Future<String> inserir(Cliente cliente) => gravacao.future;
}

class _Produtos extends Fake implements ProdutoRepository {
  @override
  Future<List<Produto>> listarTodos() async => [];
}

class _Servicos extends Fake implements ServicoRepository {
  @override
  Future<List<Servico>> listarTodos() async => [];
}

class _Orcamentos extends Fake implements OrcamentoRepository {
  @override
  Future<List<Orcamento>> listarTodos() async => [];
}

AppState _banco(_Clientes clientes) => AppState(
  clientesRepo: clientes,
  produtosRepo: _Produtos(),
  servicosRepo: _Servicos(),
  orcamentosRepo: _Orcamentos(),
);

void main() {
  testWidgets('inicialização informa falha sem exibir detalhes e repete', (
    tester,
  ) async {
    var attempts = 0;
    await tester.pumpWidget(
      FirebaseStartup(
        initialize: () async {
          if (++attempts == 1) {
            throw FirebaseException(
              plugin: 'core',
              code: 'unavailable',
              message: 'interno',
            );
          }
          return const MaterialApp(home: Text('Inicializado'));
        },
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Conexão indisponível'), findsOneWidget);
    expect(find.textContaining('interno'), findsNothing);
    await tester.tap(find.text('Tentar novamente'));
    await tester.pumpAndSettle();
    expect(find.text('Inicializado'), findsOneWidget);
  });

  test(
    'encerramento limpa listas e ignora leitura e gravação tardias',
    () async {
      final repo = _Clientes();
      final state = _banco(repo);
      final cliente = Cliente(nome: 'Teste local', telefone: '');
      state.clientes.add(cliente);
      final save = state.salvarCliente(cliente);
      state.dispose();
      expect(state.clientes, isEmpty);
      repo.leitura.complete([cliente]);
      repo.gravacao.complete('demo');
      await save;
      await Future<void>.delayed(Duration.zero);
      expect(state.clientes, isEmpty);
      expect(state.erroCarregamento, isNull);
    },
  );

  for (final entry in {
    'unavailable': 'Conexão indisponível',
    'permission-denied': 'Acesso aos dados negado',
  }.entries) {
    test(
      'carregamento trata ${entry.key} com mensagem ao proprietário',
      () async {
        final repo = _Clientes();
        final state = _banco(repo);
        repo.leitura.completeError(
          FirebaseException(
            plugin: 'firestore',
            code: entry.key,
            message: 'interno',
          ),
        );
        await Future<void>.delayed(Duration.zero);
        expect(state.erroCarregamento, contains(entry.value));
        expect(state.erroCarregamento, isNot(contains('interno')));
        state.dispose();
      },
    );
  }
}
