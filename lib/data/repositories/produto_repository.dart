import '../database/app_database.dart';
import '../models/produto_model.dart';

class ProdutoRepository {
  Future<int> inserir(Produto produto) async {
    final db = await AppDatabase.instance.database;
    final data = produto.toMap()..remove('id');

    return db.insert('produtos', data);
  }

  Future<List<Produto>> listarTodos() async {
    final db = await AppDatabase.instance.database;

    final result = await db.query(
      'produtos',
      orderBy: 'categoria ASC, nome ASC',
    );

    return result.map(Produto.fromMap).toList();
  }

  Future<List<Produto>> listarAtivos() async {
    final db = await AppDatabase.instance.database;

    final result = await db.query(
      'produtos',
      where: 'ativo = ?',
      whereArgs: [1],
      orderBy: 'categoria ASC, nome ASC',
    );

    return result.map(Produto.fromMap).toList();
  }

  Future<Produto?> buscarPorId(int id) async {
    final db = await AppDatabase.instance.database;

    final result = await db.query(
      'produtos',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (result.isEmpty) return null;

    return Produto.fromMap(result.first);
  }

  Future<int> atualizar(Produto produto) async {
    final db = await AppDatabase.instance.database;

    if (produto.id == null) {
      throw ArgumentError('Produto sem id não pode ser atualizado.');
    }

    final data = produto.toMap()..remove('id');

    return db.update(
      'produtos',
      data,
      where: 'id = ?',
      whereArgs: [produto.id],
    );
  }

  Future<int> excluir(int id) async {
    final db = await AppDatabase.instance.database;

    return db.delete(
      'produtos',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}