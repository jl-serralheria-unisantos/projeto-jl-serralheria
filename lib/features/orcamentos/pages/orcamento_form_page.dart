import 'package:flutter/material.dart';

import '../../../app_state.dart';
import '../../../shared/formatters.dart';
import 'orcamento_detalhe_page.dart';

class OrcamentoFormPage extends StatefulWidget {
  const OrcamentoFormPage({super.key, this.orcamentoId});

  final String? orcamentoId;

  @override
  State<OrcamentoFormPage> createState() => _OrcamentoFormPageState();
}

class _OrcamentoFormPageState extends State<OrcamentoFormPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _descontoController = TextEditingController(
    text: '0,00',
  );
  final TextEditingController _validadeController = TextEditingController(
    text: '7',
  );
  final TextEditingController _observacoesController = TextEditingController();

  final List<OrcamentoItem> _itens = [];
  int _tempItemId = -1;
  String? _clienteId;
  bool _salvando = false;
  bool _carregouOrcamentoInicial = false;
  late AppState _state;

  bool get _editando => widget.orcamentoId != null;

  double get _subtotal {
    return _itens.fold<double>(0, (total, item) => total + item.subtotal);
  }

  double get _desconto => parseDecimalOrNull(_descontoController.text) ?? 0;

  double get _total {
    final total = _subtotal - _desconto;
    return total < 0 ? 0 : total;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _state = AppStateScope.read(context);
    _preencherOrcamentoParaEdicao();
  }

  @override
  void dispose() {
    _descontoController.dispose();
    _validadeController.dispose();
    _observacoesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = _state;
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        _preencherOrcamentoParaEdicao();
        final orcamentoId = widget.orcamentoId;
        if (orcamentoId != null && !_carregouOrcamentoInicial) {
          return Scaffold(
            appBar: AppBar(title: const Text('Editar orçamento')),
            body: Center(
              child: state.carregando
                  ? const CircularProgressIndicator()
                  : const Text('Orçamento não encontrado.'),
            ),
          );
        }

        _sincronizarClienteSelecionado(state);
        final temClientes = state.clientes.any((cliente) => cliente.id != null);
        return Scaffold(
          appBar: AppBar(
            title: Text(_editando ? 'Editar orçamento' : 'Novo orçamento'),
          ),
          body: SafeArea(
            child: !temClientes
                ? const _SemClientes()
                : Form(
                    key: _formKey,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide = constraints.maxWidth >= 980;
                        return SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 1180),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _editando
                                        ? 'Edição de orçamento'
                                        : 'Criação de orçamento',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall
                                        ?.copyWith(fontWeight: FontWeight.w800),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    _editando
                                        ? 'Atualize cliente, itens, desconto e observações da proposta.'
                                        : 'Monte a proposta com cliente, múltiplos itens, desconto e observações.',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyLarge,
                                  ),
                                  const SizedBox(height: 16),
                                  if (isWide)
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(child: _buildDadosOrcamento()),
                                        const SizedBox(width: 16),
                                        SizedBox(
                                          width: 340,
                                          child: _buildResumoOrcamento(),
                                        ),
                                      ],
                                    )
                                  else
                                    Column(
                                      children: [
                                        _buildDadosOrcamento(),
                                        const SizedBox(height: 16),
                                        _buildResumoOrcamento(),
                                      ],
                                    ),
                                  const SizedBox(height: 16),
                                  _ItensSection(
                                    itens: _itens,
                                    onAdd: () => _abrirItemDialog(),
                                    onEdit: _abrirItemDialog,
                                    onDelete: (item) =>
                                        setState(() => _itens.remove(item)),
                                  ),
                                  const SizedBox(height: 20),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(),
                                        child: const Text('Cancelar'),
                                      ),
                                      const SizedBox(width: 8),
                                      FilledButton.icon(
                                        onPressed: _salvando
                                            ? null
                                            : () => _salvar(context),
                                        icon: const Icon(Icons.save_outlined),
                                        label: Text(
                                          _salvando
                                              ? 'Salvando...'
                                              : _editando
                                              ? 'Salvar alterações'
                                              : 'Salvar orçamento',
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        );
      },
    );
  }

  void _preencherOrcamentoParaEdicao() {
    final orcamentoId = widget.orcamentoId;
    if (_carregouOrcamentoInicial || orcamentoId == null) return;

    final orcamento = _state.orcamentoPorId(orcamentoId);
    if (orcamento == null) return;

    _clienteId = orcamento.clienteId;
    _descontoController.text = decimalText(orcamento.desconto);
    _validadeController.text = '${orcamento.validadeDias}';
    _observacoesController.text = orcamento.observacoes;
    _itens
      ..clear()
      ..addAll(
        orcamento.itens.map((item) {
          return OrcamentoItem(
            id: _tempItemId--,
            tipo: item.tipo,
            origemId: item.origemId,
            descricao: item.descricao,
            quantidade: item.quantidade,
            unidade: item.unidade,
            valorUnitario: item.valorUnitario,
            observacoes: item.observacoes,
          );
        }),
      );
    _carregouOrcamentoInicial = true;
  }

  void _sincronizarClienteSelecionado(AppState state) {
    final clienteSelecionadoExiste =
        _clienteId != null &&
        state.clientes.any((cliente) => cliente.id == _clienteId);
    if (clienteSelecionadoExiste) return;

    if (_editando) {
      _clienteId = null;
      return;
    }

    for (final cliente in state.clientes) {
      if (cliente.id != null) {
        _clienteId = cliente.id;
        return;
      }
    }

    _clienteId = null;
  }

  Widget _buildDadosOrcamento() {
    return _DadosOrcamento(
      state: _state,
      clienteId: _clienteId,
      onClienteChanged: (value) => setState(() => _clienteId = value),
      descontoController: _descontoController,
      validadeController: _validadeController,
      observacoesController: _observacoesController,
      onChanged: () => setState(() {}),
    );
  }

  Widget _buildResumoOrcamento() {
    return _ResumoOrcamento(
      subtotal: _subtotal,
      desconto: _desconto,
      total: _total,
      itens: _itens.length,
    );
  }

  Future<void> _abrirItemDialog([OrcamentoItem? item]) async {
    final itemAplicado = await showDialog<OrcamentoItem>(
      context: context,
      builder: (_) => _OrcamentoItemDialog(
        state: _state,
        item: item,
        itemId: item?.id ?? _tempItemId,
        tipoInicial: item?.tipo ?? _tipoInicialParaNovoItem(_state),
      ),
    );

    if (!mounted || itemAplicado == null) return;

    setState(() {
      if (item == null) {
        _tempItemId--;
      }
      final index = _itens.indexWhere((element) => element.id == item?.id);
      if (index >= 0) {
        _itens[index] = itemAplicado;
      } else {
        _itens.add(itemAplicado);
      }
    });
  }

  String _tipoInicialParaNovoItem(AppState state) {
    if (state.produtosAtivos.isNotEmpty) return 'produto';
    if (state.servicosAtivos.isNotEmpty) return 'servico';
    return 'manual';
  }

  Future<void> _salvar(BuildContext context) async {
    if (_salvando) return;
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    if (_itens.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Inclua pelo menos um item no orçamento.'),
        ),
      );
      return;
    }

    final state = _state;
    final clienteId = _clienteId;
    if (clienteId == null || state.clientePorId(clienteId) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione um cliente válido.')),
      );
      return;
    }

    final temItemInvalido = _itens.any(
      (item) => item.quantidade <= 0 || item.valorUnitario < 0,
    );
    if (temItemInvalido) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Revise os itens: quantidade deve ser maior que zero e valor unitário não pode ser negativo.',
          ),
        ),
      );
      return;
    }

    final itens = List<OrcamentoItem>.from(_itens);
    final desconto = parseDecimalOrNull(_descontoController.text);
    if (desconto == null || desconto < 0) return;
    final validadeDias = int.tryParse(_validadeController.text.trim()) ?? 7;
    final observacoes = _observacoesController.text.trim();

    setState(() => _salvando = true);

    try {
      final orcamentoId = widget.orcamentoId == null
          ? await state.salvarOrcamento(
              clienteId: clienteId,
              itens: itens,
              desconto: desconto,
              validadeDias: validadeDias,
              observacoes: observacoes,
            )
          : await state.atualizarOrcamento(
              id: widget.orcamentoId!,
              clienteId: clienteId,
              itens: itens,
              desconto: desconto,
              validadeDias: validadeDias,
              observacoes: observacoes,
            );

      if (!context.mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => OrcamentoDetalhePage(orcamentoId: orcamentoId),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      setState(() => _salvando = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao salvar orçamento: $e')));
    }
  }
}

