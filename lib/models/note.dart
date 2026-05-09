import 'package:firebase_auth/firebase_auth.dart';

//MODELO DART DE LA NOTA
class Note {
  final int? id; // id (null, ya que SQLite loa signa automáticamente)
  final String
  userId; // id usuario (revisar, creo que firestore lo guarda como texto pero no estoy seguro)
  final int? categoryId; // id_categoria (puede ser null si no tiene categoría)
  final String title; // titulo
  final String content; // contenido
  final int color; // color (formato: 0xFFFFFFFF)
  final DateTime createdAt; // fecha_creacion
  final DateTime updatedAt; // fecha_modificacion
  final bool isArchived; // esta_archivada
  final bool isSynced; // estado_sincronizacion

  Note({
    this.id,
    required this.userId,
    this.categoryId,
    required this.title,
    required this.content,
    this.color = 0xFFFFFFFF, // Blanco por defecto
    required this.createdAt,
    DateTime? updatedAt,
    this.isArchived = false,
    this.isSynced = false,
  }) : updatedAt =
           updatedAt ??
           createdAt; // Si no hay fecha de modificación, es igual a la de creación

  //MAPA PARA CONVERTIR LA NOTA EN DART A SQLITE
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'categoryId': categoryId,
      'title': title,
      'content': content,
      'color': color,
      'createdAt': createdAt.toIso8601String(), //FORMATO yyyy-MM-ddTHH:mm:ss
      'updatedAt': updatedAt.toIso8601String(),
      'isArchived': isArchived ? 1 : 0, // SQLite no tiene booleanos, usa 1 y 0
      'isSynced': isSynced ? 1 : 0,
    };
  }

  //MAPEO DE VUELTA, PARA CONVERTIR EL REGISTRO DE SQLITE A DART
  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'] as int?,
      userId: map['userId'] ?? '',
      categoryId: map['categoryId'] as int?,
      title: map['title'] as String,
      content: map['content'] as String,
      color: map['color'] as int,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
      isArchived: map['isArchived'] == 1,
      isSynced: map['isSynced'] == 1,
    );
  }

  // FUNCIÓN PARA CREAR UNA NOTA NUEVA, CAMBIÁNDOLE EL ID
  Note copyWith({int? id}) {
    return Note(
      id: id ?? this.id,
      userId: userId,
      categoryId: categoryId,
      title: title,
      content: content,
      color: color,
      createdAt: createdAt,
      updatedAt: updatedAt,
      isArchived: isArchived,
      isSynced: isSynced,
    );
  }
}
