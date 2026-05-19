import 'package:flutter/material.dart';

import '../../../app_state.dart';
import '../../../data/models/servico_model.dart';
import '../../../shared/formatters.dart';

class ServicosListPage extends StatefulWidget {
  const ServicosListPage({super.key});

  @override
  State<ServicosListPage> createState() => _ServicosListPageState();
}

class _ServicosListPageState extends State<ServicosListPage> {
  final TextEditingController _buscaController = TextEditingController();
  String _busca = '';

  @override
  void dispose() {
    _buscaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final servicos = state.servicos
        .where((servico) {
          final termo = _busca.toLowerCase();
          return servico.nome.toLowerCase().contains(termo) ||
              servico.unidade.toLowerCase().contains(termo) ||
              (servico.observacoes ?? '').toLowerCase().contains(termo);
        })
        .toList(growable: false);

    return Scaffold(
      appBar: AppBar(title: const Text('Serviços')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrirFormulario(context),
        icon: const Icon(Icons.add_task_outlined),
        label: const Text('Novo serviço'),
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
                    'Serviços recorrentes',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Cadastre mão de obra, instalação, frete e outras cobranças reutilizáveis.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _buscaController,
                    onChanged: (value) => setState(() => _busca = value),
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      labelText: 'Buscar serviço',
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: servicos.isEmpty
                        ? const _EmptyServicos()
                        : ListView.separated(
                            itemCount: servicos.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final servico = servicos[index];
                              return Card(
                                child: ListTile(
                                  leading: Icon(
                                    servico.ativo
                                        ? Icons.handyman_outlined
                                        : Icons.pause_circle_outline,
                                    color: servico.ativo
                                        ? const Color(0xFF8C4F24)
                                        : Colors.orange,
                                  ),
                                  title: Text(
                                    servico.nome,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  subtitle: Text(
                                    [
                                      servico.unidade,
                                      if ((servico.observacoes ?? '')
                                          .isNotEmpty)
                                        servico.observacoes!,
                                    ].join(' • '),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  trailing: Wrap(
                                    spacing: 8,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    children: [
                                      Text(
                                        formatMoney(servico.valorBase),
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w900,
                                            ),
                                      ),
                                      PopupMenuButton<String>(
                                        tooltip: 'Ações do serviço',
                                        onSelected: (value) {
                                          if (value == 'edit') {
                                            _abrirFormulario(context, servico);
                                          }
                                          if (value == 'delete') {
                                            _confirmarExclusao(
                                              context,
                                              servico,
                                            );
                                          }
                                        },
                                        itemBuilder: (context) => const [
                                          PopupMenuItem(
                                            value: 'edit',
                                            child: ListTile(
                                              leading: Icon(
                                                Icons.edit_outlined,
                                              ),
                                              title: Text('Editar'),
                                            ),
                                          ),
                                          PopupMenuItem(
                                            value: 'delete',
                                            child: ListTile(
                                              leading: Icon(
                                                Icons.delete_outline,
                                              ),
                                              title: Text('Excluir'),
                                            ),
                                          ),
                                        ],
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
    Servico? servico,
  ]) async {
    final state = AppStateScope.read(context);
    final formKey = GlobalKey<FormState>();
    final nomeController = TextEditingController(text: servico?.nome ?? '');
    final unidadeController = TextEditingController(
      text: servico?.unidade ?? 'serviço',
    );
    final valorController = TextEditingController(
      text: servico == null ? '' : decimalText(servico.valorBase),
    );
    final observacoesController = TextEditingController(
      text: servico?.observacoes ?? '',
    );
    var ativo = servico?.ativo ?? true;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(servico == null ? 'Novo serviço' : 'Editar serviço'),
              content: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
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
                        Row(
                          children: [
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
                                  labelText: 'Valor base',
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: observacoesController,
                          minLines: 3,
                          maxLines: 5,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: const InputDecoration(
                            labelText: 'Descrição',
                          ),
                        ),
                        const SizedBox(height: 8),
                        SwitchListTile(
                          value: ativo,
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Serviço ativo para orçamento'),
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
                  onPressed: () {
                    if (!formKey.currentState!.validate()) return;
                    state.salvarServico(
                      Servico(
                        id: servico?.id,
                        nome: nomeController.text.trim(),
                        unidade: unidadeController.text.trim(),
                        valorBase: parseDecimal(valorController.text),
                        observacoes: observacoesController.text.trim(),
                        ativo: ativo,
                      ),
                    );
                    Navigator.of(dialogContext).pop();
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
    unidadeController.dispose();
    valorController.dispose();
    observacoesController.dispose();
  }

  Future<void> _confirmarExclusao(BuildContext context, Servico servico) async {
    final state = AppStateScope.read(context);
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Excluir serviço'),
          content: Text('Remover ${servico.nome}?'),
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
      state.excluirServico(servico.id!);
    }
  }
}

class _EmptyServicos extends StatelessWidget {
  const _EmptyServicos();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('Nenhum serviço encontrado.'),
        ),
      ),
    );
  }
}
