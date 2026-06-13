import '../../../l10n/app_localizations.dart';

// Traduce un error de autenticación a un texto claro y coherente para el
// usuario. El repositorio propaga el código crudo de Firebase (p. ej.
// 'invalid-credential'); aquí se centraliza el copy para que login y registro
// muestren siempre lo mismo, localizado.

/// `true` si el error es la cancelación del usuario (cerró el diálogo de
/// Google/Apple): no es un fallo, la UI no debe mostrar nada.
bool isAuthCancelled(Object error) => error.toString() == 'cancelled';

/// Mensaje legible para un error de autenticación. Acepta el código de Firebase
/// o un mensaje ya formateado.
String authErrorMessage(S s, Object error) {
  switch (error.toString()) {
    case 'invalid-credential':
    case 'invalid-login-credentials':
    case 'wrong-password':
    case 'user-not-found':
      // Firebase agrupa correo inexistente y contraseña mala en el mismo código
      // (protección anti-enumeración): un único mensaje neutro para todos.
      return s.authErrorInvalidCredential;
    case 'invalid-email':
      return s.authErrorInvalidEmail;
    case 'user-disabled':
      return s.authErrorUserDisabled;
    case 'too-many-requests':
      return s.authErrorTooManyRequests;
    case 'network-request-failed':
      return s.authErrorNetwork;
    case 'email-already-in-use':
      return s.authErrorEmailInUse;
    case 'weak-password':
      return s.authErrorWeakPassword;
    case 'account-exists-with-different-credential':
      return s.authErrorAccountExists;
    case 'operation-not-allowed':
      return s.authErrorOperationNotAllowed;
    case 'requires-password':
      return s.authErrorRequiresPassword;
    default:
      return s.authErrorGeneric;
  }
}
