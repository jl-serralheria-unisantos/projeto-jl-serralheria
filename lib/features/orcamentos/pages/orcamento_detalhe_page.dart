import 'package:flutter/material.dart';

import '../../../app_state.dart';
import '../../../data/models/cliente_model.dart';
import '../../../shared/formatters.dart';

class OrcamentoDetalhePage extends StatelessWidget {
  const OrcamentoDetalhePage({super.key, required this.orcamentoId});

  final int orcamentoId;

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final orcamento = state.orcamentoPorId(orcamentoId);

    if (orcamento == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Orçamento')),
        body: const Center(child: Text('Orçamento não encontrado.')),
      );
    }

    final cliente = state.clientePorId(orcamento.clienteId);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Orçamento #${orcamento.id.toString().padLeft(3, '0')}'),
        actions: [
          IconButton(
            tooltip: 'Excluir orçamento',
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _confirmarExclusao(context, orcamento.id),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1040),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final isWide = constraints.maxWidth >= 760;
                          final clienteBox = _ClienteResumo(cliente: cliente);
                          final statusBox = _StatusResumo(orcamento: orcamento);
                          if (isWide) {
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: clienteBox),
                                const SizedBox(width: 18),
                                SizedBox(width: 300, child: statusBox),
                              ],
                            );
                          }
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              clienteBox,
                              const SizedBox(height: 16),
                              statusBox,
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Itens',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...orcamento.itens.map((item) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                _iconForTipo(item.tipo),
                                color: const Color(0xFF2F6F63),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.descricao,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${decimalText(item.quantidade)} ${item.unidade} × ${formatMoney(item.valorUnitario)}',
                                    ),
                                    if ((item.observacoes ?? '')
                                        .isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        item.observacoes!,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.textTheme.bodySmall,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                formatMoney(item.subtotal),
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 8),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        children: [
                          _TotalLinha(
                            label: 'Subtotal',
                            value: formatMoney(orcamento.subtotal),
                          ),
                          _TotalLinha(
                            label: 'Desconto',
                            value: formatMoney(orcamento.desconto),
                          ),
                          const Divider(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Valor final',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              Text(
                                formatMoney(orcamento.valorFinal),
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  color: const Color(0xFF2F6F63),
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (orcamento.observacoes.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Observações',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(orcamento.observacoes),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmarExclusao(BuildContext context, int id) async {
    final state = AppStateScope.read(context);
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Excluir orçamento'),
          content: const Text('Remover esta proposta?'),
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
      state.excluirOrcamento(id);
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    }
  }
}

class _ClienteResumo extends StatelessWidget {
  const _ClienteResumo({required this.cliente});

  final Cliente? cliente;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cliente',
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          cliente?.nome ?? 'Cliente removido',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        if (cliente != null)
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _InfoChip(icon: Icons.phone_outlined, label: cliente!.telefone),
              if ((cliente!.endereco ?? '').isNotEmpty)
                _InfoChip(
                  icon: Icons.place_outlined,
                  label: cliente!.endereco!,
                ),
            ],
          ),
      ],
    );
  }
}

class _StatusResumo extends StatelessWidget {
  const _StatusResumo({required this.orcamento});

  final OrcamentoRegistro orcamento;

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.read(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          initialValue: orcamento.status,
          decoration: const InputDecoration(labelText: 'Status'),
          items: const [
            DropdownMenuItem(value: 'em_aberto', child: Text('Em aberto')),
            DropdownMenuItem(value: 'enviado', child: Text('Enviado')),
            DropdownMenuItem(value: 'aprovado', child: Text('Aprovado')),
            DropdownMenuItem(value: 'recusado', child: Text('Recusado')),
          ],
          onChanged: (value) {
            if (value != null) {
              state.atualizarStatusOrcamento(orcamento.id, value);
            }
          },
        ),
        const SizedBox(height: 12),
        _InfoChip(
          icon: Icons.today_outlined,
          label: formatDate(orcamento.dataCriacao),
        ),
        const SizedBox(height: 8),
        _InfoChip(
          icon: Icons.event_available_outlined,
          label: 'Validade: ${orcamento.validadeDias} dias',
        ),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F4EF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE4DED4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [Icon(icon, size: 16), const SizedBox(width: 6), Text(label)],
      ),
    );
  }
}

class _TotalLinha extends StatelessWidget {
  const _TotalLinha({required this.label, required this.value});

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

IconData _iconForTipo(String tipo) {
  return switch (tipo) {
    'produto' => Icons.inventory_2_outlined,
    'servico' => Icons.handyman_outlined,
    _ => Icons.edit_note_outlined,
  };
}
