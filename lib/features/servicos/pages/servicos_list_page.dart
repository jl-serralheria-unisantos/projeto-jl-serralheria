import 'package:flutter/material.dart';

class ServicosListPage extends StatelessWidget {
  const ServicosListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Serviços'),
      ),
      body: const Center(
        child: Text('Tela de serviços'),
      ),
    );
  }
}