import 'package:flutter/material.dart';

import '../../../app_state.dart';
import '../../../data/models/produto_model.dart';
import '../../../shared/formatters.dart';

class ProdutosListPage extends StatefulWidget {
  const ProdutosListPage({super.key, this.categoriaInicial});

  final String? categoriaInicial;

  @override
  State<ProdutosListPage> createState() => _ProdutosListPageState();
}

class _ProdutosListPageState extends State<ProdutosListPage> {
  final TextEditingController _buscaController = TextEditingController();
  String _busca = '';
  late String _categoria = widget.categoriaInicial ?? 'Todas';
  late AppState _state;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _state = AppStateScope.read(context);
  }

  @override
  void dispose() {
    _buscaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _state,
      builder: (context, _) => _buildContent(context, _state),
    );
  }

  Widget _buildContent(BuildContext context, AppState state) {
    final categorias = ['Todas', ...state.categoriasProdutos];
    final produtos = state.produtos
        .where((produto) {
          final termo = _busca.toLowerCase();
          final combinaBusca =
              produto.nome.toLowerCase().contains(termo) ||
              (produto.codigo ?? '').toLowerCase().contains(termo) ||
              produto.categoria.toLowerCase().contains(termo) ||
              (produto.observacoes ?? '').toLowerCase().contains(termo);
          final combinaCategoria =
              _categoria == 'Todas' || produto.categoria == _categoria;
          return combinaBusca && combinaCategoria;
        })
        .toList(growable: false);

    return Scaffold(
      appBar: AppBar(title: const Text('Produtos')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrirFormulario(context),
        icon: const Icon(Icons.add_box_outlined),
        label: const Text('Novo produto'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Catálogo de produtos',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Perfis extraídos dos PDFs com código, linha, peso e valor base editável.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _buscaController,
                    onChanged: (value) => setState(() => _busca = value),
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      labelText: 'Buscar por código, linha ou descrição',
                    ),
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: categorias.map((categoria) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            selected: _categoria == categoria,
                            label: Text(categoria),
                            onSelected: (_) =>
                                setState(() => _categoria = categoria),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: produtos.isEmpty
                        ? const _EmptyProdutos()
                        : LayoutBuilder(
                            builder: (context, constraints) {
                              final grid = constraints.maxWidth >= 820;
                              if (!grid) {
                                return ListView.separated(
                                  itemCount: produtos.length,
                                  separatorBuilder: (_, _) =>
                                      const SizedBox(height: 10),
                                  itemBuilder: (context, index) => _ProdutoCard(
                                    produto: produtos[index],
                                    onEdit: () => _abrirFormulario(
                                      context,
                                      produtos[index],
                                    ),
                                    onDelete: () => _confirmarExclusao(
                                      context,
                                      produtos[index],
                                    ),
                                  ),
                                );
                              }

                              return GridView.builder(
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      crossAxisSpacing: 12,
                                      mainAxisSpacing: 12,
                                      childAspectRatio: 2.7,
                                    ),
                                itemCount: produtos.length,
                                itemBuilder: (context, index) => _ProdutoCard(
                                  produto: produtos[index],
                                  onEdit: () => _abrirFormulario(
                                    context,
                                    produtos[index],
                                  ),
                                  onDelete: () => _confirmarExclusao(
                                    context,
                                    produtos[index],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _abrirFormulario(
    BuildContext context, [
    Produto? produto,
  ]) async {
    final state = _state;
    final nomeController = TextEditingController(text: produto?.nome ?? '');
    final codigoController = TextEditingController(text: produto?.codigo ?? '');
    final categoriaController = TextEditingController(
      text: produto?.categoria ?? 'Avulso',
    );
    final unidadeController = TextEditingController(
      text: produto?.unidade ?? 'metro',
    );
    final valorController = TextEditingController(
      text: produto == null ? '' : decimalText(produto.valorBase),
    );
    final observacoesController = TextEditingController(
      text: produto?.observacoes ?? '',
    );
    var ativo = produto?.ativo ?? true;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final formKey = GlobalKey<FormState>();
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(produto == null ? 'Novo produto' : 'Editar produto'),
              content: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 620),
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: codigoController,
                                textCapitalization:
                                    TextCapitalization.characters,
                                decoration: const InputDecoration(
                                  labelText: 'Código',
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                controller: nomeController,
                                textCapitalization: TextCapitalization.words,
                                decoration: const InputDecoration(
                                  labelText: 'Nome',
                                ),
                                validator: (value) {
                                  if ((value ?? '').trim().isEmpty) {
                                    return 'Informe o nome.';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: categoriaController,
                                textCapitalization: TextCapitalization.words,
                                decoration: const InputDecoration(
                                  labelText: 'Linha ou categoria',
                                ),
                                validator: (value) {
                                  if ((value ?? '').trim().isEmpty) {
                                    return 'Informe a categoria.';
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
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: valorController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Valor base',
                          ),
                          validator: (value) {
                            final valor = parseDecimalOrNull(value ?? '');
                            if (valor == null || valor < 0) {
                              return 'Informe um valor válido.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: observacoesController,
                          minLines: 3,
                          maxLines: 5,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: const InputDecoration(
                            labelText: 'Descrição e observações',
                          ),
                        ),
                        const SizedBox(height: 8),
                        SwitchListTile(
                          value: ativo,
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Produto ativo para orçamento'),
                          onChanged: (value) =>
                              setDialogState(() => ativo = value),
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
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    FocusScope.of(dialogContext).unfocus();
                    final navigator = Navigator.of(dialogContext);
                    final messenger = ScaffoldMessenger.of(dialogContext);
                    final valorBase = parseDecimalOrNull(valorController.text);
                    if (valorBase == null) return;
                    final novoProduto = Produto(
                      id: produto?.id,
                      nome: nomeController.text.trim(),
                      codigo: codigoController.text.trim().isEmpty
                          ? null
                          : codigoController.text.trim(),
                      categoria: categoriaController.text.trim(),
                      unidade: unidadeController.text.trim(),
                      valorBase: valorBase,
                      observacoes: observacoesController.text.trim(),
                      ativo: ativo,
                    );
                    try {
                      await state.salvarProduto(novoProduto);
                      if (!dialogContext.mounted) return;
                      navigator.pop();
                    } catch (e) {
                      if (!dialogContext.mounted) return;
                      messenger.showSnackBar(
                        SnackBar(content: Text('Erro ao salvar produto: $e')),
                      );
                    }
                  },
                  icon: const Icon(Icons.check),
                  label: const Text('Salvar'),
                ),
              ],
            );
          },
        );
      },
    );

    nomeController.dispose();
    codigoController.dispose();
    categoriaController.dispose();
    unidadeController.dispose();
    valorController.dispose();
    observacoesController.dispose();
  }

  Future<void> _confirmarExclusao(BuildContext context, Produto produto) async {
    final state = _state;
    final id = produto.id!;
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Excluir produto'),
          content: Text('Remover ${produto.codigo ?? produto.nome} do catálogo?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Excluir'),
            ),
          ],
        );
      },
    );
    if (confirmado ?? false) {
      try {
        await state.excluirProduto(id);
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao excluir produto: $e')),
        );
      }
    }
  }
}

