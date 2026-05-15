import '../database/app_database.dart';
import '../models/item_orcamento_model.dart';
import '../models/orcamento_model.dart';

class OrcamentoRepository {
  Future<int> inserir({
    required Orcamento orcamento,
    required List<ItemOrcamento> itens,
  }) async {
    final db = await AppDatabase.instance.database;

    return db.transaction((txn) async {
      final orcamentoData = orcamento.toMap()..remove('id');

      final orcamentoId = await txn.insert(
        'orcamentos',
        orcamentoData,
      );

      for (final item in itens) {
        final itemData = item.toMap()
          ..remove('id')
          ..['orcamento_id'] = orcamentoId;

        await txn.insert('itens_orcamento', itemData);
      }

      return orcamentoId;
    });
  }

  Future<List<Orcamento>> listarTodos() async {
    final db = await AppDatabase.instance.database;

    final result = await db.query(
      'orcamentos',
      orderBy: 'data_criacao DESC',
    );

    return result.map(Orcamento.fromMap).toList();
  }

  Future<Orcamento?> buscarPorId(int id) async {
    final db = await AppDatabase.instance.database;

    final result = await db.query(
      'orcamentos',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (result.isEmpty) return null;

    return Orcamento.fromMap(result.first);
  }

  Future<List<ItemOrcamento>> listarItens(int orcamentoId) async {
    final db = await AppDatabase.instance.database;

    final result = await db.query(
      'itens_orcamento',
      where: 'orcamento_id = ?',
      whereArgs: [orcamentoId],
      orderBy: 'id ASC',
    );

    return result.map(ItemOrcamento.fromMap).toList();
  }

  Future<int> atualizarStatus({
    required int orcamentoId,
    required String status,
  }) async {
    final db = await AppDatabase.instance.database;

    return db.update(
      'orcamentos',
      {'status': status},
      where: 'id = ?',
      whereArgs: [orcamentoId],
    );
  }

  Future<int> excluir(int id) async {
    final db = await AppDatabase.instance.database;

    return db.delete(
      'orcamentos',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}