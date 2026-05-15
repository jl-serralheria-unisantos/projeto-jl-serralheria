import 'package:flutter/material.dart';

class OrcamentosListPage extends StatelessWidget {
  const OrcamentosListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Orçamentos'),
      ),
      body: const Center(
        child: Text('Tela de orçamentos'),
      ),
    );
  }
}