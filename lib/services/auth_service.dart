import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // REGISTRO CON USUARIO Y CONTRASEÑA
  Future<User?> registerWithEmail(String email, String password) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } catch (e) {
      print("Error en el registro: ${e.toString()}");
      return null;
    }
  }

  // LOGIN CON USUARIO Y CONTRASEÑA
  Future<User?> loginWithEmail(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } catch (e) {
      print("Error en el login: ${e.toString()}");
      return null;
    }
  }

  // LOGOUT
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // DEVULEVE EL ESTADO DEL USUARIO EN TIEMPO REAL
  Stream<User?> get userStatus {
    return _auth.authStateChanges();
  }
}
