import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/orcamento_model.dart';

class OrcamentoRepository {
  final _col = FirebaseFirestore.instance.collection('orcamentos');

  Future<String> inserir(Orcamento orcamento) async {
    final doc = await _col.add(orcamento.toFirestore());
    return doc.id;
  }

  Future<void> atualizar(Orcamento orcamento) async {
    final id = orcamento.id;
    if (id == null) {
      throw ArgumentError('Orcamento sem id nao pode ser atualizado.');
    }
    await _col.doc(id).update(orcamento.toFirestore());
  }

  Future<List<Orcamento>> listarTodos() async {
    final snapshot = await _col.orderBy('data_criacao', descending: true).get();
    return snapshot.docs.map(Orcamento.fromFirestore).toList();
  }

  Future<Orcamento?> buscarPorId(String id) async {
    final doc = await _col.doc(id).get();
    if (!doc.exists) return null;
    return Orcamento.fromFirestore(doc);
  }

  Future<void> atualizarStatus({
    required String orcamentoId,
    required String status,
  }) async {
    await _col.doc(orcamentoId).update({'status': status});
  }

  Future<void> excluir(String id) async {
    await _col.doc(id).delete();
  }
}
