import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/note.dart';
import '../models/note_category.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // SUBIR O ACTUALIZAR UNA NOTA
  Future<void> saveNoteToCloud(Note note) async {
    try {
      // EL NOMBRE DEL DOCUMENTO SERÁ EL ID DE LA NOTA
      await _db
          .collection('users')
          .doc(note.userId)
          .collection('notes')
          .doc(note.id.toString())
          .set(note.toMap())
          // EL TIMEOUT EVITA QUE EL PROCESO SE QUEDE EN COLA DE FORMA INDEFINIDA SIN CONEXION
          .timeout(const Duration(seconds: 3));
      print("Nota sincronizada en la nube: ${note.title}");
    } catch (e) {
      print("Error al subir a Firestore: $e");
      rethrow;
    }
  }

  // ELIMINAR UNA NOTA DE LA NUBE
  Future<void> deleteNoteFromCloud(String userId, int noteId) async {
    try {
      await _db
          .collection('users')
          .doc(userId)
          .collection('notes')
          .doc(noteId.toString())
          .delete()
          // EL TIMEOUT EVITA QUE EL PROCESO SE QUEDE EN COLA DE FORMA INDEFINIDA SIN CONEXION
          .timeout(const Duration(seconds: 3));
    } catch (e) {
      print("Error al borrar de Firestore: $e");
      rethrow;
    }
  }

  // DESCARGAR TODAS LAS NOTAS DEL USUARIO DESDE LA NUBE
  Future<List<Note>> getNotesFromCloud(String userId) async {
    try {
      QuerySnapshot snapshot = await _db
          .collection('users')
          .doc(userId)
          .collection('notes')
          .get();

      return snapshot.docs.map((doc) {
        return Note.fromMap(doc.data() as Map<String, dynamic>);
      }).toList();
    } catch (e) {
      print("Error al descargar de Firestore: $e");
      return [];
    }
  }

  // SUBIR O ACTUALIZAR UNA CATEGORÍA
  Future<void> saveCategoryToCloud(NoteCategory category) async {
    try {
      // EL NOMBRE DEL DOCUMENTO SERÁ EL ID DE LA CATEGORÍA
      await _db
          .collection('users')
          .doc(category.userId)
          .collection('categories')
          .doc(category.id.toString())
          .set(category.toMap())
          // EL TIMEOUT EVITA QUE EL PROCESO SE QUEDE EN COLA DE FORMA INDEFINIDA SIN CONEXION
          .timeout(const Duration(seconds: 3));
      print("Categoría sincronizada en la nube: ${category.name}");
    } catch (e) {
      print("Error al subir a Firestore: $e");
      rethrow;
    }
  }

  // ELIMINAR UNA CATEGORÍA DE LA NUBE
  Future<void> deleteCategoryFromCloud(String userId, int noteId) async {
    try {
      await _db
          .collection('users')
          .doc(userId)
          .collection('categories')
          .doc(noteId.toString())
          .delete()
          // EL TIMEOUT EVITA QUE EL PROCESO SE QUEDE EN COLA DE FORMA INDEFINIDA SIN CONEXION
          .timeout(const Duration(seconds: 3));
    } catch (e) {
      print("Error al borrar de Firestore: $e");
      rethrow;
    }
  }

  // DESCARGAR TODAS LAS CATEGORÍAS DEL USUARIO DESDE LA NUBE
  Future<List<NoteCategory>> getCategoriesFromCloud(String userId) async {
    try {
      QuerySnapshot snapshot = await _db
          .collection('users')
          .doc(userId)
          .collection('categories')
          .get();

      return snapshot.docs.map((doc) {
        return NoteCategory.fromMap(doc.data() as Map<String, dynamic>);
      }).toList();
    } catch (e) {
      print("Error al descargar de Firestore: $e");
      return [];
    }
  }
}
