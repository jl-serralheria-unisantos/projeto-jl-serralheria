import 'package:flutter/material.dart';

import '../../../app_state.dart';
import '../../../data/models/orcamento_model.dart';
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
    _state = AppStateScope.read(context);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _state,
      builder: (context, _) {
        final theme = Theme.of(context);
        final total = _state.totalEmPropostas;
        final state = _state;
        const statusTabs = [
          _StatusTab(
            status: 'em_aberto',
            label: 'Em aberto',
            emptyLabel: 'em aberto',
          ),
          _StatusTab(
            status: 'enviado',
            label: 'Enviados',
            emptyLabel: 'enviado',
          ),
          _StatusTab(
            status: 'aprovado',
            label: 'Aprovados',
            emptyLabel: 'aprovado',
          ),
          _StatusTab(
            status: 'recusado',
            label: 'Recusados',
            emptyLabel: 'recusado',
          ),
        ];

        return DefaultTabController(
          length: statusTabs.length,
          child: Scaffold(
            appBar: AppBar(title: const Text('Orçamentos')),
            floatingActionButton: FloatingActionButton.extended(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const OrcamentoFormPage()),
              ),
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
                          'Acompanhe orçamentos por status, valor e andamento.',
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
                              icon: Icons.check_circle_outline,
                              label: 'Aprovados',
                              value:
                                  '${_orcamentosPorStatus(state, 'aprovado').length}',
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Material(
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: const BorderSide(color: Color(0xFFE4DED4)),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: TabBar(
                            isScrollable: true,
                            tabs: statusTabs.map((tab) {
                              final count = _orcamentosPorStatus(
                                state,
                                tab.status,
                              ).length;
                              return Tab(text: '${tab.label} ($count)');
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: state.orcamentos.isEmpty
                              ? const _EmptyOrcamentos()
                              : TabBarView(
                                  children: statusTabs.map((tab) {
                                    final orcamentos = _orcamentosPorStatus(
                                      state,
                                      tab.status,
                                    );
                                    if (orcamentos.isEmpty) {
                                      return _EmptyStatusOrcamentos(
                                        statusLabel: tab.emptyLabel,
                                      );
                                    }
                                    return ListView.separated(
                                      itemCount: orcamentos.length,
                                      separatorBuilder: (_, _) =>
                                          const SizedBox(height: 10),
                                      itemBuilder: (context, index) {
                                        return _buildOrcamentoCard(
                                          context,
                                          orcamentos[index],
                                        );
                                      },
                                    );
                                  }).toList(),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _abrirDetalhe(BuildContext context, String orcamentoId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OrcamentoDetalhePage(orcamentoId: orcamentoId),
      ),
    );
  }

  void _abrirEdicao(BuildContext context, String orcamentoId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OrcamentoFormPage(orcamentoId: orcamentoId),
      ),
    );
  }

  List<Orcamento> _orcamentosPorStatus(AppState state, String status) {
    return state.orcamentos
        .where((orcamento) => orcamento.status == status)
        .toList(growable: false);
  }

  Widget _buildOrcamentoCard(BuildContext context, Orcamento orcamento) {
    final theme = Theme.of(context);
    final state = _state;
    final orcamentoId = orcamento.id;
    final cliente = state.clientePorId(orcamento.clienteId);
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFE3EFEA),
          foregroundColor: const Color(0xFF2F6F63),
          child: Text(_idCurto(orcamentoId, 2)),
        ),
        title: Text(
          _tituloOrcamento(cliente?.nome, orcamento.dataCriacao),
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text(
          '${cliente?.nome ?? 'Cliente removido'} • '
          '${formatDate(orcamento.dataCriacao)} • '
          '${orcamento.itens.length} itens • '
          'Ref. ${_idCurto(orcamentoId, 6)}',
        ),
        trailing: Wrap(
          spacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              formatMoney(orcamento.valorFinal),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            IconButton(
              tooltip: 'Editar orçamento',
              icon: const Icon(Icons.edit_outlined),
              onPressed: orcamentoId == null
                  ? null
                  : () => _abrirEdicao(context, orcamentoId),
            ),
            IconButton(
              tooltip: 'Abrir orçamento',
              icon: const Icon(Icons.chevron_right),
              onPressed: orcamentoId == null
                  ? null
                  : () => _abrirDetalhe(context, orcamentoId),
            ),
          ],
        ),
        onTap: orcamentoId == null
            ? null
            : () => _abrirDetalhe(context, orcamentoId),
      ),
    );
  }
}

class _StatusTab {
  const _StatusTab({
    required this.status,
    required this.label,
    required this.emptyLabel,
  });

  final String status;
  final String label;
  final String emptyLabel;
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

class _EmptyStatusOrcamentos extends StatelessWidget {
  const _EmptyStatusOrcamentos({required this.statusLabel});

  final String statusLabel;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('Nenhum orçamento $statusLabel.'),
        ),
      ),
    );
  }
}

String _idCurto(String? id, int tamanho) {
  if (id == null || id.isEmpty) return '--';
  final limite = id.length < tamanho ? id.length : tamanho;
  return id.substring(0, limite).toUpperCase();
}

String _tituloOrcamento(String? clienteNome, DateTime dataCriacao) {
  if (clienteNome != null) return 'Orçamento - $clienteNome';
  return 'Orçamento de ${formatDate(dataCriacao)}';
}
