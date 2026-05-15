import 'package:flutter/material.dart';

import 'features/clientes/pages/clientes_list_page.dart';
import 'features/orcamentos/pages/orcamentos_list_page.dart';
import 'features/produtos/pages/produtos_list_page.dart';
import 'features/servicos/pages/servicos_list_page.dart';

class SerralheriaApp extends StatelessWidget {
  const SerralheriaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'JL Serralheria',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.blueGrey,
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  void _abrirTela(BuildContext context, Widget page) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => page,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('JL Serralheria'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: () => _abrirTela(
                context,
                const ClientesListPage(),
              ),
              child: const Text('Clientes'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => _abrirTela(
                context,
                const ProdutosListPage(),
              ),
              child: const Text('Produtos'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => _abrirTela(
                context,
                const ServicosListPage(),
              ),
              child: const Text('Serviços'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => _abrirTela(
                context,
                const OrcamentosListPage(),
              ),
              child: const Text('Orçamentos'),
            ),
          ],
        ),
      ),
    );
  }
}