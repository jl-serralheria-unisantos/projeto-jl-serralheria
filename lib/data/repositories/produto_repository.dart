import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/produto_model.dart';

class ProdutoRepository {
  final _col = FirebaseFirestore.instance.collection('produtos');

  Future<String> inserir(Produto produto) async {
    final doc = await _col.add(produto.toFirestore());
    return doc.id;
  }

  Future<List<Produto>> listarTodos() async {
    final snapshot = await _col.orderBy('nome').get();
    final lista = snapshot.docs.map(Produto.fromFirestore).toList();
    // Ordena localmente por categoria depois nome (evita índice composto)
    lista.sort((a, b) {
      final cat = a.categoria.compareTo(b.categoria);
      if (cat != 0) return cat;
      return (a.codigo ?? a.nome).compareTo(b.codigo ?? b.nome);
    });
    return lista;
  }

  Future<void> atualizar(Produto produto) async {
    if (produto.id == null) {
      throw ArgumentError('Produto sem id não pode ser atualizado.');
    }
    await _col.doc(produto.id).update(produto.toFirestore());
  }

  Future<void> excluir(String id) async {
    await _col.doc(id).delete();
  }
}
