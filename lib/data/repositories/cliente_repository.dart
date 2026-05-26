import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/cliente_model.dart';

class ClienteRepository {
  final _col = FirebaseFirestore.instance.collection('clientes');

  Future<String> inserir(Cliente cliente) async {
    final doc = await _col.add(cliente.toFirestore());
    return doc.id;
  }

  Future<List<Cliente>> listarTodos() async {
    final snapshot = await _col.orderBy('nome').get();
    return snapshot.docs.map(Cliente.fromFirestore).toList();
  }

  Future<Cliente?> buscarPorId(String id) async {
    final doc = await _col.doc(id).get();
    if (!doc.exists) return null;
    return Cliente.fromFirestore(doc);
  }

  Future<void> atualizar(Cliente cliente) async {
    if (cliente.id == null) {
      throw ArgumentError('Cliente sem id não pode ser atualizado.');
    }
    await _col.doc(cliente.id).update(cliente.toFirestore());
  }

  Future<void> excluir(String id) async {
    await _col.doc(id).delete();
  }
}
