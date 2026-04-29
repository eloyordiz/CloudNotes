//MODELO DART DE LA CATEGORÍA
class NoteCategory {
  final int? id;
  final String name; // nombre
  final int? iconCodePoint; // icono - Code Point
  final bool isSynced; // estado_sincronizacion
  final DateTime createdAt; // fecha creación

  NoteCategory({
    this.id,
    required this.name,
    required this.iconCodePoint,
    this.isSynced = false,
    required this.createdAt,
  });

  //MAPA PARA CONVERTIR LA CATEGORÍA EN DART A SQLITE
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'iconCodePoint': iconCodePoint,
      'createdAt': createdAt.toIso8601String(),
      'isSynced': isSynced ? 1 : 0,
    };
  }

  //MAPEO DE VUELTA, PARA CONVERTIR EL REGISTRO DE SQLITE A DART
  factory NoteCategory.fromMap(Map<String, dynamic> map) {
    return NoteCategory(
      id: map['id'] as int?,
      name: map['name'] as String,
      iconCodePoint: map['iconCodePoint'] as int?,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : DateTime.now(),
      isSynced: map['isSynced'] == 1,
    );
  }
}
