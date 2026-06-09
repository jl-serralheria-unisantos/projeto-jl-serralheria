import 'package:flutter/material.dart';

import '../../../app_state.dart';
import '../../../data/models/cliente_model.dart';
import '../../../data/models/orcamento_model.dart';
import '../../../shared/formatters.dart';
import '../../pdf/services/pdf_service.dart';
import 'orcamento_form_page.dart';

class OrcamentoDetalhePage extends StatefulWidget {
  const OrcamentoDetalhePage({super.key, required this.orcamentoId});

  final String orcamentoId;

  @override
  State<OrcamentoDetalhePage> createState() => _OrcamentoDetalhePageState();
}

class _OrcamentoDetalhePageState extends State<OrcamentoDetalhePage> {
  final _pdfService = const PdfService();
  late AppState _state;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _state = AppStateScope.read(context);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _state,
      builder: (context, _) {
        final orcamento = _state.orcamentoPorId(widget.orcamentoId);

        if (orcamento == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Orçamento')),
            body: const Center(child: Text('Orçamento não encontrado.')),
          );
        }

        final cliente = _state.clientePorId(orcamento.clienteId);
        final theme = Theme.of(context);

        return Scaffold(
          appBar: AppBar(
            title: Text(_tituloOrcamento(cliente, orcamento)),
            actions: [
              IconButton(
                tooltip: 'Editar orçamento',
                icon: const Icon(Icons.edit_outlined),
                onPressed: orcamento.id == null
                    ? null
                    : () => _editarOrcamento(context, orcamento.id!),
              ),
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
                              final clienteBox = _ClienteResumo(
                                cliente: cliente,
                              );
                              final statusBox = _StatusResumo(
                                orcamento: orcamento,
                                state: _state,
                                onVisualizarPdf: () => _visualizarPdf(
                                  context,
                                  orcamento,
                                  cliente,
                                ),
                                onCompartilharPdf: () => _compartilharPdf(
                                  context,
                                  orcamento,
                                  cliente,
                                ),
                              );
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w900),
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
                                      style: theme.textTheme.titleLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.w800,
                                          ),
                                    ),
                                  ),
                                  Text(
                                    formatMoney(orcamento.valorFinal),
                                    style: theme.textTheme.headlineSmall
                                        ?.copyWith(
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
      },
    );
  }

  void _editarOrcamento(BuildContext context, String orcamentoId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OrcamentoFormPage(orcamentoId: orcamentoId),
      ),
    );
  }

  Future<void> _visualizarPdf(
    BuildContext context,
    Orcamento orcamento,
    Cliente? cliente,
  ) async {
    await _executarAcaoPdf(
      context,
      () => _pdfService.visualizarOrcamento(
        orcamento: orcamento,
        cliente: cliente,
      ),
    );
  }

  Future<void> _compartilharPdf(
    BuildContext context,
    Orcamento orcamento,
    Cliente? cliente,
  ) async {
    await _executarAcaoPdf(
      context,
      () => _pdfService.compartilharOrcamento(
        orcamento: orcamento,
        cliente: cliente,
      ),
    );
  }

  Future<void> _executarAcaoPdf(
    BuildContext context,
    Future<void> Function() acao,
  ) async {
    try {
      await acao();
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao gerar PDF: $e')),
      );
    }
  }

  Future<void> _confirmarExclusao(BuildContext context, String? id) async {
    if (id == null) return;
    final state = _state;
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
      try {
        await state.excluirOrcamento(id);
        if (!context.mounted) return;
        Navigator.of(context).pop();
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao excluir orçamento: $e')),
        );
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
  const _StatusResumo({
    required this.orcamento,
    required this.state,
    required this.onVisualizarPdf,
    required this.onCompartilharPdf,
  });

  final Orcamento orcamento;
  final AppState state;
  final VoidCallback onVisualizarPdf;
  final VoidCallback onCompartilharPdf;

  @override
  Widget build(BuildContext context) {
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
          onChanged: (value) async {
            final id = orcamento.id;
            if (value == null || id == null) return;
            try {
              await state.atualizarStatusOrcamento(id, value);
            } catch (e) {
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Erro ao atualizar status: $e')),
              );
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
          icon: Icons.tag_outlined,
          label: 'Ref. ${_idCurto(orcamento.id, 6)}',
        ),
        const SizedBox(height: 8),
        _InfoChip(
          icon: Icons.event_available_outlined,
          label: 'Validade: ${orcamento.validadeDias} dias',
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: onVisualizarPdf,
            icon: const Icon(Icons.picture_as_pdf_outlined),
            label: const Text('Visualizar PDF'),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: onCompartilharPdf,
            icon: const Icon(Icons.share_outlined),
            label: const Text('Compartilhar PDF'),
          ),
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

String _idCurto(String? id, int tamanho) {
  if (id == null || id.isEmpty) return '---';
  final limite = id.length < tamanho ? id.length : tamanho;
  return id.substring(0, limite).toUpperCase();
}

String _tituloOrcamento(Cliente? cliente, Orcamento orcamento) {
  if (cliente != null) return 'Orçamento - ${cliente.nome}';
  return 'Orçamento de ${formatDate(orcamento.dataCriacao)}';
}
