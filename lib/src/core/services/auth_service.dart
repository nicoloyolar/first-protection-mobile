import 'package:firebase_auth/firebase_auth.dart';
import 'package:first_protection/core/models/app_user_profile.dart';
import 'package:first_protection/core/services/database_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseService _databaseService = DatabaseService();

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<String?> login({
    required String email,
    required String password,
  }) async {
    if (email.isEmpty || password.isEmpty) {
      return 'Por favor, completa todos los campos';
    }

    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return null;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          return 'Usuario no encontrado';
        case 'wrong-password':
          return 'Contraseña incorrecta';
        case 'invalid-email':
          return 'El correo no es válido';
        case 'invalid-credential':
          return 'Credenciales inválidas o expiradas';
        case 'user-disabled':
          return 'Esta cuenta ha sido deshabilitada';
        case 'too-many-requests':
          return 'Demasiados intentos. Intenta más tarde';
        default:
          return 'Error de acceso: ${e.message}';
      }
    } catch (e) {
      return 'Error inesperado: No pudimos conectar con el servidor';
    }
  }

  Future<String?> loginAdmin({
    required String email,
    required String password,
  }) async {
    final error = await login(email: email, password: password);
    if (error != null) return error;

    final user = _auth.currentUser;
    if (user == null) return 'No se pudo abrir la sesión administrativa';

    final canAccessAdmin = await _databaseService.usuarioPuedeAccederAdmin(
      user.uid,
    );
    if (!canAccessAdmin) {
      await _auth.signOut();
      return 'Tu cuenta no tiene permisos para acceder al panel administrativo';
    }

    return null;
  }

  Future<AppUserProfile?> currentProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    return _databaseService.obtenerPerfilUsuario(user.uid);
  }

  Future<String?> register({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        return 'La contraseña es muy débil (mínimo 6 caracteres)';
      }
      if (e.code == 'email-already-in-use') {
        return 'Este correo ya está registrado';
      }
      if (e.code == 'invalid-email') {
        return 'El formato del correo es incorrecto';
      }
      return 'Error: ${e.message}';
    } catch (e) {
      return 'Error al registrar: $e';
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }
}