class _ProdutoCard extends StatelessWidget {
  const _ProdutoCard({
    required this.produto,
    required this.onEdit,
    required this.onDelete,
  });

  final Produto produto;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3EFEA),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    produto.codigo ?? 'SEM CÓD.',
                    style: const TextStyle(
                      color: Color(0xFF235A50),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const Spacer(),
                PopupMenuButton<String>(
                  tooltip: 'Ações do produto',
                  onSelected: (value) {
                    if (value == 'edit') onEdit();
                    if (value == 'delete') onDelete();
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: 'edit',
                      child: ListTile(
                        leading: Icon(Icons.edit_outlined),
                        title: Text('Editar'),
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: ListTile(
                        leading: Icon(Icons.delete_outline),
                        title: Text('Excluir'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              produto.nome,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              produto.categoria,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  produto.ativo
                      ? Icons.check_circle_outline
                      : Icons.pause_circle_outline,
                  size: 18,
                  color: produto.ativo
                      ? const Color(0xFF2F6F63)
                      : Colors.orange,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(produto.unidade, overflow: TextOverflow.ellipsis),
                ),
                Text(
                  formatMoney(produto.valorBase),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyProdutos extends StatelessWidget {
  const _EmptyProdutos();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('Nenhum produto encontrado.'),
        ),
      ),
    );
  }
}
