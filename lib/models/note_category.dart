//MODELO DART DE LA CATEGORÍA
class NoteCategory {
  final int? id;
  final String name; // nombre
  final String icon; // icono (DEFINIR BIEN CÓMO LO VAMOS A HACER)
  final bool isSynced; // estado_sincronizacion

  NoteCategory({
    this.id,
    required this.name,
    required this.icon,
    this.isSynced = false,
  });

  //MAPA PARA CONVERTIR LA CATEGORÍA EN DART A SQLITE
  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'icon': icon, 'isSynced': isSynced ? 1 : 0};
  }

  //MAPEO DE VUELTA, PARA CONVERTIR EL REGISTRO DE SQLITE A DART
  factory NoteCategory.fromMap(Map<String, dynamic> map) {
    return NoteCategory(
      id: map['id'] as int?,
      name: map['name'] as String,
      icon: map['icon'] as String,
      isSynced: map['isSynced'] == 1,
    );
  }
}
