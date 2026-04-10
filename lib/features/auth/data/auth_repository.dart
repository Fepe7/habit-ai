import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../domain/user_model.dart';

// Gestiona todo lo de autenticacion con Firebase Auth
class AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn _googleSignIn;

  AuthRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    GoogleSignIn? googleSignIn,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn();

  // Escucha cambios de sesion (login/logout)
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

  // Registrar usuario nuevo
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
      await _ensureUserDoc(user);
      return UserModel(
        uid: user.uid,
        email: user.email ?? '',
        displayName: user.displayName,
      );
    } on FirebaseAuthException catch (e) {
      throw e.code;
    }
  }

  // Iniciar sesion
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

  // Iniciar sesion con Google (cuenta nueva o existente)
  Future<UserModel> signInWithGoogle() async {
    try {
      // 1. lanzar el selector de cuentas de Google
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // el usuario cerro el selector sin elegir nada
        throw 'Inicio de sesión cancelado';
      }

      // 2. obtener tokens de la cuenta seleccionada
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 3. autenticar en Firebase con el credential de Google
      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user!;

      // 4. si es la primera vez, crear el doc en Firestore
      if (userCredential.additionalUserInfo?.isNewUser ?? false) {
        await _ensureUserDoc(user);
      }

      return UserModel(
        uid: user.uid,
        email: user.email ?? '',
        displayName: user.displayName,
      );
    } on FirebaseAuthException catch (e) {
      // mapear los errores mas comunes a mensajes en espanol
      switch (e.code) {
        case 'account-exists-with-different-credential':
          throw 'Ya existe una cuenta con este correo usando otro método';
        case 'invalid-credential':
          throw 'Credenciales no válidas';
        case 'network-request-failed':
          throw 'Sin conexión a internet';
        default:
          throw 'Error al iniciar sesión con Google';
      }
    } catch (e) {
      // si ya es un String (cancelacion u otro), lo reenviamos
      if (e is String) rethrow;
      throw 'Error al iniciar sesión con Google';
    }
  }

  // Crea el doc users/{uid} si no existe (primer login)
  Future<void> _ensureUserDoc(User user) async {
    final docRef = _firestore.collection('users').doc(user.uid);
    final snapshot = await docRef.get();
    if (snapshot.exists) return;

    await docRef.set({
      'email': user.email,
      'displayName': user.displayName,
      'photoURL': user.photoURL,
      'createdAt': FieldValue.serverTimestamp(),
      'onboardingCompleted': false,
    });
  }

  // Usuario actual (null si no hay sesion)
  UserModel? get currentUser {
    final user = _auth.currentUser;
    if (user == null) return null;
    return UserModel(
      uid: user.uid,
      email: user.email ?? '',
      displayName: user.displayName,
    );
  }

  // Cerrar sesion (limpia tambien la sesion de Google)
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
