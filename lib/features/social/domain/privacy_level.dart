/// Niveles de privacidad para retos y visibilidad de perfil
enum PrivacyLevel {
  everyone,   // cualquier usuario autenticado
  followers,  // solo seguidores
  nobody,     // nadie
}

extension PrivacyLevelX on PrivacyLevel {
  String get value {
    switch (this) {
      case PrivacyLevel.everyone:
        return 'everyone';
      case PrivacyLevel.followers:
        return 'followers';
      case PrivacyLevel.nobody:
        return 'nobody';
    }
  }

  static PrivacyLevel fromString(String? v) {
    switch (v) {
      case 'followers':
      case 'friends': // backward compat con datos legacy
        return PrivacyLevel.followers;
      case 'nobody':
        return PrivacyLevel.nobody;
      default:
        return PrivacyLevel.everyone;
    }
  }

  String get label {
    switch (this) {
      case PrivacyLevel.everyone:
        return 'Todos';
      case PrivacyLevel.followers:
        return 'Seguidores';
      case PrivacyLevel.nobody:
        return 'Nadie';
    }
  }
}
