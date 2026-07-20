import 'package:flutter/material.dart';

import '../../../app_state.dart';
import '../../../data/models/cliente_model.dart';

class ClientesListPage extends StatefulWidget {
  const ClientesListPage({super.key});

  @override
  State<ClientesListPage> createState() => _ClientesListPageState();
}

class _ClientesListPageState extends State<ClientesListPage> {
  final TextEditingController _buscaController = TextEditingController();
  String _busca = '';
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
    final clientes = state.clientes
        .where((cliente) {
          final termo = _busca.toLowerCase();
          return cliente.nome.toLowerCase().contains(termo) ||
              cliente.telefone.toLowerCase().contains(termo) ||
              (cliente.endereco ?? '').toLowerCase().contains(termo);
        })
        .toList(growable: false);

    return Scaffold(
      appBar: AppBar(title: const Text('Clientes')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrirFormulario(context),
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Novo cliente'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 980),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cadastro de clientes',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Registre dados básicos para reutilizar em novos orçamentos.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _buscaController,
                    onChanged: (value) => setState(() => _busca = value),
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      labelText: 'Buscar por nome, telefone ou endereço',
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: clientes.isEmpty
                        ? _EmptyClientes(
                            onCreate: () => _abrirFormulario(context),
                          )
                        : ListView.separated(
                            itemCount: clientes.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final cliente = clientes[index];
                              final nome = cliente.nome.trim();
                              final inicial = nome.characters.isEmpty
                                  ? '?'
                                  : nome.characters.first.toUpperCase();
                              return Card(
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: const Color(0xFFE3EFEA),
                                    foregroundColor: const Color(0xFF2F6F63),
                                    child: Text(inicial),
                                  ),
                                  title: Text(
                                    cliente.nome,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  subtitle: Text(
                                    [
                                      cliente.telefone,
                                      if ((cliente.endereco ?? '').isNotEmpty)
                                        cliente.endereco!,
                                      if ((cliente.observacoes ?? '')
                                          .isNotEmpty)
                                        cliente.observacoes!,
                                    ].join(' • '),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  trailing: PopupMenuButton<String>(
                                    tooltip: 'Ações do cliente',
                                    onSelected: (value) {
                                      if (value == 'edit') {
                                        _abrirFormulario(context, cliente);
                                      }
                                      if (value == 'delete') {
                                        _confirmarExclusao(context, cliente);
                                      }
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
    Cliente? cliente,
  ]) async {
    final state = _state;
    final formKey = GlobalKey<FormState>();
    final nomeController = TextEditingController(text: cliente?.nome ?? '');
    final telefoneController = TextEditingController(
      text: cliente?.telefone ?? '',
    );
    final enderecoController = TextEditingController(
      text: cliente?.endereco ?? '',
    );
    final observacoesController = TextEditingController(
      text: cliente?.observacoes ?? '',
    );
    var salvando = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(cliente == null ? 'Novo cliente' : 'Editar cliente'),
              content: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: nomeController,
                          textCapitalization: TextCapitalization.words,
                          decoration: const InputDecoration(labelText: 'Nome'),
                          validator: (value) {
                            if ((value ?? '').trim().isEmpty) {
                              return 'Informe o nome.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: telefoneController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'Telefone',
                          ),
                          validator: (value) {
                            if ((value ?? '').trim().isEmpty) {
                              return 'Informe o telefone.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: enderecoController,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: const InputDecoration(
                            labelText: 'Endereço',
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: observacoesController,
                          minLines: 3,
                          maxLines: 5,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: const InputDecoration(
                            labelText: 'Observações',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: salvando
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancelar'),
                ),
                FilledButton.icon(
                  onPressed: salvando
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;
                          FocusScope.of(dialogContext).unfocus();
                          final navigator = Navigator.of(dialogContext);
                          final messenger = ScaffoldMessenger.of(
                            dialogContext,
                          );

                          final novoCliente = Cliente(
                            id: cliente?.id,
                            nome: nomeController.text.trim(),
                            telefone: telefoneController.text.trim(),
                            endereco: enderecoController.text.trim(),
                            observacoes: observacoesController.text.trim(),
                          );

                          setDialogState(() => salvando = true);
                          try {
                            await state.salvarCliente(novoCliente);

                            if (!dialogContext.mounted) return;

                            navigator.pop();
                          } catch (e) {
                            if (!dialogContext.mounted) return;
                            setDialogState(() => salvando = false);

                            messenger.showSnackBar(
                              SnackBar(
                                content: Text('Erro ao salvar cliente: $e'),
                              ),
                            );
                          }
                        },
                  icon: const Icon(Icons.check),
                  label: Text(salvando ? 'Salvando...' : 'Salvar'),
                ),
              ],
            );
          },
        );
      },
    );

    nomeController.dispose();
    telefoneController.dispose();
    enderecoController.dispose();
    observacoesController.dispose();
  }

  Future<void> _confirmarExclusao(BuildContext context, Cliente cliente) async {
    final state = _state;
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Excluir cliente'),
          content: Text('Remover ${cliente.nome}?'),
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
        await state.excluirCliente(cliente.id!);
      } catch (e) {
        if (!context.mounted) return;
        final erro = e.toString().toLowerCase();
        final temOrcamentoVinculado =
            erro.contains('orcamento') || erro.contains('orçamento');
        final mensagem = temOrcamentoVinculado
            ? 'Não é possível excluir este cliente porque há orçamento vinculado a ele.'
            : 'Erro ao excluir cliente: $e';
        final messenger = ScaffoldMessenger.of(context);
        messenger.showSnackBar(SnackBar(content: Text(mensagem)));
      }
    }
  }
}

class _EmptyClientes extends StatelessWidget {
  const _EmptyClientes({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.groups_2_outlined, size: 44),
              const SizedBox(height: 12),
              const Text('Nenhum cliente encontrado.'),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: onCreate,
                icon: const Icon(Icons.add),
                label: const Text('Cadastrar cliente'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
