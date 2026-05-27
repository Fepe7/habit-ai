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

  /// No description provided for @authLoginTitle.
  ///
  /// In es, this message translates to:
  /// **'Iniciar sesión'**
  String get authLoginTitle;

  /// No description provided for @authRegisterTitle.
  ///
  /// In es, this message translates to:
  /// **'Crear cuenta'**
  String get authRegisterTitle;

  /// No description provided for @authTagline.
  ///
  /// In es, this message translates to:
  /// **'Tus hábitos, potenciados con IA'**
  String get authTagline;

  /// No description provided for @authRegisterTagline.
  ///
  /// In es, this message translates to:
  /// **'Empieza a construir mejores hábitos'**
  String get authRegisterTagline;

  /// No description provided for @authEmail.
  ///
  /// In es, this message translates to:
  /// **'Correo electrónico'**
  String get authEmail;

  /// No description provided for @authEmailHint.
  ///
  /// In es, this message translates to:
  /// **'Introduce tu correo electrónico'**
  String get authEmailHint;

  /// No description provided for @authEmailInvalid.
  ///
  /// In es, this message translates to:
  /// **'Introduce un correo válido'**
  String get authEmailInvalid;

  /// No description provided for @authPassword.
  ///
  /// In es, this message translates to:
  /// **'Contraseña'**
  String get authPassword;

  /// No description provided for @authPasswordHint.
  ///
  /// In es, this message translates to:
  /// **'Introduce tu contraseña'**
  String get authPasswordHint;

  /// No description provided for @authPasswordMin.
  ///
  /// In es, this message translates to:
  /// **'Mínimo 6 caracteres'**
  String get authPasswordMin;

  /// No description provided for @authPasswordConfirm.
  ///
  /// In es, this message translates to:
  /// **'Confirmar contraseña'**
  String get authPasswordConfirm;

  /// No description provided for @authPasswordMismatch.
  ///
  /// In es, this message translates to:
  /// **'Las contraseñas no coinciden'**
  String get authPasswordMismatch;

  /// No description provided for @authName.
  ///
  /// In es, this message translates to:
  /// **'Nombre'**
  String get authName;

  /// No description provided for @authNameHint.
  ///
  /// In es, this message translates to:
  /// **'Tu nombre real'**
  String get authNameHint;

  /// No description provided for @authNameRequired.
  ///
  /// In es, this message translates to:
  /// **'Introduce tu nombre'**
  String get authNameRequired;

  /// No description provided for @authUsername.
  ///
  /// In es, this message translates to:
  /// **'Nombre de usuario'**
  String get authUsername;

  /// No description provided for @authUsernameHint.
  ///
  /// In es, this message translates to:
  /// **'tunombre'**
  String get authUsernameHint;

  /// No description provided for @authUsernameAvailable.
  ///
  /// In es, this message translates to:
  /// **'¡Disponible!'**
  String get authUsernameAvailable;

  /// No description provided for @authUsernameTaken.
  ///
  /// In es, this message translates to:
  /// **'Ya está en uso, prueba otro'**
  String get authUsernameTaken;

  /// No description provided for @authUsernameHelp.
  ///
  /// In es, this message translates to:
  /// **'Te identifica en retos y amigos • 3-20 caracteres'**
  String get authUsernameHelp;

  /// No description provided for @authUsernameRequired.
  ///
  /// In es, this message translates to:
  /// **'Elige un nombre de usuario'**
  String get authUsernameRequired;

  /// No description provided for @authUsernameFormat.
  ///
  /// In es, this message translates to:
  /// **'Solo letras minúsculas, números y _ (3-20 caracteres)'**
  String get authUsernameFormat;

  /// No description provided for @authUsernameCheckFirst.
  ///
  /// In es, this message translates to:
  /// **'Comprueba la disponibilidad del username'**
  String get authUsernameCheckFirst;

  /// No description provided for @authUsernameRequiredFull.
  ///
  /// In es, this message translates to:
  /// **'Elige un nombre de usuario válido y disponible'**
  String get authUsernameRequiredFull;

  /// No description provided for @authOrSeparator.
  ///
  /// In es, this message translates to:
  /// **'o'**
  String get authOrSeparator;

  /// No description provided for @authContinueWithGoogle.
  ///
  /// In es, this message translates to:
  /// **'Continuar con Google'**
  String get authContinueWithGoogle;

  /// No description provided for @authSignIn.
  ///
  /// In es, this message translates to:
  /// **'Iniciar sesión'**
  String get authSignIn;

  /// No description provided for @authNoAccount.
  ///
  /// In es, this message translates to:
  /// **'¿No tienes cuenta? '**
  String get authNoAccount;

  /// No description provided for @authRegisterLink.
  ///
  /// In es, this message translates to:
  /// **'Regístrate'**
  String get authRegisterLink;

  /// No description provided for @authHaveAccount.
  ///
  /// In es, this message translates to:
  /// **'¿Ya tienes cuenta? '**
  String get authHaveAccount;

  /// No description provided for @authSignInLink.
  ///
  /// In es, this message translates to:
  /// **'Inicia sesión'**
  String get authSignInLink;

  /// No description provided for @authPrivacyPrefix.
  ///
  /// In es, this message translates to:
  /// **'Al crear tu cuenta aceptas la '**
  String get authPrivacyPrefix;

  /// No description provided for @authPrivacyPolicy.
  ///
  /// In es, this message translates to:
  /// **'Política de Privacidad'**
  String get authPrivacyPolicy;

  /// No description provided for @authPrivacyMiddle.
  ///
  /// In es, this message translates to:
  /// **' y los '**
  String get authPrivacyMiddle;

  /// No description provided for @authTermsOfUse.
  ///
  /// In es, this message translates to:
  /// **'Términos de Uso'**
  String get authTermsOfUse;

  /// No description provided for @navHabits.
  ///
  /// In es, this message translates to:
  /// **'Hábitos'**
  String get navHabits;

  /// No description provided for @navProgress.
  ///
  /// In es, this message translates to:
  /// **'Progreso'**
  String get navProgress;

  /// No description provided for @navAssistant.
  ///
  /// In es, this message translates to:
  /// **'Asistente'**
  String get navAssistant;

  /// No description provided for @navExplore.
  ///
  /// In es, this message translates to:
  /// **'Explorar'**
  String get navExplore;

  /// No description provided for @navProfile.
  ///
  /// In es, this message translates to:
  /// **'Perfil'**
  String get navProfile;

  /// No description provided for @navNewFollowRequest.
  ///
  /// In es, this message translates to:
  /// **'Nueva solicitud de seguimiento'**
  String get navNewFollowRequest;

  /// No description provided for @navFollowRequestBody.
  ///
  /// In es, this message translates to:
  /// **'@{username} quiere seguirte'**
  String navFollowRequestBody(String username);

  /// No description provided for @navFollowAccepted.
  ///
  /// In es, this message translates to:
  /// **'¡Solicitud aceptada!'**
  String get navFollowAccepted;

  /// No description provided for @navFollowAcceptedBody.
  ///
  /// In es, this message translates to:
  /// **'@{username} aceptó tu solicitud'**
  String navFollowAcceptedBody(String username);

  /// No description provided for @drawerProgress.
  ///
  /// In es, this message translates to:
  /// **'Tu progreso'**
  String get drawerProgress;

  /// No description provided for @drawerAchievements.
  ///
  /// In es, this message translates to:
  /// **'Logros'**
  String get drawerAchievements;

  /// No description provided for @drawerAchievementsSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Lo que has desbloqueado'**
  String get drawerAchievementsSubtitle;

  /// No description provided for @drawerLevels.
  ///
  /// In es, this message translates to:
  /// **'Niveles'**
  String get drawerLevels;

  /// No description provided for @drawerLevelsSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Tu progreso por categoría'**
  String get drawerLevelsSubtitle;

  /// No description provided for @drawerAllHabits.
  ///
  /// In es, this message translates to:
  /// **'Todos mis hábitos'**
  String get drawerAllHabits;

  /// No description provided for @drawerAllHabitsSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Activos y archivados'**
  String get drawerAllHabitsSubtitle;

  /// No description provided for @drawerWeeklyReview.
  ///
  /// In es, this message translates to:
  /// **'Revisión semanal'**
  String get drawerWeeklyReview;

  /// No description provided for @drawerWeeklyReviewSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Análisis de la IA'**
  String get drawerWeeklyReviewSubtitle;

  /// No description provided for @drawerButterfly.
  ///
  /// In es, this message translates to:
  /// **'Efecto Mariposa'**
  String get drawerButterfly;

  /// No description provided for @drawerButterflySubtitle.
  ///
  /// In es, this message translates to:
  /// **'Proyección a 3 años'**
  String get drawerButterflySubtitle;

  /// No description provided for @drawerQuickActions.
  ///
  /// In es, this message translates to:
  /// **'Acciones rápidas'**
  String get drawerQuickActions;

  /// No description provided for @drawerCreateHabit.
  ///
  /// In es, this message translates to:
  /// **'Crear hábito'**
  String get drawerCreateHabit;

  /// No description provided for @drawerCreateHabitSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Manual, sin IA'**
  String get drawerCreateHabitSubtitle;

  /// No description provided for @drawerChatAI.
  ///
  /// In es, this message translates to:
  /// **'Chat con la IA'**
  String get drawerChatAI;

  /// No description provided for @drawerChatAISubtitle.
  ///
  /// In es, this message translates to:
  /// **'Genera un plan nuevo'**
  String get drawerChatAISubtitle;

  /// No description provided for @drawerPreferences.
  ///
  /// In es, this message translates to:
  /// **'Preferencias'**
  String get drawerPreferences;

  /// No description provided for @drawerSettings.
  ///
  /// In es, this message translates to:
  /// **'Ajustes'**
  String get drawerSettings;

  /// No description provided for @drawerSettingsSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Tema, notificaciones, cuenta'**
  String get drawerSettingsSubtitle;

  /// No description provided for @drawerMenu.
  ///
  /// In es, this message translates to:
  /// **'Menú'**
  String get drawerMenu;

  /// No description provided for @drawerNoWeeklyReview.
  ///
  /// In es, this message translates to:
  /// **'Aún no hay revisión semanal'**
  String get drawerNoWeeklyReview;

  /// No description provided for @drawerNoButterfly.
  ///
  /// In es, this message translates to:
  /// **'Aún no hay proyección mensual'**
  String get drawerNoButterfly;

  /// No description provided for @drawerHabitCreated.
  ///
  /// In es, this message translates to:
  /// **'Hábito creado'**
  String get drawerHabitCreated;

  /// No description provided for @drawerHabitCreateError.
  ///
  /// In es, this message translates to:
  /// **'Error al crear el hábito'**
  String get drawerHabitCreateError;

  /// No description provided for @drawerShields.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{{count} escudo} other{{count} escudos}}'**
  String drawerShields(int count);

  /// No description provided for @drawerStreakFreeze.
  ///
  /// In es, this message translates to:
  /// **'Congela rachas si fallas'**
  String get drawerStreakFreeze;

  /// No description provided for @drawerSickMode.
  ///
  /// In es, this message translates to:
  /// **'Modo enfermedad'**
  String get drawerSickMode;

  /// No description provided for @dashboardTitle.
  ///
  /// In es, this message translates to:
  /// **'Progreso'**
  String get dashboardTitle;

  /// No description provided for @dashboardGreeting.
  ///
  /// In es, this message translates to:
  /// **'Hola, {name}'**
  String dashboardGreeting(String name);

  /// No description provided for @dashboardWeekProgress.
  ///
  /// In es, this message translates to:
  /// **'Tu avance esta semana'**
  String get dashboardWeekProgress;

  /// No description provided for @dashboardWeeklyReviewNeedMore.
  ///
  /// In es, this message translates to:
  /// **'Necesitas al menos 3 check-ins esta semana para generar la revisión'**
  String get dashboardWeeklyReviewNeedMore;

  /// No description provided for @dashboardButterflyNeedMore.
  ///
  /// In es, this message translates to:
  /// **'Necesitas al menos 10 check-ins este mes para generar la proyección'**
  String get dashboardButterflyNeedMore;

  /// No description provided for @dashboardPatternsNeedMore.
  ///
  /// In es, this message translates to:
  /// **'Necesitas al menos 14 días con datos y 3 hábitos activos para detectar patrones'**
  String get dashboardPatternsNeedMore;

  /// No description provided for @dashboardSmartAdjust.
  ///
  /// In es, this message translates to:
  /// **'Ajuste inteligente'**
  String get dashboardSmartAdjust;

  /// No description provided for @dashboardAIPersonalized.
  ///
  /// In es, this message translates to:
  /// **'IA · Personalizado'**
  String get dashboardAIPersonalized;

  /// No description provided for @dashboardAdjustDescription.
  ///
  /// In es, this message translates to:
  /// **'¿Algún hábito que no arranca? La IA analiza tus patrones y propone cambios concretos.'**
  String get dashboardAdjustDescription;

  /// No description provided for @dashboardAnalyzing.
  ///
  /// In es, this message translates to:
  /// **'Analizando…'**
  String get dashboardAnalyzing;

  /// No description provided for @dashboardRequestAdjust.
  ///
  /// In es, this message translates to:
  /// **'Pedir ajuste'**
  String get dashboardRequestAdjust;

  /// No description provided for @dashboardSuggestedAdjusts.
  ///
  /// In es, this message translates to:
  /// **'Ajustes sugeridos'**
  String get dashboardSuggestedAdjusts;

  /// No description provided for @dashboardSelectHabit.
  ///
  /// In es, this message translates to:
  /// **'Selecciona un hábito'**
  String get dashboardSelectHabit;

  /// No description provided for @dashboardNoActiveHabits.
  ///
  /// In es, this message translates to:
  /// **'No tienes hábitos activos'**
  String get dashboardNoActiveHabits;

  /// No description provided for @dashboardStreakDays.
  ///
  /// In es, this message translates to:
  /// **'Racha: {days, plural, =1{1 día} other{{days} días}}'**
  String dashboardStreakDays(int days);

  /// No description provided for @dashboardAdjustGenerated.
  ///
  /// In es, this message translates to:
  /// **'Sugerencia generada. Revísala arriba.'**
  String get dashboardAdjustGenerated;

  /// No description provided for @dashboardAdjustNotNeeded.
  ///
  /// In es, this message translates to:
  /// **'Este hábito aún no necesita ajuste — falla menos de 3 días seguidos.'**
  String get dashboardAdjustNotNeeded;

  /// No description provided for @dashboardAdjustPending.
  ///
  /// In es, this message translates to:
  /// **'Ya hay una sugerencia pendiente para este hábito.'**
  String get dashboardAdjustPending;

  /// No description provided for @dashboardAdjustError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo generar el ajuste ({reason}).'**
  String dashboardAdjustError(String reason);

  /// No description provided for @dashboardPatternsTitle.
  ///
  /// In es, this message translates to:
  /// **'Patrones IA'**
  String get dashboardPatternsTitle;

  /// No description provided for @dashboardPatternsSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Descubre correlaciones ocultas entre tus hábitos'**
  String get dashboardPatternsSubtitle;

  /// No description provided for @dashboardDetectPatterns.
  ///
  /// In es, this message translates to:
  /// **'Detectar patrones'**
  String get dashboardDetectPatterns;

  /// No description provided for @dashboardGenerating.
  ///
  /// In es, this message translates to:
  /// **'Generando…'**
  String get dashboardGenerating;

  /// No description provided for @dashboardButterflyTitle.
  ///
  /// In es, this message translates to:
  /// **'Efecto Mariposa'**
  String get dashboardButterflyTitle;

  /// No description provided for @dashboardButterflySubtitle.
  ///
  /// In es, this message translates to:
  /// **'Descubre cómo serás en 3 años si mantienes tus hábitos'**
  String get dashboardButterflySubtitle;

  /// No description provided for @dashboardGenerateProjection.
  ///
  /// In es, this message translates to:
  /// **'Generar proyección'**
  String get dashboardGenerateProjection;

  /// No description provided for @dashboardWeeklyReviewTitle.
  ///
  /// In es, this message translates to:
  /// **'Revisión semanal'**
  String get dashboardWeeklyReviewTitle;

  /// No description provided for @dashboardWeeklyReviewSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Pide a la IA que analice tu semana: rachas, wins y áreas de mejora'**
  String get dashboardWeeklyReviewSubtitle;

  /// No description provided for @dashboardGenerateNow.
  ///
  /// In es, this message translates to:
  /// **'Generar ahora'**
  String get dashboardGenerateNow;

  /// No description provided for @dashboardRegenerate.
  ///
  /// In es, this message translates to:
  /// **'Regenerar'**
  String get dashboardRegenerate;

  /// No description provided for @dashboardRegenerating.
  ///
  /// In es, this message translates to:
  /// **'Regenerando…'**
  String get dashboardRegenerating;

  /// No description provided for @dashboardNoData.
  ///
  /// In es, this message translates to:
  /// **'Sin datos todavía'**
  String get dashboardNoData;

  /// No description provided for @dashboardNoDataSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Crea hábitos y completa check-ins para ver tus estadísticas aquí'**
  String get dashboardNoDataSubtitle;

  /// No description provided for @dashboardCreateFirstHabit.
  ///
  /// In es, this message translates to:
  /// **'Crear primer hábito'**
  String get dashboardCreateFirstHabit;

  /// No description provided for @dashboardPerfectDay.
  ///
  /// In es, this message translates to:
  /// **'¡Día perfecto!'**
  String get dashboardPerfectDay;

  /// No description provided for @dashboardToday.
  ///
  /// In es, this message translates to:
  /// **'Hoy'**
  String get dashboardToday;

  /// No description provided for @dashboardNoHabitsToday.
  ///
  /// In es, this message translates to:
  /// **'No tienes hábitos programados hoy'**
  String get dashboardNoHabitsToday;

  /// No description provided for @dashboardBestStreak.
  ///
  /// In es, this message translates to:
  /// **'Mejor racha'**
  String get dashboardBestStreak;

  /// No description provided for @dashboardCompleted.
  ///
  /// In es, this message translates to:
  /// **'Completados'**
  String get dashboardCompleted;

  /// No description provided for @dashboardPerfectDays.
  ///
  /// In es, this message translates to:
  /// **'Días perfectos'**
  String get dashboardPerfectDays;

  /// No description provided for @dashboardLastWeek.
  ///
  /// In es, this message translates to:
  /// **'Última semana'**
  String get dashboardLastWeek;

  /// No description provided for @dashboardByCategory.
  ///
  /// In es, this message translates to:
  /// **'Por categoría'**
  String get dashboardByCategory;

  /// No description provided for @dashboardActiveStreaks.
  ///
  /// In es, this message translates to:
  /// **'Rachas activas'**
  String get dashboardActiveStreaks;

  /// No description provided for @dashboardAchievements.
  ///
  /// In es, this message translates to:
  /// **'Logros'**
  String get dashboardAchievements;

  /// No description provided for @dashboardUnlockAchievements.
  ///
  /// In es, this message translates to:
  /// **'Completa hábitos para desbloquear logros'**
  String get dashboardUnlockAchievements;

  /// No description provided for @dashboardMasteryProfile.
  ///
  /// In es, this message translates to:
  /// **'Perfil de Maestría'**
  String get dashboardMasteryProfile;

  /// No description provided for @dashboardStartMastery.
  ///
  /// In es, this message translates to:
  /// **'Completa hábitos para desbloquear tu perfil de maestría.'**
  String get dashboardStartMastery;

  /// No description provided for @habitsTitle.
  ///
  /// In es, this message translates to:
  /// **'Mis hábitos'**
  String get habitsTitle;

  /// No description provided for @habitsGreeting.
  ///
  /// In es, this message translates to:
  /// **'Hola, {name}'**
  String habitsGreeting(String name);

  /// No description provided for @habitsDateFormat.
  ///
  /// In es, this message translates to:
  /// **'{day}, {date}'**
  String habitsDateFormat(String day, String date);

  /// No description provided for @habitsSelectHabits.
  ///
  /// In es, this message translates to:
  /// **'Seleccionar hábitos'**
  String get habitsSelectHabits;

  /// No description provided for @habitsSelected.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 seleccionado} other{{count} seleccionados}}'**
  String habitsSelected(int count);

  /// No description provided for @habitsMoveToGroup.
  ///
  /// In es, this message translates to:
  /// **'Mover a grupo'**
  String get habitsMoveToGroup;

  /// No description provided for @habitsDeleteSelected.
  ///
  /// In es, this message translates to:
  /// **'Eliminar seleccionados'**
  String get habitsDeleteSelected;

  /// No description provided for @habitsDeleteTitle.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{Eliminar 1 hábito} other{Eliminar {count} hábitos}}'**
  String habitsDeleteTitle(int count);

  /// No description provided for @habitsDeleteSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Se desactivarán pero se conservará el historial.'**
  String get habitsDeleteSubtitle;

  /// No description provided for @habitsDeleted.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 hábito eliminado} other{{count} hábitos eliminados}}'**
  String habitsDeleted(int count);

  /// No description provided for @habitsDeleteError.
  ///
  /// In es, this message translates to:
  /// **'Error al eliminar los hábitos'**
  String get habitsDeleteError;

  /// No description provided for @habitsDeleteSingleTitle.
  ///
  /// In es, this message translates to:
  /// **'Eliminar hábito'**
  String get habitsDeleteSingleTitle;

  /// No description provided for @habitsDeleteSingleContent.
  ///
  /// In es, this message translates to:
  /// **'¿Seguro que quieres eliminar \"{title}\"?\n\nSe desactivará pero se conservará el historial.'**
  String habitsDeleteSingleContent(String title);

  /// No description provided for @habitsDeleteSingleSuccess.
  ///
  /// In es, this message translates to:
  /// **'\"{title}\" eliminado'**
  String habitsDeleteSingleSuccess(String title);

  /// No description provided for @habitsDeleteSingleError.
  ///
  /// In es, this message translates to:
  /// **'Error al eliminar el hábito'**
  String get habitsDeleteSingleError;

  /// No description provided for @habitsUpdated.
  ///
  /// In es, this message translates to:
  /// **'Hábito actualizado'**
  String get habitsUpdated;

  /// No description provided for @habitsUpdateError.
  ///
  /// In es, this message translates to:
  /// **'Error al actualizar el hábito'**
  String get habitsUpdateError;

  /// No description provided for @habitsAdjusted.
  ///
  /// In es, this message translates to:
  /// **'Hábito ajustado ✓'**
  String get habitsAdjusted;

  /// No description provided for @habitsNoGroup.
  ///
  /// In es, this message translates to:
  /// **'Sin grupo'**
  String get habitsNoGroup;

  /// No description provided for @habitsMoved.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 hábito movido} other{{count} hábitos movidos}}'**
  String habitsMoved(int count);

  /// No description provided for @habitsMoveError.
  ///
  /// In es, this message translates to:
  /// **'Error al mover los hábitos'**
  String get habitsMoveError;

  /// No description provided for @habitsGroupCreateError.
  ///
  /// In es, this message translates to:
  /// **'Error al crear la rutina'**
  String get habitsGroupCreateError;

  /// No description provided for @habitsDeleteGroupTitle.
  ///
  /// In es, this message translates to:
  /// **'Eliminar \"{title}\"'**
  String habitsDeleteGroupTitle(String title);

  /// No description provided for @habitsDeleteGroupContent.
  ///
  /// In es, this message translates to:
  /// **'¿Qué quieres hacer con los hábitos de esta rutina?'**
  String get habitsDeleteGroupContent;

  /// No description provided for @habitsDeleteGroupOnly.
  ///
  /// In es, this message translates to:
  /// **'Solo la rutina'**
  String get habitsDeleteGroupOnly;

  /// No description provided for @habitsDeleteGroupAndHabits.
  ///
  /// In es, this message translates to:
  /// **'Rutina y hábitos'**
  String get habitsDeleteGroupAndHabits;

  /// No description provided for @habitsGroupDeleted.
  ///
  /// In es, this message translates to:
  /// **'Rutina \"{title}\" eliminada'**
  String habitsGroupDeleted(String title);

  /// No description provided for @habitsGroupDeleteError.
  ///
  /// In es, this message translates to:
  /// **'Error al eliminar la rutina'**
  String get habitsGroupDeleteError;

  /// No description provided for @habitsDragToReorder.
  ///
  /// In es, this message translates to:
  /// **'Arrastra para reordenar'**
  String get habitsDragToReorder;

  /// No description provided for @habitsDone.
  ///
  /// In es, this message translates to:
  /// **'Listo'**
  String get habitsDone;

  /// No description provided for @habitsCreate.
  ///
  /// In es, this message translates to:
  /// **'Crear'**
  String get habitsCreate;

  /// No description provided for @habitsChainLabel.
  ///
  /// In es, this message translates to:
  /// **'CADENA'**
  String get habitsChainLabel;

  /// No description provided for @habitsTotalCount.
  ///
  /// In es, this message translates to:
  /// **'·  {count} hábitos'**
  String habitsTotalCount(int count);

  /// No description provided for @habitsProgressToday.
  ///
  /// In es, this message translates to:
  /// **'Progreso de hoy'**
  String get habitsProgressToday;

  /// No description provided for @habitsAllDone.
  ///
  /// In es, this message translates to:
  /// **'¡Todo listo!'**
  String get habitsAllDone;

  /// No description provided for @habitsCompletedOf.
  ///
  /// In es, this message translates to:
  /// **'{completed} de {total} hábitos completados'**
  String habitsCompletedOf(int completed, int total);

  /// No description provided for @habitsEditGroup.
  ///
  /// In es, this message translates to:
  /// **'Editar grupo'**
  String get habitsEditGroup;

  /// No description provided for @habitsTapToAdd.
  ///
  /// In es, this message translates to:
  /// **'Toca para añadir hábitos'**
  String get habitsTapToAdd;

  /// No description provided for @habitsLoadError.
  ///
  /// In es, this message translates to:
  /// **'No se pudieron cargar tus hábitos. Comprueba tu conexión.'**
  String get habitsLoadError;

  /// No description provided for @habitsFirstChain.
  ///
  /// In es, this message translates to:
  /// **'¡Primera cadena creada!'**
  String get habitsFirstChain;

  /// No description provided for @habitsAtomicTitle.
  ///
  /// In es, this message translates to:
  /// **'Así funciona el hábito atómico'**
  String get habitsAtomicTitle;

  /// No description provided for @habitsAtomicStep1.
  ///
  /// In es, this message translates to:
  /// **'Completa el hábito ancla'**
  String get habitsAtomicStep1;

  /// No description provided for @habitsAtomicStep1Desc.
  ///
  /// In es, this message translates to:
  /// **'El primer hábito de la cadena se resalta cuando lo terminas.'**
  String get habitsAtomicStep1Desc;

  /// No description provided for @habitsAtomicStep2.
  ///
  /// In es, this message translates to:
  /// **'El siguiente se ilumina'**
  String get habitsAtomicStep2;

  /// No description provided for @habitsAtomicStep2Desc.
  ///
  /// In es, this message translates to:
  /// **'Verás \"Después de X\" en el hábito encadenado. Es tu señal.'**
  String get habitsAtomicStep2Desc;

  /// No description provided for @habitsAtomicStep3.
  ///
  /// In es, this message translates to:
  /// **'Completa toda la cadena'**
  String get habitsAtomicStep3;

  /// No description provided for @habitsAtomicStep3Desc.
  ///
  /// In es, this message translates to:
  /// **'Cuando terminas todos recibes una celebración especial 🔥'**
  String get habitsAtomicStep3Desc;

  /// No description provided for @habitsAtomicGotIt.
  ///
  /// In es, this message translates to:
  /// **'¡Entendido!'**
  String get habitsAtomicGotIt;

  /// No description provided for @habitsXpBonus.
  ///
  /// In es, this message translates to:
  /// **'+5 XP · Hábito atómico'**
  String get habitsXpBonus;

  /// No description provided for @habitDetailDescription.
  ///
  /// In es, this message translates to:
  /// **'Descripción'**
  String get habitDetailDescription;

  /// No description provided for @habitDetailDays.
  ///
  /// In es, this message translates to:
  /// **'días'**
  String get habitDetailDays;

  /// No description provided for @habitDetailCurrentStreak.
  ///
  /// In es, this message translates to:
  /// **'Racha actual'**
  String get habitDetailCurrentStreak;

  /// No description provided for @habitDetailBestStreak.
  ///
  /// In es, this message translates to:
  /// **'Mejor racha'**
  String get habitDetailBestStreak;

  /// No description provided for @habitDetailCompletedToday.
  ///
  /// In es, this message translates to:
  /// **'Completado hoy'**
  String get habitDetailCompletedToday;

  /// No description provided for @habitDetailShieldedToday.
  ///
  /// In es, this message translates to:
  /// **'Racha protegida hoy'**
  String get habitDetailShieldedToday;

  /// No description provided for @habitDetailMarkComplete.
  ///
  /// In es, this message translates to:
  /// **'Marcar como completado'**
  String get habitDetailMarkComplete;

  /// No description provided for @habitDetailUseShield.
  ///
  /// In es, this message translates to:
  /// **'Usar escudo ({count, plural, =1{1 disponible} other{{count} disponibles}})'**
  String habitDetailUseShield(int count);

  /// No description provided for @habitDetailShieldTitle.
  ///
  /// In es, this message translates to:
  /// **'Usar escudo de racha'**
  String get habitDetailShieldTitle;

  /// No description provided for @habitDetailShieldContent.
  ///
  /// In es, this message translates to:
  /// **'Gastarás 1 escudo para proteger la racha de \"{title}\" hoy.\n\nTe quedan {count} escudos.'**
  String habitDetailShieldContent(String title, int count);

  /// No description provided for @habitDetailUseShieldButton.
  ///
  /// In es, this message translates to:
  /// **'Usar escudo'**
  String get habitDetailUseShieldButton;

  /// No description provided for @habitDetailShieldUsed.
  ///
  /// In es, this message translates to:
  /// **'🛡️ Escudo usado — racha protegida'**
  String get habitDetailShieldUsed;

  /// No description provided for @habitDetailNoShields.
  ///
  /// In es, this message translates to:
  /// **'No tienes escudos disponibles'**
  String get habitDetailNoShields;

  /// No description provided for @habitDetailDeleteTitle.
  ///
  /// In es, this message translates to:
  /// **'Eliminar hábito'**
  String get habitDetailDeleteTitle;

  /// No description provided for @habitDetailDeleteContent.
  ///
  /// In es, this message translates to:
  /// **'¿Seguro que quieres eliminar \"{title}\"?\n\nSe desactivará y no aparecerá en tu lista, pero se conservará el historial.'**
  String habitDetailDeleteContent(String title);

  /// No description provided for @habitDetailDelete.
  ///
  /// In es, this message translates to:
  /// **'Eliminar'**
  String get habitDetailDelete;

  /// No description provided for @habitDetailAISuggestion.
  ///
  /// In es, this message translates to:
  /// **'Sugerencia de la IA'**
  String get habitDetailAISuggestion;

  /// No description provided for @habitDetailApplyAdjust.
  ///
  /// In es, this message translates to:
  /// **'Aplicar ajuste'**
  String get habitDetailApplyAdjust;

  /// No description provided for @habitDetailLater.
  ///
  /// In es, this message translates to:
  /// **'Ahora no'**
  String get habitDetailLater;

  /// No description provided for @habitDetailNotFound.
  ///
  /// In es, this message translates to:
  /// **'El hábito no existe o fue eliminado.'**
  String get habitDetailNotFound;

  /// No description provided for @habitDetailLogCompleted.
  ///
  /// In es, this message translates to:
  /// **'Completado'**
  String get habitDetailLogCompleted;

  /// No description provided for @habitDetailLogShield.
  ///
  /// In es, this message translates to:
  /// **'Escudo'**
  String get habitDetailLogShield;

  /// No description provided for @habitDetailLogSick.
  ///
  /// In es, this message translates to:
  /// **'Enfermedad'**
  String get habitDetailLogSick;

  /// No description provided for @habitDetailLogSickMode.
  ///
  /// In es, this message translates to:
  /// **'Modo enfermedad'**
  String get habitDetailLogSickMode;

  /// No description provided for @habitDetailLogMissed.
  ///
  /// In es, this message translates to:
  /// **'No completado'**
  String get habitDetailLogMissed;

  /// No description provided for @habitDetailFilterAll.
  ///
  /// In es, this message translates to:
  /// **'Todos'**
  String get habitDetailFilterAll;

  /// No description provided for @habitDetailFilterDaily.
  ///
  /// In es, this message translates to:
  /// **'Diario'**
  String get habitDetailFilterDaily;

  /// No description provided for @aiTitle.
  ///
  /// In es, this message translates to:
  /// **'Asistente IA'**
  String get aiTitle;

  /// No description provided for @aiSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Powered by Gemini'**
  String get aiSubtitle;

  /// No description provided for @aiWelcome.
  ///
  /// In es, this message translates to:
  /// **'¡Hola! Soy tu asistente de hábitos. Cuéntame tus metas y te generaré un plan personalizado.'**
  String get aiWelcome;

  /// No description provided for @aiOfflineError.
  ///
  /// In es, this message translates to:
  /// **'El asistente IA necesita conexión a internet'**
  String get aiOfflineError;

  /// No description provided for @aiConnectionError.
  ///
  /// In es, this message translates to:
  /// **'No pude conectar con el asistente. Comprueba tu conexión.'**
  String get aiConnectionError;

  /// No description provided for @aiHabitsAdded.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 hábito añadido} other{{count} hábitos añadidos}}'**
  String aiHabitsAdded(int count);

  /// No description provided for @aiSaveError.
  ///
  /// In es, this message translates to:
  /// **'Error al guardar los hábitos'**
  String get aiSaveError;

  /// No description provided for @aiGeminiLabel.
  ///
  /// In es, this message translates to:
  /// **'Gemini'**
  String get aiGeminiLabel;

  /// No description provided for @aiInputHint.
  ///
  /// In es, this message translates to:
  /// **'Escribe tus metas...'**
  String get aiInputHint;

  /// No description provided for @aiThinking.
  ///
  /// In es, this message translates to:
  /// **'Pensando...'**
  String get aiThinking;

  /// No description provided for @aiExploreTemplates.
  ///
  /// In es, this message translates to:
  /// **'¿Sin ideas? Explora plantillas de la comunidad'**
  String get aiExploreTemplates;

  /// No description provided for @aiSuggestion1.
  ///
  /// In es, this message translates to:
  /// **'Quiero hacer ejercicio y comer mejor'**
  String get aiSuggestion1;

  /// No description provided for @aiSuggestion2.
  ///
  /// In es, this message translates to:
  /// **'Necesito ser más productivo'**
  String get aiSuggestion2;

  /// No description provided for @aiSuggestion3.
  ///
  /// In es, this message translates to:
  /// **'Quiero leer más y dormir mejor'**
  String get aiSuggestion3;

  /// No description provided for @aiSuggestion4.
  ///
  /// In es, this message translates to:
  /// **'Mejorar mi salud mental'**
  String get aiSuggestion4;

  /// No description provided for @categorySalud.
  ///
  /// In es, this message translates to:
  /// **'Salud'**
  String get categorySalud;

  /// No description provided for @categoryProductividad.
  ///
  /// In es, this message translates to:
  /// **'Productividad'**
  String get categoryProductividad;

  /// No description provided for @categoryBienestar.
  ///
  /// In es, this message translates to:
  /// **'Bienestar'**
  String get categoryBienestar;

  /// No description provided for @categorySocial.
  ///
  /// In es, this message translates to:
  /// **'Social'**
  String get categorySocial;

  /// No description provided for @categoryAprendizaje.
  ///
  /// In es, this message translates to:
  /// **'Aprendizaje'**
  String get categoryAprendizaje;

  /// No description provided for @categoryFinanzas.
  ///
  /// In es, this message translates to:
  /// **'Finanzas'**
  String get categoryFinanzas;

  /// No description provided for @achievementsTitle.
  ///
  /// In es, this message translates to:
  /// **'Logros'**
  String get achievementsTitle;

  /// No description provided for @achievementsUnlocked.
  ///
  /// In es, this message translates to:
  /// **'{count} logros desbloqueados'**
  String achievementsUnlocked(int count);

  /// No description provided for @levelsTitle.
  ///
  /// In es, this message translates to:
  /// **'Perfil de Maestría'**
  String get levelsTitle;

  /// No description provided for @levelsMedium.
  ///
  /// In es, this message translates to:
  /// **'Nivel medio'**
  String get levelsMedium;

  /// No description provided for @levelsTotalXp.
  ///
  /// In es, this message translates to:
  /// **'{xp} XP total'**
  String levelsTotalXp(int xp);

  /// No description provided for @levelsStronger.
  ///
  /// In es, this message translates to:
  /// **'Más fuerte'**
  String get levelsStronger;

  /// No description provided for @levelsByCategory.
  ///
  /// In es, this message translates to:
  /// **'Por categoría'**
  String get levelsByCategory;

  /// No description provided for @levelsRadar.
  ///
  /// In es, this message translates to:
  /// **'Radar de habilidades'**
  String get levelsRadar;

  /// No description provided for @levelsEmpty.
  ///
  /// In es, this message translates to:
  /// **'Empieza a crear hábitos'**
  String get levelsEmpty;

  /// No description provided for @levelsEmptySubtitle.
  ///
  /// In es, this message translates to:
  /// **'Completa check-ins para subir de nivel en cada categoría.'**
  String get levelsEmptySubtitle;

  /// No description provided for @profileTitle.
  ///
  /// In es, this message translates to:
  /// **'Perfil'**
  String get profileTitle;

  /// No description provided for @profileNoHabits.
  ///
  /// In es, this message translates to:
  /// **'Sin hábitos activos'**
  String get profileNoHabits;

  /// No description provided for @profileMastery.
  ///
  /// In es, this message translates to:
  /// **'Maestría'**
  String get profileMastery;

  /// No description provided for @profileActiveHabits.
  ///
  /// In es, this message translates to:
  /// **'Hábitos activos'**
  String get profileActiveHabits;

  /// No description provided for @profileEdit.
  ///
  /// In es, this message translates to:
  /// **'Editar'**
  String get profileEdit;

  /// No description provided for @profileStreak.
  ///
  /// In es, this message translates to:
  /// **'Racha'**
  String get profileStreak;

  /// No description provided for @profileHabits.
  ///
  /// In es, this message translates to:
  /// **'Hábitos'**
  String get profileHabits;

  /// No description provided for @profileBestStreak.
  ///
  /// In es, this message translates to:
  /// **'Mejor racha'**
  String get profileBestStreak;

  /// No description provided for @profileLevel.
  ///
  /// In es, this message translates to:
  /// **'Nivel'**
  String get profileLevel;

  /// No description provided for @profileFollowers.
  ///
  /// In es, this message translates to:
  /// **'seguidores'**
  String get profileFollowers;

  /// No description provided for @profileFollowing.
  ///
  /// In es, this message translates to:
  /// **'siguiendo'**
  String get profileFollowing;

  /// No description provided for @profileBestStreakShort.
  ///
  /// In es, this message translates to:
  /// **'máx {days}d'**
  String profileBestStreakShort(int days);

  /// No description provided for @exploreTitle.
  ///
  /// In es, this message translates to:
  /// **'HabitAI'**
  String get exploreTitle;

  /// No description provided for @exploreSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Descubre hábitos\ny creadores'**
  String get exploreSubtitle;

  /// No description provided for @exploreSearchHint.
  ///
  /// In es, this message translates to:
  /// **'Buscar personas, plantillas…'**
  String get exploreSearchHint;

  /// No description provided for @exploreChallenges.
  ///
  /// In es, this message translates to:
  /// **'Retos'**
  String get exploreChallenges;

  /// No description provided for @exploreSeeAll.
  ///
  /// In es, this message translates to:
  /// **'Ver todos'**
  String get exploreSeeAll;

  /// No description provided for @exploreSeeAllAlt.
  ///
  /// In es, this message translates to:
  /// **'Ver todas'**
  String get exploreSeeAllAlt;

  /// No description provided for @exploreCreateChallenge.
  ///
  /// In es, this message translates to:
  /// **'Crea tu primer reto'**
  String get exploreCreateChallenge;

  /// No description provided for @exploreChallengeSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Reta a un amigo a un hábito compartido'**
  String get exploreChallengeSubtitle;

  /// No description provided for @exploreFeaturedTemplates.
  ///
  /// In es, this message translates to:
  /// **'Plantillas destacadas'**
  String get exploreFeaturedTemplates;

  /// No description provided for @exploreNoTemplates.
  ///
  /// In es, this message translates to:
  /// **'Aún no hay plantillas publicadas'**
  String get exploreNoTemplates;

  /// No description provided for @exploreFeaturedCreators.
  ///
  /// In es, this message translates to:
  /// **'Creadores destacados'**
  String get exploreFeaturedCreators;

  /// No description provided for @exploreNoProfiles.
  ///
  /// In es, this message translates to:
  /// **'Aún no hay perfiles públicos'**
  String get exploreNoProfiles;

  /// No description provided for @explorePeople.
  ///
  /// In es, this message translates to:
  /// **'Personas'**
  String get explorePeople;

  /// No description provided for @exploreTemplates.
  ///
  /// In es, this message translates to:
  /// **'Plantillas'**
  String get exploreTemplates;

  /// No description provided for @exploreNoResults.
  ///
  /// In es, this message translates to:
  /// **'Sin resultados'**
  String get exploreNoResults;

  /// No description provided for @exploreNoResultsHint.
  ///
  /// In es, this message translates to:
  /// **'Prueba con otro término de búsqueda.'**
  String get exploreNoResultsHint;

  /// No description provided for @explorePending.
  ///
  /// In es, this message translates to:
  /// **'Pendiente de aceptar'**
  String get explorePending;

  /// No description provided for @exploreFollowing.
  ///
  /// In es, this message translates to:
  /// **'Siguiendo'**
  String get exploreFollowing;

  /// No description provided for @exploreFollow.
  ///
  /// In es, this message translates to:
  /// **'Seguir'**
  String get exploreFollow;

  /// No description provided for @exploreRequest.
  ///
  /// In es, this message translates to:
  /// **'Solicitar'**
  String get exploreRequest;

  /// No description provided for @exploreRequested.
  ///
  /// In es, this message translates to:
  /// **'Solicitado'**
  String get exploreRequested;

  /// No description provided for @exploreImport.
  ///
  /// In es, this message translates to:
  /// **'Importar'**
  String get exploreImport;

  /// No description provided for @exploreChallengeDays.
  ///
  /// In es, this message translates to:
  /// **'{days} días'**
  String exploreChallengeDays(int days);

  /// No description provided for @exploreHabitCount.
  ///
  /// In es, this message translates to:
  /// **'{count} hábitos'**
  String exploreHabitCount(int count);

  /// No description provided for @exploreHabitCountShort.
  ///
  /// In es, this message translates to:
  /// **'{count} hab.'**
  String exploreHabitCountShort(int count);

  /// No description provided for @snackbarRetry.
  ///
  /// In es, this message translates to:
  /// **'Reintentar'**
  String get snackbarRetry;

  /// No description provided for @weekdayMonday.
  ///
  /// In es, this message translates to:
  /// **'Lunes'**
  String get weekdayMonday;

  /// No description provided for @weekdayTuesday.
  ///
  /// In es, this message translates to:
  /// **'Martes'**
  String get weekdayTuesday;

  /// No description provided for @weekdayWednesday.
  ///
  /// In es, this message translates to:
  /// **'Miércoles'**
  String get weekdayWednesday;

  /// No description provided for @weekdayThursday.
  ///
  /// In es, this message translates to:
  /// **'Jueves'**
  String get weekdayThursday;

  /// No description provided for @weekdayFriday.
  ///
  /// In es, this message translates to:
  /// **'Viernes'**
  String get weekdayFriday;

  /// No description provided for @weekdaySaturday.
  ///
  /// In es, this message translates to:
  /// **'Sábado'**
  String get weekdaySaturday;

  /// No description provided for @weekdaySunday.
  ///
  /// In es, this message translates to:
  /// **'Domingo'**
  String get weekdaySunday;

  /// No description provided for @weekdayMonShort.
  ///
  /// In es, this message translates to:
  /// **'Lun'**
  String get weekdayMonShort;

  /// No description provided for @weekdayTueShort.
  ///
  /// In es, this message translates to:
  /// **'Mar'**
  String get weekdayTueShort;

  /// No description provided for @weekdayWedShort.
  ///
  /// In es, this message translates to:
  /// **'Mié'**
  String get weekdayWedShort;

  /// No description provided for @weekdayThuShort.
  ///
  /// In es, this message translates to:
  /// **'Jue'**
  String get weekdayThuShort;

  /// No description provided for @weekdayFriShort.
  ///
  /// In es, this message translates to:
  /// **'Vie'**
  String get weekdayFriShort;

  /// No description provided for @weekdaySatShort.
  ///
  /// In es, this message translates to:
  /// **'Sáb'**
  String get weekdaySatShort;

  /// No description provided for @weekdaySunShort.
  ///
  /// In es, this message translates to:
  /// **'Dom'**
  String get weekdaySunShort;

  /// No description provided for @weekdayTodayShort.
  ///
  /// In es, this message translates to:
  /// **'Hoy'**
  String get weekdayTodayShort;

  /// No description provided for @weekdayLShort.
  ///
  /// In es, this message translates to:
  /// **'L'**
  String get weekdayLShort;

  /// No description provided for @weekdayMShort.
  ///
  /// In es, this message translates to:
  /// **'M'**
  String get weekdayMShort;

  /// No description provided for @weekdayXShort.
  ///
  /// In es, this message translates to:
  /// **'X'**
  String get weekdayXShort;

  /// No description provided for @weekdayJShort.
  ///
  /// In es, this message translates to:
  /// **'J'**
  String get weekdayJShort;

  /// No description provided for @weekdayVShort.
  ///
  /// In es, this message translates to:
  /// **'V'**
  String get weekdayVShort;

  /// No description provided for @weekdaySShort.
  ///
  /// In es, this message translates to:
  /// **'S'**
  String get weekdaySShort;

  /// No description provided for @weekdayDShort.
  ///
  /// In es, this message translates to:
  /// **'D'**
  String get weekdayDShort;

  /// No description provided for @monthJan.
  ///
  /// In es, this message translates to:
  /// **'ene'**
  String get monthJan;

  /// No description provided for @monthFeb.
  ///
  /// In es, this message translates to:
  /// **'feb'**
  String get monthFeb;

  /// No description provided for @monthMar.
  ///
  /// In es, this message translates to:
  /// **'mar'**
  String get monthMar;

  /// No description provided for @monthApr.
  ///
  /// In es, this message translates to:
  /// **'abr'**
  String get monthApr;

  /// No description provided for @monthMay.
  ///
  /// In es, this message translates to:
  /// **'may'**
  String get monthMay;

  /// No description provided for @monthJun.
  ///
  /// In es, this message translates to:
  /// **'jun'**
  String get monthJun;

  /// No description provided for @monthJul.
  ///
  /// In es, this message translates to:
  /// **'jul'**
  String get monthJul;

  /// No description provided for @monthAug.
  ///
  /// In es, this message translates to:
  /// **'ago'**
  String get monthAug;

  /// No description provided for @monthSep.
  ///
  /// In es, this message translates to:
  /// **'sep'**
  String get monthSep;

  /// No description provided for @monthOct.
  ///
  /// In es, this message translates to:
  /// **'oct'**
  String get monthOct;

  /// No description provided for @monthNov.
  ///
  /// In es, this message translates to:
  /// **'nov'**
  String get monthNov;

  /// No description provided for @monthDec.
  ///
  /// In es, this message translates to:
  /// **'dic'**
  String get monthDec;
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