class _DadosOrcamento extends StatelessWidget {
  const _DadosOrcamento({
    required this.state,
    required this.clienteId,
    required this.onClienteChanged,
    required this.descontoController,
    required this.validadeController,
    required this.observacoesController,
    required this.onChanged,
  });

  final AppState state;
  final String? clienteId;
  final ValueChanged<String?> onClienteChanged;
  final TextEditingController descontoController;
  final TextEditingController validadeController;
  final TextEditingController observacoesController;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dados da proposta',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              key: ValueKey(clienteId),
              initialValue: clienteId,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Cliente'),
              items: state.clientes
                  .where((cliente) => cliente.id != null)
                  .map((cliente) {
                    return DropdownMenuItem<String>(
                      value: cliente.id!,
                      child: Text(cliente.nome, overflow: TextOverflow.ellipsis),
                    );
                  })
                  .toList(),
              validator: (value) {
                if (value == null) return 'Selecione um cliente.';
                return null;
              },
              onChanged: onClienteChanged,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: descontoController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(labelText: 'Desconto'),
                    validator: (value) {
                      final desconto = parseDecimalOrNull(value ?? '');
                      if (desconto == null || desconto < 0) {
                        return 'Informe um desconto válido.';
                      }
                      return null;
                    },
                    onChanged: (_) => onChanged(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: validadeController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Validade (dias)',
                    ),
                    validator: (value) {
                      final dias = int.tryParse((value ?? '').trim());
                      if (dias == null || dias <= 0) {
                        return 'Informe dias válidos.';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: observacoesController,
              minLines: 4,
              maxLines: 6,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Observações gerais',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResumoOrcamento extends StatelessWidget {
  const _ResumoOrcamento({
    required this.subtotal,
    required this.desconto,
    required this.total,
    required this.itens,
  });

  final double subtotal;
  final double desconto;
  final double total;
  final int itens;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Resumo',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 14),
            _ResumoLinha(label: 'Itens', value: '$itens'),
            _ResumoLinha(label: 'Subtotal', value: formatMoney(subtotal)),
            _ResumoLinha(label: 'Desconto', value: formatMoney(desconto)),
            const Divider(height: 24),
            Text('Valor final', style: theme.textTheme.labelLarge),
            Text(
              formatMoney(total),
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
                color: const Color(0xFF2F6F63),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResumoLinha extends StatelessWidget {
  const _ResumoLinha({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _OrcamentoItemDialog extends StatefulWidget {
  const _OrcamentoItemDialog({
    required this.state,
    required this.itemId,
    required this.tipoInicial,
    this.item,
  });

  final AppState state;
  final OrcamentoItem? item;
  final int itemId;
  final String tipoInicial;

  @override
  State<_OrcamentoItemDialog> createState() => _OrcamentoItemDialogState();
}

class _OrcamentoItemDialogState extends State<_OrcamentoItemDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late String _tipo;
  String? _origemId;
  late final TextEditingController _descricaoController;
  late final TextEditingController _quantidadeController;
  late final TextEditingController _unidadeController;
  late final TextEditingController _valorController;
  late final TextEditingController _observacoesController;

  AppState get _state => widget.state;

  @override
  void initState() {
    super.initState();

    final item = widget.item;
    _tipo = widget.tipoInicial;
    _origemId = item?.origemId;
    _descricaoController = TextEditingController(text: item?.descricao ?? '');
    _quantidadeController = TextEditingController(
      text: item == null ? '1' : decimalText(item.quantidade),
    );
    _unidadeController = TextEditingController(text: item?.unidade ?? 'metro');
    _valorController = TextEditingController(
      text: item == null ? '' : decimalText(item.valorUnitario),
    );
    _observacoesController = TextEditingController(
      text: item?.observacoes ?? '',
    );

    if (item == null) {
      _escolherPrimeiraOrigem();
    } else {
      _limparOrigemInexistente();
    }
  }

  @override
  void dispose() {
    _descricaoController.dispose();
    _quantidadeController.dispose();
    _unidadeController.dispose();
    _valorController.dispose();
    _observacoesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final produtos = _state.produtosAtivos;
    final servicos = _state.servicosAtivos;

    return AlertDialog(
      title: Text(widget.item == null ? 'Adicionar item' : 'Editar item'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _tipo,
                  decoration: const InputDecoration(labelText: 'Tipo de item'),
                  items: const [
                    DropdownMenuItem(
                      value: 'produto',
                      child: Text('Produto do catálogo'),
                    ),
                    DropdownMenuItem(
                      value: 'servico',
                      child: Text('Serviço recorrente'),
                    ),
                    DropdownMenuItem(
                      value: 'manual',
                      child: Text('Item manual'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _tipo = value;
                      _origemId = null;
                      if (_tipo == 'manual') {
                        _descricaoController.clear();
                        _unidadeController.text = 'un';
                        _valorController.clear();
                        _observacoesController.clear();
                      } else {
                        _escolherPrimeiraOrigem();
                      }
                    });
                  },
                ),
                if (_tipo == 'produto') ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    key: const ValueKey('produto-orcamento'),
                    initialValue: _origemId,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Produto'),
                    items: produtos.map((produto) {
                      return DropdownMenuItem<String>(
                        value: produto.id,
                        child: Text(
                          '${produto.codigo ?? produto.nome} • ${produto.categoria}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    validator: (value) {
                      if (value == null) {
                        return 'Selecione um produto.';
                      }
                      return null;
                    },
                    onChanged: (value) {
                      setState(() {
                        _origemId = value;
                        _aplicarProduto(value);
                      });
                    },
                  ),
                ],
                if (_tipo == 'servico') ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    key: const ValueKey('servico-orcamento'),
                    initialValue: _origemId,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Serviço'),
                    items: servicos.map((servico) {
                      return DropdownMenuItem<String>(
                        value: servico.id,
                        child: Text(
                          servico.nome,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    validator: (value) {
                      if (value == null) {
                        return 'Selecione um serviço.';
                      }
                      return null;
                    },
                    onChanged: (value) {
                      setState(() {
                        _origemId = value;
                        _aplicarServico(value);
                      });
                    },
                  ),
                ],
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descricaoController,
                  minLines: 2,
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Descrição do item',
                  ),
                  validator: (value) {
                    if ((value ?? '').trim().isEmpty) {
                      return 'Informe a descrição.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _quantidadeController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Quantidade',
                        ),
                        validator: (value) {
                          final quantidade = parseDecimalOrNull(value ?? '');
                          if (quantidade == null || quantidade <= 0) {
                            return 'Informe quantidade maior que zero.';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _unidadeController,
                        decoration: const InputDecoration(labelText: 'Unidade'),
                        validator: (value) {
                          if ((value ?? '').trim().isEmpty) {
                            return 'Informe a unidade.';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _valorController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Valor unitário',
                        ),
                        validator: (value) {
                          final valor = parseDecimalOrNull(value ?? '');
                          if (valor == null) {
                            return 'Informe o valor.';
                          }
                          if (valor < 0) {
                            return 'Informe valor maior ou igual a zero.';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _observacoesController,
                  minLines: 2,
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Observações do item',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          onPressed: _aplicar,
          icon: const Icon(Icons.check),
          label: const Text('Aplicar'),
        ),
      ],
    );
  }

  void _limparOrigemInexistente() {
    if (_tipo == 'produto' &&
        !_state.produtosAtivos.any((produto) => produto.id == _origemId)) {
      _origemId = null;
    } else if (_tipo == 'servico' &&
        !_state.servicosAtivos.any((servico) => servico.id == _origemId)) {
      _origemId = null;
    }
  }

  void _escolherPrimeiraOrigem() {
    if (_tipo == 'produto' && _state.produtosAtivos.isNotEmpty) {
      _origemId = _state.produtosAtivos.first.id;
      _aplicarProduto(_origemId);
    } else if (_tipo == 'servico' && _state.servicosAtivos.isNotEmpty) {
      _origemId = _state.servicosAtivos.first.id;
      _aplicarServico(_origemId);
    } else {
      _origemId = null;
      if (_descricaoController.text.isEmpty) {
        _unidadeController.text = 'un';
      }
    }
  }

  void _aplicarProduto(String? id) {
    final produto = id == null ? null : _state.produtoPorId(id);
    if (produto == null) return;
    _descricaoController.text = [
      if (produto.codigo != null) produto.codigo,
      produto.nome,
    ].join(' - ');
    _unidadeController.text = produto.unidade;
    _valorController.text = decimalText(produto.valorBase);
    _observacoesController.text = produto.observacoes ?? '';
  }

  void _aplicarServico(String? id) {
    final servico = id == null ? null : _state.servicoPorId(id);
    if (servico == null) return;
    _descricaoController.text = servico.nome;
    _unidadeController.text = servico.unidade;
    _valorController.text = decimalText(servico.valorBase);
    _observacoesController.text = servico.observacoes ?? '';
  }

  void _aplicar() {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    Navigator.of(context).pop(
      OrcamentoItem(
        id: widget.itemId,
        tipo: _tipo,
        origemId: _origemId,
        descricao: _descricaoController.text.trim(),
        quantidade: parseDecimal(_quantidadeController.text),
        unidade: _unidadeController.text.trim(),
        valorUnitario: parseDecimal(_valorController.text),
        observacoes: _observacoesController.text.trim(),
      ),
    );
  }
}

class _ItensSection extends StatelessWidget {
  const _ItensSection({
    required this.itens,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  final List<OrcamentoItem> itens;
  final VoidCallback onAdd;
  final ValueChanged<OrcamentoItem> onEdit;
  final ValueChanged<OrcamentoItem> onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Itens do orçamento',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                FilledButton.icon(
                  onPressed: onAdd,
                  icon: const Icon(Icons.add),
                  label: const Text('Adicionar item'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (itens.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F4EF),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE4DED4)),
                ),
                child: const Text('Nenhum item incluído.'),
              )
            else
              Column(
                children: itens.map((item) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFDFCF9),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE4DED4)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE3EFEA),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              _iconForTipo(item.tipo),
                              color: const Color(0xFF2F6F63),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.descricao,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${decimalText(item.quantidade)} ${item.unidade} × ${formatMoney(item.valorUnitario)}',
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                formatMoney(item.subtotal),
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              Wrap(
                                spacing: 2,
                                children: [
                                  IconButton(
                                    tooltip: 'Editar item',
                                    icon: const Icon(Icons.edit_outlined),
                                    onPressed: () => onEdit(item),
                                  ),
                                  IconButton(
                                    tooltip: 'Remover item',
                                    icon: const Icon(Icons.delete_outline),
                                    onPressed: () => onDelete(item),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }
}

class _SemClientes extends StatelessWidget {
  const _SemClientes();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('Cadastre um cliente antes de criar um orçamento.'),
        ),
      ),
    );
  }
}

IconData _iconForTipo(String tipo) {
  return switch (tipo) {
    'produto' => Icons.inventory_2_outlined,
    'servico' => Icons.handyman_outlined,
    _ => Icons.edit_note_outlined,
  };
}
