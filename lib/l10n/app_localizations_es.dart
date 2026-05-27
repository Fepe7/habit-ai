// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class SEs extends S {
  SEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'HabitAI';

  @override
  String get cancel => 'Cancelar';

  @override
  String get save => 'Guardar';

  @override
  String get confirm => 'Continuar';

  @override
  String get activate => 'Activar';

  @override
  String get days => 'Días';

  @override
  String daysLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count días',
      one: '1 día',
    );
    return '$_temp0';
  }

  @override
  String get settingsTitle => 'Ajustes';

  @override
  String get settingsSectionCommunity => 'Comunidad';

  @override
  String get settingsExploreDirectory => 'Explorar directorio';

  @override
  String get settingsExploreDirectorySubtitle =>
      'Descubre perfiles públicos de otros usuarios';

  @override
  String get settingsFollowers => 'Seguidores';

  @override
  String get settingsFollowersSubtitle => 'Gestiona tus seguidores y seguidos';

  @override
  String get settingsSectionAppearance => 'Apariencia';

  @override
  String get settingsThemeLabel => 'Tema';

  @override
  String get settingsSectionLanguage => 'Idioma';

  @override
  String get settingsSectionGeneral => 'General';

  @override
  String get settingsAchievements => 'Logros';

  @override
  String get settingsAchievementsSubtitle => 'Tus logros desbloqueados';

  @override
  String get settingsSectionInfo => 'Información';

  @override
  String get settingsAbout => 'Acerca de HabitAI';

  @override
  String get settingsAboutSubtitle => 'Versión 1.0.0 — TFG 2º DAM';

  @override
  String get settingsPrivacy => 'Privacidad';

  @override
  String get settingsPrivacySubtitle => 'Retos, perfil y visibilidad';

  @override
  String get settingsSectionLegal => 'Legal';

  @override
  String get settingsPrivacyPolicy => 'Política de privacidad';

  @override
  String get settingsPrivacyPolicySubtitle => 'Cómo tratamos tus datos';

  @override
  String get settingsTerms => 'Términos de uso';

  @override
  String get settingsTermsSubtitle => 'Condiciones del servicio';

  @override
  String get settingsSectionStreakProtection => 'Protección de rachas';

  @override
  String get settingsSignOut => 'Cerrar sesión';

  @override
  String get settingsSignOutConfirmTitle => 'Cerrar sesión';

  @override
  String get settingsSignOutConfirmContent =>
      '¿Estás seguro de que quieres cerrar sesión?';

  @override
  String get settingsDeleteAccount => 'Eliminar cuenta';

  @override
  String get settingsDeleteAccountSubtitle => 'Se borrarán todos tus datos';

  @override
  String get settingsDeleteAccountConfirmContent =>
      'Se borrarán permanentemente todos tus datos: hábitos, rachas, logros, conversaciones con la IA, seguidores y tu perfil.\n\nEsta acción no se puede deshacer.';

  @override
  String get settingsDeleteConfirmTitle => 'Confirmar eliminación';

  @override
  String get settingsDeleteConfirmPrompt => 'Escribe ELIMINAR para confirmar:';

  @override
  String get settingsEditNameTitle => 'Cambiar nombre';

  @override
  String get settingsEditNameHint => 'Tu nombre';

  @override
  String get settingsNameUpdated => 'Nombre actualizado';

  @override
  String get settingsNameUpdateError => 'No se pudo actualizar el nombre';

  @override
  String get settingsDeleteRequiresRelogin =>
      'Por seguridad, cierra sesión, vuelve a entrar e inténtalo de nuevo';

  @override
  String settingsDeleteAccountError(String error) {
    return 'Error al eliminar la cuenta: $error';
  }

  @override
  String get settingsFallbackUsername => 'Usuario';

  @override
  String get settingsNotifications => 'Notificaciones';

  @override
  String get settingsNotificationsEnabled =>
      'Recibirás recordatorios de tus hábitos';

  @override
  String get settingsNotificationsDisabled => 'Recordatorios desactivados';

  @override
  String get settingsNotificationsSystemPrompt =>
      'Activa las notificaciones en los ajustes del sistema';

  @override
  String get settingsSickMode => 'Modo enfermedad';

  @override
  String get settingsSickModeSubtitle =>
      'Protege todas las rachas sin gastar escudos';

  @override
  String settingsSickModeActive(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days días',
      one: '1 día',
    );
    return 'Activo — termina en $_temp0';
  }

  @override
  String get settingsSickModeDialogTitle => 'Modo enfermedad';

  @override
  String get settingsSickModeDialogContent =>
      'Tus rachas quedarán protegidas durante este período. Máximo 7 días.';

  @override
  String get settingsShieldsTile => 'Escudos de racha';

  @override
  String settingsShieldsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count disponibles de 5',
      one: '$count disponible de 5',
    );
    return '$_temp0';
  }

  @override
  String get settingsShieldsTooltip =>
      'Gana escudos completando rachas de 7, 30 y 90 días.\nÚsalos en HabitAI para proteger tu racha si fallas un día.';

  @override
  String get themeLight => 'Claro';

  @override
  String get themeDark => 'Oscuro';

  @override
  String get themeAuto => 'Auto';

  @override
  String get languageSelectorLabel => 'Idioma';

  @override
  String get languageEs => 'Español';

  @override
  String get languageEn => 'English';
}
