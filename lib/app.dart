import 'package:flutter/material.dart';

import 'app_state.dart';
import 'features/clientes/pages/clientes_list_page.dart';
import 'features/orcamentos/pages/orcamento_form_page.dart';
import 'features/orcamentos/pages/orcamentos_list_page.dart';
import 'features/produtos/pages/produtos_list_page.dart';
import 'features/servicos/pages/servicos_list_page.dart';
import 'shared/formatters.dart';

class SerralheriaApp extends StatefulWidget {
  const SerralheriaApp({super.key});

  @override
  State<SerralheriaApp> createState() => _SerralheriaAppState();
}

class _SerralheriaAppState extends State<SerralheriaApp> {
  late final AppState _state = AppState();

  @override
  void dispose() {
    _state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF2F6F63);

    return AppStateScope(
      state: _state,
      child: MaterialApp(
        title: 'JL Serralheria',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: seed,
            brightness: Brightness.light,
          ),
          scaffoldBackgroundColor: const Color(0xFFF7F4EF),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            centerTitle: false,
            elevation: 0,
            backgroundColor: Color(0xFFF7F4EF),
            foregroundColor: Color(0xFF1D2B29),
          ),
          cardTheme: CardThemeData(
            elevation: 0,
            color: Colors.white,
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: const BorderSide(color: Color(0xFFE4DED4)),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFD8D2C8)),
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            ),
          ),
          floatingActionButtonTheme: const FloatingActionButtonThemeData(
            backgroundColor: Color(0xFFB56B1E),
            foregroundColor: Colors.white,
          ),
        ),
        home: ListenableBuilder(
          listenable: _state,
          builder: (context, _) {
            if (_state.carregando) return const _LoadingPage();
            if (_state.erroCarregamento != null) {
              return _ErrorPage(
                erro: _state.erroCarregamento!,
                onRetry: () => _state.carregarTudo(),
              );
            }
            return const HomePage();
          },
        ),
      ),
    );
  }
}

class _LoadingPage extends StatelessWidget {
  const _LoadingPage();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Carregando dados...'),
          ],
        ),
      ),
    );
  }
}

class _ErrorPage extends StatelessWidget {
  const _ErrorPage({required this.erro, required this.onRetry});

  final String erro;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'Erro ao conectar com o Firebase',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Text(
                  erro,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late AppState _state;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _state = AppStateScope.of(context);
  }

