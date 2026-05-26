import 'package:flutter/widgets.dart';

import 'data/models/cliente_model.dart';
import 'data/models/orcamento_model.dart';
import 'data/models/produto_model.dart';
import 'data/models/servico_model.dart';
import 'data/repositories/cliente_repository.dart';
import 'data/repositories/orcamento_repository.dart';
import 'data/repositories/produto_repository.dart';
import 'data/repositories/servico_repository.dart';
import 'shared/formatters.dart';

class AppStateScope extends InheritedWidget {
  const AppStateScope({
    super.key,
    required this.state,
    required super.child,
  });

  final AppState state;

  static AppState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppStateScope>();
    assert(scope != null, 'AppStateScope nao encontrado na arvore.');
    return scope!.state;
  }

  static AppState read(BuildContext context) {
    final scope =
        context.findAncestorWidgetOfExactType<AppStateScope>();
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

  double get subtotal => quantidade * valorUnitario;

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

class AppState extends ChangeNotifier {
  AppState() {
    carregarTudo();
  }

  final _clienteRepo = ClienteRepository();
  final _produtoRepo = ProdutoRepository();
  final _servicoRepo = ServicoRepository();
  final _orcamentoRepo = OrcamentoRepository();

  final List<Cliente> clientes = [];
  final List<Produto> produtos = [];
  final List<Servico> servicos = [];
  final List<Orcamento> orcamentos = [];

  bool carregando = true;
  String? erroCarregamento;
  int _tempItemId = -1;

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

  Future<void> carregarTudo() async {
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

      // Popula catálogo e serviços padrão se o banco estiver vazio
      if (produtos.isEmpty) await _seedProdutos();
      if (servicos.isEmpty) await _seedServicos();
      if (clientes.isEmpty) await _seedClientes();
    } catch (e) {
      erroCarregamento = e.toString();
    }

    carregando = false;
    notifyListeners();
  }

  // ── Clientes ──────────────────────────────────────────────────────────────

  Future<String> salvarCliente(Cliente cliente) async {
    if (cliente.id == null) {
      final id = await _clienteRepo.inserir(cliente);
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
    await _clienteRepo.atualizar(cliente);
    final index = clientes.indexWhere((c) => c.id == cliente.id);
    if (index >= 0) {
      clientes[index] = cliente;
      clientes.sort((a, b) => a.nome.compareTo(b.nome));
      _notify();
    }
    return cliente.id!;
  }

  Future<void> excluirCliente(String id) async {
    await _clienteRepo.excluir(id);
    clientes.removeWhere((c) => c.id == id);
    orcamentos.removeWhere((o) => o.clienteId == id);
    _notify();
  }

  // ── Produtos ──────────────────────────────────────────────────────────────

  Future<String> salvarProduto(Produto produto) async {
    if (produto.id == null) {
      final id = await _produtoRepo.inserir(produto);
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
    await _produtoRepo.atualizar(produto);
    final index = produtos.indexWhere((p) => p.id == produto.id);
    if (index >= 0) {
      produtos[index] = produto;
      _ordenarProdutos();
      _notify();
    }
    return produto.id!;
  }

  Future<void> excluirProduto(String id) async {
    await _produtoRepo.excluir(id);
    produtos.removeWhere((p) => p.id == id);
    _notify();
  }

  // ── Serviços ──────────────────────────────────────────────────────────────

  Future<String> salvarServico(Servico servico) async {
    if (servico.id == null) {
      final id = await _servicoRepo.inserir(servico);
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
    await _servicoRepo.atualizar(servico);
    final index = servicos.indexWhere((s) => s.id == servico.id);
    if (index >= 0) {
      servicos[index] = servico;
      servicos.sort((a, b) => a.nome.compareTo(b.nome));
      _notify();
    }
    return servico.id!;
  }

  Future<void> excluirServico(String id) async {
    await _servicoRepo.excluir(id);
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
    final itensEmbutidos = itens
        .map((item) => ItemOrcamentoEmbutido(
              tipo: item.tipo,
              origemId: item.origemId,
              descricao: item.descricao,
              quantidade: item.quantidade,
              unidade: item.unidade,
              valorUnitario: item.valorUnitario,
              observacoes: item.observacoes,
            ))
        .toList();

    final subtotal =
        itensEmbutidos.fold<double>(0, (t, i) => t + i.subtotal);
    final valorFinal = (subtotal - desconto) < 0 ? 0.0 : subtotal - desconto;

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

    final id = await _orcamentoRepo.inserir(orcamento);
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

  Future<void> atualizarStatusOrcamento(String id, String status) async {
    await _orcamentoRepo.atualizarStatus(orcamentoId: id, status: status);
    final index = orcamentos.indexWhere((o) => o.id == id);
    if (index >= 0) {
      orcamentos[index] = orcamentos[index].copyWith(status: status);
      _notify();
    }
  }

  Future<void> excluirOrcamento(String id) async {
    await _orcamentoRepo.excluir(id);
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

  // ── Seeds (dados iniciais) ────────────────────────────────────────────────

  Future<void> _seedClientes() async {
    final lista = [
      Cliente(
        nome: 'Cliente balcão',
        telefone: '(11) 90000-0000',
        endereco: 'Atendimento rápido',
        observacoes: 'Cliente padrão para orçamentos sem cadastro completo.',
      ),
      Cliente(
        nome: 'Condomínio Jardim Metal',
        telefone: '(11) 95555-1212',
        endereco: 'Guarulhos - SP',
        observacoes: 'Costuma solicitar portões, gradis e manutenção.',
      ),
    ];
    for (final c in lista) {
      await salvarCliente(c);
    }
  }

  Future<void> _seedServicos() async {
    final lista = [
      Servico(nome: 'Medição técnica', unidade: 'visita', valorBase: 120, observacoes: 'Levantamento de medidas, vãos e condições de instalação.'),
      Servico(nome: 'Fabricação de porta de alumínio', unidade: 'un', valorBase: 480, observacoes: 'Mão de obra para corte, montagem e acabamento.'),
      Servico(nome: 'Fabricação de portão', unidade: 'm²', valorBase: 620, observacoes: 'Mão de obra para estrutura, reforços e preparação para instalação.'),
      Servico(nome: 'Instalação de box temperado', unidade: 'un', valorBase: 280, observacoes: 'Instalação com conferência de esquadro e vedação.'),
      Servico(nome: 'Instalação de janela Linha Suprema', unidade: 'un', valorBase: 360, observacoes: 'Colocação, regulagem e fixação de esquadrias.'),
      Servico(nome: 'Gradil e corrimão sob medida', unidade: 'm', valorBase: 210, observacoes: 'Mão de obra de montagem para perfis de gradil e corrimão.'),
      Servico(nome: 'Pintura eletrostática', unidade: 'm²', valorBase: 95, observacoes: 'Preparação e acabamento; cor definida no fechamento.'),
      Servico(nome: 'Reparo e solda', unidade: 'hora', valorBase: 140, observacoes: 'Correção, reforço ou ajuste em peças existentes.'),
      Servico(nome: 'Entrega local', unidade: 'serviço', valorBase: 90, observacoes: 'Frete urbano para retirada ou entrega de materiais.'),
    ];
    for (final s in lista) {
      await salvarServico(s);
    }
  }

  Future<void> _seedProdutos() async {
    for (final seed in _catalogSeeds) {
      await salvarProduto(Produto(
        nome: 'Perfil ${seed.codigo}',
        codigo: seed.codigo,
        categoria: seed.categoria,
        unidade: 'metro',
        valorBase: _precoEstimadoPorMetro(seed.pesoKgMetro),
        observacoes:
            'Peso linear: ${formatWeight(seed.pesoKgMetro)}. '
            'Linha/tamanho: ${seed.categoria}. Página ${seed.pagina}. '
            'Fonte: ${seed.fonte}; referência cruzada com Catalogo-Completo.pdf.',
      ));
    }
  }
}

double _precoEstimadoPorMetro(double pesoKgMetro) {
  const valorReferenciaKg = 58.0;
  return ((pesoKgMetro * valorReferenciaKg) * 100).roundToDouble() / 100;
}

class _CatalogSeed {
  const _CatalogSeed(this.codigo, this.categoria, this.pesoKgMetro, this.pagina, this.fonte);
  final String codigo;
  final String categoria;
  final double pesoKgMetro;
  final String pagina;
  final String fonte;
}

const List<_CatalogSeed> _catalogSeeds = [
  _CatalogSeed('E-256', 'Box frisado', 0.233, '36', 'Catalogo-Completo.pdf'),
  _CatalogSeed('I-154', 'Box frisado', 0.233, '36', 'Catalogo-Completo.pdf'),
  _CatalogSeed('U-653', 'Box frisado', 0.180, '36', 'Catalogo-Completo.pdf'),
  _CatalogSeed('U-1002', 'Box frisado', 0.188, '36', 'Catalogo-Completo.pdf'),
  _CatalogSeed('U-655', 'Box frisado', 0.601, '36', 'Catalogo-Completo.pdf'),
  _CatalogSeed('NI-150', 'Box frisado leve', 0.421, '37', 'Catalogo-Completo.pdf'),
  _CatalogSeed('NI-151', 'Box frisado leve', 0.251, '37', 'Catalogo-Completo.pdf'),
  _CatalogSeed('NI-152', 'Box frisado leve', 0.179, '37', 'Catalogo-Completo.pdf'),
  _CatalogSeed('NI-153', 'Box frisado leve', 0.154, '37', 'Catalogo-Completo.pdf'),
  _CatalogSeed('NI-154', 'Box frisado leve', 0.210, '37', 'Catalogo-Completo.pdf'),
  _CatalogSeed('A-022', 'Box liso', 0.318, '38', 'Catalogo-Completo.pdf'),
  _CatalogSeed('E-117', 'Box liso', 0.240, '38', 'Catalogo-Completo.pdf'),
  _CatalogSeed('I-083', 'Box liso', 0.272, '38', 'Catalogo-Completo.pdf'),
  _CatalogSeed('U-397', 'Box liso', 0.580, '38', 'Catalogo-Completo.pdf'),
  _CatalogSeed('U-1056', 'Box liso', 0.183, '39', 'Catalogo-Completo.pdf'),
  _CatalogSeed('Y-107', 'Box liso', 0.175, '39', 'Catalogo-Completo.pdf'),
  _CatalogSeed('U-399', 'Box liso', 0.228, '39', 'Catalogo-Completo.pdf'),
  _CatalogSeed('Y-106', 'Box liso', 0.245, '39', 'Catalogo-Completo.pdf'),
  _CatalogSeed('U-398', 'Box liso', 0.192, '39', 'Catalogo-Completo.pdf'),
  _CatalogSeed('NI-651', 'Box liso leve', 0.211, '40', 'Catalogo-Completo.pdf'),
  _CatalogSeed('NI-649', 'Box liso leve', 0.162, '40', 'Catalogo-Completo.pdf'),
  _CatalogSeed('NI-650', 'Box liso leve', 0.181, '40', 'Catalogo-Completo.pdf'),
  _CatalogSeed('NI-652', 'Box liso leve', 0.198, '40', 'Catalogo-Completo.pdf'),
  _CatalogSeed('NI-653', 'Box liso leve', 0.443, '40', 'Catalogo-Completo.pdf'),
  _CatalogSeed('E-306', 'Box temperado', 0.390, '41', 'Catalogo-Completo (2).pdf'),
  _CatalogSeed('E-512A', 'Box temperado', 0.427, '41', 'Catalogo-Completo (2).pdf'),
  _CatalogSeed('BX-070', 'Box temperado', 0.418, '41', 'Catalogo-Completo (2).pdf'),
  _CatalogSeed('E-1050', 'Box temperado', 0.240, '41', 'Catalogo-Completo (2).pdf'),
  _CatalogSeed('E-1052', 'Box temperado', 0.263, '41', 'Catalogo-Completo (2).pdf'),
  _CatalogSeed('CB-266', 'Box temperado', 0.223, '41', 'Catalogo-Completo (2).pdf'),
  _CatalogSeed('NI-1117', 'Box temperado', 0.520, '43', 'Catalogo-Completo (2).pdf'),
  _CatalogSeed('NI-005', 'Box temperado', 0.230, '43', 'Catalogo-Completo (2).pdf'),
  _CatalogSeed('NI-004', 'Box temperado', 0.176, '43', 'Catalogo-Completo (2).pdf'),
  _CatalogSeed('NI-115', 'Box temperado', 1.180, '43', 'Catalogo-Completo (2).pdf'),
  _CatalogSeed('NI-078', 'Box temperado', 0.575, '43', 'Catalogo-Completo (2).pdf'),
  _CatalogSeed('NI-079', 'Box temperado', 0.250, '43', 'Catalogo-Completo (2).pdf'),
  _CatalogSeed('NI-611', 'Box temperado', 0.281, '47', 'Catalogo-Completo (2).pdf'),
  _CatalogSeed('NI-714', 'Box temperado', 0.322, '47', 'Catalogo-Completo (2).pdf'),
  _CatalogSeed('NI-833', 'Box temperado', 0.503, '47', 'Catalogo-Completo (2).pdf'),
  _CatalogSeed('NI-841', 'Box temperado', 0.350, '47', 'Catalogo-Completo (2).pdf'),
  _CatalogSeed('NI-939', 'Box temperado', 0.579, '47', 'Catalogo-Completo (2).pdf'),
  _CatalogSeed('U-1108', 'Box temperado', 0.300, '49', 'Catalogo-Completo (2).pdf'),
  _CatalogSeed('Y-343', 'Box temperado', 0.314, '49', 'Catalogo-Completo (2).pdf'),
  _CatalogSeed('Y-343A', 'Box temperado', 0.279, '49', 'Catalogo-Completo (2).pdf'),
  _CatalogSeed('NI-1122', 'Box temperado', 0.524, '49', 'Catalogo-Completo (2).pdf'),
  _CatalogSeed('NI-1087', 'Box temperado', 0.468, '49', 'Catalogo-Completo (2).pdf'),
  _CatalogSeed('NI-964', 'Kit pia', 0.172, '53', 'Catalogo-Completo (2).pdf'),
  _CatalogSeed('NI-969', 'Kit pia', 0.176, '53', 'Catalogo-Completo (2).pdf'),
  _CatalogSeed('NI-971', 'Kit pia', 0.344, '53', 'Catalogo-Completo (2).pdf'),
  _CatalogSeed('NI-970', 'Kit pia', 0.305, '53', 'Catalogo-Completo (2).pdf'),
  _CatalogSeed('NI-1315', 'Kit pia', 0.137, '53', 'Catalogo-Completo (2).pdf'),
  _CatalogSeed('NI-559', 'Linha 23', 0.312, '54', 'Catalogo-Completo (2).pdf'),
  _CatalogSeed('NI-624', 'Linha 23', 0.266, '54', 'Catalogo-Completo (2).pdf'),
  _CatalogSeed('NI-625', 'Linha 23', 0.223, '54', 'Catalogo-Completo (2).pdf'),
  _CatalogSeed('NI-626', 'Linha 23', 0.208, '54', 'Catalogo-Completo (2).pdf'),
  _CatalogSeed('NI-627', 'Linha 23', 0.282, '54', 'Catalogo-Completo (2).pdf'),
  _CatalogSeed('NI-628', 'Linha 23', 0.245, '54', 'Catalogo-Completo (2).pdf'),
  _CatalogSeed('NI-629', 'Linha 23', 0.106, '55', 'Catalogo-Completo (2).pdf'),
  _CatalogSeed('NI-630', 'Linha 23', 0.155, '55', 'Catalogo-Completo (2).pdf'),
  _CatalogSeed('NI-757', 'Linha 23', 0.334, '55', 'Catalogo-Completo (2).pdf'),
  _CatalogSeed('NI-759', 'Linha 23', 0.326, '55', 'Catalogo-Completo (2).pdf'),
  _CatalogSeed('NI-760', 'Linha 23', 0.249, '55', 'Catalogo-Completo (2).pdf'),
  _CatalogSeed('A-055', 'Linha 25', 0.434, '56', 'Catalogo-Completo (2).pdf'),
  _CatalogSeed('A-194', 'Linha 25', 0.571, '56', 'Catalogo-Completo (2).pdf'),
  _CatalogSeed('A-202E', 'Linha 25', 0.611, '56', 'Catalogo-Completo (2).pdf'),
  _CatalogSeed('A-048', 'Linha 25', 0.645, '56', 'Catalogo-Completo (2).pdf'),
  _CatalogSeed('A-034', 'Linha 25', 0.499, '56', 'Catalogo-Completo (2).pdf'),
  _CatalogSeed('A-195', 'Linha 25', 0.599, '56', 'Catalogo-Completo (2).pdf'),
  _CatalogSeed('DV-029', 'Linha 25', 0.242, '56', 'Catalogo-Completo (2).pdf'),
  _CatalogSeed('DV-111', 'Linha 25', 0.171, '56', 'Catalogo-Completo (2).pdf'),
  _CatalogSeed('I-105', 'Linha 25', 0.220, '57', 'Catalogo-Completo (2).pdf'),
  _CatalogSeed('E-277', 'Linha 25', 0.462, '57', 'Catalogo-Completo (2).pdf'),
  _CatalogSeed('I-122', 'Linha 25', 0.464, '57', 'Catalogo-Completo (2).pdf'),
  _CatalogSeed('P-140', 'Linha 25', 0.436, '57', 'Catalogo-Completo (2).pdf'),
  _CatalogSeed('P-146', 'Linha 25', 0.466, '57', 'Catalogo-Completo (2).pdf'),
  _CatalogSeed('L-715', 'Linha 25', 0.255, '57', 'Catalogo-Completo (2).pdf'),
  _CatalogSeed('P-167', 'Linha 25', 0.406, '58', 'Catalogo-Completo (2).pdf'),
  _CatalogSeed('P-166', 'Linha 25', 0.406, '58', 'Catalogo-Completo (2).pdf'),
  _CatalogSeed('P-153', 'Linha 25', 0.455, '58', 'Catalogo-Completo (2).pdf'),
  _CatalogSeed('P-152', 'Linha 25', 0.523, '58', 'Catalogo-Completo (2).pdf'),
  _CatalogSeed('P-151', 'Linha 25', 0.496, '58', 'Catalogo-Completo (2).pdf'),
  _CatalogSeed('P-147', 'Linha 25', 0.351, '58', 'Catalogo-Completo (2).pdf'),
  _CatalogSeed('P-227', 'Linha 25', 0.492, '59', 'Catalogo-Completo (2).pdf'),
  _CatalogSeed('P-318', 'Linha 25', 0.553, '59', 'Catalogo-Completo (2).pdf'),
  _CatalogSeed('P-412A', 'Linha 25', 0.439, '59', 'Catalogo-Completo (2).pdf'),
  _CatalogSeed('P-414', 'Linha 25', 0.611, '59', 'Catalogo-Completo (2).pdf'),
  _CatalogSeed('Y-195', 'Linha 25', 0.432, '60', 'Catalogo-Completo (2).pdf'),
  _CatalogSeed('Y-312', 'Linha 25', 0.475, '60', 'Catalogo-Completo (2).pdf'),
  _CatalogSeed('Y-350', 'Linha 25', 0.950, '60', 'Catalogo-Completo (2).pdf'),
  _CatalogSeed('Y-260', 'Linha 25', 0.658, '60', 'Catalogo-Completo (2).pdf'),
  _CatalogSeed('P-319', 'Linha 25', 0.603, '61', 'Catalogo-Completo (2).pdf'),
  _CatalogSeed('Z-114', 'Linha 25', 0.519, '61', 'Catalogo-Completo (2).pdf'),
  _CatalogSeed('A-056', 'Linha 25', 0.373, '61', 'Catalogo-Completo (2).pdf'),
  _CatalogSeed('Z-175', 'Linha 25', 0.533, '61', 'Catalogo-Completo (2).pdf'),
  _CatalogSeed('A-058', 'Linha 25', 0.220, '61', 'Catalogo-Completo (2).pdf'),
  _CatalogSeed('A-144', 'Linha 30', 0.766, '65', 'Catalogo-Completo (2).pdf'),
  _CatalogSeed('P-273', 'Linha 30', 0.563, '65', 'Catalogo-Completo (2).pdf'),
  _CatalogSeed('P-270', 'Linha 30', 0.793, '65', 'Catalogo-Completo (2).pdf'),
  _CatalogSeed('P-264', 'Linha 30', 1.156, '65', 'Catalogo-Completo (2).pdf'),
  _CatalogSeed('Y-140', 'Linha 30', 0.386, '65', 'Catalogo-Completo (2).pdf'),
  _CatalogSeed('Y-181', 'Linha 30', 0.535, '65', 'Catalogo-Completo (2).pdf'),
  _CatalogSeed('U-482', 'Linha 30', 0.114, '65', 'Catalogo-Completo (2).pdf'),
  _CatalogSeed('BG-057', 'Linha 30-90', 1.166, '66', 'Catalogo-Completo (2).pdf'),
  _CatalogSeed('LG-047', 'Linha 30-90', 1.133, '66', 'Catalogo-Completo (2).pdf'),
  _CatalogSeed('LG-068', 'Linha 30-90', 0.383, '66', 'Catalogo-Completo (2).pdf'),
  _CatalogSeed('LG-017', 'Linha 30-90', 1.004, '66', 'Catalogo-Completo (2).pdf'),
  _CatalogSeed('LG-083', 'Linha 30-90', 0.411, '66', 'Catalogo-Completo (2).pdf'),
  _CatalogSeed('SU-001', 'Linha Suprema', 0.713, '77', 'Catalogo-Completo (2).pdf'),
  _CatalogSeed('SU-002', 'Linha Suprema', 0.692, '77', 'Catalogo-Completo (2).pdf'),
  _CatalogSeed('SU-003', 'Linha Suprema', 0.494, '77', 'Catalogo-Completo (2).pdf'),
  _CatalogSeed('SU-004', 'Linha Suprema', 0.502, '77', 'Catalogo-Completo (2).pdf'),
  _CatalogSeed('SU-005', 'Linha Suprema', 0.974, '77', 'Catalogo-Completo (2).pdf'),
  _CatalogSeed('SU-006', 'Linha Suprema', 0.982, '77', 'Catalogo-Completo (2).pdf'),
  _CatalogSeed('SU-010', 'Linha Suprema', 0.960, '78', 'Catalogo-Completo (2).pdf'),
  _CatalogSeed('SU-011', 'Linha Suprema', 0.973, '78', 'Catalogo-Completo (2).pdf'),
  _CatalogSeed('SU-012', 'Linha Suprema', 0.542, '78', 'Catalogo-Completo (2).pdf'),
  _CatalogSeed('SU-013', 'Linha Suprema', 0.707, '79', 'Catalogo-Completo (2).pdf'),
  _CatalogSeed('SU-014', 'Linha Suprema', 0.648, '79', 'Catalogo-Completo (2).pdf'),
  _CatalogSeed('SU-040', 'Linha Suprema', 0.973, '79', 'Catalogo-Completo (2).pdf'),
  _CatalogSeed('SU-047', 'Linha Suprema', 1.041, '79', 'Catalogo-Completo (2).pdf'),
  _CatalogSeed('SU-049', 'Linha Suprema', 1.042, '80', 'Catalogo-Completo (2).pdf'),
  _CatalogSeed('SU-060', 'Linha Suprema', 0.912, '80', 'Catalogo-Completo (2).pdf'),
  _CatalogSeed('SU-061', 'Linha Suprema', 1.062, '80', 'Catalogo-Completo (2).pdf'),
  _CatalogSeed('SU-121', 'Linha Suprema', 1.415, '84', 'Catalogo-Completo (2).pdf'),
  _CatalogSeed('SU-122', 'Linha Suprema', 1.413, '84', 'Catalogo-Completo (2).pdf'),
  _CatalogSeed('SU-123', 'Linha Suprema', 0.969, '84', 'Catalogo-Completo (2).pdf'),
  _CatalogSeed('SU-225', 'Linha Suprema', 1.003, '86', 'Catalogo-Completo (2).pdf'),
  _CatalogSeed('SU-226', 'Linha Suprema', 1.009, '86', 'Catalogo-Completo (2).pdf'),
  _CatalogSeed('SU-227', 'Linha Suprema', 0.504, '86', 'Catalogo-Completo (2).pdf'),
  _CatalogSeed('SU-230', 'Linha Suprema', 0.955, '86', 'Catalogo-Completo (2).pdf'),
  _CatalogSeed('NI-003', 'Portão', 1.351, '92', 'Catalogo-Completo (2).pdf'),
  _CatalogSeed('NI-019', 'Portão', 0.247, '92', 'Catalogo-Completo (2).pdf'),
  _CatalogSeed('NI-116', 'Portão', 0.631, '92', 'Catalogo-Completo (2).pdf'),
  _CatalogSeed('NI-263', 'Portão', 0.767, '93', 'Catalogo-Completo (2).pdf'),
  _CatalogSeed('NI-262', 'Portão', 0.450, '93', 'Catalogo-Completo (2).pdf'),
  _CatalogSeed('NI-310', 'Portão', 0.430, '93', 'Catalogo-Completo (2).pdf'),
  _CatalogSeed('NI-667', 'Portão', 3.104, '94', 'Catalogo-Completo (2).pdf'),
  _CatalogSeed('NI-668', 'Portão', 1.412, '95', 'Catalogo-Completo (2).pdf'),
  _CatalogSeed('NI-047', 'Portão', 0.729, '97', 'Catalogo-Completo (2).pdf'),
  _CatalogSeed('NI-1010', 'Portão', 0.507, '97', 'Catalogo-Completo (2).pdf'),
  _CatalogSeed('TUB-4598', 'Portão', 0.571, '97', 'Catalogo-Completo (2).pdf'),
  _CatalogSeed('NI-983', 'Portão', 0.636, '98', 'Catalogo-Completo (2).pdf'),
  _CatalogSeed('NI-1002', 'Portão', 0.779, '98', 'Catalogo-Completo (2).pdf'),
  _CatalogSeed('NI-009', 'Porta padronizada 90 graus', 0.308, '100', 'Catalogo-Completo (2).pdf'),
  _CatalogSeed('NI-013', 'Porta padronizada 90 graus', 0.349, '100', 'Catalogo-Completo (2).pdf'),
  _CatalogSeed('NI-011', 'Porta padronizada 90 graus', 0.503, '100', 'Catalogo-Completo (2).pdf'),
  _CatalogSeed('NI-012', 'Porta padronizada 90 graus', 0.593, '100', 'Catalogo-Completo (2).pdf'),
  _CatalogSeed('Y-355', 'Lambril', 0.692, '101', 'Catalogo-Completo (2).pdf'),
  _CatalogSeed('Y-335', 'Lambril', 0.717, '101', 'Catalogo-Completo (2).pdf'),
  _CatalogSeed('LB-069', 'Lambril', 0.724, '102', 'Catalogo-Completo (2).pdf'),
  _CatalogSeed('LB-070', 'Lambril', 0.763, '102', 'Catalogo-Completo (2).pdf'),
  _CatalogSeed('LB-072', 'Lambril', 0.656, '103', 'Catalogo-Completo (2).pdf'),
  _CatalogSeed('LB-077', 'Lambril', 0.638, '103', 'Catalogo-Completo (2).pdf'),
  _CatalogSeed('CG-074', 'Gradil e corrimão', 0.239, '105', 'Catalogo-Completo (2).pdf'),
  _CatalogSeed('CG-075', 'Gradil e corrimão', 0.521, '105', 'Catalogo-Completo (2).pdf'),
  _CatalogSeed('CG-077', 'Gradil e corrimão', 0.507, '105', 'Catalogo-Completo (2).pdf'),
  _CatalogSeed('CG-083', 'Gradil e corrimão', 0.723, '105', 'Catalogo-Completo (2).pdf'),
  _CatalogSeed('CG-731', 'Gradil e corrimão', 1.332, '105', 'Catalogo-Completo (2).pdf'),
  _CatalogSeed('NI-409', 'Gradil e corrimão', 1.131, '107', 'Catalogo-Completo (2).pdf'),
  _CatalogSeed('NI-761', 'Gradil e corrimão', 0.229, '107', 'Catalogo-Completo (2).pdf'),
  _CatalogSeed('NI-680', 'Gradil e corrimão', 0.668, '107', 'Catalogo-Completo (2).pdf'),
];
