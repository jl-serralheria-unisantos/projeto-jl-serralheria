import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/servico_model.dart';

class ServicoRepository {
  final _col = FirebaseFirestore.instance.collection('servicos');

  Future<String> inserir(Servico servico) async {
    final doc = await _col.add(servico.toFirestore());
    return doc.id;
  }

  Future<List<Servico>> listarTodos() async {
    final snapshot = await _col.orderBy('nome').get();
    return snapshot.docs.map(Servico.fromFirestore).toList();
  }

  Future<void> atualizar(Servico servico) async {
    if (servico.id == null) {
      throw ArgumentError('Serviço sem id não pode ser atualizado.');
    }
    await _col.doc(servico.id).update(servico.toFirestore());
  }

  Future<void> excluir(String id) async {
    await _col.doc(id).delete();
  }
}
