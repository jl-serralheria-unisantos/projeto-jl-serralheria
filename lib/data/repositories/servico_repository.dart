import '../database/app_database.dart';
import '../models/servico_model.dart';

class ServicoRepository {
  Future<int> inserir(Servico servico) async {
    final db = await AppDatabase.instance.database;
    final data = servico.toMap()..remove('id');

    return db.insert('servicos', data);
  }

  Future<List<Servico>> listarTodos() async {
    final db = await AppDatabase.instance.database;

    final result = await db.query(
      'servicos',
      orderBy: 'nome ASC',
    );

    return result.map(Servico.fromMap).toList();
  }

  Future<List<Servico>> listarAtivos() async {
    final db = await AppDatabase.instance.database;

    final result = await db.query(
      'servicos',
      where: 'ativo = ?',
      whereArgs: [1],
      orderBy: 'nome ASC',
    );

    return result.map(Servico.fromMap).toList();
  }

  Future<Servico?> buscarPorId(int id) async {
    final db = await AppDatabase.instance.database;

    final result = await db.query(
      'servicos',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (result.isEmpty) return null;

    return Servico.fromMap(result.first);
  }

  Future<int> atualizar(Servico servico) async {
    final db = await AppDatabase.instance.database;

    if (servico.id == null) {
      throw ArgumentError('Serviço sem id não pode ser atualizado.');
    }

    final data = servico.toMap()..remove('id');

    return db.update(
      'servicos',
      data,
      where: 'id = ?',
      whereArgs: [servico.id],
    );
  }

  Future<int> excluir(int id) async {
    final db = await AppDatabase.instance.database;

    return db.delete(
      'servicos',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}