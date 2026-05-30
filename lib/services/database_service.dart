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
      version: 5,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 5) {
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
        userId STRING NOT NULL,
        name TEXT NOT NULL,
        iconCodePoint INTEGER NOT NULL,
        createdAt TEXT NOT NULL,
        isSynced INTEGER NOT NULL,
        isDeleted INTEGER NOT NULL
      )
    ''');

    // 2. TABLA NOTAS
    await db.execute('''
      CREATE TABLE notes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId STRING NOT NULL,
        categoryId INTEGER,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        color INTEGER NOT NULL,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        isArchived INTEGER NOT NULL,
        isSynced INTEGER NOT NULL,
        isDeleted INTEGER NOT NULL,
        FOREIGN KEY (categoryId) REFERENCES categories (id) ON DELETE SET NULL
      )
    ''');
  }

  // NOTAS
  // Función para insertar una nota
  Future<int> createNote(Note note) async {
    final db = await instance.database;
    return await db.insert(
      'notes',
      note.toMap(),
      // SI INTENTAMOS CARGAR LAS NOTAS DE LA NUBE EN LOCAL, PUEDE HABER LAS MISMAS NOTAS CON ID REPETIDOS
      // CONFLICT ALGORITHM EVITA ESTOS ERRORES AL CARGAR DATOS DE LA BD NUBE EN LA BD LOCAL SOBREESCRIBIENDO LAS NOTAS
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Función para leer todas las notas - AÑADIDO FILTRO POR USUARIO
  Future<List<Note>> readAllNotes(String userId) async {
    final db = await instance.database;
    final result = await db.query(
      'notes',
      where: 'userId = ? AND isDeleted = 0',
      whereArgs: [userId],
      orderBy: 'createdAt DESC',
    );

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

  // Función para borrar una nota (SOFT DELETE)
  Future<int> deleteNote(int id) async {
    final db = await instance.database;
    return db.update(
      'notes',
      {'isDeleted': 1, 'isSynced': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Función para borrar una nota (HARD DELETE)
  Future<int> hardDeleteNote(int id) async {
    final db = await instance.database;
    return await db.delete('notes', where: 'id = ?', whereArgs: [id]);
  }

  // CATEGORÍAS
  // Función para insertar una categoría
  Future<int> createCategory(NoteCategory category) async {
    final db = await instance.database;
    return await db.insert(
      'categories',
      category.toMap(),
      // SI INTENTAMOS CARGAR LAS CATEGORÍAS DE LA NUBE EN LOCAL, PUEDE HABER LAS MISMAS CATEGORÍAS CON ID REPETIDOS
      // CONFLICT ALGORITHM EVITA ESTOS ERRORES AL CARGAR DATOS DE LA BD NUBE EN LA BD LOCAL SOBRESCRIBIENDO LAS CATEGORÁIS
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Función para leer todas las categorías
  Future<List<NoteCategory>> readAllCategories(String userId) async {
    final db = await instance.database;
    final result = await db.query(
      'categories',
      where: 'userId = ? AND isDeleted = 0',
      whereArgs: [userId],
      orderBy: 'name ASC',
    );
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

  // Función para eliminar las categorías (SOFT DELETE)
  Future<int> deleteCategory(int id) async {
    final db = await instance.database;
    return db.update(
      'categories',
      {'isDeleted': 1, 'isSynced': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Función para eliminar las categorías (HARD DELETE)
  Future<int> hardDeleteCategory(int id) async {
    final db = await instance.database;
    return await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  // Función para contar cuántas notas pertenecen a una categoría
  Future<int> countNotesInCategory(int categoryId) async {
    final db = await instance.database;
    // QUERY SQL
    final result = await db.rawQuery(
      'SELECT COUNT(*) FROM notes WHERE categoryId = ?',
      [categoryId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }

  // FUNCIÓN PARA BORRAR LA BD LOCAL (SOLO USADO AL CERRAR SESIÓN)
  Future<void> clearLocalData() async {
    final db = await instance.database;
    await db.delete('notes');
    await db.delete('categories');
    print("Base de datos local limpiada con éxito");
  }

  // BUSCAR NOTAS PENDIENTES DE SINCRONIZAR
  Future<List<Note>> getUnsyncedNotes(String userId) async {
    final db = await instance.database;
    final result = await db.query(
      'notes',
      where: 'userId = ? AND isSynced = ?',
      whereArgs: [userId, 0],
    );
    return result.map((json) => Note.fromMap(json)).toList();
  }

  // BUSCAR CATEGORÍAS PENDIENTES DE SINCRONIZAR
  Future<List<NoteCategory>> getUnsyncedCategories(String userId) async {
    final db = await instance.database;
    final result = await db.query(
      'categories',
      where: 'userId = ? AND isSynced = ?',
      whereArgs: [userId, 0],
    );
    return result.map((json) => NoteCategory.fromMap(json)).toList();
  }

  // QUITAR CATEGORÍA A LAS NOTAS HUÉRFANAS
  Future<void> removeCategoryFromNotes(int categoryId) async {
    final db = await instance.database;
    await db.update(
      'notes',
      {'categoryId': null, 'isSynced': 0},
      where: 'categoryId = ?',
      whereArgs: [categoryId],
    );
  }

  // BUSCAR UNA NOTA ESPECÍFICA POR SU ID
  Future<Note?> getNoteById(int id) async {
    final db = await instance.database;
    final maps = await db.query('notes', where: 'id = ?', whereArgs: [id]);

    if (maps.isNotEmpty) {
      return Note.fromMap(maps.first);
    }
    return null;
  }

  // BUSCAR UNA CATEGORÍA ESPECÍFICA POR SU ID
  Future<NoteCategory?> getCategoryById(int id) async {
    final db = await instance.database;
    final maps = await db.query('categories', where: 'id = ?', whereArgs: [id]);

    if (maps.isNotEmpty) {
      return NoteCategory.fromMap(maps.first);
    }
    return null;
  }
}
