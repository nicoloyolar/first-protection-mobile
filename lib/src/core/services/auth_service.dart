import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<String?> login({required String email, required String password}) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') return 'Usuario no encontrado';
      if (e.code == 'wrong-password') return 'Contraseña incorrecta';
      if (e.code == 'invalid-email') return 'El correo no es válido'; 
      return 'Error: ${e.message}';
    } catch (e) {
      return 'Error desconocido: $e';
    }
  }

  Future<String?> register({required String email, required String password}) async {
    try {
      await _auth.createUserWithEmailAndPassword(
        email: email, 
        password: password
      );
      return null; 
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') return 'La contraseña es muy débil (mínimo 6 caracteres)';
      if (e.code == 'email-already-in-use') return 'Este correo ya está registrado';
      if (e.code == 'invalid-email') return 'El formato del correo es incorrecto';
      return 'Error: ${e.message}';
    } catch (e) {
      return 'Error al registrar: $e';
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }
}