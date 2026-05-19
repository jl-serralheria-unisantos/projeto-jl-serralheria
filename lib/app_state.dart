import 'package:flutter/widgets.dart';

import 'data/models/cliente_model.dart';
import 'data/models/produto_model.dart';
import 'data/models/servico_model.dart';
import 'shared/formatters.dart';

class AppStateScope extends InheritedNotifier<AppState> {
  const AppStateScope({
    super.key,
    required AppState state,
    required super.child,
  }) : super(notifier: state);

  static AppState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppStateScope>();
    assert(scope != null, 'AppStateScope nao encontrado na arvore.');
    return scope!.notifier!;
  }

  static AppState read(BuildContext context) {
    final element = context
        .getElementForInheritedWidgetOfExactType<AppStateScope>();
    final scope = element?.widget as AppStateScope?;
    assert(scope != null, 'AppStateScope nao encontrado na arvore.');
    return scope!.notifier!;
  }
}

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
  final int? origemId;
  final String descricao;
  final double quantidade;
  final String unidade;
  final double valorUnitario;
  final String? observacoes;

  double get subtotal => quantidade * valorUnitario;

  OrcamentoItem copyWith({
    int? id,
    String? tipo,
    int? origemId,
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

class OrcamentoRegistro {
  const OrcamentoRegistro({
    required this.id,
    required this.clienteId,
    required this.dataCriacao,
    required this.status,
    required this.desconto,
    required this.validadeDias,
    required this.observacoes,
    required this.itens,
  });

  final int id;
  final int clienteId;
  final DateTime dataCriacao;
  final String status;
  final double desconto;
  final int validadeDias;
  final String observacoes;
  final List<OrcamentoItem> itens;

  double get subtotal {
    return itens.fold<double>(0, (total, item) => total + item.subtotal);
  }

  double get valorFinal {
    final total = subtotal - desconto;
    return total < 0 ? 0 : total;
  }

  OrcamentoRegistro copyWith({
    String? status,
    double? desconto,
    int? validadeDias,
    String? observacoes,
    List<OrcamentoItem>? itens,
  }) {
    return OrcamentoRegistro(
      id: id,
      clienteId: clienteId,
      dataCriacao: dataCriacao,
      status: status ?? this.status,
      desconto: desconto ?? this.desconto,
      validadeDias: validadeDias ?? this.validadeDias,
      observacoes: observacoes ?? this.observacoes,
      itens: itens ?? this.itens,
    );
  }
}

class CatalogSeed {
  const CatalogSeed(
    this.codigo,
    this.categoria,
    this.pesoKgMetro,
    this.pagina,
    this.fonte,
  );

  final String codigo;
  final String categoria;
  final double pesoKgMetro;
  final String pagina;
  final String fonte;
}

class AppState extends ChangeNotifier {
  AppState() {
    _seed();
  }

  final List<Cliente> clientes = [];
  final List<Produto> produtos = [];
  final List<Servico> servicos = [];
  final List<OrcamentoRegistro> orcamentos = [];

  int _nextClienteId = 1;
  int _nextProdutoId = 1;
  int _nextServicoId = 1;
  int _nextOrcamentoId = 1;
  int _nextOrcamentoItemId = 1;

  List<Produto> get produtosAtivos {
    return produtos.where((produto) => produto.ativo).toList(growable: false);
  }

  List<Servico> get servicosAtivos {
    return servicos.where((servico) => servico.ativo).toList(growable: false);
  }

  List<String> get categoriasProdutos {
    final categorias =
        produtos.map((produto) => produto.categoria).toSet().toList()..sort();
    return categorias;
  }

  Cliente? clientePorId(int id) {
    for (final cliente in clientes) {
      if (cliente.id == id) return cliente;
    }
    return null;
  }

  Produto? produtoPorId(int id) {
    for (final produto in produtos) {
      if (produto.id == id) return produto;
    }
    return null;
  }

  Servico? servicoPorId(int id) {
    for (final servico in servicos) {
      if (servico.id == id) return servico;
    }
    return null;
  }

  OrcamentoRegistro? orcamentoPorId(int id) {
    for (final orcamento in orcamentos) {
      if (orcamento.id == id) return orcamento;
    }
    return null;
  }

  int salvarCliente(Cliente cliente) {
    if (cliente.id == null) {
      final novo = Cliente(
        id: _nextClienteId++,
        nome: cliente.nome,
        telefone: cliente.telefone,
        endereco: cliente.endereco,
        observacoes: cliente.observacoes,
      );
      clientes.add(novo);
      clientes.sort((a, b) => a.nome.compareTo(b.nome));
      notifyListeners();
      return novo.id!;
    }

    final index = clientes.indexWhere((item) => item.id == cliente.id);
    if (index >= 0) {
      clientes[index] = cliente;
      clientes.sort((a, b) => a.nome.compareTo(b.nome));
      notifyListeners();
    }
    return cliente.id!;
  }

  void excluirCliente(int id) {
    clientes.removeWhere((cliente) => cliente.id == id);
    orcamentos.removeWhere((orcamento) => orcamento.clienteId == id);
    notifyListeners();
  }

  int salvarProduto(Produto produto) {
    if (produto.id == null) {
      final novo = Produto(
        id: _nextProdutoId++,
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
      notifyListeners();
      return novo.id!;
    }

    final index = produtos.indexWhere((item) => item.id == produto.id);
    if (index >= 0) {
      produtos[index] = produto;
      _ordenarProdutos();
      notifyListeners();
    }
    return produto.id!;
  }

  void excluirProduto(int id) {
    produtos.removeWhere((produto) => produto.id == id);
    notifyListeners();
  }

  int salvarServico(Servico servico) {
    if (servico.id == null) {
      final novo = Servico(
        id: _nextServicoId++,
        nome: servico.nome,
        unidade: servico.unidade,
        valorBase: servico.valorBase,
        observacoes: servico.observacoes,
        ativo: servico.ativo,
      );
      servicos.add(novo);
      servicos.sort((a, b) => a.nome.compareTo(b.nome));
      notifyListeners();
      return novo.id!;
    }

    final index = servicos.indexWhere((item) => item.id == servico.id);
    if (index >= 0) {
      servicos[index] = servico;
      servicos.sort((a, b) => a.nome.compareTo(b.nome));
      notifyListeners();
    }
    return servico.id!;
  }

  void excluirServico(int id) {
    servicos.removeWhere((servico) => servico.id == id);
    notifyListeners();
  }

  int salvarOrcamento({
    required int clienteId,
    required List<OrcamentoItem> itens,
    required double desconto,
    required int validadeDias,
    required String observacoes,
  }) {
    final itensComId = itens
        .map((item) => item.copyWith(id: _nextOrcamentoItemId++))
        .toList(growable: false);
    final novo = OrcamentoRegistro(
      id: _nextOrcamentoId++,
      clienteId: clienteId,
      dataCriacao: DateTime.now(),
      status: 'em_aberto',
      desconto: desconto,
      validadeDias: validadeDias,
      observacoes: observacoes,
      itens: itensComId,
    );

    orcamentos.insert(0, novo);
    notifyListeners();
    return novo.id;
  }

  void atualizarStatusOrcamento(int id, String status) {
    final index = orcamentos.indexWhere((orcamento) => orcamento.id == id);
    if (index >= 0) {
      orcamentos[index] = orcamentos[index].copyWith(status: status);
      notifyListeners();
    }
  }

  void excluirOrcamento(int id) {
    orcamentos.removeWhere((orcamento) => orcamento.id == id);
    notifyListeners();
  }

  void _seed() {
    clientes.addAll([
      Cliente(
        id: _nextClienteId++,
        nome: 'Cliente balcão',
        telefone: '(11) 90000-0000',
        endereco: 'Atendimento rápido',
        observacoes: 'Cliente padrão para orçamentos sem cadastro completo.',
      ),
      Cliente(
        id: _nextClienteId++,
        nome: 'Condomínio Jardim Metal',
        telefone: '(11) 95555-1212',
        endereco: 'Guarulhos - SP',
        observacoes: 'Costuma solicitar portões, gradis e manutenção.',
      ),
    ]);

    for (final seed in _catalogSeeds) {
      produtos.add(_produtoDoCatalogo(seed));
    }
    _ordenarProdutos();

    servicos.addAll([
      _servico(
        'Medição técnica',
        'visita',
        120,
        'Levantamento de medidas, vãos e condições de instalação.',
      ),
      _servico(
        'Fabricação de porta de alumínio',
        'un',
        480,
        'Mão de obra para corte, montagem e acabamento.',
      ),
      _servico(
        'Fabricação de portão',
        'm²',
        620,
        'Mão de obra para estrutura, reforços e preparação para instalação.',
      ),
      _servico(
        'Instalação de box temperado',
        'un',
        280,
        'Instalação com conferência de esquadro e vedação.',
      ),
      _servico(
        'Instalação de janela Linha Suprema',
        'un',
        360,
        'Colocação, regulagem e fixação de esquadrias.',
      ),
      _servico(
        'Gradil e corrimão sob medida',
        'm',
        210,
        'Mão de obra de montagem para perfis de gradil e corrimão.',
      ),
      _servico(
        'Pintura eletrostática',
        'm²',
        95,
        'Preparação e acabamento; cor definida no fechamento.',
      ),
      _servico(
        'Reparo e solda',
        'hora',
        140,
        'Correção, reforço ou ajuste em peças existentes.',
      ),
      _servico(
        'Entrega local',
        'serviço',
        90,
        'Frete urbano para retirada ou entrega de materiais.',
      ),
    ]);
  }

  Produto _produtoDoCatalogo(CatalogSeed seed) {
    return Produto(
      id: _nextProdutoId++,
      nome: 'Perfil ${seed.codigo}',
      codigo: seed.codigo,
      categoria: seed.categoria,
      unidade: 'metro',
      valorBase: _precoEstimadoPorMetro(seed.pesoKgMetro),
      observacoes:
          'Peso linear: ${formatWeight(seed.pesoKgMetro)}. '
          'Linha/tamanho: ${seed.categoria}. Página ${seed.pagina}. '
          'Fonte: ${seed.fonte}; referência cruzada com Catalogo-Completo.pdf.',
    );
  }

  Servico _servico(
    String nome,
    String unidade,
    double valor,
    String observacoes,
  ) {
    return Servico(
      id: _nextServicoId++,
      nome: nome,
      unidade: unidade,
      valorBase: valor,
      observacoes: observacoes,
    );
  }

  void _ordenarProdutos() {
    produtos.sort((a, b) {
      final categoria = a.categoria.compareTo(b.categoria);
      if (categoria != 0) return categoria;
      return (a.codigo ?? a.nome).compareTo(b.codigo ?? b.nome);
    });
  }
}

double _precoEstimadoPorMetro(double pesoKgMetro) {
  const valorReferenciaKg = 58.0;
  return ((pesoKgMetro * valorReferenciaKg) * 100).roundToDouble() / 100;
}

const List<CatalogSeed> _catalogSeeds = [
  CatalogSeed('E-256', 'Box frisado', 0.233, '36', 'Catalogo-Completo.pdf'),
  CatalogSeed('I-154', 'Box frisado', 0.233, '36', 'Catalogo-Completo.pdf'),
  CatalogSeed('U-653', 'Box frisado', 0.180, '36', 'Catalogo-Completo.pdf'),
  CatalogSeed('U-1002', 'Box frisado', 0.188, '36', 'Catalogo-Completo.pdf'),
  CatalogSeed('U-655', 'Box frisado', 0.601, '36', 'Catalogo-Completo.pdf'),
  CatalogSeed(
    'NI-150',
    'Box frisado leve',
    0.421,
    '37',
    'Catalogo-Completo.pdf',
  ),
  CatalogSeed(
    'NI-151',
    'Box frisado leve',
    0.251,
    '37',
    'Catalogo-Completo.pdf',
  ),
  CatalogSeed(
    'NI-152',
    'Box frisado leve',
    0.179,
    '37',
    'Catalogo-Completo.pdf',
  ),
  CatalogSeed(
    'NI-153',
    'Box frisado leve',
    0.154,
    '37',
    'Catalogo-Completo.pdf',
  ),
  CatalogSeed(
    'NI-154',
    'Box frisado leve',
    0.210,
    '37',
    'Catalogo-Completo.pdf',
  ),
  CatalogSeed('A-022', 'Box liso', 0.318, '38', 'Catalogo-Completo.pdf'),
  CatalogSeed('E-117', 'Box liso', 0.240, '38', 'Catalogo-Completo.pdf'),
  CatalogSeed('I-083', 'Box liso', 0.272, '38', 'Catalogo-Completo.pdf'),
  CatalogSeed('U-397', 'Box liso', 0.580, '38', 'Catalogo-Completo.pdf'),
  CatalogSeed('U-1056', 'Box liso', 0.183, '39', 'Catalogo-Completo.pdf'),
  CatalogSeed('Y-107', 'Box liso', 0.175, '39', 'Catalogo-Completo.pdf'),
  CatalogSeed('U-399', 'Box liso', 0.228, '39', 'Catalogo-Completo.pdf'),
  CatalogSeed('Y-106', 'Box liso', 0.245, '39', 'Catalogo-Completo.pdf'),
  CatalogSeed('U-398', 'Box liso', 0.192, '39', 'Catalogo-Completo.pdf'),
  CatalogSeed('NI-651', 'Box liso leve', 0.211, '40', 'Catalogo-Completo.pdf'),
  CatalogSeed('NI-649', 'Box liso leve', 0.162, '40', 'Catalogo-Completo.pdf'),
  CatalogSeed('NI-650', 'Box liso leve', 0.181, '40', 'Catalogo-Completo.pdf'),
  CatalogSeed('NI-652', 'Box liso leve', 0.198, '40', 'Catalogo-Completo.pdf'),
  CatalogSeed('NI-653', 'Box liso leve', 0.443, '40', 'Catalogo-Completo.pdf'),
  CatalogSeed(
    'E-306',
    'Box temperado',
    0.390,
    '41',
    'Catalogo-Completo (2).pdf',
  ),
  CatalogSeed(
    'E-512A',
    'Box temperado',
    0.427,
    '41',
    'Catalogo-Completo (2).pdf',
  ),
  CatalogSeed(
    'BX-070',
    'Box temperado',
    0.418,
    '41',
    'Catalogo-Completo (2).pdf',
  ),
  CatalogSeed(
    'E-1050',
    'Box temperado',
    0.240,
    '41',
    'Catalogo-Completo (2).pdf',
  ),
  CatalogSeed(
    'E-1052',
    'Box temperado',
    0.263,
    '41',
    'Catalogo-Completo (2).pdf',
  ),
  CatalogSeed(
    'CB-266',
    'Box temperado',
    0.223,
    '41',
    'Catalogo-Completo (2).pdf',
  ),
  CatalogSeed(
    'E-1050E',
    'Box temperado',
    0.238,
    '41',
    'Catalogo-Completo (2).pdf',
  ),
  CatalogSeed(
    'NI-1117',
    'Box temperado',
    0.520,
    '43',
    'Catalogo-Completo (2).pdf',
  ),
  CatalogSeed(
    'NI-005',
    'Box temperado',
    0.230,
    '43',
    'Catalogo-Completo (2).pdf',
  ),
  CatalogSeed(
    'NI-004',
    'Box temperado',
    0.176,
    '43',
    'Catalogo-Completo (2).pdf',
  ),
  CatalogSeed(
    'NI-115',
    'Box temperado',
    1.180,
    '43',
    'Catalogo-Completo (2).pdf',
  ),
  CatalogSeed(
    'NI-078',
    'Box temperado',
    0.575,
    '43',
    'Catalogo-Completo (2).pdf',
  ),
  CatalogSeed(
    'NI-079',
    'Box temperado',
    0.250,
    '43',
    'Catalogo-Completo (2).pdf',
  ),
  CatalogSeed(
    'NI-611',
    'Box temperado',
    0.281,
    '47',
    'Catalogo-Completo (2).pdf',
  ),
  CatalogSeed(
    'NI-714',
    'Box temperado',
    0.322,
    '47',
    'Catalogo-Completo (2).pdf',
  ),
  CatalogSeed(
    'NI-833',
    'Box temperado',
    0.503,
    '47',
    'Catalogo-Completo (2).pdf',
  ),
  CatalogSeed(
    'NI-841',
    'Box temperado',
    0.350,
    '47',
    'Catalogo-Completo (2).pdf',
  ),
  CatalogSeed(
    'NI-939',
    'Box temperado',
    0.579,
    '47',
    'Catalogo-Completo (2).pdf',
  ),
  CatalogSeed(
    'U-1108',
    'Box temperado',
    0.300,
    '49',
    'Catalogo-Completo (2).pdf',
  ),
  CatalogSeed(
    'Y-343',
    'Box temperado',
    0.314,
    '49',
    'Catalogo-Completo (2).pdf',
  ),
  CatalogSeed(
    'Y-343A',
    'Box temperado',
    0.279,
    '49',
    'Catalogo-Completo (2).pdf',
  ),
  CatalogSeed(
    'NI-1122',
    'Box temperado',
    0.524,
    '49',
    'Catalogo-Completo (2).pdf',
  ),
  CatalogSeed(
    'NI-1087',
    'Box temperado',
    0.468,
    '49',
    'Catalogo-Completo (2).pdf',
  ),
  CatalogSeed('NI-964', 'Kit pia', 0.172, '53', 'Catalogo-Completo (2).pdf'),
  CatalogSeed('NI-969', 'Kit pia', 0.176, '53', 'Catalogo-Completo (2).pdf'),
  CatalogSeed('NI-971', 'Kit pia', 0.344, '53', 'Catalogo-Completo (2).pdf'),
  CatalogSeed('NI-970', 'Kit pia', 0.305, '53', 'Catalogo-Completo (2).pdf'),
  CatalogSeed('NI-1315', 'Kit pia', 0.137, '53', 'Catalogo-Completo (2).pdf'),
  CatalogSeed('NI-559', 'Linha 23', 0.312, '54', 'Catalogo-Completo (2).pdf'),
  CatalogSeed('NI-624', 'Linha 23', 0.266, '54', 'Catalogo-Completo (2).pdf'),
  CatalogSeed('NI-625', 'Linha 23', 0.223, '54', 'Catalogo-Completo (2).pdf'),
  CatalogSeed('NI-626', 'Linha 23', 0.208, '54', 'Catalogo-Completo (2).pdf'),
  CatalogSeed('NI-627', 'Linha 23', 0.282, '54', 'Catalogo-Completo (2).pdf'),
  CatalogSeed('NI-628', 'Linha 23', 0.245, '54', 'Catalogo-Completo (2).pdf'),
  CatalogSeed('NI-629', 'Linha 23', 0.106, '55', 'Catalogo-Completo (2).pdf'),
  CatalogSeed('NI-630', 'Linha 23', 0.155, '55', 'Catalogo-Completo (2).pdf'),
  CatalogSeed('NI-757', 'Linha 23', 0.334, '55', 'Catalogo-Completo (2).pdf'),
  CatalogSeed('NI-759', 'Linha 23', 0.326, '55', 'Catalogo-Completo (2).pdf'),
  CatalogSeed('NI-760', 'Linha 23', 0.249, '55', 'Catalogo-Completo (2).pdf'),
  CatalogSeed('A-055', 'Linha 25', 0.434, '56', 'Catalogo-Completo (2).pdf'),
  CatalogSeed('A-194', 'Linha 25', 0.571, '56', 'Catalogo-Completo (2).pdf'),
  CatalogSeed('A-202E', 'Linha 25', 0.611, '56', 'Catalogo-Completo (2).pdf'),
  CatalogSeed('A-048', 'Linha 25', 0.645, '56', 'Catalogo-Completo (2).pdf'),
  CatalogSeed('A-034', 'Linha 25', 0.499, '56', 'Catalogo-Completo (2).pdf'),
  CatalogSeed('A-195', 'Linha 25', 0.599, '56', 'Catalogo-Completo (2).pdf'),
  CatalogSeed('DV-029', 'Linha 25', 0.242, '56', 'Catalogo-Completo (2).pdf'),
  CatalogSeed('DV-111', 'Linha 25', 0.171, '56', 'Catalogo-Completo (2).pdf'),
  CatalogSeed('I-105', 'Linha 25', 0.220, '57', 'Catalogo-Completo (2).pdf'),
  CatalogSeed('E-277', 'Linha 25', 0.462, '57', 'Catalogo-Completo (2).pdf'),
  CatalogSeed('I-122', 'Linha 25', 0.464, '57', 'Catalogo-Completo (2).pdf'),
  CatalogSeed('P-140', 'Linha 25', 0.436, '57', 'Catalogo-Completo (2).pdf'),
  CatalogSeed('P-146', 'Linha 25', 0.466, '57', 'Catalogo-Completo (2).pdf'),
  CatalogSeed('L-715', 'Linha 25', 0.255, '57', 'Catalogo-Completo (2).pdf'),
  CatalogSeed('P-167', 'Linha 25', 0.406, '58', 'Catalogo-Completo (2).pdf'),
  CatalogSeed('P-166', 'Linha 25', 0.406, '58', 'Catalogo-Completo (2).pdf'),
  CatalogSeed('P-153', 'Linha 25', 0.455, '58', 'Catalogo-Completo (2).pdf'),
  CatalogSeed('P-152', 'Linha 25', 0.523, '58', 'Catalogo-Completo (2).pdf'),
  CatalogSeed('P-151', 'Linha 25', 0.496, '58', 'Catalogo-Completo (2).pdf'),
  CatalogSeed('P-147', 'Linha 25', 0.351, '58', 'Catalogo-Completo (2).pdf'),
  CatalogSeed('P-227', 'Linha 25', 0.492, '59', 'Catalogo-Completo (2).pdf'),
  CatalogSeed('P-318', 'Linha 25', 0.553, '59', 'Catalogo-Completo (2).pdf'),
  CatalogSeed('P-412A', 'Linha 25', 0.439, '59', 'Catalogo-Completo (2).pdf'),
  CatalogSeed('P-414', 'Linha 25', 0.611, '59', 'Catalogo-Completo (2).pdf'),
  CatalogSeed('Y-195', 'Linha 25', 0.432, '60', 'Catalogo-Completo (2).pdf'),
  CatalogSeed('Y-312', 'Linha 25', 0.475, '60', 'Catalogo-Completo (2).pdf'),
  CatalogSeed('Y-350', 'Linha 25', 0.950, '60', 'Catalogo-Completo (2).pdf'),
  CatalogSeed('Y-260', 'Linha 25', 0.658, '60', 'Catalogo-Completo (2).pdf'),
  CatalogSeed('P-319', 'Linha 25', 0.603, '61', 'Catalogo-Completo (2).pdf'),
  CatalogSeed('Z-114', 'Linha 25', 0.519, '61', 'Catalogo-Completo (2).pdf'),
  CatalogSeed('A-056', 'Linha 25', 0.373, '61', 'Catalogo-Completo (2).pdf'),
  CatalogSeed('Z-175', 'Linha 25', 0.533, '61', 'Catalogo-Completo (2).pdf'),
  CatalogSeed('A-058', 'Linha 25', 0.220, '61', 'Catalogo-Completo (2).pdf'),
  CatalogSeed('A-144', 'Linha 30', 0.766, '65', 'Catalogo-Completo (2).pdf'),
  CatalogSeed('P-273', 'Linha 30', 0.563, '65', 'Catalogo-Completo (2).pdf'),
  CatalogSeed('P-270', 'Linha 30', 0.793, '65', 'Catalogo-Completo (2).pdf'),
  CatalogSeed('P-264', 'Linha 30', 1.156, '65', 'Catalogo-Completo (2).pdf'),
  CatalogSeed('Y-140', 'Linha 30', 0.386, '65', 'Catalogo-Completo (2).pdf'),
  CatalogSeed('Y-181', 'Linha 30', 0.535, '65', 'Catalogo-Completo (2).pdf'),
  CatalogSeed('U-482', 'Linha 30', 0.114, '65', 'Catalogo-Completo (2).pdf'),
  CatalogSeed(
    'BG-057',
    'Linha 30-90',
    1.166,
    '66',
    'Catalogo-Completo (2).pdf',
  ),
  CatalogSeed(
    'LG-047',
    'Linha 30-90',
    1.133,
    '66',
    'Catalogo-Completo (2).pdf',
  ),
  CatalogSeed(
    'LG-068',
    'Linha 30-90',
    0.383,
    '66',
    'Catalogo-Completo (2).pdf',
  ),
  CatalogSeed(
    'LG-017',
    'Linha 30-90',
    1.004,
    '66',
    'Catalogo-Completo (2).pdf',
  ),
  CatalogSeed(
    'LG-083',
    'Linha 30-90',
    0.411,
    '66',
    'Catalogo-Completo (2).pdf',
  ),
  CatalogSeed(
    'SU-001',
    'Linha Suprema',
    0.713,
    '77',
    'Catalogo-Completo (2).pdf',
  ),
  CatalogSeed(
    'SU-002',
    'Linha Suprema',
    0.692,
    '77',
    'Catalogo-Completo (2).pdf',
  ),
  CatalogSeed(
    'SU-003',
    'Linha Suprema',
    0.494,
    '77',
    'Catalogo-Completo (2).pdf',
  ),
  CatalogSeed(
    'SU-004',
    'Linha Suprema',
    0.502,
    '77',
    'Catalogo-Completo (2).pdf',
  ),
  CatalogSeed(
    'SU-005',
    'Linha Suprema',
    0.974,
    '77',
    'Catalogo-Completo (2).pdf',
  ),
  CatalogSeed(
    'SU-006',
    'Linha Suprema',
    0.982,
    '77',
    'Catalogo-Completo (2).pdf',
  ),
  CatalogSeed(
    'SU-010',
    'Linha Suprema',
    0.960,
    '78',
    'Catalogo-Completo (2).pdf',
  ),
  CatalogSeed(
    'SU-011',
    'Linha Suprema',
    0.973,
    '78',
    'Catalogo-Completo (2).pdf',
  ),
  CatalogSeed(
    'SU-012',
    'Linha Suprema',
    0.542,
    '78',
    'Catalogo-Completo (2).pdf',
  ),
  CatalogSeed(
    'SU-013',
    'Linha Suprema',
    0.707,
    '79',
    'Catalogo-Completo (2).pdf',
  ),
  CatalogSeed(
    'SU-014',
    'Linha Suprema',
    0.648,
    '79',
    'Catalogo-Completo (2).pdf',
  ),
  CatalogSeed(
    'SU-040',
    'Linha Suprema',
    0.973,
    '79',
    'Catalogo-Completo (2).pdf',
  ),
  CatalogSeed(
    'SU-047',
    'Linha Suprema',
    1.041,
    '79',
    'Catalogo-Completo (2).pdf',
  ),
  CatalogSeed(
    'SU-049',
    'Linha Suprema',
    1.042,
    '80',
    'Catalogo-Completo (2).pdf',
  ),
  CatalogSeed(
    'SU-060',
    'Linha Suprema',
    0.912,
    '80',
    'Catalogo-Completo (2).pdf',
  ),
  CatalogSeed(
    'SU-061',
    'Linha Suprema',
    1.062,
    '80',
    'Catalogo-Completo (2).pdf',
  ),
  CatalogSeed(
    'SU-121',
    'Linha Suprema',
    1.415,
    '84',
    'Catalogo-Completo (2).pdf',
  ),
  CatalogSeed(
    'SU-122',
    'Linha Suprema',
    1.413,
    '84',
    'Catalogo-Completo (2).pdf',
  ),
  CatalogSeed(
    'SU-123',
    'Linha Suprema',
    0.969,
    '84',
    'Catalogo-Completo (2).pdf',
  ),
  CatalogSeed(
    'SU-225',
    'Linha Suprema',
    1.003,
    '86',
    'Catalogo-Completo (2).pdf',
  ),
  CatalogSeed(
    'SU-226',
    'Linha Suprema',
    1.009,
    '86',
    'Catalogo-Completo (2).pdf',
  ),
  CatalogSeed(
    'SU-227',
    'Linha Suprema',
    0.504,
    '86',
    'Catalogo-Completo (2).pdf',
  ),
  CatalogSeed(
    'SU-230',
    'Linha Suprema',
    0.955,
    '86',
    'Catalogo-Completo (2).pdf',
  ),
  CatalogSeed('NI-003', 'Portão', 1.351, '92', 'Catalogo-Completo (2).pdf'),
  CatalogSeed('NI-019', 'Portão', 0.247, '92', 'Catalogo-Completo (2).pdf'),
  CatalogSeed('NI-116', 'Portão', 0.631, '92', 'Catalogo-Completo (2).pdf'),
  CatalogSeed('NI-263', 'Portão', 0.767, '93', 'Catalogo-Completo (2).pdf'),
  CatalogSeed('NI-262', 'Portão', 0.450, '93', 'Catalogo-Completo (2).pdf'),
  CatalogSeed('NI-310', 'Portão', 0.430, '93', 'Catalogo-Completo (2).pdf'),
  CatalogSeed('NI-667', 'Portão', 3.104, '94', 'Catalogo-Completo (2).pdf'),
  CatalogSeed('NI-668', 'Portão', 1.412, '95', 'Catalogo-Completo (2).pdf'),
  CatalogSeed('NI-047', 'Portão', 0.729, '97', 'Catalogo-Completo (2).pdf'),
  CatalogSeed('NI-1010', 'Portão', 0.507, '97', 'Catalogo-Completo (2).pdf'),
  CatalogSeed('TUB-4598', 'Portão', 0.571, '97', 'Catalogo-Completo (2).pdf'),
  CatalogSeed('NI-983', 'Portão', 0.636, '98', 'Catalogo-Completo (2).pdf'),
  CatalogSeed('NI-1002', 'Portão', 0.779, '98', 'Catalogo-Completo (2).pdf'),
  CatalogSeed(
    'NI-009',
    'Porta padronizada 90 graus',
    0.308,
    '100',
    'Catalogo-Completo (2).pdf',
  ),
  CatalogSeed(
    'NI-013',
    'Porta padronizada 90 graus',
    0.349,
    '100',
    'Catalogo-Completo (2).pdf',
  ),
  CatalogSeed(
    'NI-011',
    'Porta padronizada 90 graus',
    0.503,
    '100',
    'Catalogo-Completo (2).pdf',
  ),
  CatalogSeed(
    'NI-012',
    'Porta padronizada 90 graus',
    0.593,
    '100',
    'Catalogo-Completo (2).pdf',
  ),
  CatalogSeed('Y-355', 'Lambril', 0.692, '101', 'Catalogo-Completo (2).pdf'),
  CatalogSeed('Y-335', 'Lambril', 0.717, '101', 'Catalogo-Completo (2).pdf'),
  CatalogSeed('LB-069', 'Lambril', 0.724, '102', 'Catalogo-Completo (2).pdf'),
  CatalogSeed('LB-070', 'Lambril', 0.763, '102', 'Catalogo-Completo (2).pdf'),
  CatalogSeed('LB-072', 'Lambril', 0.656, '103', 'Catalogo-Completo (2).pdf'),
  CatalogSeed('LB-077', 'Lambril', 0.638, '103', 'Catalogo-Completo (2).pdf'),
  CatalogSeed(
    'CG-074',
    'Gradil e corrimão',
    0.239,
    '105',
    'Catalogo-Completo (2).pdf',
  ),
  CatalogSeed(
    'CG-075',
    'Gradil e corrimão',
    0.521,
    '105',
    'Catalogo-Completo (2).pdf',
  ),
  CatalogSeed(
    'CG-077',
    'Gradil e corrimão',
    0.507,
    '105',
    'Catalogo-Completo (2).pdf',
  ),
  CatalogSeed(
    'CG-083',
    'Gradil e corrimão',
    0.723,
    '105',
    'Catalogo-Completo (2).pdf',
  ),
  CatalogSeed(
    'CG-731',
    'Gradil e corrimão',
    1.332,
    '105',
    'Catalogo-Completo (2).pdf',
  ),
  CatalogSeed(
    'NI-409',
    'Gradil e corrimão',
    1.131,
    '107',
    'Catalogo-Completo (2).pdf',
  ),
  CatalogSeed(
    'NI-761',
    'Gradil e corrimão',
    0.229,
    '107',
    'Catalogo-Completo (2).pdf',
  ),
  CatalogSeed(
    'NI-680',
    'Gradil e corrimão',
    0.668,
    '107',
    'Catalogo-Completo (2).pdf',
  ),
];
