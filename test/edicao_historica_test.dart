import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_jl_serralheria/app_state.dart';
import 'package:projeto_jl_serralheria/data/models/cliente_model.dart';
import 'package:projeto_jl_serralheria/data/models/orcamento_model.dart';
import 'package:projeto_jl_serralheria/data/models/produto_model.dart';
import 'package:projeto_jl_serralheria/data/models/servico_model.dart';
import 'package:projeto_jl_serralheria/data/repositories/cliente_repository.dart';
import 'package:projeto_jl_serralheria/data/repositories/orcamento_repository.dart';
import 'package:projeto_jl_serralheria/data/repositories/produto_repository.dart';
import 'package:projeto_jl_serralheria/data/repositories/servico_repository.dart';
import 'package:projeto_jl_serralheria/features/orcamentos/pages/orcamento_form_page.dart';
import 'package:projeto_jl_serralheria/features/produtos/pages/produtos_list_page.dart';
import 'package:projeto_jl_serralheria/features/servicos/pages/servicos_list_page.dart';
import 'package:projeto_jl_serralheria/shared/formatters.dart';

class _Clientes extends Fake implements ClienteRepository {
  @override
  Future<List<Cliente>> listarTodos() async => [
    Cliente(id: 'c', nome: 'Cliente', telefone: ''),
  ];
}

class _Produtos extends Fake implements ProdutoRepository {
  _Produtos(this.doc);
  final Map<String, dynamic> doc;
  Map<String, dynamic>? gravado;
  @override
  Future<List<Produto>> listarTodos() async => [
    Produto.fromMap('cadastro', doc),
  ];
  @override
  Future<void> atualizar(Produto produto) async {
    gravado = produto.toFirestore();
  }
}

class _Servicos extends Fake implements ServicoRepository {
  _Servicos(this.doc);
  final Map<String, dynamic> doc;
  Map<String, dynamic>? gravado;
  @override
  Future<List<Servico>> listarTodos() async => [
    Servico.fromMap('cadastro', doc),
  ];
  @override
  Future<void> atualizar(Servico servico) async {
    gravado = servico.toFirestore();
  }
}

class _Orcamentos extends Fake implements OrcamentoRepository {
  _Orcamentos(this.registros);
  final Map<String, Map<String, dynamic>> registros;
  int gravacoes = 0;
  @override
  Future<List<Orcamento>> listarTodos() async =>
      registros.entries.map((e) => Orcamento.fromMap(e.key, e.value)).toList();
  @override
  Future<void> atualizar(Orcamento orcamento) async {
    registros[orcamento.id!]!.addAll(
      orcamento.toFirestore(preservarTotalOriginal: true),
    );
    gravacoes++;
  }
}

class _Banco {
  _Banco({Object? preco = r'R$ 125,50', Object? total = 100})
    : produtos = _Produtos({'nome': 'Perfil', 'valor_base': preco}),
      servicos = _Servicos({'nome': 'Perfil', 'valor_base': preco}),
      orcamentos = _Orcamentos({
        'orc': {
          'cliente_id': 'c',
          'valor_total': total,
          'status': 'enviado',
          'data_criacao': Timestamp.fromDate(DateTime(2024)),
          'itens': [
            {'quantidade': 1, 'valor_unitario': 100, 'descricao': 'Original'},
          ],
        },
      });
  final _Produtos produtos;
  final _Servicos servicos;
  final _Orcamentos orcamentos;
  late final estado = AppState(
    clientesRepo: _Clientes(),
    produtosRepo: produtos,
    servicosRepo: servicos,
    orcamentosRepo: orcamentos,
  );

  Future<void> abrir(WidgetTester t, Widget pagina) async {
    await t.binding.setSurfaceSize(const Size(1200, 1000));
    addTearDown(() => t.binding.setSurfaceSize(null));
    await t.pumpWidget(
      AppStateScope(
        state: estado,
        child: MaterialApp(home: pagina),
      ),
    );
    await t.pumpAndSettle();
  }
}

Future<void> tocar(WidgetTester t, Finder alvo) async {
  await t.ensureVisible(alvo);
  await t.tap(alvo);
  await t.pumpAndSettle();
}

