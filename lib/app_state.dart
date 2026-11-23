import 'package:flutter/widgets.dart';

import 'data/models/cliente_model.dart';
import 'data/models/orcamento_model.dart';
import 'data/models/produto_model.dart';
import 'data/models/servico_model.dart';
import 'data/repositories/cliente_repository.dart';
import 'data/repositories/orcamento_repository.dart';
import 'data/repositories/produto_repository.dart';
import 'data/repositories/servico_repository.dart';
import 'shared/calculo_orcamento.dart';
import 'shared/formatters.dart';
import 'shared/firebase_failure.dart';

class AppStateScope extends InheritedWidget {
  const AppStateScope({super.key, required this.state, required super.child});

  final AppState state;

  static AppState of(BuildContext context) {
    return read(context);
  }

  static AppState read(BuildContext context) {
    final scope = context.findAncestorWidgetOfExactType<AppStateScope>();
    assert(scope != null, 'AppStateScope nao encontrado na arvore.');
    return scope!.state;
  }

  @override
  bool updateShouldNotify(AppStateScope oldWidget) => state != oldWidget.state;
}

// Item usado apenas na UI durante montagem do orçamento (antes de salvar)
class OrcamentoItem {
  const OrcamentoItem({
    required this.id,
    required this.tipo,
    required this.descricao,
    required this.quantidade,
    required this.unidade,
    required this.valorUnitario,
    this.origemId,
    this.observacoes,
  });

  final int id;
  final String tipo;
  final String? origemId;
  final String descricao;
  final double quantidade;
  final String unidade;
  final double valorUnitario;
  final String? observacoes;

  BigInt get subtotalCentavos =>
      CalculoOrcamento.centavosLinha(quantidade, valorUnitario);
  double get subtotal => quantidade.isFinite && valorUnitario.isFinite
      ? CalculoOrcamento.reais(subtotalCentavos)
      : double.nan;

  OrcamentoItem copyWith({
    int? id,
    String? tipo,
    String? origemId,
    String? descricao,
    double? quantidade,
    String? unidade,
    double? valorUnitario,
    String? observacoes,
  }) {
    return OrcamentoItem(
      id: id ?? this.id,
      tipo: tipo ?? this.tipo,
      origemId: origemId ?? this.origemId,
      descricao: descricao ?? this.descricao,
      quantidade: quantidade ?? this.quantidade,
      unidade: unidade ?? this.unidade,
      valorUnitario: valorUnitario ?? this.valorUnitario,
      observacoes: observacoes ?? this.observacoes,
    );
  }
}

class ResumoPropostas {
  const ResumoPropostas(this.centavos, this.conhecidos, this.invalidos);
  final BigInt centavos;
  final int conhecidos;
  final List<Orcamento> invalidos;

  String get rotulo => invalidos.isEmpty
      ? 'Em propostas'
      : 'Total parcial • a revisar: ${invalidos.length}';
  String get valorFormatado => conhecidos == 0 && invalidos.isNotEmpty
      ? 'Sem valor conhecido'
      : formatarCentavos(centavos);
}

class AppState extends ChangeNotifier {
  AppState({
    ClienteRepository? clientesRepo,
    ProdutoRepository? produtosRepo,
    ServicoRepository? servicosRepo,
    OrcamentoRepository? orcamentosRepo,
  }) : _clienteRepo = clientesRepo ?? ClienteRepository(),
       _produtoRepo = produtosRepo ?? ProdutoRepository(),
       _servicoRepo = servicosRepo ?? ServicoRepository(),
       _orcamentoRepo = orcamentosRepo ?? OrcamentoRepository() {
    carregarTudo();
  }

  final ClienteRepository _clienteRepo;
  final ProdutoRepository _produtoRepo;
  final ServicoRepository _servicoRepo;
  final OrcamentoRepository _orcamentoRepo;

  final List<Cliente> clientes = [];
  final List<Produto> produtos = [];
  final List<Servico> servicos = [];
  final List<Orcamento> orcamentos = [];

  bool carregando = true;
  String? erroCarregamento;
  int _tempItemId = -1;

