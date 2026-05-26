import 'package:flutter/material.dart';

import '../../../app_state.dart';
import '../../../shared/formatters.dart';

class OrcamentoFormPage extends StatefulWidget {
  const OrcamentoFormPage({super.key});

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
  late AppState _state;

  double get _subtotal {
    return _itens.fold<double>(0, (total, item) => total + item.subtotal);
  }

  double get _desconto => parseDecimal(_descontoController.text);

  double get _total {
    final total = _subtotal - _desconto;
    return total < 0 ? 0 : total;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _state = AppStateScope.of(context);
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
    if (_clienteId == null && state.clientes.isNotEmpty) {
      _clienteId = state.clientes.first.id;
    }
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        if (_clienteId == null && state.clientes.isNotEmpty) {
          _clienteId = state.clientes.first.id;
        }
        return Scaffold(
      appBar: AppBar(title: const Text('Novo orçamento')),
      body: SafeArea(
        child: state.clientes.isEmpty
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
                                'Criação de orçamento',
                                style: Theme.of(context).textTheme.headlineSmall
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Monte a proposta com cliente, múltiplos itens, desconto e observações.',
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                              const SizedBox(height: 16),
                              if (isWide)
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                                onAdd: () => _abrirItemDialog(context),
                                onEdit: (item) =>
                                    _abrirItemDialog(context, item),
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
                                    onPressed: () => _salvar(context),
                                    icon: const Icon(Icons.save_outlined),
                                    label: const Text('Salvar orçamento'),
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

  Future<void> _abrirItemDialog(
    BuildContext context, [
    OrcamentoItem? item,
  ]) async {
    final state = _state;
    var tipo = item?.tipo ?? 'produto';
    String? origemId = item?.origemId;
    final descricaoController = TextEditingController(
      text: item?.descricao ?? '',
    );
    final quantidadeController = TextEditingController(
      text: item == null ? '1' : decimalText(item.quantidade),
    );
    final unidadeController = TextEditingController(
      text: item?.unidade ?? 'metro',
    );
    final valorController = TextEditingController(
      text: item == null ? '' : decimalText(item.valorUnitario),
    );
    final observacoesController = TextEditingController(
      text: item?.observacoes ?? '',
    );

    void aplicarProduto(String? id) {
      final produto = id == null ? null : state.produtoPorId(id);
      if (produto == null) return;
      descricaoController.text = [
        if (produto.codigo != null) produto.codigo,
        produto.nome,
      ].join(' - ');
      unidadeController.text = produto.unidade;
      valorController.text = decimalText(produto.valorBase);
      observacoesController.text = produto.observacoes ?? '';
    }

    void aplicarServico(String? id) {
      final servico = id == null ? null : state.servicoPorId(id);
      if (servico == null) return;
      descricaoController.text = servico.nome;
      unidadeController.text = servico.unidade;
      valorController.text = decimalText(servico.valorBase);
      observacoesController.text = servico.observacoes ?? '';
    }

    void escolherPrimeiraOrigem() {
      if (tipo == 'produto' && state.produtosAtivos.isNotEmpty) {
        origemId = state.produtosAtivos.first.id;
        aplicarProduto(origemId);
      } else if (tipo == 'servico' && state.servicosAtivos.isNotEmpty) {
        origemId = state.servicosAtivos.first.id;
        aplicarServico(origemId);
      } else {
        origemId = null;
        if (descricaoController.text.isEmpty) {
          unidadeController.text = 'un';
        }
      }
    }

    if (item == null) {
      escolherPrimeiraOrigem();
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final formKey = GlobalKey<FormState>();
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final produtos = state.produtosAtivos;
            final servicos = state.servicosAtivos;
            return AlertDialog(
              title: Text(item == null ? 'Adicionar item' : 'Editar item'),
              content: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        DropdownButtonFormField<String>(
                          initialValue: tipo,
                          decoration: const InputDecoration(
                            labelText: 'Tipo de item',
                          ),
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
                            setDialogState(() {
                              tipo = value;
                              origemId = null;
                              if (tipo == 'manual') {
                                descricaoController.clear();
                                unidadeController.text = 'un';
                                valorController.clear();
                                observacoesController.clear();
                              } else {
                                escolherPrimeiraOrigem();
                              }
                            });
                          },
                        ),
                        if (tipo == 'produto') ...[
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            initialValue: origemId,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Produto',
                            ),
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
                              if (value == null) return 'Selecione um produto.';
                              return null;
                            },
                            onChanged: (value) {
                              setDialogState(() {
                                origemId = value;
                                aplicarProduto(value);
                              });
                            },
                          ),
                        ],
                        if (tipo == 'servico') ...[
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            initialValue: origemId,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Serviço',
                            ),
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
                              if (value == null) return 'Selecione um serviço.';
                              return null;
                            },
                            onChanged: (value) {
                              setDialogState(() {
                                origemId = value;
                                aplicarServico(value);
                              });
                            },
                          ),
                        ],
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: descricaoController,
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
                                controller: quantidadeController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                decoration: const InputDecoration(
                                  labelText: 'Quantidade',
                                ),
                                validator: (value) {
                                  if (parseDecimal(value ?? '') <= 0) {
                                    return 'Quantidade inválida.';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: unidadeController,
                                decoration: const InputDecoration(
                                  labelText: 'Unidade',
                                ),
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
                                controller: valorController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                decoration: const InputDecoration(
                                  labelText: 'Valor unitário',
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: observacoesController,
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
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancelar'),
                ),
                FilledButton.icon(
                  onPressed: () {
                    if (!formKey.currentState!.validate()) return;
                    final novo = OrcamentoItem(
                      id: item?.id ?? _tempItemId--,
                      tipo: tipo,
                      origemId: origemId,
                      descricao: descricaoController.text.trim(),
                      quantidade: parseDecimal(quantidadeController.text),
                      unidade: unidadeController.text.trim(),
                      valorUnitario: parseDecimal(valorController.text),
                      observacoes: observacoesController.text.trim(),
                    );

                    Navigator.of(dialogContext).pop();
                    setState(() {
                      final index = _itens.indexWhere(
                        (element) => element.id == item?.id,
                      );
                      if (index >= 0) {
                        _itens[index] = novo;
                      } else {
                        _itens.add(novo);
                      }
                    });
                  },
                  icon: const Icon(Icons.check),
                  label: const Text('Aplicar'),
                ),
              ],
            );
          },
        );
      },
    );

    descricaoController.dispose();
    quantidadeController.dispose();
    unidadeController.dispose();
    valorController.dispose();
    observacoesController.dispose();
  }

  void _salvar(BuildContext context) {
    if (!_formKey.currentState!.validate()) return;
    if (_itens.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Inclua pelo menos um item no orçamento.'),
        ),
      );
      return;
    }

    final state = _state;
    final clienteId = _clienteId!;
    final itens = List<OrcamentoItem>.from(_itens);
    final desconto = _desconto;
    final validadeDias = int.tryParse(_validadeController.text.trim()) ?? 7;
    final observacoes = _observacoesController.text.trim();

    Navigator.of(context).pop();
    state.salvarOrcamento(
      clienteId: clienteId,
      itens: itens,
      desconto: desconto,
      validadeDias: validadeDias,
      observacoes: observacoes,
    );
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
              initialValue: clienteId,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Cliente'),
              items: state.clientes.map((cliente) {
                return DropdownMenuItem<String>(
                  value: cliente.id,
                  child: Text(cliente.nome, overflow: TextOverflow.ellipsis),
                );
              }).toList(),
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
