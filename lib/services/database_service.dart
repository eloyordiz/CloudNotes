import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/note.dart';

class DatabaseService {
  // Inicialización de la BD
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('notes.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    // TABLA notes
    // AQUÍ HABRÁ QUE METER MANO EN EL FUTURO, CUANDO SE AÑADAN LAS CATEGORÍAS, TIMESTAMPS, ETC
    await db.execute('''
      CREATE TABLE notes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        isSynced INTEGER NOT NULL
      )
    ''');
  }

  // Función para insertar una nota
  Future<int> createNote(Note note) async {
    final db = await instance.database;
    return await db.insert('notes', note.toMap());
  }

  // Función para leer todas las notas
  Future<List<Note>> readAllNotes() async {
    final db = await instance.database;
    final result = await db.query('notes', orderBy: 'createdAt DESC');

    return result.map((json) => Note.fromMap(json)).toList();
  }

  // FALTAN LAS ACCIONES DE EDITAR NOTAS, ELIMINAR NOTAS Y TODO LO DE CATEGORÍAS

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
