import '../database/app_database.dart';
import '../models/cliente_model.dart';

class ClienteRepository {
  Future<int> inserir(Cliente cliente) async {
    final db = await AppDatabase.instance.database;
    final data = cliente.toMap()..remove('id');

    return db.insert('clientes', data);
  }

  Future<List<Cliente>> listarTodos() async {
    final db = await AppDatabase.instance.database;

    final result = await db.query(
      'clientes',
      orderBy: 'nome ASC',
    );

    return result.map(Cliente.fromMap).toList();
  }

  Future<Cliente?> buscarPorId(int id) async {
    final db = await AppDatabase.instance.database;

    final result = await db.query(
      'clientes',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (result.isEmpty) return null;

    return Cliente.fromMap(result.first);
  }

  Future<int> atualizar(Cliente cliente) async {
    final db = await AppDatabase.instance.database;

    if (cliente.id == null) {
      throw ArgumentError('Cliente sem id não pode ser atualizado.');
    }

    final data = cliente.toMap()..remove('id');

    return db.update(
      'clientes',
      data,
      where: 'id = ?',
      whereArgs: [cliente.id],
    );
  }

  Future<int> excluir(int id) async {
    final db = await AppDatabase.instance.database;

    return db.delete(
      'clientes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}