  List<Orcamento> get orcamentosEmProposta =>
      orcamentos.where((o) => o.status != 'recusado').toList(growable: false);

  ResumoPropostas get resumoEmPropostas {
    var soma = BigInt.zero;
    var conhecidos = 0;
    final invalidos = <Orcamento>[];
    for (final proposta in orcamentosEmProposta) {
      final centavos = proposta.totalRegistradoCentavos;
      if (centavos == null) {
        invalidos.add(proposta);
      } else {
        soma += centavos;
        conhecidos++;
      }
    }
    return ResumoPropostas(soma, conhecidos, List.unmodifiable(invalidos));
  }

  List<Produto> get produtosAtivos =>
      produtos.where((p) => p.ativo).toList(growable: false);

  List<Servico> get servicosAtivos =>
      servicos.where((s) => s.ativo).toList(growable: false);

  List<String> get categoriasProdutos {
    final cats = produtos.map((p) => p.categoria).toSet().toList()..sort();
    return cats;
  }

  Cliente? clientePorId(String id) {
    for (final c in clientes) {
      if (c.id == id) return c;
    }
    return null;
  }

  Produto? produtoPorId(String id) {
    for (final p in produtos) {
      if (p.id == id) return p;
    }
    return null;
  }

  Servico? servicoPorId(String id) {
    for (final s in servicos) {
      if (s.id == id) return s;
    }
    return null;
  }

