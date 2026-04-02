import 'package:firebase_auth/firebase_auth.dart';
import '../domain/user_model.dart';

/// Repositorio que encapsula todas las operaciones de autenticación.
/// La UI nunca interactúa con FirebaseAuth directamente, solo con este repositorio.
class AuthRepository {
  final FirebaseAuth _auth;

  AuthRepository({FirebaseAuth? auth})
      : _auth = auth ?? FirebaseAuth.instance;

  /// Stream reactivo del estado de autenticación.
  /// Emite el usuario actual cuando inicia/cierra sesión.
  Stream<UserModel?> get authStateChanges {
    return _auth.authStateChanges().map((user) {
      if (user == null) return null;
      return UserModel(
        uid: user.uid,
        email: user.email ?? '',
        displayName: user.displayName,
      );
    });
  }

  /// Registro con email y contraseña.
  /// Devuelve el UserModel creado o lanza una excepción con mensaje en español.
  Future<UserModel> register({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user!;
      return UserModel(
        uid: user.uid,
        email: user.email ?? '',
        displayName: user.displayName,
      );
    } on FirebaseAuthException catch (e) {
      throw e.code;
    }
  }

  /// Login con email y contraseña.
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user!;
      return UserModel(
        uid: user.uid,
        email: user.email ?? '',
        displayName: user.displayName,
      );
    } on FirebaseAuthException catch (e) {
      throw e.code;
    }
  }

  /// Cierra la sesión del usuario actual.
  Future<void> signOut() async {
    await _auth.signOut();
  }

}
