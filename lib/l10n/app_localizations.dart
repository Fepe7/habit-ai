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

  /// No description provided for @settingsRateApp.
  ///
  /// In es, this message translates to:
  /// **'Valorar HabitAI'**
  String get settingsRateApp;

  /// No description provided for @settingsRateAppSubtitle.
  ///
  /// In es, this message translates to:
  /// **'¿Te gusta la app? Déjanos una reseña'**
  String get settingsRateAppSubtitle;

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

  /// No description provided for @achievementUnlockedBanner.
  ///
  /// In es, this message translates to:
  /// **'¡Logro desbloqueado!'**
  String get achievementUnlockedBanner;

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

  /// No description provided for @levelNvl.
  ///
  /// In es, this message translates to:
  /// **'Nvl {n}'**
  String levelNvl(int n);

  /// No description provided for @levelNvlShort.
  ///
  /// In es, this message translates to:
  /// **'Nvl'**
  String get levelNvlShort;

  /// No description provided for @levelMaxShort.
  ///
  /// In es, this message translates to:
  /// **'Máx.'**
  String get levelMaxShort;

  /// No description provided for @levelXpAccum.
  ///
  /// In es, this message translates to:
  /// **'XP acumulado'**
  String get levelXpAccum;

  /// No description provided for @levelHowToEarnXp.
  ///
  /// In es, this message translates to:
  /// **'Cómo ganar XP'**
  String get levelHowToEarnXp;

  /// No description provided for @levelXpTipCheckin.
  ///
  /// In es, this message translates to:
  /// **'+10 XP por cada check-in completado'**
  String get levelXpTipCheckin;

  /// No description provided for @levelXpTipStreak.
  ///
  /// In es, this message translates to:
  /// **'+5 XP por día de racha activa (máx. +50)'**
  String get levelXpTipStreak;

  /// No description provided for @levelXpTipAchievement.
  ///
  /// In es, this message translates to:
  /// **'+50 XP por cada logro desbloqueado'**
  String get levelXpTipAchievement;

  /// No description provided for @levelXpToNext.
  ///
  /// In es, this message translates to:
  /// **'Faltan {xp} XP para {title}'**
  String levelXpToNext(int xp, String title);

  /// No description provided for @levelMaxReached.
  ///
  /// In es, this message translates to:
  /// **'¡Nivel máximo alcanzado!'**
  String get levelMaxReached;

  /// No description provided for @levelSalud1.
  ///
  /// In es, this message translates to:
  /// **'Novato'**
  String get levelSalud1;

  /// No description provided for @levelSalud2.
  ///
  /// In es, this message translates to:
  /// **'Atleta'**
  String get levelSalud2;

  /// No description provided for @levelSalud3.
  ///
  /// In es, this message translates to:
  /// **'Guerrero'**
  String get levelSalud3;

  /// No description provided for @levelSalud4.
  ///
  /// In es, this message translates to:
  /// **'Campeón'**
  String get levelSalud4;

  /// No description provided for @levelSalud5.
  ///
  /// In es, this message translates to:
  /// **'Titán'**
  String get levelSalud5;

  /// No description provided for @levelProductividad1.
  ///
  /// In es, this message translates to:
  /// **'Aprendiz'**
  String get levelProductividad1;

  /// No description provided for @levelProductividad2.
  ///
  /// In es, this message translates to:
  /// **'Organizado'**
  String get levelProductividad2;

  /// No description provided for @levelProductividad3.
  ///
  /// In es, this message translates to:
  /// **'Estratega'**
  String get levelProductividad3;

  /// No description provided for @levelProductividad4.
  ///
  /// In es, this message translates to:
  /// **'Ejecutor'**
  String get levelProductividad4;

  /// No description provided for @levelProductividad5.
  ///
  /// In es, this message translates to:
  /// **'Maestro'**
  String get levelProductividad5;

  /// No description provided for @levelBienestar1.
  ///
  /// In es, this message translates to:
  /// **'Inquieto'**
  String get levelBienestar1;

  /// No description provided for @levelBienestar2.
  ///
  /// In es, this message translates to:
  /// **'Sereno'**
  String get levelBienestar2;

  /// No description provided for @levelBienestar3.
  ///
  /// In es, this message translates to:
  /// **'Equilibrado'**
  String get levelBienestar3;

  /// No description provided for @levelBienestar4.
  ///
  /// In es, this message translates to:
  /// **'Zen'**
  String get levelBienestar4;

  /// No description provided for @levelBienestar5.
  ///
  /// In es, this message translates to:
  /// **'Iluminado'**
  String get levelBienestar5;

  /// No description provided for @levelSocial1.
  ///
  /// In es, this message translates to:
  /// **'Tímido'**
  String get levelSocial1;

  /// No description provided for @levelSocial2.
  ///
  /// In es, this message translates to:
  /// **'Amigable'**
  String get levelSocial2;

  /// No description provided for @levelSocial3.
  ///
  /// In es, this message translates to:
  /// **'Conector'**
  String get levelSocial3;

  /// No description provided for @levelSocial4.
  ///
  /// In es, this message translates to:
  /// **'Líder'**
  String get levelSocial4;

  /// No description provided for @levelSocial5.
  ///
  /// In es, this message translates to:
  /// **'Embajador'**
  String get levelSocial5;

  /// No description provided for @levelAprendizaje1.
  ///
  /// In es, this message translates to:
  /// **'Curioso'**
  String get levelAprendizaje1;

  /// No description provided for @levelAprendizaje2.
  ///
  /// In es, this message translates to:
  /// **'Estudiante'**
  String get levelAprendizaje2;

  /// No description provided for @levelAprendizaje3.
  ///
  /// In es, this message translates to:
  /// **'Erudito'**
  String get levelAprendizaje3;

  /// No description provided for @levelAprendizaje4.
  ///
  /// In es, this message translates to:
  /// **'Sabio'**
  String get levelAprendizaje4;

  /// No description provided for @levelAprendizaje5.
  ///
  /// In es, this message translates to:
  /// **'Maestro'**
  String get levelAprendizaje5;

  /// No description provided for @levelFinanzas1.
  ///
  /// In es, this message translates to:
  /// **'Ahorrador'**
  String get levelFinanzas1;

  /// No description provided for @levelFinanzas2.
  ///
  /// In es, this message translates to:
  /// **'Prudente'**
  String get levelFinanzas2;

  /// No description provided for @levelFinanzas3.
  ///
  /// In es, this message translates to:
  /// **'Inversor'**
  String get levelFinanzas3;

  /// No description provided for @levelFinanzas4.
  ///
  /// In es, this message translates to:
  /// **'Magnate'**
  String get levelFinanzas4;

  /// No description provided for @levelFinanzas5.
  ///
  /// In es, this message translates to:
  /// **'Mecenas'**
  String get levelFinanzas5;

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

  /// No description provided for @profileEditButton.
  ///
  /// In es, this message translates to:
  /// **'Editar perfil'**
  String get profileEditButton;

  /// No description provided for @profileOpenSettings.
  ///
  /// In es, this message translates to:
  /// **'Ajustes'**
  String get profileOpenSettings;

  /// No description provided for @editProfileTitle.
  ///
  /// In es, this message translates to:
  /// **'Editar perfil'**
  String get editProfileTitle;

  /// No description provided for @editProfileSave.
  ///
  /// In es, this message translates to:
  /// **'Guardar'**
  String get editProfileSave;

  /// No description provided for @editProfileNameLabel.
  ///
  /// In es, this message translates to:
  /// **'Nombre'**
  String get editProfileNameLabel;

  /// No description provided for @editProfileBioLabel.
  ///
  /// In es, this message translates to:
  /// **'Biografía'**
  String get editProfileBioLabel;

  /// No description provided for @editProfileBioHint.
  ///
  /// In es, this message translates to:
  /// **'Cuéntale al mundo sobre tus hábitos…'**
  String get editProfileBioHint;

  /// No description provided for @editProfileChangePhoto.
  ///
  /// In es, this message translates to:
  /// **'Cambiar foto'**
  String get editProfileChangePhoto;

  /// No description provided for @editProfileUsernameLabel.
  ///
  /// In es, this message translates to:
  /// **'Nombre de usuario'**
  String get editProfileUsernameLabel;

  /// No description provided for @editProfileChooseUsername.
  ///
  /// In es, this message translates to:
  /// **'Elegir nombre de usuario'**
  String get editProfileChooseUsername;

  /// No description provided for @editProfileSaved.
  ///
  /// In es, this message translates to:
  /// **'Perfil actualizado'**
  String get editProfileSaved;

  /// No description provided for @editProfileSaveError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo guardar el perfil'**
  String get editProfileSaveError;

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

  /// No description provided for @exploreByAuthor.
  ///
  /// In es, this message translates to:
  /// **'Por @{username}'**
  String exploreByAuthor(String username);

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

  /// No description provided for @habitFieldTitle.
  ///
  /// In es, this message translates to:
  /// **'Título'**
  String get habitFieldTitle;

  /// No description provided for @habitFieldDescription.
  ///
  /// In es, this message translates to:
  /// **'Descripción'**
  String get habitFieldDescription;

  /// No description provided for @habitFieldOptional.
  ///
  /// In es, this message translates to:
  /// **'Opcional'**
  String get habitFieldOptional;

  /// No description provided for @habitFieldCategory.
  ///
  /// In es, this message translates to:
  /// **'Categoría'**
  String get habitFieldCategory;

  /// No description provided for @habitFieldWeekdays.
  ///
  /// In es, this message translates to:
  /// **'Días de la semana'**
  String get habitFieldWeekdays;

  /// No description provided for @habitFieldReminder.
  ///
  /// In es, this message translates to:
  /// **'Recordatorio'**
  String get habitFieldReminder;

  /// No description provided for @habitNoReminder.
  ///
  /// In es, this message translates to:
  /// **'Sin recordatorio'**
  String get habitNoReminder;

  /// No description provided for @createHabitTitle.
  ///
  /// In es, this message translates to:
  /// **'Nuevo hábito'**
  String get createHabitTitle;

  /// No description provided for @createHabitTitleHint.
  ///
  /// In es, this message translates to:
  /// **'Ej: Leer 20 minutos'**
  String get createHabitTitleHint;

  /// No description provided for @createHabitGroupLabel.
  ///
  /// In es, this message translates to:
  /// **'Grupo'**
  String get createHabitGroupLabel;

  /// No description provided for @createHabitGroupHint.
  ///
  /// In es, this message translates to:
  /// **'Agrupa este hábito con otros relacionados'**
  String get createHabitGroupHint;

  /// No description provided for @createHabitNoGroup.
  ///
  /// In es, this message translates to:
  /// **'Sin grupo'**
  String get createHabitNoGroup;

  /// No description provided for @createHabitChainLabel.
  ///
  /// In es, this message translates to:
  /// **'Encadenar después de...'**
  String get createHabitChainLabel;

  /// No description provided for @createHabitChainHint.
  ///
  /// In es, this message translates to:
  /// **'Se mostrará como siguiente paso al completar el hábito ancla'**
  String get createHabitChainHint;

  /// No description provided for @createHabitChainNone.
  ///
  /// In es, this message translates to:
  /// **'Ninguno'**
  String get createHabitChainNone;

  /// No description provided for @createHabitCta.
  ///
  /// In es, this message translates to:
  /// **'Crear hábito'**
  String get createHabitCta;

  /// No description provided for @editHabitTitle.
  ///
  /// In es, this message translates to:
  /// **'Editar hábito'**
  String get editHabitTitle;

  /// No description provided for @editHabitTitleHint.
  ///
  /// In es, this message translates to:
  /// **'Ej: Correr 30 minutos'**
  String get editHabitTitleHint;

  /// No description provided for @editHabitRoutineLabel.
  ///
  /// In es, this message translates to:
  /// **'Rutina'**
  String get editHabitRoutineLabel;

  /// No description provided for @editHabitNoRoutine.
  ///
  /// In es, this message translates to:
  /// **'Sin rutina'**
  String get editHabitNoRoutine;

  /// No description provided for @editHabitChainLabel.
  ///
  /// In es, this message translates to:
  /// **'Cadena de hábitos'**
  String get editHabitChainLabel;

  /// No description provided for @editHabitChainedCount.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 hábito encadenado} other{{count} hábitos encadenados}}'**
  String editHabitChainedCount(int count);

  /// No description provided for @editHabitChainThis.
  ///
  /// In es, this message translates to:
  /// **'← este'**
  String get editHabitChainThis;

  /// No description provided for @editHabitChainRemove.
  ///
  /// In es, this message translates to:
  /// **'Quitar de la cadena'**
  String get editHabitChainRemove;

  /// No description provided for @editHabitNoChain.
  ///
  /// In es, this message translates to:
  /// **'Este hábito no pertenece a ninguna cadena. Puedes encadenarlo al crear hábitos nuevos.'**
  String get editHabitNoChain;

  /// No description provided for @editHabitSaveCta.
  ///
  /// In es, this message translates to:
  /// **'Guardar cambios'**
  String get editHabitSaveCta;

  /// No description provided for @commonDelete.
  ///
  /// In es, this message translates to:
  /// **'Eliminar'**
  String get commonDelete;

  /// No description provided for @commonCancel.
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get commonCancel;

  /// No description provided for @commonEdit.
  ///
  /// In es, this message translates to:
  /// **'Editar'**
  String get commonEdit;

  /// No description provided for @habitCardAfter.
  ///
  /// In es, this message translates to:
  /// **'Después de \"{title}\"'**
  String habitCardAfter(String title);

  /// No description provided for @habitCardNext.
  ///
  /// In es, this message translates to:
  /// **'¡Siguiente!'**
  String get habitCardNext;

  /// No description provided for @habitCardCoachLabel.
  ///
  /// In es, this message translates to:
  /// **'– COACH · PREGUNTA DEL DÍA'**
  String get habitCardCoachLabel;

  /// No description provided for @habitCardCoachApply.
  ///
  /// In es, this message translates to:
  /// **'SÍ, HAZLO →'**
  String get habitCardCoachApply;

  /// No description provided for @habitCardCoachDismiss.
  ///
  /// In es, this message translates to:
  /// **'OTRA OPCIÓN'**
  String get habitCardCoachDismiss;

  /// No description provided for @createChoiceHabitTitle.
  ///
  /// In es, this message translates to:
  /// **'Nuevo hábito'**
  String get createChoiceHabitTitle;

  /// No description provided for @createChoiceHabitSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Un hábito individual'**
  String get createChoiceHabitSubtitle;

  /// No description provided for @createChoiceGroupTitle.
  ///
  /// In es, this message translates to:
  /// **'Nueva rutina'**
  String get createChoiceGroupTitle;

  /// No description provided for @createChoiceGroupSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Grupo de hábitos relacionados'**
  String get createChoiceGroupSubtitle;

  /// No description provided for @createGroupTitle.
  ///
  /// In es, this message translates to:
  /// **'Nueva rutina'**
  String get createGroupTitle;

  /// No description provided for @createGroupNameLabel.
  ///
  /// In es, this message translates to:
  /// **'Nombre de la rutina'**
  String get createGroupNameLabel;

  /// No description provided for @createGroupNameHint.
  ///
  /// In es, this message translates to:
  /// **'Ej: Rutina matutina'**
  String get createGroupNameHint;

  /// No description provided for @createGroupDescHint.
  ///
  /// In es, this message translates to:
  /// **'Opcional — para qué sirve esta rutina'**
  String get createGroupDescHint;

  /// No description provided for @createGroupEmojiLabel.
  ///
  /// In es, this message translates to:
  /// **'Emoji'**
  String get createGroupEmojiLabel;

  /// No description provided for @createGroupEmojiHint.
  ///
  /// In es, this message translates to:
  /// **'Pega un emoji o selecciona abajo'**
  String get createGroupEmojiHint;

  /// No description provided for @createGroupCta.
  ///
  /// In es, this message translates to:
  /// **'Crear rutina'**
  String get createGroupCta;

  /// No description provided for @emptyHabitsTitle.
  ///
  /// In es, this message translates to:
  /// **'¡Empieza tu camino!'**
  String get emptyHabitsTitle;

  /// No description provided for @emptyHabitsSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Cuéntale a la IA tus metas y te creará\nun plan de hábitos personalizado.'**
  String get emptyHabitsSubtitle;

  /// No description provided for @emptyHabitsAction.
  ///
  /// In es, this message translates to:
  /// **'Crear mi plan con IA'**
  String get emptyHabitsAction;

  /// No description provided for @stackCompleteTitle.
  ///
  /// In es, this message translates to:
  /// **'¡CADENA COMPLETA!'**
  String get stackCompleteTitle;

  /// No description provided for @stackCompleteCount.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 hábito seguido. ¡Imparable!} other{{count} hábitos seguidos. ¡Imparable!}}'**
  String stackCompleteCount(int count);

  /// No description provided for @stackCompleteSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Así se construye un hábito atómico.'**
  String get stackCompleteSubtitle;

  /// No description provided for @allHabitsTotal.
  ///
  /// In es, this message translates to:
  /// **'{count} en total'**
  String allHabitsTotal(int count);

  /// No description provided for @allHabitsCancelSelection.
  ///
  /// In es, this message translates to:
  /// **'Cancelar selección'**
  String get allHabitsCancelSelection;

  /// No description provided for @allHabitsTabActive.
  ///
  /// In es, this message translates to:
  /// **'Activos'**
  String get allHabitsTabActive;

  /// No description provided for @allHabitsTabArchived.
  ///
  /// In es, this message translates to:
  /// **'Archivados'**
  String get allHabitsTabArchived;

  /// No description provided for @allHabitsTabRoutines.
  ///
  /// In es, this message translates to:
  /// **'Rutinas'**
  String get allHabitsTabRoutines;

  /// No description provided for @allHabitsEmptyActiveTitle.
  ///
  /// In es, this message translates to:
  /// **'No tienes hábitos creados'**
  String get allHabitsEmptyActiveTitle;

  /// No description provided for @allHabitsEmptyActiveSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Crea hábitos desde la pantalla principal o con la IA.'**
  String get allHabitsEmptyActiveSubtitle;

  /// No description provided for @allHabitsEmptyArchivedTitle.
  ///
  /// In es, this message translates to:
  /// **'No tienes hábitos archivados'**
  String get allHabitsEmptyArchivedTitle;

  /// No description provided for @allHabitsEmptyRoutinesTitle.
  ///
  /// In es, this message translates to:
  /// **'No tienes rutinas creadas'**
  String get allHabitsEmptyRoutinesTitle;

  /// No description provided for @allHabitsEmptyRoutinesSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Crea una rutina desde el \"+\" de la pantalla principal.'**
  String get allHabitsEmptyRoutinesSubtitle;

  /// No description provided for @allHabitsNoHabitsYet.
  ///
  /// In es, this message translates to:
  /// **'Sin hábitos aún'**
  String get allHabitsNoHabitsYet;

  /// No description provided for @allHabitsHardDeleteTitle.
  ///
  /// In es, this message translates to:
  /// **'Borrar definitivamente'**
  String get allHabitsHardDeleteTitle;

  /// No description provided for @allHabitsHardDeleteContent.
  ///
  /// In es, this message translates to:
  /// **'¿Seguro que quieres borrar \"{title}\" para siempre?\n\nEsto borra el hábito y todos sus registros. No se puede deshacer.'**
  String allHabitsHardDeleteContent(String title);

  /// No description provided for @allHabitsHardDeleteConfirm.
  ///
  /// In es, this message translates to:
  /// **'Borrar definitivo'**
  String get allHabitsHardDeleteConfirm;

  /// No description provided for @allHabitsHardDeleted.
  ///
  /// In es, this message translates to:
  /// **'\"{title}\" borrado permanentemente'**
  String allHabitsHardDeleted(String title);

  /// No description provided for @allHabitsHardDeleteError.
  ///
  /// In es, this message translates to:
  /// **'Error al borrar el hábito'**
  String get allHabitsHardDeleteError;

  /// No description provided for @allHabitsBulkDeleteTitle.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{Borrar 1 hábito} other{Borrar {count} hábitos}}'**
  String allHabitsBulkDeleteTitle(int count);

  /// No description provided for @allHabitsBulkDeleteContent.
  ///
  /// In es, this message translates to:
  /// **'Se borrarán definitivamente con todos sus registros. No se puede deshacer.'**
  String get allHabitsBulkDeleteContent;

  /// No description provided for @allHabitsDeleteButton.
  ///
  /// In es, this message translates to:
  /// **'Borrar'**
  String get allHabitsDeleteButton;

  /// No description provided for @allHabitsBulkDeleted.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 hábito borrado} other{{count} hábitos borrados}}'**
  String allHabitsBulkDeleted(int count);

  /// No description provided for @allHabitsBulkDeleteError.
  ///
  /// In es, this message translates to:
  /// **'Error al borrar los hábitos'**
  String get allHabitsBulkDeleteError;

  /// No description provided for @allHabitsBulkDeleteGroupsTitle.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{Eliminar 1 rutina} other{Eliminar {count} rutinas}}'**
  String allHabitsBulkDeleteGroupsTitle(int count);

  /// No description provided for @allHabitsBulkDeleteGroupsContent.
  ///
  /// In es, this message translates to:
  /// **'¿Qué quieres hacer con los hábitos de las rutinas seleccionadas?'**
  String get allHabitsBulkDeleteGroupsContent;

  /// No description provided for @allHabitsBulkDeleteGroupsOnly.
  ///
  /// In es, this message translates to:
  /// **'Solo las rutinas'**
  String get allHabitsBulkDeleteGroupsOnly;

  /// No description provided for @allHabitsBulkDeleteGroupsAndHabits.
  ///
  /// In es, this message translates to:
  /// **'Rutinas y hábitos'**
  String get allHabitsBulkDeleteGroupsAndHabits;

  /// No description provided for @allHabitsGroupsDeleted.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 rutina eliminada} other{{count} rutinas eliminadas}}'**
  String allHabitsGroupsDeleted(int count);

  /// No description provided for @allHabitsGroupsDeleteError.
  ///
  /// In es, this message translates to:
  /// **'Error al eliminar las rutinas'**
  String get allHabitsGroupsDeleteError;

  /// No description provided for @groupDetailEditTitle.
  ///
  /// In es, this message translates to:
  /// **'Editar grupo'**
  String get groupDetailEditTitle;

  /// No description provided for @groupDetailAddHabitError.
  ///
  /// In es, this message translates to:
  /// **'Error al añadir el hábito'**
  String get groupDetailAddHabitError;

  /// No description provided for @groupDetailHabitAdded.
  ///
  /// In es, this message translates to:
  /// **'Hábito añadido a la rutina'**
  String get groupDetailHabitAdded;

  /// No description provided for @groupDetailGroupUpdated.
  ///
  /// In es, this message translates to:
  /// **'Grupo actualizado'**
  String get groupDetailGroupUpdated;

  /// No description provided for @groupDetailGroupUpdateError.
  ///
  /// In es, this message translates to:
  /// **'Error al actualizar el grupo'**
  String get groupDetailGroupUpdateError;

  /// No description provided for @groupDetailPublishNoHabits.
  ///
  /// In es, this message translates to:
  /// **'El grupo no tiene hábitos, añade al menos uno.'**
  String get groupDetailPublishNoHabits;

  /// No description provided for @groupDetailPublishNeedPublic.
  ///
  /// In es, this message translates to:
  /// **'Activa tu perfil público en Ajustes antes de publicar.'**
  String get groupDetailPublishNeedPublic;

  /// No description provided for @groupDetailPublishNeedPublicTitle.
  ///
  /// In es, this message translates to:
  /// **'Necesitas un perfil público'**
  String get groupDetailPublishNeedPublicTitle;

  /// No description provided for @groupDetailPublishNeedPublicBody.
  ///
  /// In es, this message translates to:
  /// **'Para compartir una plantilla con la comunidad necesitas un perfil público con username. ¿Crear el tuyo ahora?'**
  String get groupDetailPublishNeedPublicBody;

  /// No description provided for @groupDetailPublishCreateProfileCta.
  ///
  /// In es, this message translates to:
  /// **'Crear perfil público'**
  String get groupDetailPublishCreateProfileCta;

  /// No description provided for @groupDetailPublishReactivateBody.
  ///
  /// In es, this message translates to:
  /// **'Tu perfil público está desactivado. Reactívalo para compartir esta plantilla con tu username.'**
  String get groupDetailPublishReactivateBody;

  /// No description provided for @groupDetailPublishReactivateCta.
  ///
  /// In es, this message translates to:
  /// **'Reactivar perfil'**
  String get groupDetailPublishReactivateCta;

  /// No description provided for @groupDetailPublishTitle.
  ///
  /// In es, this message translates to:
  /// **'Publicar como plantilla'**
  String get groupDetailPublishTitle;

  /// No description provided for @groupDetailPublishBody.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{Se publicará 1 hábito sin datos personales (sin rachas ni historial).} other{Se publicarán {count} hábitos sin datos personales (sin rachas ni historial).}}'**
  String groupDetailPublishBody(int count);

  /// No description provided for @groupDetailPublishDescLabel.
  ///
  /// In es, this message translates to:
  /// **'Descripción (opcional)'**
  String get groupDetailPublishDescLabel;

  /// No description provided for @groupDetailPublishDescHint.
  ///
  /// In es, this message translates to:
  /// **'Explica para quién es este plan…'**
  String get groupDetailPublishDescHint;

  /// No description provided for @groupDetailPublishConfirm.
  ///
  /// In es, this message translates to:
  /// **'Publicar'**
  String get groupDetailPublishConfirm;

  /// No description provided for @groupDetailPublishSuccess.
  ///
  /// In es, this message translates to:
  /// **'Plantilla publicada en la comunidad'**
  String get groupDetailPublishSuccess;

  /// No description provided for @groupDetailViewAction.
  ///
  /// In es, this message translates to:
  /// **'Ver'**
  String get groupDetailViewAction;

  /// No description provided for @groupDetailPublishError.
  ///
  /// In es, this message translates to:
  /// **'Error al publicar la plantilla'**
  String get groupDetailPublishError;

  /// No description provided for @groupDetailUnpublishTitle.
  ///
  /// In es, this message translates to:
  /// **'Retirar plantilla'**
  String get groupDetailUnpublishTitle;

  /// No description provided for @groupDetailUnpublishContent.
  ///
  /// In es, this message translates to:
  /// **'La plantilla desaparecerá del marketplace. Las copias importadas por otros usuarios no se verán afectadas.'**
  String get groupDetailUnpublishContent;

  /// No description provided for @groupDetailUnpublishConfirm.
  ///
  /// In es, this message translates to:
  /// **'Retirar'**
  String get groupDetailUnpublishConfirm;

  /// No description provided for @groupDetailUnpublishSuccess.
  ///
  /// In es, this message translates to:
  /// **'Plantilla retirada del marketplace'**
  String get groupDetailUnpublishSuccess;

  /// No description provided for @groupDetailUnpublishError.
  ///
  /// In es, this message translates to:
  /// **'Error al retirar la plantilla'**
  String get groupDetailUnpublishError;

  /// No description provided for @groupDetailUnpublishTooltip.
  ///
  /// In es, this message translates to:
  /// **'Retirar del marketplace'**
  String get groupDetailUnpublishTooltip;

  /// No description provided for @groupDetailPublishTooltip.
  ///
  /// In es, this message translates to:
  /// **'Publicar como plantilla'**
  String get groupDetailPublishTooltip;

  /// No description provided for @groupDetailNotFound.
  ///
  /// In es, this message translates to:
  /// **'Este grupo ya no existe.'**
  String get groupDetailNotFound;

  /// No description provided for @groupDetailHabitsHeader.
  ///
  /// In es, this message translates to:
  /// **'Hábitos del grupo'**
  String get groupDetailHabitsHeader;

  /// No description provided for @groupDetailEmptyTitle.
  ///
  /// In es, this message translates to:
  /// **'Sin hábitos en este grupo'**
  String get groupDetailEmptyTitle;

  /// No description provided for @groupDetailEmptySubtitle.
  ///
  /// In es, this message translates to:
  /// **'Añade hábitos con el botón +'**
  String get groupDetailEmptySubtitle;

  /// No description provided for @groupDetailEditNameLabel.
  ///
  /// In es, this message translates to:
  /// **'Título del grupo'**
  String get groupDetailEditNameLabel;

  /// No description provided for @groupDetailEditNameHint.
  ///
  /// In es, this message translates to:
  /// **'Ej: Rutina de gimnasio'**
  String get groupDetailEditNameHint;

  /// No description provided for @groupDetailEditEmojiHint.
  ///
  /// In es, this message translates to:
  /// **'Pega un emoji o déjalo vacío'**
  String get groupDetailEditEmojiHint;

  /// No description provided for @commonApply.
  ///
  /// In es, this message translates to:
  /// **'Aplicar'**
  String get commonApply;

  /// No description provided for @monthFullJan.
  ///
  /// In es, this message translates to:
  /// **'Enero'**
  String get monthFullJan;

  /// No description provided for @monthFullFeb.
  ///
  /// In es, this message translates to:
  /// **'Febrero'**
  String get monthFullFeb;

  /// No description provided for @monthFullMar.
  ///
  /// In es, this message translates to:
  /// **'Marzo'**
  String get monthFullMar;

  /// No description provided for @monthFullApr.
  ///
  /// In es, this message translates to:
  /// **'Abril'**
  String get monthFullApr;

  /// No description provided for @monthFullMay.
  ///
  /// In es, this message translates to:
  /// **'Mayo'**
  String get monthFullMay;

  /// No description provided for @monthFullJun.
  ///
  /// In es, this message translates to:
  /// **'Junio'**
  String get monthFullJun;

  /// No description provided for @monthFullJul.
  ///
  /// In es, this message translates to:
  /// **'Julio'**
  String get monthFullJul;

  /// No description provided for @monthFullAug.
  ///
  /// In es, this message translates to:
  /// **'Agosto'**
  String get monthFullAug;

  /// No description provided for @monthFullSep.
  ///
  /// In es, this message translates to:
  /// **'Septiembre'**
  String get monthFullSep;

  /// No description provided for @monthFullOct.
  ///
  /// In es, this message translates to:
  /// **'Octubre'**
  String get monthFullOct;

  /// No description provided for @monthFullNov.
  ///
  /// In es, this message translates to:
  /// **'Noviembre'**
  String get monthFullNov;

  /// No description provided for @monthFullDec.
  ///
  /// In es, this message translates to:
  /// **'Diciembre'**
  String get monthFullDec;

  /// No description provided for @butterflyNotFound.
  ///
  /// In es, this message translates to:
  /// **'No se encontró la proyección o puede que haya expirado.'**
  String get butterflyNotFound;

  /// No description provided for @butterflyCheckins.
  ///
  /// In es, this message translates to:
  /// **'{count} check-ins'**
  String butterflyCheckins(int count);

  /// No description provided for @butterflyStreakDays.
  ///
  /// In es, this message translates to:
  /// **'{count}d racha'**
  String butterflyStreakDays(int count);

  /// No description provided for @butterflyCompletion.
  ///
  /// In es, this message translates to:
  /// **'{percent}% completitud'**
  String butterflyCompletion(int percent);

  /// No description provided for @butterflyKeyMoments.
  ///
  /// In es, this message translates to:
  /// **'Momentos clave'**
  String get butterflyKeyMoments;

  /// No description provided for @patternInsightsNeedConnection.
  ///
  /// In es, this message translates to:
  /// **'Necesitas conexión para regenerar los patrones'**
  String get patternInsightsNeedConnection;

  /// No description provided for @patternInsightsNeedMore.
  ///
  /// In es, this message translates to:
  /// **'Necesitas al menos 14 días con datos y 3 hábitos activos.'**
  String get patternInsightsNeedMore;

  /// No description provided for @patternInsightsUpdated.
  ///
  /// In es, this message translates to:
  /// **'Patrones actualizados.'**
  String get patternInsightsUpdated;

  /// No description provided for @patternInsightsEmptyTitle.
  ///
  /// In es, this message translates to:
  /// **'Sin insights para {period}'**
  String patternInsightsEmptyTitle(String period);

  /// No description provided for @patternInsightsEmptySubtitle.
  ///
  /// In es, this message translates to:
  /// **'Genera los patrones desde el dashboard o espera a que el sistema los procese automáticamente.'**
  String get patternInsightsEmptySubtitle;

  /// No description provided for @patternInsightsRegenerate.
  ///
  /// In es, this message translates to:
  /// **'Regenerar patrones'**
  String get patternInsightsRegenerate;

  /// No description provided for @patternInsightsLimitedData.
  ///
  /// In es, this message translates to:
  /// **'Datos limitados'**
  String get patternInsightsLimitedData;

  /// No description provided for @patternInsightsDetected.
  ///
  /// In es, this message translates to:
  /// **'{count} patrones detectados'**
  String patternInsightsDetected(int count);

  /// No description provided for @patternInsightsConfidenceHigh.
  ///
  /// In es, this message translates to:
  /// **'Alta confianza'**
  String get patternInsightsConfidenceHigh;

  /// No description provided for @patternInsightsConfidenceMedium.
  ///
  /// In es, this message translates to:
  /// **'Media'**
  String get patternInsightsConfidenceMedium;

  /// No description provided for @patternInsightsConfidenceLow.
  ///
  /// In es, this message translates to:
  /// **'Baja'**
  String get patternInsightsConfidenceLow;

  /// No description provided for @weeklyReviewNotFound.
  ///
  /// In es, this message translates to:
  /// **'No se encontró esta revisión'**
  String get weeklyReviewNotFound;

  /// No description provided for @weeklyReviewLoadError.
  ///
  /// In es, this message translates to:
  /// **'Error al cargar la revisión'**
  String get weeklyReviewLoadError;

  /// No description provided for @weeklyReviewHabitGone.
  ///
  /// In es, this message translates to:
  /// **'Este hábito ya no existe'**
  String get weeklyReviewHabitGone;

  /// No description provided for @weeklyReviewWins.
  ///
  /// In es, this message translates to:
  /// **'Lo que funcionó'**
  String get weeklyReviewWins;

  /// No description provided for @weeklyReviewStruggles.
  ///
  /// In es, this message translates to:
  /// **'Dónde fallaste'**
  String get weeklyReviewStruggles;

  /// No description provided for @weeklyReviewWeekLabel.
  ///
  /// In es, this message translates to:
  /// **'Semana {weekId}'**
  String weeklyReviewWeekLabel(String weekId);

  /// No description provided for @weeklyReviewStatCheckins.
  ///
  /// In es, this message translates to:
  /// **'Check-ins'**
  String get weeklyReviewStatCheckins;

  /// No description provided for @weeklyReviewStatHabits.
  ///
  /// In es, this message translates to:
  /// **'Hábitos'**
  String get weeklyReviewStatHabits;

  /// No description provided for @weeklyReviewStatAtRisk.
  ///
  /// In es, this message translates to:
  /// **'En riesgo'**
  String get weeklyReviewStatAtRisk;

  /// No description provided for @weeklyReviewFocusTitle.
  ///
  /// In es, this message translates to:
  /// **'Tu foco esta semana'**
  String get weeklyReviewFocusTitle;

  /// No description provided for @weeklyReviewRecommendations.
  ///
  /// In es, this message translates to:
  /// **'Recomendaciones'**
  String get weeklyReviewRecommendations;

  /// No description provided for @planCardSaved.
  ///
  /// In es, this message translates to:
  /// **'Hábitos guardados'**
  String get planCardSaved;

  /// No description provided for @planCardAddSelected.
  ///
  /// In es, this message translates to:
  /// **'Añadir hábitos seleccionados'**
  String get planCardAddSelected;

  /// No description provided for @planCardFrequencyDaily.
  ///
  /// In es, this message translates to:
  /// **'Diario'**
  String get planCardFrequencyDaily;

  /// No description provided for @planCardFrequencyWeekly.
  ///
  /// In es, this message translates to:
  /// **'Semanal'**
  String get planCardFrequencyWeekly;

  /// No description provided for @planCardFrequencyCustom.
  ///
  /// In es, this message translates to:
  /// **'Personalizado'**
  String get planCardFrequencyCustom;

  /// No description provided for @challengesTitle.
  ///
  /// In es, this message translates to:
  /// **'Mis retos'**
  String get challengesTitle;

  /// No description provided for @challengesNew.
  ///
  /// In es, this message translates to:
  /// **'Nuevo reto'**
  String get challengesNew;

  /// No description provided for @challengesEmptyTitle.
  ///
  /// In es, this message translates to:
  /// **'Sin retos todavía'**
  String get challengesEmptyTitle;

  /// No description provided for @challengesEmptySubtitle.
  ///
  /// In es, this message translates to:
  /// **'Reta a un amigo a completar un hábito juntos durante varios días'**
  String get challengesEmptySubtitle;

  /// No description provided for @challengesSectionPending.
  ///
  /// In es, this message translates to:
  /// **'Pendientes'**
  String get challengesSectionPending;

  /// No description provided for @challengesSectionActive.
  ///
  /// In es, this message translates to:
  /// **'Activos'**
  String get challengesSectionActive;

  /// No description provided for @challengesSectionFinished.
  ///
  /// In es, this message translates to:
  /// **'Finalizados'**
  String get challengesSectionFinished;

  /// No description provided for @challengeCardWaiting.
  ///
  /// In es, this message translates to:
  /// **'Esperando aceptación...'**
  String get challengeCardWaiting;

  /// No description provided for @challengeStatusPending.
  ///
  /// In es, this message translates to:
  /// **'Pendiente'**
  String get challengeStatusPending;

  /// No description provided for @challengeStatusActive.
  ///
  /// In es, this message translates to:
  /// **'Activo'**
  String get challengeStatusActive;

  /// No description provided for @challengeStatusCompleted.
  ///
  /// In es, this message translates to:
  /// **'Completado'**
  String get challengeStatusCompleted;

  /// No description provided for @challengeStatusDeclined.
  ///
  /// In es, this message translates to:
  /// **'Rechazado'**
  String get challengeStatusDeclined;

  /// No description provided for @challengeStatusAbandoned.
  ///
  /// In es, this message translates to:
  /// **'Abandonado'**
  String get challengeStatusAbandoned;

  /// No description provided for @challengeDetailTitle.
  ///
  /// In es, this message translates to:
  /// **'Reto compartido'**
  String get challengeDetailTitle;

  /// No description provided for @challengeDetailNotFound.
  ///
  /// In es, this message translates to:
  /// **'Reto no encontrado'**
  String get challengeDetailNotFound;

  /// No description provided for @challengeDetailAccepted.
  ///
  /// In es, this message translates to:
  /// **'¡Reto aceptado! El hábito fue creado en tu lista'**
  String get challengeDetailAccepted;

  /// No description provided for @challengeDetailAcceptError.
  ///
  /// In es, this message translates to:
  /// **'Error al aceptar el reto'**
  String get challengeDetailAcceptError;

  /// No description provided for @challengeDetailDeclineTitle.
  ///
  /// In es, this message translates to:
  /// **'Rechazar reto'**
  String get challengeDetailDeclineTitle;

  /// No description provided for @challengeDetailDeclineContent.
  ///
  /// In es, this message translates to:
  /// **'¿Seguro que quieres rechazar este reto?'**
  String get challengeDetailDeclineContent;

  /// No description provided for @challengeDetailDeclineConfirm.
  ///
  /// In es, this message translates to:
  /// **'Rechazar'**
  String get challengeDetailDeclineConfirm;

  /// No description provided for @challengeDetailAbandonTitle.
  ///
  /// In es, this message translates to:
  /// **'Abandonar reto'**
  String get challengeDetailAbandonTitle;

  /// No description provided for @challengeDetailAbandonContent.
  ///
  /// In es, this message translates to:
  /// **'¿Seguro que quieres abandonar? No podrás retomarlo.'**
  String get challengeDetailAbandonContent;

  /// No description provided for @challengeDetailAbandonConfirm.
  ///
  /// In es, this message translates to:
  /// **'Abandonar'**
  String get challengeDetailAbandonConfirm;

  /// No description provided for @challengeDetailAbandonTooltip.
  ///
  /// In es, this message translates to:
  /// **'Abandonar'**
  String get challengeDetailAbandonTooltip;

  /// No description provided for @challengeDetailYourProgress.
  ///
  /// In es, this message translates to:
  /// **'Tu progreso'**
  String get challengeDetailYourProgress;

  /// No description provided for @challengeDetailPartner.
  ///
  /// In es, this message translates to:
  /// **'Compañero'**
  String get challengeDetailPartner;

  /// No description provided for @challengeDetailCompletedTitle.
  ///
  /// In es, this message translates to:
  /// **'¡Reto completado!'**
  String get challengeDetailCompletedTitle;

  /// No description provided for @challengeDetailCompletedSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Ambos habéis demostrado constancia'**
  String get challengeDetailCompletedSubtitle;

  /// No description provided for @challengeDetailDeclinedState.
  ///
  /// In es, this message translates to:
  /// **'Reto rechazado'**
  String get challengeDetailDeclinedState;

  /// No description provided for @challengeDetailAbandonedState.
  ///
  /// In es, this message translates to:
  /// **'Reto abandonado'**
  String get challengeDetailAbandonedState;

  /// No description provided for @challengeDetailWaitingPartner.
  ///
  /// In es, this message translates to:
  /// **'Esperando a que {name} acepte el reto'**
  String challengeDetailWaitingPartner(String name);

  /// No description provided for @challengeDetailFallbackPartner.
  ///
  /// In es, this message translates to:
  /// **'tu compañero'**
  String get challengeDetailFallbackPartner;

  /// No description provided for @challengeDetailFallbackPartnerCap.
  ///
  /// In es, this message translates to:
  /// **'Compañero'**
  String get challengeDetailFallbackPartnerCap;

  /// No description provided for @challengeDetailFallbackSomeone.
  ///
  /// In es, this message translates to:
  /// **'Alguien'**
  String get challengeDetailFallbackSomeone;

  /// No description provided for @challengeDetailYouChallenged.
  ///
  /// In es, this message translates to:
  /// **'Retaste a {name}'**
  String challengeDetailYouChallenged(String name);

  /// No description provided for @challengeDetailChallengedYou.
  ///
  /// In es, this message translates to:
  /// **'{name} te ha retado'**
  String challengeDetailChallengedYou(String name);

  /// No description provided for @challengeDetailAcceptQuestion.
  ///
  /// In es, this message translates to:
  /// **'¿Aceptas el reto?'**
  String get challengeDetailAcceptQuestion;

  /// No description provided for @challengeDetailAcceptHint.
  ///
  /// In es, this message translates to:
  /// **'Se creará automáticamente el hábito en tu lista y empezareis juntos'**
  String get challengeDetailAcceptHint;

  /// No description provided for @challengeDetailAcceptCta.
  ///
  /// In es, this message translates to:
  /// **'Aceptar reto'**
  String get challengeDetailAcceptCta;

  /// No description provided for @challengeDetailCompletedToday.
  ///
  /// In es, this message translates to:
  /// **'¡Completado hoy!'**
  String get challengeDetailCompletedToday;

  /// No description provided for @challengeDetailMarkToday.
  ///
  /// In es, this message translates to:
  /// **'Marcar hoy como completado'**
  String get challengeDetailMarkToday;

  /// No description provided for @challengeDetailProgressDays.
  ///
  /// In es, this message translates to:
  /// **'{completed} / {total} días'**
  String challengeDetailProgressDays(int completed, int total);

  /// No description provided for @createChallengeTitle.
  ///
  /// In es, this message translates to:
  /// **'Crear reto'**
  String get createChallengeTitle;

  /// No description provided for @createChallengeError.
  ///
  /// In es, this message translates to:
  /// **'Error al crear reto: {error}'**
  String createChallengeError(String error);

  /// No description provided for @createChallengeHabitName.
  ///
  /// In es, this message translates to:
  /// **'Nombre del hábito'**
  String get createChallengeHabitName;

  /// No description provided for @createChallengeHabitHint.
  ///
  /// In es, this message translates to:
  /// **'Ej: Meditar 10 minutos'**
  String get createChallengeHabitHint;

  /// No description provided for @createChallengeDuration.
  ///
  /// In es, this message translates to:
  /// **'Duración'**
  String get createChallengeDuration;

  /// No description provided for @createChallengePartnerLabel.
  ///
  /// In es, this message translates to:
  /// **'Compañero de reto'**
  String get createChallengePartnerLabel;

  /// No description provided for @createChallengeSearchUsername.
  ///
  /// In es, this message translates to:
  /// **'Buscar por username'**
  String get createChallengeSearchUsername;

  /// No description provided for @createChallengeFollowerChip.
  ///
  /// In es, this message translates to:
  /// **'Seguidor'**
  String get createChallengeFollowerChip;

  /// No description provided for @createChallengeSend.
  ///
  /// In es, this message translates to:
  /// **'Enviar reto'**
  String get createChallengeSend;

  /// No description provided for @communityTitle.
  ///
  /// In es, this message translates to:
  /// **'Comunidad'**
  String get communityTitle;

  /// No description provided for @communitySearchHint.
  ///
  /// In es, this message translates to:
  /// **'Buscar plantillas…'**
  String get communitySearchHint;

  /// No description provided for @communitySortPopular.
  ///
  /// In es, this message translates to:
  /// **'Popular'**
  String get communitySortPopular;

  /// No description provided for @communitySortRecent.
  ///
  /// In es, this message translates to:
  /// **'Recientes'**
  String get communitySortRecent;

  /// No description provided for @communityFilterAll.
  ///
  /// In es, this message translates to:
  /// **'Todas'**
  String get communityFilterAll;

  /// No description provided for @communityLoadMore.
  ///
  /// In es, this message translates to:
  /// **'Cargar más'**
  String get communityLoadMore;

  /// No description provided for @communityEndOfList.
  ///
  /// In es, this message translates to:
  /// **'— fin de la lista —'**
  String get communityEndOfList;

  /// No description provided for @communityEmptyTitle.
  ///
  /// In es, this message translates to:
  /// **'Todavía no hay plantillas'**
  String get communityEmptyTitle;

  /// No description provided for @communityEmptySubtitle.
  ///
  /// In es, this message translates to:
  /// **'Sé el primero en publicar un plan de hábitos.'**
  String get communityEmptySubtitle;

  /// No description provided for @communityEmptyFilterTitle.
  ///
  /// In es, this message translates to:
  /// **'Sin resultados para ese filtro'**
  String get communityEmptyFilterTitle;

  /// No description provided for @communityEmptyFilterSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Prueba otra categoría o quita el filtro.'**
  String get communityEmptyFilterSubtitle;

  /// No description provided for @communityDetailNotFound.
  ///
  /// In es, this message translates to:
  /// **'Plantilla no encontrada'**
  String get communityDetailNotFound;

  /// No description provided for @communityDetailLoadError.
  ///
  /// In es, this message translates to:
  /// **'Error al cargar la plantilla'**
  String get communityDetailLoadError;

  /// No description provided for @communityDetailImported.
  ///
  /// In es, this message translates to:
  /// **'{emoji} \"{title}\" importado a tus hábitos'**
  String communityDetailImported(String emoji, String title);

  /// No description provided for @communityDetailImportError.
  ///
  /// In es, this message translates to:
  /// **'Error al importar la plantilla'**
  String get communityDetailImportError;

  /// No description provided for @communityDetailReportTitle.
  ///
  /// In es, this message translates to:
  /// **'Reportar plantilla'**
  String get communityDetailReportTitle;

  /// No description provided for @communityDetailReportContent.
  ///
  /// In es, this message translates to:
  /// **'¿Quieres reportar esta plantilla por contenido inapropiado? Será revisada por el equipo.'**
  String get communityDetailReportContent;

  /// No description provided for @communityDetailReportConfirm.
  ///
  /// In es, this message translates to:
  /// **'Reportar'**
  String get communityDetailReportConfirm;

  /// No description provided for @communityDetailReportSent.
  ///
  /// In es, this message translates to:
  /// **'Reporte enviado, gracias'**
  String get communityDetailReportSent;

  /// No description provided for @communityDetailImports.
  ///
  /// In es, this message translates to:
  /// **'{count} imports'**
  String communityDetailImports(int count);

  /// No description provided for @communityDetailByAuthor.
  ///
  /// In es, this message translates to:
  /// **'Por {name}'**
  String communityDetailByAuthor(String name);

  /// No description provided for @communityDetailHabitsIncluded.
  ///
  /// In es, this message translates to:
  /// **'Hábitos incluidos'**
  String get communityDetailHabitsIncluded;

  /// No description provided for @communityDetailMyTemplate.
  ///
  /// In es, this message translates to:
  /// **'Esta es tu plantilla'**
  String get communityDetailMyTemplate;

  /// No description provided for @communityDetailImporting.
  ///
  /// In es, this message translates to:
  /// **'Importando…'**
  String get communityDetailImporting;

  /// No description provided for @communityDetailImportCta.
  ///
  /// In es, this message translates to:
  /// **'Importar a mis hábitos'**
  String get communityDetailImportCta;

  /// No description provided for @streakDaysShort.
  ///
  /// In es, this message translates to:
  /// **'{count}d'**
  String streakDaysShort(int count);

  /// No description provided for @categoryDetailTitle.
  ///
  /// In es, this message translates to:
  /// **'Categorías'**
  String get categoryDetailTitle;

  /// No description provided for @categoryDetailDistribution.
  ///
  /// In es, this message translates to:
  /// **'Distribución'**
  String get categoryDetailDistribution;

  /// No description provided for @categoryDetailWeeklyPct.
  ///
  /// In es, this message translates to:
  /// **'{percent}% semanal'**
  String categoryDetailWeeklyPct(int percent);

  /// No description provided for @streaksDetailTitle.
  ///
  /// In es, this message translates to:
  /// **'Rachas'**
  String get streaksDetailTitle;

  /// No description provided for @streaksDetailBestGlobal.
  ///
  /// In es, this message translates to:
  /// **'Mejor racha global'**
  String get streaksDetailBestGlobal;

  /// No description provided for @streaksDetailOnStreak.
  ///
  /// In es, this message translates to:
  /// **'En racha'**
  String get streaksDetailOnStreak;

  /// No description provided for @streaksDetailNoStreak.
  ///
  /// In es, this message translates to:
  /// **'Sin racha'**
  String get streaksDetailNoStreak;

  /// No description provided for @streaksDetailBestShort.
  ///
  /// In es, this message translates to:
  /// **'mejor: {count}d'**
  String streaksDetailBestShort(int count);

  /// No description provided for @weeklyDetailTitle.
  ///
  /// In es, this message translates to:
  /// **'Progreso mensual'**
  String get weeklyDetailTitle;

  /// No description provided for @weeklyDetailDailyBreakdown.
  ///
  /// In es, this message translates to:
  /// **'Desglose diario'**
  String get weeklyDetailDailyBreakdown;

  /// No description provided for @weeklyDetailAverage.
  ///
  /// In es, this message translates to:
  /// **'Media'**
  String get weeklyDetailAverage;

  /// No description provided for @weeklyDetailLast30Days.
  ///
  /// In es, this message translates to:
  /// **'Últimos 30 días'**
  String get weeklyDetailLast30Days;

  /// No description provided for @usernameSheetTitleNew.
  ///
  /// In es, this message translates to:
  /// **'Elige tu username'**
  String get usernameSheetTitleNew;

  /// No description provided for @usernameSheetTitleChange.
  ///
  /// In es, this message translates to:
  /// **'Cambiar username'**
  String get usernameSheetTitleChange;

  /// No description provided for @usernameSheetSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Tu username es único y público. Aparecerá en tu perfil y en los retos.'**
  String get usernameSheetSubtitle;

  /// No description provided for @usernameSheetHelperIdle.
  ///
  /// In es, this message translates to:
  /// **'Te identifica en la comunidad'**
  String get usernameSheetHelperIdle;

  /// No description provided for @usernameSheetChecking.
  ///
  /// In es, this message translates to:
  /// **'Comprobando...'**
  String get usernameSheetChecking;

  /// No description provided for @usernameSheetVisibleData.
  ///
  /// In es, this message translates to:
  /// **'Datos visibles en tu perfil:'**
  String get usernameSheetVisibleData;

  /// No description provided for @usernameSheetDataName.
  ///
  /// In es, this message translates to:
  /// **'Nombre y @username'**
  String get usernameSheetDataName;

  /// No description provided for @usernameSheetDataStreaks.
  ///
  /// In es, this message translates to:
  /// **'Rachas actuales'**
  String get usernameSheetDataStreaks;

  /// No description provided for @usernameSheetDataHabits.
  ///
  /// In es, this message translates to:
  /// **'Hábitos activos (título y categoría)'**
  String get usernameSheetDataHabits;

  /// No description provided for @usernameSheetDataLevel.
  ///
  /// In es, this message translates to:
  /// **'Nivel y logros'**
  String get usernameSheetDataLevel;

  /// No description provided for @usernameSheetPrivacy.
  ///
  /// In es, this message translates to:
  /// **'Nunca se comparten: email, notas, recordatorios.'**
  String get usernameSheetPrivacy;

  /// No description provided for @usernameSheetConfirm.
  ///
  /// In es, this message translates to:
  /// **'Confirmar'**
  String get usernameSheetConfirm;

  /// Título genérico de error
  ///
  /// In es, this message translates to:
  /// **'Algo salió mal'**
  String get errorDefault;

  /// No description provided for @habitDetailInfo.
  ///
  /// In es, this message translates to:
  /// **'Información'**
  String get habitDetailInfo;

  /// No description provided for @habitDetailAIGenerated.
  ///
  /// In es, this message translates to:
  /// **'Generado por IA'**
  String get habitDetailAIGenerated;

  /// No description provided for @habitDetailFrequency.
  ///
  /// In es, this message translates to:
  /// **'Frecuencia'**
  String get habitDetailFrequency;

  /// No description provided for @habitsOrderSaveError.
  ///
  /// In es, this message translates to:
  /// **'Error al guardar el orden'**
  String get habitsOrderSaveError;

  /// No description provided for @habitsDeleteGroup.
  ///
  /// In es, this message translates to:
  /// **'Eliminar grupo'**
  String get habitsDeleteGroup;

  /// No description provided for @notificationsTitle.
  ///
  /// In es, this message translates to:
  /// **'Notificaciones'**
  String get notificationsTitle;

  /// No description provided for @notificationsClearActivity.
  ///
  /// In es, this message translates to:
  /// **'Limpiar actividad'**
  String get notificationsClearActivity;

  /// No description provided for @notificationsActiveReminders.
  ///
  /// In es, this message translates to:
  /// **'Recordatorios activos'**
  String get notificationsActiveReminders;

  /// No description provided for @notificationsAdjustSuggested.
  ///
  /// In es, this message translates to:
  /// **'Ajuste sugerido: {habitTitle}'**
  String notificationsAdjustSuggested(String habitTitle);

  /// No description provided for @notificationsWeeklyReviewReady.
  ///
  /// In es, this message translates to:
  /// **'Revisión semanal lista'**
  String get notificationsWeeklyReviewReady;

  /// No description provided for @notificationsMonthlyProjection.
  ///
  /// In es, this message translates to:
  /// **'Proyección mensual 🦋'**
  String get notificationsMonthlyProjection;

  /// No description provided for @notificationsChallengeReceived.
  ///
  /// In es, this message translates to:
  /// **'¡Te han retado!'**
  String get notificationsChallengeReceived;

  /// No description provided for @notificationsChallengeAccepted.
  ///
  /// In es, this message translates to:
  /// **'¡Tu reto fue aceptado!'**
  String get notificationsChallengeAccepted;

  /// No description provided for @notificationsReminderAt.
  ///
  /// In es, this message translates to:
  /// **'Recordatorio a las {time}'**
  String notificationsReminderAt(String time);

  /// No description provided for @notificationsYesterday.
  ///
  /// In es, this message translates to:
  /// **'Ayer'**
  String get notificationsYesterday;

  /// No description provided for @notificationsDaysAgo.
  ///
  /// In es, this message translates to:
  /// **'Hace {days}d'**
  String notificationsDaysAgo(int days);

  /// No description provided for @notificationsWeeksAgo.
  ///
  /// In es, this message translates to:
  /// **'Hace {weeks}sem'**
  String notificationsWeeksAgo(int weeks);

  /// No description provided for @notificationsMonthsAgo.
  ///
  /// In es, this message translates to:
  /// **'Hace {months}mes'**
  String notificationsMonthsAgo(int months);

  /// No description provided for @notificationsEmpty.
  ///
  /// In es, this message translates to:
  /// **'Sin notificaciones'**
  String get notificationsEmpty;

  /// No description provided for @notificationsEmptySubtitle.
  ///
  /// In es, this message translates to:
  /// **'Aquí aparecerán tus logros, recordatorios y sugerencias de la IA.'**
  String get notificationsEmptySubtitle;

  /// No description provided for @notificationsNoActivity.
  ///
  /// In es, this message translates to:
  /// **'Sin actividad reciente'**
  String get notificationsNoActivity;

  /// No description provided for @notificationsLoadError.
  ///
  /// In es, this message translates to:
  /// **'No se pudieron cargar las notificaciones.'**
  String get notificationsLoadError;

  /// No description provided for @followersTabFollowers.
  ///
  /// In es, this message translates to:
  /// **'Seguidores'**
  String get followersTabFollowers;

  /// No description provided for @followersTabFollowing.
  ///
  /// In es, this message translates to:
  /// **'Siguiendo'**
  String get followersTabFollowing;

  /// No description provided for @followersTabRequests.
  ///
  /// In es, this message translates to:
  /// **'Solicitudes'**
  String get followersTabRequests;

  /// No description provided for @followersMutual.
  ///
  /// In es, this message translates to:
  /// **'Mutuo'**
  String get followersMutual;

  /// No description provided for @followersFollowsYou.
  ///
  /// In es, this message translates to:
  /// **'Te sigue'**
  String get followersFollowsYou;

  /// No description provided for @followersUnfollow.
  ///
  /// In es, this message translates to:
  /// **'Dejar de seguir'**
  String get followersUnfollow;

  /// No description provided for @followersRemoveTitle.
  ///
  /// In es, this message translates to:
  /// **'Eliminar seguidor'**
  String get followersRemoveTitle;

  /// No description provided for @followersRemoveContent.
  ///
  /// In es, this message translates to:
  /// **'¿Eliminar a @{username} de tus seguidores?'**
  String followersRemoveContent(String username);

  /// No description provided for @followersUnfollowContent.
  ///
  /// In es, this message translates to:
  /// **'¿Dejar de seguir a @{username}?'**
  String followersUnfollowContent(String username);

  /// No description provided for @followersRequestAlreadySent.
  ///
  /// In es, this message translates to:
  /// **'Solicitud ya enviada'**
  String get followersRequestAlreadySent;

  /// No description provided for @followersRequestSent.
  ///
  /// In es, this message translates to:
  /// **'Solicitud enviada a @{username}'**
  String followersRequestSent(String username);

  /// No description provided for @followersNowFollowing.
  ///
  /// In es, this message translates to:
  /// **'Siguiendo a @{username}'**
  String followersNowFollowing(String username);

  /// No description provided for @followersRemoved.
  ///
  /// In es, this message translates to:
  /// **'Seguidor eliminado'**
  String get followersRemoved;

  /// No description provided for @followersUnfollowed.
  ///
  /// In es, this message translates to:
  /// **'Dejaste de seguir a @{username}'**
  String followersUnfollowed(String username);

  /// No description provided for @followersRequestsError.
  ///
  /// In es, this message translates to:
  /// **'Error al cargar solicitudes: {error}'**
  String followersRequestsError(String error);

  /// No description provided for @followersEmptyTitle.
  ///
  /// In es, this message translates to:
  /// **'Aún no tienes seguidores'**
  String get followersEmptyTitle;

  /// No description provided for @followersEmptySubtitle.
  ///
  /// In es, this message translates to:
  /// **'Busca usuarios por @username para seguirlos o que te sigan'**
  String get followersEmptySubtitle;

  /// No description provided for @followingEmptyTitle.
  ///
  /// In es, this message translates to:
  /// **'No sigues a nadie'**
  String get followingEmptyTitle;

  /// No description provided for @followingEmptySubtitle.
  ///
  /// In es, this message translates to:
  /// **'Busca usuarios en la pestaña Seguidores'**
  String get followingEmptySubtitle;

  /// No description provided for @followersRequestsEmptyTitle.
  ///
  /// In es, this message translates to:
  /// **'Sin solicitudes pendientes'**
  String get followersRequestsEmptyTitle;

  /// No description provided for @followersRequestsEmptySubtitle.
  ///
  /// In es, this message translates to:
  /// **'Aquí aparecerán las solicitudes de seguimiento que recibas'**
  String get followersRequestsEmptySubtitle;

  /// No description provided for @followersSearchHint.
  ///
  /// In es, this message translates to:
  /// **'Buscar por @username'**
  String get followersSearchHint;

  /// No description provided for @publicProfileNotAvailable.
  ///
  /// In es, this message translates to:
  /// **'Perfil no disponible'**
  String get publicProfileNotAvailable;

  /// No description provided for @publicProfileMemberSince.
  ///
  /// In es, this message translates to:
  /// **'Miembro desde {month}'**
  String publicProfileMemberSince(String month);

  /// No description provided for @publicProfileMutualFollower.
  ///
  /// In es, this message translates to:
  /// **'Seguidor mutuo'**
  String get publicProfileMutualFollower;

  /// No description provided for @publicProfilePrivate.
  ///
  /// In es, this message translates to:
  /// **'Esta cuenta es privada'**
  String get publicProfilePrivate;

  /// No description provided for @publicProfileRequestPending.
  ///
  /// In es, this message translates to:
  /// **'Tu solicitud está pendiente de aprobación.'**
  String get publicProfileRequestPending;

  /// No description provided for @publicProfileFollowToSee.
  ///
  /// In es, this message translates to:
  /// **'Síguelo para ver sus hábitos y estadísticas.'**
  String get publicProfileFollowToSee;

  /// No description provided for @publicProfileNoHabits.
  ///
  /// In es, this message translates to:
  /// **'Sin hábitos visibles'**
  String get publicProfileNoHabits;

  /// No description provided for @publicProfileMore.
  ///
  /// In es, this message translates to:
  /// **'más'**
  String get publicProfileMore;

  /// No description provided for @publicProfilesFeedTitle.
  ///
  /// In es, this message translates to:
  /// **'Explorar perfiles'**
  String get publicProfilesFeedTitle;

  /// No description provided for @publicProfilesFeedSearchHint.
  ///
  /// In es, this message translates to:
  /// **'Buscar por @username…'**
  String get publicProfilesFeedSearchHint;

  /// No description provided for @publicProfilesFeedEmptySubtitle.
  ///
  /// In es, this message translates to:
  /// **'Activa tu perfil en Ajustes para aparecer aquí.'**
  String get publicProfilesFeedEmptySubtitle;

  /// No description provided for @publicProfilesFeedNoResultsSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Prueba con otro @username'**
  String get publicProfilesFeedNoResultsSubtitle;

  /// No description provided for @avatarPickerTitle.
  ///
  /// In es, this message translates to:
  /// **'Foto de perfil'**
  String get avatarPickerTitle;

  /// No description provided for @avatarPickerGallery.
  ///
  /// In es, this message translates to:
  /// **'Elegir de la galería'**
  String get avatarPickerGallery;

  /// No description provided for @avatarPickerCamera.
  ///
  /// In es, this message translates to:
  /// **'Hacer una foto'**
  String get avatarPickerCamera;

  /// No description provided for @avatarPickerRemove.
  ///
  /// In es, this message translates to:
  /// **'Quitar foto'**
  String get avatarPickerRemove;

  /// No description provided for @avatarPickerCropNote.
  ///
  /// In es, this message translates to:
  /// **'Se recortará al centro automáticamente'**
  String get avatarPickerCropNote;

  /// No description provided for @avatarPickerUpdated.
  ///
  /// In es, this message translates to:
  /// **'Foto de perfil actualizada'**
  String get avatarPickerUpdated;

  /// No description provided for @avatarPickerUploadError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo subir la foto'**
  String get avatarPickerUploadError;

  /// No description provided for @avatarPickerRemoved.
  ///
  /// In es, this message translates to:
  /// **'Foto eliminada'**
  String get avatarPickerRemoved;

  /// No description provided for @avatarPickerRemoveError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo eliminar la foto'**
  String get avatarPickerRemoveError;

  /// No description provided for @avatarPickerProcessing.
  ///
  /// In es, this message translates to:
  /// **'Procesando foto…'**
  String get avatarPickerProcessing;

  /// No description provided for @publicProfileLevelShort.
  ///
  /// In es, this message translates to:
  /// **'Niv. {level}'**
  String publicProfileLevelShort(String level);

  /// No description provided for @publicProfileAverageLevel.
  ///
  /// In es, this message translates to:
  /// **'Nivel medio'**
  String get publicProfileAverageLevel;

  /// No description provided for @privacySectionVisibility.
  ///
  /// In es, this message translates to:
  /// **'Visibilidad'**
  String get privacySectionVisibility;

  /// No description provided for @privacyPublicProfileTitle.
  ///
  /// In es, this message translates to:
  /// **'Perfil público'**
  String get privacyPublicProfileTitle;

  /// No description provided for @privacyPublicProfileDescOn.
  ///
  /// In es, this message translates to:
  /// **'Apareces en el directorio, cualquiera puede seguirte'**
  String get privacyPublicProfileDescOn;

  /// No description provided for @privacyPublicProfileDescOff.
  ///
  /// In es, this message translates to:
  /// **'Solo tus seguidores pueden verte'**
  String get privacyPublicProfileDescOff;

  /// No description provided for @privacyChangeUsername.
  ///
  /// In es, this message translates to:
  /// **'Cambiar username'**
  String get privacyChangeUsername;

  /// No description provided for @privacyUsernameTaken.
  ///
  /// In es, this message translates to:
  /// **'El username ya está ocupado'**
  String get privacyUsernameTaken;

  /// No description provided for @privacyUsernameHint.
  ///
  /// In es, this message translates to:
  /// **'Elige un nombre de usuario para que otros puedan encontrarte.'**
  String get privacyUsernameHint;

  /// No description provided for @privacyDisableTitle.
  ///
  /// In es, this message translates to:
  /// **'Desactivar perfil público'**
  String get privacyDisableTitle;

  /// No description provided for @privacyDisableContent.
  ///
  /// In es, this message translates to:
  /// **'Tu perfil desaparecerá del directorio. Tus seguidores actuales podrán seguir viéndote hasta que los elimines.'**
  String get privacyDisableContent;

  /// No description provided for @privacyDisableButton.
  ///
  /// In es, this message translates to:
  /// **'Desactivar'**
  String get privacyDisableButton;

  /// No description provided for @privacyNoHabits.
  ///
  /// In es, this message translates to:
  /// **'No tienes hábitos activos'**
  String get privacyNoHabits;

  /// No description provided for @privacyPublicViewLabel.
  ///
  /// In es, this message translates to:
  /// **'Qué ve todo el mundo'**
  String get privacyPublicViewLabel;

  /// No description provided for @privacyFollowersViewLabel.
  ///
  /// In es, this message translates to:
  /// **'Qué ven tus seguidores'**
  String get privacyFollowersViewLabel;

  /// No description provided for @privacyChallengesTitle.
  ///
  /// In es, this message translates to:
  /// **'Quién puede enviarme retos'**
  String get privacyChallengesTitle;

  /// No description provided for @privacyChallengesDesc.
  ///
  /// In es, this message translates to:
  /// **'Controla quién puede invitarte a competir en un hábito'**
  String get privacyChallengesDesc;

  /// No description provided for @privacyVisibleHabitsSection.
  ///
  /// In es, this message translates to:
  /// **'Hábitos visibles en tu perfil'**
  String get privacyVisibleHabitsSection;

  /// No description provided for @privacyHabitsLabel.
  ///
  /// In es, this message translates to:
  /// **'Hábitos activos'**
  String get privacyHabitsLabel;

  /// No description provided for @privacyStatsLabel.
  ///
  /// In es, this message translates to:
  /// **'Estadísticas'**
  String get privacyStatsLabel;

  /// No description provided for @privacyFollowersLabel.
  ///
  /// In es, this message translates to:
  /// **'Seguidores / Siguiendo'**
  String get privacyFollowersLabel;

  /// No description provided for @privacyOptionPublic.
  ///
  /// In es, this message translates to:
  /// **'Público'**
  String get privacyOptionPublic;

  /// No description provided for @privacyOptionFollowers.
  ///
  /// In es, this message translates to:
  /// **'Seguidores'**
  String get privacyOptionFollowers;

  /// No description provided for @privacyOptionPrivate.
  ///
  /// In es, this message translates to:
  /// **'Privado'**
  String get privacyOptionPrivate;

  /// No description provided for @privacyLevelEveryone.
  ///
  /// In es, this message translates to:
  /// **'Todos'**
  String get privacyLevelEveryone;

  /// No description provided for @privacyLevelNobody.
  ///
  /// In es, this message translates to:
  /// **'Nadie'**
  String get privacyLevelNobody;

  /// No description provided for @achievementFirstHabitTitle.
  ///
  /// In es, this message translates to:
  /// **'Primer paso'**
  String get achievementFirstHabitTitle;

  /// No description provided for @achievementFirstHabitDesc.
  ///
  /// In es, this message translates to:
  /// **'Crea tu primer hábito'**
  String get achievementFirstHabitDesc;

  /// No description provided for @achievementAiPlanTitle.
  ///
  /// In es, this message translates to:
  /// **'Asistente personal'**
  String get achievementAiPlanTitle;

  /// No description provided for @achievementAiPlanDesc.
  ///
  /// In es, this message translates to:
  /// **'Genera un plan con la IA'**
  String get achievementAiPlanDesc;

  /// No description provided for @achievementPerfectDayTitle.
  ///
  /// In es, this message translates to:
  /// **'Día perfecto'**
  String get achievementPerfectDayTitle;

  /// No description provided for @achievementPerfectDayDesc.
  ///
  /// In es, this message translates to:
  /// **'Completa todos los hábitos del día'**
  String get achievementPerfectDayDesc;

  /// No description provided for @achievementStreak3Title.
  ///
  /// In es, this message translates to:
  /// **'En marcha'**
  String get achievementStreak3Title;

  /// No description provided for @achievementStreak3Desc.
  ///
  /// In es, this message translates to:
  /// **'Consigue una racha de 3 días'**
  String get achievementStreak3Desc;

  /// No description provided for @achievementStreak7Title.
  ///
  /// In es, this message translates to:
  /// **'Semana de fuego'**
  String get achievementStreak7Title;

  /// No description provided for @achievementStreak7Desc.
  ///
  /// In es, this message translates to:
  /// **'Consigue una racha de 7 días'**
  String get achievementStreak7Desc;

  /// No description provided for @achievementStreak14Title.
  ///
  /// In es, this message translates to:
  /// **'Imparable'**
  String get achievementStreak14Title;

  /// No description provided for @achievementStreak14Desc.
  ///
  /// In es, this message translates to:
  /// **'Consigue una racha de 14 días'**
  String get achievementStreak14Desc;

  /// No description provided for @achievementStreak30Title.
  ///
  /// In es, this message translates to:
  /// **'Leyenda'**
  String get achievementStreak30Title;

  /// No description provided for @achievementStreak30Desc.
  ///
  /// In es, this message translates to:
  /// **'Consigue una racha de 30 días'**
  String get achievementStreak30Desc;

  /// No description provided for @achievementHabits5Title.
  ///
  /// In es, this message translates to:
  /// **'Cinco en acción'**
  String get achievementHabits5Title;

  /// No description provided for @achievementHabits5Desc.
  ///
  /// In es, this message translates to:
  /// **'Ten 5 hábitos activos'**
  String get achievementHabits5Desc;

  /// No description provided for @achievementTotal50Title.
  ///
  /// In es, this message translates to:
  /// **'Medio centenar'**
  String get achievementTotal50Title;

  /// No description provided for @achievementTotal50Desc.
  ///
  /// In es, this message translates to:
  /// **'Completa 50 check-ins en total'**
  String get achievementTotal50Desc;

  /// No description provided for @achievementTotal100Title.
  ///
  /// In es, this message translates to:
  /// **'Centenario'**
  String get achievementTotal100Title;

  /// No description provided for @achievementTotal100Desc.
  ///
  /// In es, this message translates to:
  /// **'Completa 100 check-ins en total'**
  String get achievementTotal100Desc;

  /// No description provided for @achievementPerfectWeekTitle.
  ///
  /// In es, this message translates to:
  /// **'Semana impecable'**
  String get achievementPerfectWeekTitle;

  /// No description provided for @achievementPerfectWeekDesc.
  ///
  /// In es, this message translates to:
  /// **'7 días seguidos completando todo'**
  String get achievementPerfectWeekDesc;

  /// No description provided for @achievementChallengeTitle.
  ///
  /// In es, this message translates to:
  /// **'Compañeros de reto'**
  String get achievementChallengeTitle;

  /// No description provided for @achievementChallengeDesc.
  ///
  /// In es, this message translates to:
  /// **'Completa un reto compartido'**
  String get achievementChallengeDesc;

  /// No description provided for @moodTitle.
  ///
  /// In es, this message translates to:
  /// **'Mi ánimo'**
  String get moodTitle;

  /// No description provided for @moodHowAreYou.
  ///
  /// In es, this message translates to:
  /// **'¿Cómo te sientes?'**
  String get moodHowAreYou;

  /// No description provided for @moodSave.
  ///
  /// In es, this message translates to:
  /// **'Guardar ánimo'**
  String get moodSave;

  /// No description provided for @moodNotePlaceholder.
  ///
  /// In es, this message translates to:
  /// **'Añade una nota (opcional)'**
  String get moodNotePlaceholder;

  /// No description provided for @moodTimeBlockLabel.
  ///
  /// In es, this message translates to:
  /// **'Momento del día'**
  String get moodTimeBlockLabel;

  /// No description provided for @moodTimeBlockMorning.
  ///
  /// In es, this message translates to:
  /// **'Mañana'**
  String get moodTimeBlockMorning;

  /// No description provided for @moodTimeBlockMidday.
  ///
  /// In es, this message translates to:
  /// **'Mediodía'**
  String get moodTimeBlockMidday;

  /// No description provided for @moodTimeBlockAfternoon.
  ///
  /// In es, this message translates to:
  /// **'Tarde'**
  String get moodTimeBlockAfternoon;

  /// No description provided for @moodTimeBlockNight.
  ///
  /// In es, this message translates to:
  /// **'Noche'**
  String get moodTimeBlockNight;

  /// No description provided for @moodHabitsToday.
  ///
  /// In es, this message translates to:
  /// **'Hábitos completados hoy'**
  String get moodHabitsToday;

  /// No description provided for @moodEmptyState.
  ///
  /// In es, this message translates to:
  /// **'Aún no hay registros de ánimo'**
  String get moodEmptyState;

  /// No description provided for @moodEmptyStateCta.
  ///
  /// In es, this message translates to:
  /// **'Registra tu primer ánimo'**
  String get moodEmptyStateCta;

  /// No description provided for @moodWeekChart.
  ///
  /// In es, this message translates to:
  /// **'Ánimo últimos 7 días'**
  String get moodWeekChart;

  /// No description provided for @moodLabelAnxiety.
  ///
  /// In es, this message translates to:
  /// **'Ansiedad'**
  String get moodLabelAnxiety;

  /// No description provided for @moodLabelTiredness.
  ///
  /// In es, this message translates to:
  /// **'Cansancio'**
  String get moodLabelTiredness;

  /// No description provided for @moodLabelMotivation.
  ///
  /// In es, this message translates to:
  /// **'Motivación'**
  String get moodLabelMotivation;

  /// No description provided for @moodLabelCalm.
  ///
  /// In es, this message translates to:
  /// **'Calma'**
  String get moodLabelCalm;

  /// No description provided for @moodLabelStress.
  ///
  /// In es, this message translates to:
  /// **'Estrés'**
  String get moodLabelStress;

  /// No description provided for @moodLabelSadness.
  ///
  /// In es, this message translates to:
  /// **'Tristeza'**
  String get moodLabelSadness;

  /// No description provided for @moodLabelEnergy.
  ///
  /// In es, this message translates to:
  /// **'Energía'**
  String get moodLabelEnergy;

  /// No description provided for @moodLabelAnger.
  ///
  /// In es, this message translates to:
  /// **'Enfado'**
  String get moodLabelAnger;

  /// No description provided for @moodLabelGratitude.
  ///
  /// In es, this message translates to:
  /// **'Gratitud'**
  String get moodLabelGratitude;

  /// No description provided for @moodLabelFocus.
  ///
  /// In es, this message translates to:
  /// **'Concentración'**
  String get moodLabelFocus;

  /// No description provided for @moodCalendarTitle.
  ///
  /// In es, this message translates to:
  /// **'Calendario de ánimo'**
  String get moodCalendarTitle;

  /// No description provided for @moodCalendarLegend.
  ///
  /// In es, this message translates to:
  /// **'Leyenda'**
  String get moodCalendarLegend;

  /// No description provided for @moodDeleteEntry.
  ///
  /// In es, this message translates to:
  /// **'Eliminar registro'**
  String get moodDeleteEntry;

  /// No description provided for @moodNoEntriesDay.
  ///
  /// In es, this message translates to:
  /// **'Sin registros este día'**
  String get moodNoEntriesDay;

  /// No description provided for @drawerMoodCalendar.
  ///
  /// In es, this message translates to:
  /// **'Mi ánimo'**
  String get drawerMoodCalendar;

  /// No description provided for @drawerMoodCalendarSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Historial mensual de estado de ánimo'**
  String get drawerMoodCalendarSubtitle;

  /// No description provided for @moodCorrelationTitle.
  ///
  /// In es, this message translates to:
  /// **'Ánimo y hábitos'**
  String get moodCorrelationTitle;

  /// No description provided for @moodCorrelationNotEnoughData.
  ///
  /// In es, this message translates to:
  /// **'Necesitas más registros para ver correlaciones'**
  String get moodCorrelationNotEnoughData;

  /// No description provided for @moodCorrelationDays7.
  ///
  /// In es, this message translates to:
  /// **'7 días'**
  String get moodCorrelationDays7;

  /// No description provided for @moodCorrelationDays30.
  ///
  /// In es, this message translates to:
  /// **'30 días'**
  String get moodCorrelationDays30;

  /// No description provided for @moodChartLegendHabits.
  ///
  /// In es, this message translates to:
  /// **'% hábitos'**
  String get moodChartLegendHabits;

  /// No description provided for @moodChartLegendMood.
  ///
  /// In es, this message translates to:
  /// **'ánimo'**
  String get moodChartLegendMood;

  /// No description provided for @moodInsightsTitle.
  ///
  /// In es, this message translates to:
  /// **'Insights de ánimo'**
  String get moodInsightsTitle;

  /// No description provided for @moodInsightsAllCategories.
  ///
  /// In es, this message translates to:
  /// **'Todas las categorías'**
  String get moodInsightsAllCategories;

  /// No description provided for @moodCorrelationDaysCompleted.
  ///
  /// In es, this message translates to:
  /// **'días completado'**
  String get moodCorrelationDaysCompleted;

  /// No description provided for @moodConfidenceLow.
  ///
  /// In es, this message translates to:
  /// **'Poca fiabilidad'**
  String get moodConfidenceLow;

  /// No description provided for @moodConfidenceMedium.
  ///
  /// In es, this message translates to:
  /// **'Fiabilidad media'**
  String get moodConfidenceMedium;

  /// No description provided for @moodConfidenceHigh.
  ///
  /// In es, this message translates to:
  /// **'Alta fiabilidad'**
  String get moodConfidenceHigh;

  /// No description provided for @moodStreakBoost.
  ///
  /// In es, this message translates to:
  /// **'Con 5+ días seguidos: {diff}'**
  String moodStreakBoost(String diff);

  /// No description provided for @moodInsightsDelayedHeader.
  ///
  /// In es, this message translates to:
  /// **'Efecto al día siguiente'**
  String get moodInsightsDelayedHeader;

  /// No description provided for @moodDelayedBoost.
  ///
  /// In es, this message translates to:
  /// **'Hacer {habitName} hoy mejora tu ánimo de mañana en {diff}'**
  String moodDelayedBoost(String habitName, String diff);

  /// No description provided for @moodCorrelationBoost.
  ///
  /// In es, this message translates to:
  /// **'Tu ánimo {emoji} sube {diff} los días que haces {habitName}'**
  String moodCorrelationBoost(String emoji, String diff, String habitName);

  /// No description provided for @moodCorrelationDrop.
  ///
  /// In es, this message translates to:
  /// **'Los días sin {habitName}, tu ánimo baja {diff}'**
  String moodCorrelationDrop(String habitName, String diff);

  /// No description provided for @moodInsightsPositiveHeader.
  ///
  /// In es, this message translates to:
  /// **'Te hacen bien'**
  String get moodInsightsPositiveHeader;

  /// No description provided for @moodInsightsNegativeHeader.
  ///
  /// In es, this message translates to:
  /// **'Mejor no faltar'**
  String get moodInsightsNegativeHeader;

  /// No description provided for @weeklyReviewMoodInsights.
  ///
  /// In es, this message translates to:
  /// **'Análisis emocional'**
  String get weeklyReviewMoodInsights;

  /// No description provided for @moodBannerMorning.
  ///
  /// In es, this message translates to:
  /// **'¡Buenos días! ¿Cómo has dormido?'**
  String get moodBannerMorning;

  /// No description provided for @moodBannerAfternoon.
  ///
  /// In es, this message translates to:
  /// **'¿Qué tal va la tarde?'**
  String get moodBannerAfternoon;

  /// No description provided for @moodBannerNight.
  ///
  /// In es, this message translates to:
  /// **'¿Cómo ha ido el día?'**
  String get moodBannerNight;

  /// No description provided for @moodRating1.
  ///
  /// In es, this message translates to:
  /// **'Fatal'**
  String get moodRating1;

  /// No description provided for @moodRating2.
  ///
  /// In es, this message translates to:
  /// **'Regular'**
  String get moodRating2;

  /// No description provided for @moodRating3.
  ///
  /// In es, this message translates to:
  /// **'Normal'**
  String get moodRating3;

  /// No description provided for @moodRating4.
  ///
  /// In es, this message translates to:
  /// **'Bien'**
  String get moodRating4;

  /// No description provided for @moodRating5.
  ///
  /// In es, this message translates to:
  /// **'Genial'**
  String get moodRating5;

  /// No description provided for @moodLoggedToday.
  ///
  /// In es, this message translates to:
  /// **'Registrado'**
  String get moodLoggedToday;

  /// No description provided for @moodStreakDays.
  ///
  /// In es, this message translates to:
  /// **'Racha de {count} días'**
  String moodStreakDays(int count);

  /// No description provided for @moodQuickSave.
  ///
  /// In es, this message translates to:
  /// **'Guardar rápido'**
  String get moodQuickSave;

  /// No description provided for @moodTellMore.
  ///
  /// In es, this message translates to:
  /// **'¿Quieres añadir detalles?'**
  String get moodTellMore;

  /// No description provided for @moodSkip.
  ///
  /// In es, this message translates to:
  /// **'Saltar'**
  String get moodSkip;

  /// No description provided for @moodNext.
  ///
  /// In es, this message translates to:
  /// **'Siguiente'**
  String get moodNext;

  /// No description provided for @moodAnythingOnMind.
  ///
  /// In es, this message translates to:
  /// **'¿Algo que quieras anotar?'**
  String get moodAnythingOnMind;

  /// No description provided for @moodSaveError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo guardar el ánimo. Inténtalo de nuevo.'**
  String get moodSaveError;

  /// No description provided for @moodDeleteError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo eliminar el registro'**
  String get moodDeleteError;

  /// No description provided for @moodDeleteConfirm.
  ///
  /// In es, this message translates to:
  /// **'¿Eliminar este registro de ánimo?'**
  String get moodDeleteConfirm;

  /// No description provided for @moodLabelsPositive.
  ///
  /// In es, this message translates to:
  /// **'Lo que sientes bien'**
  String get moodLabelsPositive;

  /// No description provided for @moodLabelsNegative.
  ///
  /// In es, this message translates to:
  /// **'Lo que pesa hoy'**
  String get moodLabelsNegative;

  /// No description provided for @updateForceTitle.
  ///
  /// In es, this message translates to:
  /// **'Actualización obligatoria'**
  String get updateForceTitle;

  /// No description provided for @updateSoftTitle.
  ///
  /// In es, this message translates to:
  /// **'Nueva versión disponible'**
  String get updateSoftTitle;

  /// No description provided for @updateNow.
  ///
  /// In es, this message translates to:
  /// **'Actualizar ahora'**
  String get updateNow;

  /// No description provided for @updateLater.
  ///
  /// In es, this message translates to:
  /// **'Ahora no'**
  String get updateLater;
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
