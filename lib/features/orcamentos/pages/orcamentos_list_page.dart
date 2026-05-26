import 'package:flutter/material.dart';

import '../../../app_state.dart';
import '../../../shared/formatters.dart';
import 'orcamento_detalhe_page.dart';
import 'orcamento_form_page.dart';

class OrcamentosListPage extends StatefulWidget {
  const OrcamentosListPage({super.key});

  @override
  State<OrcamentosListPage> createState() => _OrcamentosListPageState();
}

class _OrcamentosListPageState extends State<OrcamentosListPage> {
  late AppState _state;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _state = AppStateScope.of(context);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _state,
      builder: (context, _) {
        final theme = Theme.of(context);
        final total = _state.orcamentos.fold<double>(
          0,
          (sum, orcamento) => sum + orcamento.valorFinal,
        );
        final state = _state;

        return Scaffold(
          appBar: AppBar(title: const Text('Orçamentos')),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const OrcamentoFormPage())),
            icon: const Icon(Icons.add),
            label: const Text('Novo orçamento'),
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1040),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Propostas comerciais',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Acompanhe orçamentos com múltiplos itens, desconto e valor final.',
                        style: theme.textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _ResumoTile(
                            icon: Icons.request_quote_outlined,
                            label: 'Orçamentos',
                            value: '${state.orcamentos.length}',
                          ),
                          _ResumoTile(
                            icon: Icons.payments_outlined,
                            label: 'Valor total',
                            value: formatMoney(total),
                          ),
                          _ResumoTile(
                            icon: Icons.inventory_2_outlined,
                            label: 'Produtos no catálogo',
                            value: '${state.produtos.length}',
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: state.orcamentos.isEmpty
                            ? const _EmptyOrcamentos()
                            : ListView.separated(
                                itemCount: state.orcamentos.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(height: 10),
                                itemBuilder: (context, index) {
                                  final orcamento = state.orcamentos[index];
                                  final cliente = state.clientePorId(
                                    orcamento.clienteId,
                                  );
                                  return Card(
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: const Color(0xFFE3EFEA),
                                        foregroundColor: const Color(0xFF2F6F63),
                                        child: Text(
                                          (orcamento.id?.substring(0, 2) ?? '--').toUpperCase(),
                                        ),
                                      ),
                                      title: Text(
                                        cliente?.nome ?? 'Cliente removido',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      subtitle: Text(
                                        '${formatDate(orcamento.dataCriacao)} • '
                                        '${orcamento.itens.length} itens • '
                                        '${_statusLabel(orcamento.status)}',
                                      ),
                                      trailing: Wrap(
                                        spacing: 8,
                                        crossAxisAlignment:
                                            WrapCrossAlignment.center,
                                        children: [
                                          Text(
                                            formatMoney(orcamento.valorFinal),
                                            style: theme.textTheme.titleMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w900,
                                                ),
                                          ),
                                          IconButton(
                                            tooltip: 'Abrir orçamento',
                                            icon: const Icon(Icons.chevron_right),
                                            onPressed: () =>
                                                Navigator.of(context).push(
                                                  MaterialPageRoute(
                                                    builder: (_) =>
                                                        OrcamentoDetalhePage(
                                                          orcamentoId: orcamento.id!,
                                                        ),
                                                  ),
                                                ),
                                          ),
                                        ],
                                      ),
                                      onTap: () => Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => OrcamentoDetalhePage(
                                            orcamentoId: orcamento.id!,
                                          ),
                                        ),
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
      },
    );
  }
}

class _ResumoTile extends StatelessWidget {
  const _ResumoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 220,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE4DED4)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF2F6F63)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: theme.textTheme.labelMedium),
                Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyOrcamentos extends StatelessWidget {
  const _EmptyOrcamentos();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.request_quote_outlined, size: 48),
              const SizedBox(height: 12),
              const Text('Nenhum orçamento criado ainda.'),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const OrcamentoFormPage()),
                ),
                icon: const Icon(Icons.add),
                label: const Text('Criar orçamento'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _statusLabel(String status) {
  return switch (status) {
    'enviado' => 'Enviado',
    'aprovado' => 'Aprovado',
    'recusado' => 'Recusado',
    _ => 'Em aberto',
  };
}
