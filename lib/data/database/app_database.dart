import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'jl_serralheria.db');

    return openDatabase(
      path,
      version: 1,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE clientes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT NOT NULL,
        telefone TEXT NOT NULL,
        endereco TEXT,
        observacoes TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE produtos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT NOT NULL,
        codigo TEXT,
        categoria TEXT NOT NULL,
        unidade TEXT NOT NULL,
        valor_base REAL NOT NULL,
        observacoes TEXT,
        ativo INTEGER NOT NULL DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE servicos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT NOT NULL,
        unidade TEXT NOT NULL,
        valor_base REAL NOT NULL,
        observacoes TEXT,
        ativo INTEGER NOT NULL DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE orcamentos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        cliente_id INTEGER NOT NULL,
        data_criacao TEXT NOT NULL,
        status TEXT NOT NULL,
        valor_total REAL NOT NULL,
        observacoes TEXT,
        validade_dias INTEGER NOT NULL DEFAULT 7,
        FOREIGN KEY (cliente_id) REFERENCES clientes (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE itens_orcamento (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        orcamento_id INTEGER NOT NULL,
        produto_id INTEGER,
        servico_id INTEGER,
        tipo_item TEXT NOT NULL,
        descricao TEXT NOT NULL,
        quantidade REAL NOT NULL,
        unidade TEXT NOT NULL,
        valor_unitario REAL NOT NULL,
        observacoes TEXT,
        FOREIGN KEY (orcamento_id) REFERENCES orcamentos (id) ON DELETE CASCADE,
        FOREIGN KEY (produto_id) REFERENCES produtos (id),
        FOREIGN KEY (servico_id) REFERENCES servicos (id)
      )
    ''');
  }
}