void main() {
  for (final produto in [true, false]) {
    final tipo = produto ? 'produto' : 'serviço';
    for (final valido in [true, false]) {
      testWidgets(
        'edição de nome de $tipo com preço histórico ${valido ? "válido" : "ilegível"}',
        (t) async {
          final banco = _Banco(preco: valido ? r'R$ 125,50' : 'desconhecido');
          await banco.abrir(
            t,
            produto ? const ProdutosListPage() : const ServicosListPage(),
          );
          await tocar(t, find.byTooltip('Ações do $tipo'));
          await tocar(t, find.text('Editar'));
          await t.enterText(
            find.widgetWithText(TextFormField, 'Nome'),
            'Novo nome',
          );
          if (!valido) {
            expect(
              find.text('Revise o preço histórico antes de salvar.'),
              findsOneWidget,
            );
            await tocar(t, find.text('Salvar'));
            expect(
              produto ? banco.produtos.gravado : banco.servicos.gravado,
              isNull,
            );
            await t.enterText(
              find.widgetWithText(TextFormField, 'Valor base'),
              '45,25',
            );
          }
          await tocar(t, find.text('Salvar'));
          final salvo = produto
              ? banco.produtos.gravado
              : banco.servicos.gravado;
          expect(salvo?['nome'], 'Novo nome');
          expect(salvo?['valor_base'], valido ? 125.5 : 45.25);
        },
      );
    }
  }
  for (final confirmar in [false, true]) {
    testWidgets(
      'alterar 100 para 120 e ${confirmar ? "confirmar" : "cancelar"}',
      (t) async {
        final banco = _Banco();
        await banco.abrir(t, const OrcamentoFormPage(orcamentoId: 'orc'));
        await tocar(t, find.byTooltip('Editar item'));
        await t.enterText(
          find.widgetWithText(TextFormField, 'Valor unitário'),
          '120,00',
        );
        await tocar(t, find.text('Aplicar'));
        await tocar(t, find.text('Salvar alterações'));
        expect(
          find.textContaining(
            'Total registrado: ${formatMoney(100)}. Total após salvar: ${formatMoney(120)}.',
          ),
          findsOneWidget,
        );
        expect(banco.orcamentos.gravacoes, 0);
        await tocar(t, find.text(confirmar ? 'Confirmar' : 'Voltar'));
        expect(banco.orcamentos.gravacoes, confirmar ? 1 : 0);
        final doc = banco.orcamentos.registros['orc']!;
        expect(doc['valor_total'], confirmar ? 120 : 100);
        expect(doc['itens'][0]['valor_unitario'], confirmar ? 120 : 100);
        expect(doc['status'], 'enviado');
        expect(doc['data_criacao'], Timestamp.fromDate(DateTime(2024)));
      },
    );
  }
  testWidgets(
    'alterar somente observação conserva total bruto equivalente sem diálogo',
    (t) async {
      const bruto = 100.00000000000001;
      final banco = _Banco(total: bruto);
      await banco.abrir(t, const OrcamentoFormPage(orcamentoId: 'orc'));
      await t.enterText(
        find.widgetWithText(TextFormField, 'Observações gerais'),
        'Revisado',
      );
      await tocar(t, find.text('Salvar alterações'));
      expect(find.text('Atualizar orçamento histórico?'), findsNothing);
      expect(banco.orcamentos.gravacoes, 1);
      expect(banco.orcamentos.registros['orc']!['valor_total'], bruto);
      expect(banco.orcamentos.registros['orc']!['observacoes'], 'Revisado');
    },
  );
  testWidgets('orçamento já divergente continua exigindo confirmação', (
    t,
  ) async {
    final banco = _Banco(total: 99.99);
    await banco.abrir(t, const OrcamentoFormPage(orcamentoId: 'orc'));
    await tocar(t, find.text('Salvar alterações'));
    expect(find.text('Atualizar orçamento histórico?'), findsOneWidget);
    await tocar(t, find.text('Voltar'));
    expect(banco.orcamentos.gravacoes, 0);
    expect(banco.orcamentos.registros['orc']!['valor_total'], 99.99);
  });

  test(
    'indicador soma centavos conhecidos e identifica pendentes por orçamento',
    () async {
      final banco = _Banco();
      banco.orcamentos.registros.addAll({
        'centavos': {'valor_total': 0.1 + 0.2},
        'zero': {'valor_total': 0},
        'texto': {'valor_total': '???'},
        'infinito': {'valor_total': double.infinity},
        'recusado': {'status': 'recusado', 'valor_total': '???'},
      });
      final estado = banco.estado;
      await Future<void>.delayed(Duration.zero);
      final resumo = estado.resumoEmPropostas;
      expect(resumo.centavos, BigInt.from(10030));
      expect(resumo.conhecidos, 3);
      expect(resumo.invalidos.map((o) => o.id), ['texto', 'infinito']);
      expect(resumo.rotulo, contains('parcial'));
      estado.orcamentos.removeWhere((o) => o.totalRegistradoCentavos != null);
      expect(estado.resumoEmPropostas.valorFormatado, 'Sem valor conhecido');
    },
  );
}
