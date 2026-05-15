import 'package:flutter/material.dart';

class ProdutosListPage extends StatelessWidget {
  const ProdutosListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Produtos'),
      ),
      body: const Center(
        child: Text('Tela de produtos'),
      ),
    );
  }
}