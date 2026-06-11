import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../domain/user_model.dart';
import '../../../services/push_notification_service.dart';

// Gestiona todo lo de autenticacion con Firebase Auth
class AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AuthRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

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
    String? name,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user!;
      // guardar nombre en Firebase Auth para que authStateChanges lo lea
      if (name != null && name.isNotEmpty) {
        await user.updateDisplayName(name);
      }
      await _ensureUserDoc(user, displayName: name);
      return UserModel(
        uid: user.uid,
        email: user.email ?? '',
        displayName: name ?? user.displayName,
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

  // Enviar correo de restablecimiento de contraseña.
  // El email lo envía Firebase Auth (gratis, plantilla en la consola);
  // no necesita Cloud Function ni proveedor SMTP.
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw e.code;
    }
  }

  // Iniciar sesion con Google (cuenta nueva o existente)
  Future<UserModel> signInWithGoogle() async {
    try {
      // 1. lanzar el selector de cuentas (v7: singleton + authenticate, lanza si cancela)
      final googleUser = await GoogleSignIn.instance.authenticate();

      // 2. obtener idToken (v7: accessToken ya no está en authentication, solo idToken)
      final googleAuth = googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      // 3. autenticar en Firebase con el credential de Google
      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user!;

      // 4. crear el doc si es la primera vez, o sincronizar la foto de Google
      //    si la cuenta ya existía pero le faltaba el campo photoUrl.
      await _ensureUserDoc(user);

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

  // Iniciar sesion con Apple (cuenta nueva o existente) — solo iOS/macOS.
  Future<UserModel> signInWithApple() async {
    try {
      // 1. nonce: Apple firma el sha256, Firebase verifica con el valor crudo
      final rawNonce = _generateNonce();
      final hashedNonce = _sha256ofString(rawNonce);

      // 2. lanzar el diálogo nativo de Apple (lanza si el usuario cancela)
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: hashedNonce,
      );

      // 3. construir el credential de Firebase con el idToken + nonce crudo.
      //    Firebase exige también el authorizationCode como accessToken para
      //    validar el token; sin él devuelve "Invalid Auth response from apple.com".
      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        rawNonce: rawNonce,
        accessToken: appleCredential.authorizationCode,
      );

      // 4. autenticar en Firebase
      final userCredential = await _auth.signInWithCredential(oauthCredential);
      final user = userCredential.user!;

      // 5. Apple SOLO entrega el nombre en el primer inicio de sesión.
      //    Lo persistimos en Firebase Auth si aún no hay displayName.
      final fullName = [
        appleCredential.givenName,
        appleCredential.familyName,
      ].whereType<String>().where((p) => p.trim().isNotEmpty).join(' ').trim();
      if (fullName.isNotEmpty &&
          (user.displayName == null || user.displayName!.isEmpty)) {
        await user.updateDisplayName(fullName);
      }

      // 6. si es la primera vez, crear el doc en Firestore
      if (userCredential.additionalUserInfo?.isNewUser ?? false) {
        await _ensureUserDoc(
          user,
          displayName: fullName.isNotEmpty ? fullName : null,
        );
      }

      return UserModel(
        uid: user.uid,
        email: user.email ?? '',
        displayName:
            user.displayName ?? (fullName.isNotEmpty ? fullName : null),
      );
    } on SignInWithAppleAuthorizationException catch (e) {
      // cancelación del usuario → sentinela que la UI ignora sin mostrar error
      if (e.code == AuthorizationErrorCode.canceled) throw 'cancelled';
      throw 'Error al iniciar sesión con Apple';
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'account-exists-with-different-credential':
          throw 'Ya existe una cuenta con este correo usando otro método';
        case 'invalid-credential':
          throw 'Credenciales no válidas';
        case 'network-request-failed':
          throw 'Sin conexión a internet';
        default:
          throw 'Error al iniciar sesión con Apple';
      }
    } catch (e) {
      if (e is String) rethrow;
      throw 'Error al iniciar sesión con Apple';
    }
  }

  // Genera un nonce criptográficamente seguro para el flujo de Apple.
  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }

  // SHA-256 en hex de una cadena (para el nonce que recibe Apple).
  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    return sha256.convert(bytes).toString();
  }

  // Crea el doc users/{uid} si no existe (primer login)
  Future<void> _ensureUserDoc(User user, {String? displayName}) async {
    final docRef = _firestore.collection('users').doc(user.uid);
    final snapshot = await docRef.get();
    if (snapshot.exists) {
      // Doc existente: rellenar la foto del proveedor (Google/Apple) si falta.
      // Cubre cuentas creadas antes de unificar el nombre del campo a 'photoUrl'
      // (antes se guardaba como 'photoURL' y el modelo nunca lo leía).
      final data = snapshot.data();
      final hasPhoto = (data?['photoUrl'] as String?)?.isNotEmpty ?? false;
      if (!hasPhoto && (user.photoURL?.isNotEmpty ?? false)) {
        await docRef.update({'photoUrl': user.photoURL});
      }
      return;
    }

    await docRef.set({
      'email': user.email,
      'displayName': displayName ?? user.displayName,
      // Campo canónico 'photoUrl' (coincide con UserModel.fromFirestore/toJson)
      'photoUrl': user.photoURL,
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

  // Cerrar sesion (limpia tambien la sesion de Google y el token de push)
  Future<void> signOut() async {
    await PushNotificationService.instance.unregisterForCurrentUser();
    await GoogleSignIn.instance.signOut();
    await _auth.signOut();
  }

  // Proveedor principal de la sesión actual ('password', 'google.com', 'apple.com').
  String? get primaryProviderId {
    final providers = _auth.currentUser?.providerData;
    if (providers == null || providers.isEmpty) return null;
    return providers.first.providerId;
  }

  // Reautentica al usuario según su proveedor. Imprescindible antes de borrar
  // la cuenta: user.delete() exige login reciente (requires-recent-login).
  // Para email/contraseña hay que pasar la contraseña; con Google/Apple se
  // relanza el diálogo nativo del proveedor.
  Future<void> _reauthenticate(User user, {String? password}) async {
    final providerId = user.providerData.isNotEmpty
        ? user.providerData.first.providerId
        : 'password';
    try {
      switch (providerId) {
        case 'google.com':
          final googleUser = await GoogleSignIn.instance.authenticate();
          final googleAuth = googleUser.authentication;
          final cred =
              GoogleAuthProvider.credential(idToken: googleAuth.idToken);
          await user.reauthenticateWithCredential(cred);
          break;
        case 'apple.com':
          final rawNonce = _generateNonce();
          final hashedNonce = _sha256ofString(rawNonce);
          final appleCredential = await SignInWithApple.getAppleIDCredential(
            scopes: const [AppleIDAuthorizationScopes.email],
            nonce: hashedNonce,
          );
          final oauthCredential = OAuthProvider('apple.com').credential(
            idToken: appleCredential.identityToken,
            rawNonce: rawNonce,
            accessToken: appleCredential.authorizationCode,
          );
          await user.reauthenticateWithCredential(oauthCredential);
          break;
        default: // email/contraseña
          if (password == null || password.isEmpty) {
            throw 'requires-password';
          }
          final cred = EmailAuthProvider.credential(
            email: user.email ?? '',
            password: password,
          );
          await user.reauthenticateWithCredential(cred);
      }
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) throw 'cancelled';
      throw 'Error al verificar con Apple';
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) throw 'cancelled';
      throw 'Error al verificar con Google';
    } on FirebaseAuthException catch (e) {
      // contraseña incorrecta, credencial inválida, etc. → propagar el code
      throw e.code;
    }
  }

  // Eliminar cuenta y todos los datos asociados
  Future<void> deleteAccount({String? password}) async {
    final user = _auth.currentUser;
    if (user == null) throw 'No hay sesión activa';
    final uid = user.uid;

    // 0. reautenticar ANTES de tocar datos. Si la verificación falla, los datos
    //    quedan intactos en vez de borrarse a medias dejando la cuenta huérfana.
    await _reauthenticate(user, password: password);

    // 1. leer username antes de borrar datos
    final userDoc = await _firestore.collection('users').doc(uid).get();
    final username = userDoc.data()?['username'] as String?;

    // 2. borrar referencias en followers/following de otros usuarios.
    //    DEBE ir antes de _deleteSubcollections, que borra mis subcolecciones
    //    following/followers (de las que aquí leo a quién hay que avisar).
    await _deleteFollowRelations(uid);

    // 3. borrar subcolecciones de users/{uid}
    await _deleteSubcollections(uid);

    // 4. borrar doc principal del usuario
    await _firestore.collection('users').doc(uid).delete();

    // 5. borrar entrada de directorio y username reservado
    await _firestore.collection('user_directory').doc(uid).delete();
    if (username != null) {
      await _firestore.collection('usernames').doc(username).delete();
    }

    // 6. borrar follow_requests donde participe
    await _deleteFollowRequests(uid);

    // 6.5 borrar plantillas de comunidad subidas por el usuario
    await _deleteCommunityTemplates(uid);

    // 7. borrar avatar de Storage
    try {
      await FirebaseStorage.instance.ref('users/$uid/avatar.jpg').delete();
    } catch (_) {}

    // 8. cerrar Google y borrar cuenta de Auth
    await GoogleSignIn.instance.signOut();
    await user.delete();
  }

  Future<void> _deleteSubcollections(String uid) async {
    final userRef = _firestore.collection('users').doc(uid);
    const subs = [
      'habits',
      'achievements',
      'ai_conversations',
      'weekly_reviews',
      'butterfly_projections',
      'pattern_insights',
      'renegotiations',
      'shield_grants',
      'mood_entries',
      'habit_groups',
      'followers',
      'following',
      'fcm_tokens',
    ];

    for (final sub in subs) {
      final colRef = userRef.collection(sub);
      final docs = await colRef.get();
      for (final doc in docs.docs) {
        // habits tiene subcolección logs
        if (sub == 'habits') {
          final logs = await doc.reference.collection('logs').get();
          for (final log in logs.docs) {
            await log.reference.delete();
          }
        }
        await doc.reference.delete();
      }
    }
  }

  // Borra las plantillas (rutinas) que el usuario publicó en la comunidad,
  // junto con su subcolección de hábitos.
  Future<void> _deleteCommunityTemplates(String uid) async {
    final templates = await _firestore
        .collection('community_templates')
        .where('authorUid', isEqualTo: uid)
        .get();
    for (final tpl in templates.docs) {
      // La regla de borrado de habits/{id} verifica el authorUid del doc
      // padre, así que hay que vaciar la subcolección ANTES de borrar el doc.
      final habits = await tpl.reference.collection('habits').get();
      for (final h in habits.docs) {
        await h.reference.delete();
      }
      await tpl.reference.delete();
    }
  }

  Future<void> _deleteFollowRequests(String uid) async {
    // solicitudes enviadas
    final sent = await _firestore
        .collection('follow_requests')
        .where('fromUid', isEqualTo: uid)
        .get();
    for (final doc in sent.docs) {
      await doc.reference.delete();
    }
    // solicitudes recibidas
    final received = await _firestore
        .collection('follow_requests')
        .where('toUid', isEqualTo: uid)
        .get();
    for (final doc in received.docs) {
      await doc.reference.delete();
    }
  }

  Future<void> _deleteFollowRelations(String uid) async {
    // borrar mi doc de los followers de la gente que sigo
    final myFollowing = await _firestore
        .collection('users')
        .doc(uid)
        .collection('following')
        .get();
    for (final doc in myFollowing.docs) {
      final otherUid = doc.id;
      await _firestore
          .collection('users')
          .doc(otherUid)
          .collection('followers')
          .doc(uid)
          .delete();
    }

    // borrar mi doc del following de la gente que me sigue
    final myFollowers = await _firestore
        .collection('users')
        .doc(uid)
        .collection('followers')
        .get();
    for (final doc in myFollowers.docs) {
      final otherUid = doc.id;
      await _firestore
          .collection('users')
          .doc(otherUid)
          .collection('following')
          .doc(uid)
          .delete();
    }
  }
}