  Orcamento? orcamentoPorId(String id) {
    for (final o in orcamentos) {
      if (o.id == id) return o;
    }
    return null;
  }

  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    clientes.clear();
    produtos.clear();
    servicos.clear();
    orcamentos.clear();
    erroCarregamento = null;
    super.dispose();
  }

  Future<T> _write<T>(Future<T> Function() operation) async {
    if (_disposed) throw StateError('A sessão foi encerrada.');
    try {
      return await operation();
    } catch (error) {
      throw FirebaseFailure.forOperation(
        error,
        'Não foi possível salvar a alteração.',
      );
    }
  }

  Future<void> carregarTudo() async {
    if (_disposed) return;
    carregando = true;
    erroCarregamento = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _clienteRepo.listarTodos(),
        _produtoRepo.listarTodos(),
        _servicoRepo.listarTodos(),
        _orcamentoRepo.listarTodos(),
      ]);

      if (_disposed) return;
      clientes
        ..clear()
        ..addAll(results[0] as List<Cliente>);
      produtos
        ..clear()
        ..addAll(results[1] as List<Produto>);
      servicos
        ..clear()
        ..addAll(results[2] as List<Servico>);
      orcamentos
        ..clear()
        ..addAll(results[3] as List<Orcamento>);
    } catch (e) {
      if (_disposed) return;
      erroCarregamento = FirebaseFailure.forOperation(
        e,
        'Não foi possível carregar os dados.',
      ).message;
    }

    carregando = false;
    if (hasListeners) notifyListeners();
  }

  // ── Clientes ──────────────────────────────────────────────────────────────

  Future<String> salvarCliente(Cliente cliente) async {
    if (cliente.id == null) {
      final id = await _write(() => _clienteRepo.inserir(cliente));
      if (_disposed) return id;
      final novo = Cliente(
        id: id,
        nome: cliente.nome,
        telefone: cliente.telefone,
        endereco: cliente.endereco,
        observacoes: cliente.observacoes,
      );
      clientes.add(novo);
      clientes.sort((a, b) => a.nome.compareTo(b.nome));
      _notify();
      return id;
    }
    await _write(() => _clienteRepo.atualizar(cliente));
    if (_disposed) return cliente.id!;
    final index = clientes.indexWhere((c) => c.id == cliente.id);
    if (index >= 0) {
      clientes[index] = cliente;
      clientes.sort((a, b) => a.nome.compareTo(b.nome));
      _notify();
    }
    return cliente.id!;
  }

  Future<void> excluirCliente(String id) async {
    final temOrcamentoVinculado = orcamentos.any((o) => o.clienteId == id);
    if (temOrcamentoVinculado) {
      throw StateError(
        'Nao e possivel excluir cliente com orcamento vinculado.',
      );
    }

    await _write(() => _clienteRepo.excluir(id));
    if (_disposed) return;
    clientes.removeWhere((c) => c.id == id);
    _notify();
  }

  // ── Produtos ──────────────────────────────────────────────────────────────

  Future<String> salvarProduto(Produto produto) async {
    if (!CalculoOrcamento.valorValido(produto.valorBase)) {
      throw StateError(CalculoOrcamento.mensagemValor);
    }
    if (produto.id == null) {
      final id = await _write(() => _produtoRepo.inserir(produto));
      if (_disposed) return id;
      final novo = Produto(
        id: id,
        nome: produto.nome,
        codigo: produto.codigo,
        categoria: produto.categoria,
        unidade: produto.unidade,
        valorBase: produto.valorBase,
        observacoes: produto.observacoes,
        ativo: produto.ativo,
      );
      produtos.add(novo);
      _ordenarProdutos();
      _notify();
      return id;
    }
    await _write(() => _produtoRepo.atualizar(produto));
    if (_disposed) return produto.id!;
    final index = produtos.indexWhere((p) => p.id == produto.id);
    if (index >= 0) {
      produtos[index] = produto;
      _ordenarProdutos();
      _notify();
    }
    return produto.id!;
  }

  Future<void> excluirProduto(String id) async {
    await _write(() => _produtoRepo.excluir(id));
    if (_disposed) return;
    produtos.removeWhere((p) => p.id == id);
    _notify();
  }

  // ── Serviços ──────────────────────────────────────────────────────────────

  Future<String> salvarServico(Servico servico) async {
    if (!CalculoOrcamento.valorValido(servico.valorBase)) {
      throw StateError(CalculoOrcamento.mensagemValor);
    }
    if (servico.id == null) {
      final id = await _write(() => _servicoRepo.inserir(servico));
      if (_disposed) return id;
      final novo = Servico(
        id: id,
        nome: servico.nome,
        unidade: servico.unidade,
        valorBase: servico.valorBase,
        observacoes: servico.observacoes,
        ativo: servico.ativo,
      );
      servicos.add(novo);
      servicos.sort((a, b) => a.nome.compareTo(b.nome));
      _notify();
      return id;
    }
    await _write(() => _servicoRepo.atualizar(servico));
    if (_disposed) return servico.id!;
    final index = servicos.indexWhere((s) => s.id == servico.id);
    if (index >= 0) {
      servicos[index] = servico;
      servicos.sort((a, b) => a.nome.compareTo(b.nome));
      _notify();
    }
    return servico.id!;
  }

  Future<void> excluirServico(String id) async {
    await _write(() => _servicoRepo.excluir(id));
    if (_disposed) return;
    servicos.removeWhere((s) => s.id == id);
    _notify();
  }

  // ── Orçamentos ────────────────────────────────────────────────────────────

  Future<String> salvarOrcamento({
    required String clienteId,
    required List<OrcamentoItem> itens,
    required double desconto,
    required int validadeDias,
    required String observacoes,
  }) async {
    _validarDadosOrcamento(
      clienteId: clienteId,
      itens: itens,
      validadeDias: validadeDias,
    );
    final itensEmbutidos = _itensEmbutidos(itens);

    final valorFinal = CalculoOrcamento.total(
      CalculoOrcamento.somar(itensEmbutidos.map((i) => i.subtotalCentavos)),
      desconto,
    );

    final orcamento = Orcamento(
      clienteId: clienteId,
      dataCriacao: DateTime.now(),
      status: 'em_aberto',
      desconto: desconto,
      valorTotal: valorFinal,
      validadeDias: validadeDias,
      observacoes: observacoes,
      itens: itensEmbutidos,
    );

    final id = await _write(() => _orcamentoRepo.inserir(orcamento));
    if (_disposed) return id;
    final novo = Orcamento(
      id: id,
      clienteId: orcamento.clienteId,
      dataCriacao: orcamento.dataCriacao,
      status: orcamento.status,
      desconto: orcamento.desconto,
      valorTotal: orcamento.valorTotal,
      validadeDias: orcamento.validadeDias,
      observacoes: orcamento.observacoes,
      itens: orcamento.itens,
    );
    orcamentos.insert(0, novo);
    _notify();
    return id;
  }

  Future<String> atualizarOrcamento({
    required String id,
    required String clienteId,
    required List<OrcamentoItem> itens,
    required double desconto,
    required int validadeDias,
    required String observacoes,
  }) async {
    _validarDadosOrcamento(
      clienteId: clienteId,
      itens: itens,
      validadeDias: validadeDias,
    );

    final index = orcamentos.indexWhere((o) => o.id == id);
    if (index < 0) {
      throw StateError('Orcamento nao encontrado.');
    }

    final itensEmbutidos = _itensEmbutidos(itens);
    final valorFinal = CalculoOrcamento.total(
      CalculoOrcamento.somar(itensEmbutidos.map((i) => i.subtotalCentavos)),
      desconto,
    );

    final atualizado = orcamentos[index].copyWith(
      clienteId: clienteId,
      desconto: desconto,
      valorTotal: valorFinal,
      validadeDias: validadeDias,
      observacoes: observacoes,
      itens: itensEmbutidos,
    );

    await _write(() => _orcamentoRepo.atualizar(atualizado));
    if (_disposed) return id;
    orcamentos[index] = atualizado;
    _ordenarOrcamentos();
    _notify();
    return id;
  }

  Future<void> atualizarStatusOrcamento(String id, String status) async {
    await _write(
      () => _orcamentoRepo.atualizarStatus(orcamentoId: id, status: status),
    );
    if (_disposed) return;
    final index = orcamentos.indexWhere((o) => o.id == id);
    if (index >= 0) {
      orcamentos[index] = orcamentos[index].copyWith(status: status);
      _notify();
    }
  }

  Future<void> excluirOrcamento(String id) async {
    await _write(() => _orcamentoRepo.excluir(id));
    if (_disposed) return;
    orcamentos.removeWhere((o) => o.id == id);
    _notify();
  }

  int nextTempItemId() => _tempItemId--;

  void _notify() {
    if (!hasListeners) return;
    Future.microtask(() {
      if (hasListeners) notifyListeners();
    });
  }

  void _ordenarProdutos() {
    produtos.sort((a, b) {
      final cat = a.categoria.compareTo(b.categoria);
      if (cat != 0) return cat;
      return (a.codigo ?? a.nome).compareTo(b.codigo ?? b.nome);
    });
  }

  void _ordenarOrcamentos() {
    orcamentos.sort((a, b) => b.dataCriacao.compareTo(a.dataCriacao));
  }

  void _validarDadosOrcamento({
    required String clienteId,
    required List<OrcamentoItem> itens,
    required int validadeDias,
  }) {
    if (clientePorId(clienteId) == null) {
      throw StateError('Cliente selecionado nao encontrado.');
    }
    if (itens.isEmpty) {
      throw StateError('Inclua pelo menos um item no orcamento.');
    }
    if (validadeDias <= 0) {
      throw StateError('Validade deve ser maior que zero.');
    }
    for (final item in itens) {
      if (!CalculoOrcamento.quantidadeValida(item.quantidade)) {
        throw StateError(CalculoOrcamento.mensagemQuantidade);
      }
      if (!CalculoOrcamento.valorValido(item.valorUnitario)) {
        throw StateError(CalculoOrcamento.mensagemValor);
      }
    }
  }

  List<ItemOrcamentoEmbutido> _itensEmbutidos(List<OrcamentoItem> itens) {
    return itens
        .map(
          (item) => ItemOrcamentoEmbutido(
            tipo: item.tipo,
            origemId: item.origemId,
            descricao: item.descricao,
            quantidade: item.quantidade,
            unidade: item.unidade,
            valorUnitario: item.valorUnitario,
            observacoes: item.observacoes,
          ),
        )
        .toList();
  }
}
