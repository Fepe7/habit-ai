import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of S
/// returned by `S.of(context)`.
///
/// Applications need to include `S.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: S.localizationsDelegates,
///   supportedLocales: S.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the S.supportedLocales
/// property.
abstract class S {
  S(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static S of(BuildContext context) {
    return Localizations.of<S>(context, S)!;
  }

  static const LocalizationsDelegate<S> delegate = _SDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
  ];

  /// Nombre de la aplicación
  ///
  /// In es, this message translates to:
  /// **'HabitAI'**
  String get appTitle;

  /// Botón cancelar genérico
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get cancel;

  /// Botón guardar genérico
  ///
  /// In es, this message translates to:
  /// **'Guardar'**
  String get save;

  /// Botón confirmar genérico
  ///
  /// In es, this message translates to:
  /// **'Continuar'**
  String get confirm;

  /// Botón activar
  ///
  /// In es, this message translates to:
  /// **'Activar'**
  String get activate;

  /// Días (slider label)
  ///
  /// In es, this message translates to:
  /// **'Días'**
  String get days;

  /// Número de días con plural
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 día} other{{count} días}}'**
  String daysLabel(int count);

  /// Título pantalla de ajustes
  ///
  /// In es, this message translates to:
  /// **'Ajustes'**
  String get settingsTitle;

  /// No description provided for @settingsSectionCommunity.
  ///
  /// In es, this message translates to:
  /// **'Comunidad'**
  String get settingsSectionCommunity;

  /// No description provided for @settingsExploreDirectory.
  ///
  /// In es, this message translates to:
  /// **'Explorar directorio'**
  String get settingsExploreDirectory;

  /// No description provided for @settingsExploreDirectorySubtitle.
  ///
  /// In es, this message translates to:
  /// **'Descubre perfiles públicos de otros usuarios'**
  String get settingsExploreDirectorySubtitle;

  /// No description provided for @settingsFollowers.
  ///
  /// In es, this message translates to:
  /// **'Seguidores'**
  String get settingsFollowers;

  /// No description provided for @settingsFollowersSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Gestiona tus seguidores y seguidos'**
  String get settingsFollowersSubtitle;

  /// No description provided for @settingsSectionAppearance.
  ///
  /// In es, this message translates to:
  /// **'Apariencia'**
  String get settingsSectionAppearance;

  /// No description provided for @settingsThemeLabel.
  ///
  /// In es, this message translates to:
  /// **'Tema'**
  String get settingsThemeLabel;

  /// No description provided for @settingsSectionLanguage.
  ///
  /// In es, this message translates to:
  /// **'Idioma'**
  String get settingsSectionLanguage;

  /// No description provided for @settingsSectionGeneral.
  ///
  /// In es, this message translates to:
  /// **'General'**
  String get settingsSectionGeneral;

  /// No description provided for @settingsAchievements.
  ///
  /// In es, this message translates to:
  /// **'Logros'**
  String get settingsAchievements;

  /// No description provided for @settingsAchievementsSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Tus logros desbloqueados'**
  String get settingsAchievementsSubtitle;

  /// No description provided for @settingsSectionInfo.
  ///
  /// In es, this message translates to:
  /// **'Información'**
  String get settingsSectionInfo;

  /// No description provided for @settingsAbout.
  ///
  /// In es, this message translates to:
  /// **'Acerca de HabitAI'**
  String get settingsAbout;

  /// No description provided for @settingsAboutSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Versión 1.0.0 — TFG 2º DAM'**
  String get settingsAboutSubtitle;

  /// No description provided for @settingsPrivacy.
  ///
  /// In es, this message translates to:
  /// **'Privacidad'**
  String get settingsPrivacy;

  /// No description provided for @settingsPrivacySubtitle.
  ///
  /// In es, this message translates to:
  /// **'Retos, perfil y visibilidad'**
  String get settingsPrivacySubtitle;

  /// No description provided for @settingsSectionLegal.
  ///
  /// In es, this message translates to:
  /// **'Legal'**
  String get settingsSectionLegal;

  /// No description provided for @settingsPrivacyPolicy.
  ///
  /// In es, this message translates to:
  /// **'Política de privacidad'**
  String get settingsPrivacyPolicy;

  /// No description provided for @settingsPrivacyPolicySubtitle.
  ///
  /// In es, this message translates to:
  /// **'Cómo tratamos tus datos'**
  String get settingsPrivacyPolicySubtitle;

  /// No description provided for @settingsTerms.
  ///
  /// In es, this message translates to:
  /// **'Términos de uso'**
  String get settingsTerms;

  /// No description provided for @settingsTermsSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Condiciones del servicio'**
  String get settingsTermsSubtitle;

  /// No description provided for @settingsSectionStreakProtection.
  ///
  /// In es, this message translates to:
  /// **'Protección de rachas'**
  String get settingsSectionStreakProtection;

  /// No description provided for @settingsSignOut.
  ///
  /// In es, this message translates to:
  /// **'Cerrar sesión'**
  String get settingsSignOut;

  /// No description provided for @settingsSignOutConfirmTitle.
  ///
  /// In es, this message translates to:
  /// **'Cerrar sesión'**
  String get settingsSignOutConfirmTitle;

  /// No description provided for @settingsSignOutConfirmContent.
  ///
  /// In es, this message translates to:
  /// **'¿Estás seguro de que quieres cerrar sesión?'**
  String get settingsSignOutConfirmContent;

  /// No description provided for @settingsDeleteAccount.
  ///
  /// In es, this message translates to:
  /// **'Eliminar cuenta'**
  String get settingsDeleteAccount;

  /// No description provided for @settingsDeleteAccountSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Se borrarán todos tus datos'**
  String get settingsDeleteAccountSubtitle;

  /// No description provided for @settingsDeleteAccountConfirmContent.
  ///
  /// In es, this message translates to:
  /// **'Se borrarán permanentemente todos tus datos: hábitos, rachas, logros, conversaciones con la IA, seguidores y tu perfil.\n\nEsta acción no se puede deshacer.'**
  String get settingsDeleteAccountConfirmContent;

  /// No description provided for @settingsDeleteConfirmTitle.
  ///
  /// In es, this message translates to:
  /// **'Confirmar eliminación'**
  String get settingsDeleteConfirmTitle;

  /// No description provided for @settingsDeleteConfirmPrompt.
  ///
  /// In es, this message translates to:
  /// **'Escribe ELIMINAR para confirmar:'**
  String get settingsDeleteConfirmPrompt;

  /// No description provided for @settingsEditNameTitle.
  ///
  /// In es, this message translates to:
  /// **'Cambiar nombre'**
  String get settingsEditNameTitle;

  /// No description provided for @settingsEditNameHint.
  ///
  /// In es, this message translates to:
  /// **'Tu nombre'**
  String get settingsEditNameHint;

  /// No description provided for @settingsNameUpdated.
  ///
  /// In es, this message translates to:
  /// **'Nombre actualizado'**
  String get settingsNameUpdated;

  /// No description provided for @settingsNameUpdateError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo actualizar el nombre'**
  String get settingsNameUpdateError;

  /// No description provided for @settingsDeleteRequiresRelogin.
  ///
  /// In es, this message translates to:
  /// **'Por seguridad, cierra sesión, vuelve a entrar e inténtalo de nuevo'**
  String get settingsDeleteRequiresRelogin;

  /// No description provided for @settingsDeleteAccountError.
  ///
  /// In es, this message translates to:
  /// **'Error al eliminar la cuenta: {error}'**
  String settingsDeleteAccountError(String error);

  /// No description provided for @settingsFallbackUsername.
  ///
  /// In es, this message translates to:
  /// **'Usuario'**
  String get settingsFallbackUsername;

  /// No description provided for @settingsNotifications.
  ///
  /// In es, this message translates to:
  /// **'Notificaciones'**
  String get settingsNotifications;

  /// No description provided for @settingsNotificationsEnabled.
  ///
  /// In es, this message translates to:
  /// **'Recibirás recordatorios de tus hábitos'**
  String get settingsNotificationsEnabled;

  /// No description provided for @settingsNotificationsDisabled.
  ///
  /// In es, this message translates to:
  /// **'Recordatorios desactivados'**
  String get settingsNotificationsDisabled;

  /// No description provided for @settingsNotificationsSystemPrompt.
  ///
  /// In es, this message translates to:
  /// **'Activa las notificaciones en los ajustes del sistema'**
  String get settingsNotificationsSystemPrompt;

  /// No description provided for @settingsSickMode.
  ///
  /// In es, this message translates to:
  /// **'Modo enfermedad'**
  String get settingsSickMode;

  /// No description provided for @settingsSickModeSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Protege todas las rachas sin gastar escudos'**
  String get settingsSickModeSubtitle;

  /// Estado del modo enfermedad activo con días restantes
  ///
  /// In es, this message translates to:
  /// **'Activo — termina en {days, plural, =1{1 día} other{{days} días}}'**
  String settingsSickModeActive(int days);

  /// No description provided for @settingsSickModeDialogTitle.
  ///
  /// In es, this message translates to:
  /// **'Modo enfermedad'**
  String get settingsSickModeDialogTitle;

  /// No description provided for @settingsSickModeDialogContent.
  ///
  /// In es, this message translates to:
  /// **'Tus rachas quedarán protegidas durante este período. Máximo 7 días.'**
  String get settingsSickModeDialogContent;

  /// No description provided for @settingsShieldsTile.
  ///
  /// In es, this message translates to:
  /// **'Escudos de racha'**
  String get settingsShieldsTile;

  /// No description provided for @settingsShieldsCount.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{{count} disponible de 5} other{{count} disponibles de 5}}'**
  String settingsShieldsCount(int count);

  /// No description provided for @settingsShieldsTooltip.
  ///
  /// In es, this message translates to:
  /// **'Gana escudos completando rachas de 7, 30 y 90 días.\nÚsalos en HabitAI para proteger tu racha si fallas un día.'**
  String get settingsShieldsTooltip;

  /// No description provided for @themeLight.
  ///
  /// In es, this message translates to:
  /// **'Claro'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In es, this message translates to:
  /// **'Oscuro'**
  String get themeDark;

  /// No description provided for @themeAuto.
  ///
  /// In es, this message translates to:
  /// **'Auto'**
  String get themeAuto;

  /// No description provided for @languageSelectorLabel.
  ///
  /// In es, this message translates to:
  /// **'Idioma'**
  String get languageSelectorLabel;

  /// No description provided for @languageEs.
  ///
  /// In es, this message translates to:
  /// **'Español'**
  String get languageEs;

  /// No description provided for @languageEn.
  ///
  /// In es, this message translates to:
  /// **'English'**
  String get languageEn;
}

class _SDelegate extends LocalizationsDelegate<S> {
  const _SDelegate();

  @override
  Future<S> load(Locale locale) {
    return SynchronousFuture<S>(lookupS(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_SDelegate old) => false;
}

S lookupS(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return SEn();
    case 'es':
      return SEs();
  }

  throw FlutterError(
    'S.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
