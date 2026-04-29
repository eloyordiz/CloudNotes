import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

// IMPORTS DEL PROYECTO
import '../models/note.dart';
import '../models/note_category.dart';

class DatabaseService {
  /* EL SERVICE INCLUYE:
  
  - INICIALIZACIÓN DE LA BASE DE DATOS
  - UPGRADES A LA BASE DE DATOS, SEGÚN LA VERSIÓN
  - ESTRUCTURA DE LAS TABLAS:
    - NOTAS
    - CATEGORÍAS
  - ACCIONES CRUD PARA LAS NOTAS

  */
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

    return await openDatabase(
      path,
      version: 3,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 3) {
      await db.execute('DROP TABLE IF EXISTS notes');
      await db.execute('DROP TABLE IF EXISTS categories');
      await _createDB(db, newVersion);
    }
  }

  Future _createDB(Database db, int version) async {
    // 1. TABLA CATEGORÍAS
    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        iconCodePoint INTEGER NOT NULL,
        createdAt TEXT NOT NULL,
        isSynced INTEGER NOT NULL
      )
    ''');

    // 2. TABLA NOTAS
    await db.execute('''
      CREATE TABLE notes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        categoryId INTEGER,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        color INTEGER NOT NULL,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        isArchived INTEGER NOT NULL,
        isSynced INTEGER NOT NULL,
        FOREIGN KEY (categoryId) REFERENCES categories (id) ON DELETE SET NULL
      )
    ''');
  }

  // NOTAS
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

  // Función para actualizar una nota
  Future<int> updateNote(Note note) async {
    final db = await instance.database;
    return db.update(
      'notes',
      note.toMap(),
      where: 'id = ?',
      whereArgs: [note.id],
    );
  }

  // Función para borrar una nota
  Future<int> deleteNote(int id) async {
    final db = await instance.database;
    return await db.delete('notes', where: 'id = ?', whereArgs: [id]);
  }

  // CATEGORÍAS
  // Función para insertar una categoría
  Future<NoteCategory> createCategory(NoteCategory category) async {
    final db = await instance.database;
    final id = await db.insert('categories', category.toMap());
    return NoteCategory(
      id: id,
      name: category.name,
      iconCodePoint: category.iconCodePoint,
      isSynced: category.isSynced,
      createdAt: category.createdAt,
    );
  }

  // Función para leer todas las categorías
  Future<List<NoteCategory>> readAllCategories() async {
    final db = await instance.database;
    final result = await db.query('categories', orderBy: 'name ASC');
    return result.map((json) => NoteCategory.fromMap(json)).toList();
  }

  // Función para editar las categorías
  Future<int> updateCategory(NoteCategory category) async {
    final db = await instance.database;
    return db.update(
      'categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  // Función para eliminar las categorías
  Future<int> deleteCategory(int id) async {
    final db = await instance.database;
    return await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
