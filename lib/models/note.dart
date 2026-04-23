class Note {
  // 1. PROPIEDADES DE LA NOTA
  int? id; // SQLite asigna el ID automáticamente
  String title;
  String content;
  DateTime createdAt;
  bool isSynced;

  // 2. CONSTRUCTOR
  Note({
    this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    this.isSynced = false, // POR DEFECTO NO SINCRONIZADA
  });

  // 3. MAPEO DEL OBJETO DART (NOTA) A SQL. ESTO ES NECESARIO PARA ESCRIBIR
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      // SQLite NO ADMITE CAMPOS DATETIME. LO GUARDAMOS COMO TEXTO (yyyy-MM-ddTHH:mm:ss)
      'createdAt': createdAt.toIso8601String(),
      // SQLite NO ADMITE BOOLEANOS. LO GUARDAMOS COMO 1/0
      'isSynced': isSynced ? 1 : 0,
    };
  }

  // 4. MAPEO DE SQL AL OBJETO DART. ESTO ES NECESARIO PARA LEER
  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'],
      title: map['title'],
      content: map['content'],
      // PASO DEL ISO8601 AL DATETIME DE DART
      createdAt: DateTime.parse(map['createdAt']),
      // PASO DEL 1/0 DE SQL AL BOOLEANO DE DART
      isSynced: map['isSynced'] == 1,
    );
  }
}