  void _abrirTela(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _state,
      builder: (context, _) {
        final state = _state;
        final theme = Theme.of(context);
        final isCompact = MediaQuery.sizeOf(context).width < 560;
        final totalAberto = state.orcamentos.fold<double>(
          0,
          (total, orcamento) => total + orcamento.valorFinal,
        );

        return Scaffold(
          appBar: AppBar(
            title: const Text('JL Serralheria'),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: isCompact
                    ? IconButton.filled(
                        tooltip: 'Novo orçamento',
                        onPressed: () =>
                            _abrirTela(context, const OrcamentoFormPage()),
                        icon: const Icon(Icons.add),
                      )
                    : FilledButton.icon(
                        onPressed: () =>
                            _abrirTela(context, const OrcamentoFormPage()),
                        icon: const Icon(Icons.add),
                        label: const Text('Novo orçamento'),
                      ),
              ),
            ],
          ),
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 900;
                final horizontalPadding = isWide ? 32.0 : 16.0;
                final availableWidth =
                    constraints.maxWidth - (horizontalPadding * 2);
                final contentWidth = availableWidth > 1180
                    ? 1180.0
                    : availableWidth;
                final useFourColumnCards = contentWidth >= 1000;
                final double cardAspectRatio;
                if (useFourColumnCards) {
                  cardAspectRatio = 1.55;
                } else if (contentWidth < 520) {
                  cardAspectRatio = 0.95;
                } else {
                  cardAspectRatio = 1.6;
                }
                return SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: 16,
                  ),
                  child: Center(
                    child: SizedBox(
                      width: contentWidth,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _HeaderPanel(totalAberto: totalAberto),
                          const SizedBox(height: 20),
                          GridView.count(
                            crossAxisCount: useFourColumnCards ? 4 : 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            childAspectRatio: cardAspectRatio,
                            children: [
                              _HomeActionCard(
                                icon: Icons.groups_2_outlined,
                                title: 'Clientes',
                                value: '${state.clientes.length}',
                                description: 'Nome, telefone e observações',
                                color: const Color(0xFF2F6F63),
                                onTap: () => _abrirTela(
                                  context,
                                  const ClientesListPage(),
                                ),
                              ),
                              _HomeActionCard(
                                icon: Icons.inventory_2_outlined,
                                title: 'Produtos',
                                value: '${state.produtos.length}',
                                description: 'Perfis do catálogo PDF',
                                color: const Color(0xFF6E5B32),
                                onTap: () => _abrirTela(
                                  context,
                                  const ProdutosListPage(),
                                ),
                              ),
                              _HomeActionCard(
                                icon: Icons.handyman_outlined,
                                title: 'Serviços',
                                value: '${state.servicos.length}',
                                description: 'Mão de obra e recorrências',
                                color: const Color(0xFF8C4F24),
                                onTap: () => _abrirTela(
                                  context,
                                  const ServicosListPage(),
                                ),
                              ),
                              _HomeActionCard(
                                icon: Icons.request_quote_outlined,
                                title: 'Orçamentos',
                                value: '${state.orcamentos.length}',
                                description: 'Subtotal, desconto e total',
                                color: const Color(0xFF3F5F88),
                                onTap: () => _abrirTela(
                                  context,
                                  const OrcamentosListPage(),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              _MetricPill(
                                icon: Icons.picture_as_pdf_outlined,
                                label: 'Catálogos usados',
                                value: '2 PDFs',
                              ),
                              _MetricPill(
                                icon: Icons.straighten_outlined,
                                label: 'Linhas cadastradas',
                                value: '${state.categoriasProdutos.length}',
                              ),
                              _MetricPill(
                                icon: Icons.payments_outlined,
                                label: 'Total em propostas',
                                value: formatMoney(totalAberto),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Linhas do catálogo',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: state.categoriasProdutos.take(18).map((
                              categoria,
                            ) {
                              return ActionChip(
                                avatar: const Icon(
                                  Icons.category_outlined,
                                  size: 18,
                                ),
                                label: Text(categoria),
                                onPressed: () => _abrirTela(
                                  context,
                                  ProdutosListPage(categoriaInicial: categoria),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Últimos orçamentos',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 10),
                          if (state.orcamentos.isEmpty)
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(18),
                                child: Row(
                                  children: [
                                    const Icon(Icons.request_quote_outlined),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'Nenhum orçamento criado ainda.',
                                        style: theme.textTheme.bodyLarge,
                                      ),
                                    ),
                                    TextButton.icon(
                                      onPressed: () => _abrirTela(
                                        context,
                                        const OrcamentoFormPage(),
                                      ),
                                      icon: const Icon(Icons.add),
                                      label: const Text('Criar'),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            Column(
                              children: state.orcamentos.take(3).map((
                                orcamento,
                              ) {
                                final cliente = state.clientePorId(
                                  orcamento.clienteId,
                                );
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: Card(
                                    child: ListTile(
                                      leading: const Icon(
                                        Icons.description_outlined,
                                      ),
                                      title: Text(
                                        'Orçamento #${(orcamento.id ?? '').substring(0, (orcamento.id ?? '').length.clamp(0, 6)).toUpperCase()}',
                                      ),
                                      subtitle: Text(
                                        '${cliente?.nome ?? 'Cliente removido'} • ${formatDate(orcamento.dataCriacao)}',
                                      ),
                                      trailing: Text(
                                        formatMoney(orcamento.valorFinal),
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w800,
                                            ),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _HeaderPanel extends StatelessWidget {
  const _HeaderPanel({required this.totalAberto});

  final double totalAberto;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1F3D38),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF17302C)),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        runSpacing: 16,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gestão de orçamentos da serralheria',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Clientes, catálogo de perfis Alumax, serviços recorrentes e propostas em uma rotina única.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: const Color(0xFFDCE8E3),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF5E8),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Em propostas',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: const Color(0xFF5B3C1C),
                  ),
                ),
                Text(
                  formatMoney(totalAberto),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: const Color(0xFF5B3C1C),
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

class _HomeActionCard extends StatelessWidget {
  const _HomeActionCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.description,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String value;
  final String description;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: color),
                  ),
                  const Spacer(),
                  Text(
                    value,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: color,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE4DED4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: const Color(0xFF2F6F63)),
          const SizedBox(width: 8),
          Text(label, style: theme.textTheme.bodyMedium),
          const SizedBox(width: 10),
          Text(
            value,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
