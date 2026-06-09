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
  String get settingsRateApp => 'Valorar HabitAI';

  @override
  String get settingsRateAppSubtitle => '¿Te gusta la app? Déjanos una reseña';

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

  @override
  String get authLoginTitle => 'Iniciar sesión';

  @override
  String get authRegisterTitle => 'Crear cuenta';

  @override
  String get authTagline => 'Tus hábitos, potenciados con IA';

  @override
  String get authRegisterTagline => 'Empieza a construir mejores hábitos';

  @override
  String get authEmail => 'Correo electrónico';

  @override
  String get authEmailHint => 'Introduce tu correo electrónico';

  @override
  String get authEmailInvalid => 'Introduce un correo válido';

  @override
  String get authPassword => 'Contraseña';

  @override
  String get authPasswordHint => 'Introduce tu contraseña';

  @override
  String get authPasswordMin => 'Mínimo 6 caracteres';

  @override
  String get authPasswordConfirm => 'Confirmar contraseña';

  @override
  String get authPasswordMismatch => 'Las contraseñas no coinciden';

  @override
  String get authName => 'Nombre';

  @override
  String get authNameHint => 'Tu nombre real';

  @override
  String get authNameRequired => 'Introduce tu nombre';

  @override
  String get authUsername => 'Nombre de usuario';

  @override
  String get authUsernameHint => 'tunombre';

  @override
  String get authUsernameAvailable => '¡Disponible!';

  @override
  String get authUsernameTaken => 'Ya está en uso, prueba otro';

  @override
  String get authUsernameHelp =>
      'Te identifica en retos y amigos • 3-20 caracteres';

  @override
  String get authUsernameRequired => 'Elige un nombre de usuario';

  @override
  String get authUsernameFormat =>
      'Solo letras minúsculas, números y _ (3-20 caracteres)';

  @override
  String get authUsernameCheckFirst =>
      'Comprueba la disponibilidad del username';

  @override
  String get authUsernameRequiredFull =>
      'Elige un nombre de usuario válido y disponible';

  @override
  String get authOrSeparator => 'o';

  @override
  String get authContinueWithGoogle => 'Continuar con Google';

  @override
  String get authContinueWithApple => 'Continuar con Apple';

  @override
  String get authSignIn => 'Iniciar sesión';

  @override
  String get authNoAccount => '¿No tienes cuenta? ';

  @override
  String get authRegisterLink => 'Regístrate';

  @override
  String get authHaveAccount => '¿Ya tienes cuenta? ';

  @override
  String get authSignInLink => 'Inicia sesión';

  @override
  String get authPrivacyPrefix => 'Al crear tu cuenta aceptas la ';

  @override
  String get authPrivacyPolicy => 'Política de Privacidad';

  @override
  String get authPrivacyMiddle => ' y los ';

  @override
  String get authTermsOfUse => 'Términos de Uso';

  @override
  String get navHabits => 'Hábitos';

  @override
  String get navProgress => 'Progreso';

  @override
  String get navAssistant => 'Asistente';

  @override
  String get navExplore => 'Explorar';

  @override
  String get navProfile => 'Perfil';

  @override
  String get navNewFollowRequest => 'Nueva solicitud de seguimiento';

  @override
  String navFollowRequestBody(String username) {
    return '@$username quiere seguirte';
  }

  @override
  String get navFollowAccepted => '¡Solicitud aceptada!';

  @override
  String navFollowAcceptedBody(String username) {
    return '@$username aceptó tu solicitud';
  }

  @override
  String get drawerProgress => 'Tu progreso';

  @override
  String get drawerAchievements => 'Logros';

  @override
  String get drawerAchievementsSubtitle => 'Lo que has desbloqueado';

  @override
  String get drawerLevels => 'Niveles';

  @override
  String get drawerLevelsSubtitle => 'Tu progreso por categoría';

  @override
  String get drawerAllHabits => 'Todos mis hábitos';

  @override
  String get drawerAllHabitsSubtitle => 'Activos y archivados';

  @override
  String get drawerWeeklyReview => 'Revisión semanal';

  @override
  String get drawerWeeklyReviewSubtitle => 'Análisis de la IA';

  @override
  String get drawerButterfly => 'Efecto Mariposa';

  @override
  String get drawerButterflySubtitle => 'Proyección a 3 años';

  @override
  String get drawerQuickActions => 'Acciones rápidas';

  @override
  String get drawerCreateHabit => 'Crear hábito';

  @override
  String get drawerCreateHabitSubtitle => 'Manual, sin IA';

  @override
  String get drawerChatAI => 'Chat con la IA';

  @override
  String get drawerChatAISubtitle => 'Genera un plan nuevo';

  @override
  String get drawerPreferences => 'Preferencias';

  @override
  String get drawerSettings => 'Ajustes';

  @override
  String get drawerSettingsSubtitle => 'Tema, notificaciones, cuenta';

  @override
  String get drawerMenu => 'Menú';

  @override
  String get drawerNoWeeklyReview => 'Aún no hay revisión semanal';

  @override
  String get drawerNoButterfly => 'Aún no hay proyección mensual';

  @override
  String get drawerHabitCreated => 'Hábito creado';

  @override
  String get drawerHabitCreateError => 'Error al crear el hábito';

  @override
  String drawerShields(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count escudos',
      one: '$count escudo',
    );
    return '$_temp0';
  }

  @override
  String get drawerStreakFreeze => 'Congela rachas si fallas';

  @override
  String get drawerSickMode => 'Modo enfermedad';

  @override
  String get dashboardTitle => 'Progreso';

  @override
  String dashboardGreeting(String name) {
    return 'Hola, $name';
  }

  @override
  String get dashboardWeekProgress => 'Tu avance esta semana';

  @override
  String get dashboardWeeklyReviewNeedMore =>
      'Necesitas al menos 3 check-ins esta semana para generar la revisión';

  @override
  String get dashboardButterflyNeedMore =>
      'Necesitas al menos 10 check-ins este mes para generar la proyección';

  @override
  String get dashboardPatternsNeedMore =>
      'Necesitas al menos 14 días con datos y 3 hábitos activos para detectar patrones';

  @override
  String get dashboardSmartAdjust => 'Ajuste inteligente';

  @override
  String get dashboardInsightsTitle => 'Insights IA';

  @override
  String get dashboardInsightsChipAdjust => 'Ajustes';

  @override
  String get dashboardInsightsChipWeekly => 'Semanal';

  @override
  String get dashboardInsightsChipButterfly => 'Mariposa';

  @override
  String get dashboardInsightsChipPatterns => 'Patrones';

  @override
  String get dashboardAIPersonalized => 'IA · Personalizado';

  @override
  String get dashboardAdjustDescription =>
      '¿Algún hábito que no arranca? La IA analiza tus patrones y propone cambios concretos.';

  @override
  String get dashboardAnalyzing => 'Analizando…';

  @override
  String get dashboardRequestAdjust => 'Pedir ajuste';

  @override
  String get dashboardSuggestedAdjusts => 'Ajustes sugeridos';

  @override
  String get dashboardSelectHabit => 'Selecciona un hábito';

  @override
  String get dashboardNoActiveHabits => 'No tienes hábitos activos';

  @override
  String dashboardStreakDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days días',
      one: '1 día',
    );
    return 'Racha: $_temp0';
  }

  @override
  String get dashboardAdjustGenerated =>
      'Sugerencia generada. Revísala arriba.';

  @override
  String get dashboardAdjustNotNeeded =>
      'Este hábito aún no necesita ajuste — falla menos de 3 días seguidos.';

  @override
  String get dashboardAdjustPending =>
      'Ya hay una sugerencia pendiente para este hábito.';

  @override
  String dashboardAdjustError(String reason) {
    return 'No se pudo generar el ajuste ($reason).';
  }

  @override
  String get dashboardPatternsTitle => 'Patrones IA';

  @override
  String get dashboardPatternsSubtitle =>
      'Descubre correlaciones ocultas entre tus hábitos';

  @override
  String get dashboardDetectPatterns => 'Detectar patrones';

  @override
  String get dashboardGenerating => 'Generando…';

  @override
  String get dashboardButterflyTitle => 'Efecto Mariposa';

  @override
  String get dashboardButterflySubtitle =>
      'Descubre cómo serás en 3 años si mantienes tus hábitos';

  @override
  String get dashboardGenerateProjection => 'Generar proyección';

  @override
  String get dashboardWeeklyReviewTitle => 'Revisión semanal';

  @override
  String get dashboardWeeklyReviewSubtitle =>
      'Pide a la IA que analice tu semana: rachas, wins y áreas de mejora';

  @override
  String get dashboardGenerateNow => 'Generar ahora';

  @override
  String get dashboardRegenerate => 'Regenerar';

  @override
  String get dashboardRegenerating => 'Regenerando…';

  @override
  String get dashboardNoData => 'Sin datos todavía';

  @override
  String get dashboardNoDataSubtitle =>
      'Crea hábitos y completa check-ins para ver tus estadísticas aquí';

  @override
  String get dashboardCreateFirstHabit => 'Crear primer hábito';

  @override
  String get dashboardPerfectDay => '¡Día perfecto!';

  @override
  String get dashboardToday => 'Hoy';

  @override
  String get dashboardNoHabitsToday => 'No tienes hábitos programados hoy';

  @override
  String get dashboardBestStreak => 'Mejor racha';

  @override
  String get dashboardCompleted => 'Completados';

  @override
  String get dashboardPerfectDays => 'Días perfectos';

  @override
  String get dashboardLastWeek => 'Última semana';

  @override
  String get dashboardByCategory => 'Por categoría';

  @override
  String get dashboardActiveStreaks => 'Rachas activas';

  @override
  String get dashboardAchievements => 'Logros';

  @override
  String get dashboardUnlockAchievements =>
      'Completa hábitos para desbloquear logros';

  @override
  String get dashboardMasteryProfile => 'Perfil de Maestría';

  @override
  String get dashboardStartMastery =>
      'Completa hábitos para desbloquear tu perfil de maestría.';

  @override
  String get habitsTitle => 'Mis hábitos';

  @override
  String habitsGreeting(String name) {
    return 'Hola, $name';
  }

  @override
  String habitsDateFormat(String day, String date) {
    return '$day, $date';
  }

  @override
  String get habitsSelectHabits => 'Seleccionar hábitos';

  @override
  String habitsSelected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count seleccionados',
      one: '1 seleccionado',
    );
    return '$_temp0';
  }

  @override
  String get habitsMoveToGroup => 'Mover a grupo';

  @override
  String get habitsDeleteSelected => 'Eliminar seleccionados';

  @override
  String habitsDeleteTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Eliminar $count hábitos',
      one: 'Eliminar 1 hábito',
    );
    return '$_temp0';
  }

  @override
  String get habitsDeleteSubtitle =>
      'Se desactivarán pero se conservará el historial.';

  @override
  String habitsDeleted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hábitos eliminados',
      one: '1 hábito eliminado',
    );
    return '$_temp0';
  }

  @override
  String get habitsDeleteError => 'Error al eliminar los hábitos';

  @override
  String get habitsDeleteSingleTitle => 'Eliminar hábito';

  @override
  String habitsDeleteSingleContent(String title) {
    return '¿Seguro que quieres eliminar \"$title\"?\n\nSe desactivará pero se conservará el historial.';
  }

  @override
  String habitsDeleteSingleSuccess(String title) {
    return '\"$title\" eliminado';
  }

  @override
  String get habitsDeleteSingleError => 'Error al eliminar el hábito';

  @override
  String get habitsUpdated => 'Hábito actualizado';

  @override
  String get habitsUpdateError => 'Error al actualizar el hábito';

  @override
  String get habitsAdjusted => 'Hábito ajustado ✓';

  @override
  String get habitsNoGroup => 'Sin grupo';

  @override
  String habitsMoved(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hábitos movidos',
      one: '1 hábito movido',
    );
    return '$_temp0';
  }

  @override
  String get habitsMoveError => 'Error al mover los hábitos';

  @override
  String get habitsGroupCreateError => 'Error al crear la rutina';

  @override
  String habitsDeleteGroupTitle(String title) {
    return 'Eliminar \"$title\"';
  }

  @override
  String get habitsDeleteGroupContent =>
      '¿Qué quieres hacer con los hábitos de esta rutina?';

  @override
  String get habitsDeleteGroupOnly => 'Solo la rutina';

  @override
  String get habitsDeleteGroupAndHabits => 'Rutina y hábitos';

  @override
  String habitsGroupDeleted(String title) {
    return 'Rutina \"$title\" eliminada';
  }

  @override
  String get habitsGroupDeleteError => 'Error al eliminar la rutina';

  @override
  String get habitsDragToReorder => 'Arrastra para reordenar';

  @override
  String get habitsDone => 'Listo';

  @override
  String get habitsCreate => 'Crear';

  @override
  String get habitsChainLabel => 'CADENA';

  @override
  String habitsTotalCount(int count) {
    return '·  $count hábitos';
  }

  @override
  String get habitsProgressToday => 'Progreso de hoy';

  @override
  String get habitsAllDone => '¡Todo listo!';

  @override
  String get habitsCompletedTodaySection => 'Completados hoy';

  @override
  String habitsCompletedOf(int completed, int total) {
    return '$completed de $total hábitos completados';
  }

  @override
  String get habitsEditGroup => 'Editar grupo';

  @override
  String get habitsTapToAdd => 'Toca para añadir hábitos';

  @override
  String get habitsLoadError =>
      'No se pudieron cargar tus hábitos. Comprueba tu conexión.';

  @override
  String get habitsFirstChain => '¡Primera cadena creada!';

  @override
  String get habitsAtomicTitle => 'Así funciona el hábito atómico';

  @override
  String get habitsAtomicStep1 => 'Completa el hábito ancla';

  @override
  String get habitsAtomicStep1Desc =>
      'El primer hábito de la cadena se resalta cuando lo terminas.';

  @override
  String get habitsAtomicStep2 => 'El siguiente se ilumina';

  @override
  String get habitsAtomicStep2Desc =>
      'Verás \"Después de X\" en el hábito encadenado. Es tu señal.';

  @override
  String get habitsAtomicStep3 => 'Completa toda la cadena';

  @override
  String get habitsAtomicStep3Desc =>
      'Cuando terminas todos recibes una celebración especial 🔥';

  @override
  String get habitsAtomicGotIt => '¡Entendido!';

  @override
  String get habitsXpBonus => '+5 XP · Hábito atómico';

  @override
  String get habitDetailDescription => 'Descripción';

  @override
  String get habitDetailDays => 'días';

  @override
  String get habitDetailCurrentStreak => 'Racha actual';

  @override
  String get habitDetailBestStreak => 'Mejor racha';

  @override
  String get habitDetailCompletedToday => 'Completado hoy';

  @override
  String get habitDetailShieldedToday => 'Racha protegida hoy';

  @override
  String get habitDetailMarkComplete => 'Marcar como completado';

  @override
  String habitDetailUseShield(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count disponibles',
      one: '1 disponible',
    );
    return 'Usar escudo ($_temp0)';
  }

  @override
  String get habitDetailShieldTitle => 'Usar escudo de racha';

  @override
  String habitDetailShieldContent(String title, int count) {
    return 'Gastarás 1 escudo para proteger la racha de \"$title\" hoy.\n\nTe quedan $count escudos.';
  }

  @override
  String get habitDetailUseShieldButton => 'Usar escudo';

  @override
  String get habitDetailShieldUsed => '🛡️ Escudo usado — racha protegida';

  @override
  String get habitDetailNoShields => 'No tienes escudos disponibles';

  @override
  String get habitDetailDeleteTitle => 'Eliminar hábito';

  @override
  String habitDetailDeleteContent(String title) {
    return '¿Seguro que quieres eliminar \"$title\"?\n\nSe desactivará y no aparecerá en tu lista, pero se conservará el historial.';
  }

  @override
  String get habitDetailDelete => 'Eliminar';

  @override
  String get habitDetailAISuggestion => 'Sugerencia de la IA';

  @override
  String get habitDetailApplyAdjust => 'Aplicar ajuste';

  @override
  String get habitDetailLater => 'Ahora no';

  @override
  String get habitDetailNotFound => 'El hábito no existe o fue eliminado.';

  @override
  String get habitDetailLogCompleted => 'Completado';

  @override
  String get habitDetailLogShield => 'Escudo';

  @override
  String get habitDetailLogSick => 'Enfermedad';

  @override
  String get habitDetailLogSickMode => 'Modo enfermedad';

  @override
  String get habitDetailLogMissed => 'No completado';

  @override
  String get habitDetailFilterAll => 'Todos';

  @override
  String get habitDetailFilterDaily => 'Diario';

  @override
  String get aiTitle => 'Asistente IA';

  @override
  String get aiSubtitle => 'Powered by Gemini';

  @override
  String get aiWelcome =>
      '¡Hola! Soy tu asistente de hábitos. Cuéntame tus metas y te generaré un plan personalizado.';

  @override
  String get aiOfflineError => 'El asistente IA necesita conexión a internet';

  @override
  String get aiConnectionError =>
      'No pude conectar con el asistente. Comprueba tu conexión.';

  @override
  String aiHabitsAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hábitos añadidos',
      one: '1 hábito añadido',
    );
    return '$_temp0';
  }

  @override
  String get aiSaveError => 'Error al guardar los hábitos';

  @override
  String get aiGeminiLabel => 'Gemini';

  @override
  String get aiInputHint => 'Escribe tus metas...';

  @override
  String get aiThinking => 'Pensando...';

  @override
  String get aiExploreTemplates =>
      '¿Sin ideas? Explora plantillas de la comunidad';

  @override
  String get aiSuggestion1 => 'Quiero hacer ejercicio y comer mejor';

  @override
  String get aiSuggestion2 => 'Necesito ser más productivo';

  @override
  String get aiSuggestion3 => 'Quiero leer más y dormir mejor';

  @override
  String get aiSuggestion4 => 'Mejorar mi salud mental';

  @override
  String get createHabitVisibilityLabel => 'Visibilidad';

  @override
  String get challengeVisibilityToggleTitle => 'Reto público';

  @override
  String get challengeVisibilityToggleSubtitle =>
      'Visible en tu perfil público';

  @override
  String get challengesSectionTitle => 'Retos';

  @override
  String get challengeAnonymousPartner => 'Compañero';

  @override
  String get aiPausedBanner =>
      'IA en mantenimiento temporalmente — el resto de la app funciona con normalidad.';

  @override
  String get aiPausedMessage =>
      'El asistente de IA está en mantenimiento temporalmente. El resto de la app funciona con normalidad.';

  @override
  String get categorySalud => 'Salud';

  @override
  String get categoryProductividad => 'Productividad';

  @override
  String get categoryBienestar => 'Bienestar';

  @override
  String get categorySocial => 'Social';

  @override
  String get categoryAprendizaje => 'Aprendizaje';

  @override
  String get categoryFinanzas => 'Finanzas';

  @override
  String get achievementsTitle => 'Logros';

  @override
  String get achievementUnlockedBanner => '¡Logro desbloqueado!';

  @override
  String achievementsUnlocked(int count) {
    return '$count logros desbloqueados';
  }

  @override
  String get levelsTitle => 'Perfil de Maestría';

  @override
  String get levelsMedium => 'Nivel medio';

  @override
  String levelsTotalXp(int xp) {
    return '$xp XP total';
  }

  @override
  String get levelsStronger => 'Más fuerte';

  @override
  String get levelsByCategory => 'Por categoría';

  @override
  String get levelsRadar => 'Radar de habilidades';

  @override
  String get levelsEmpty => 'Empieza a crear hábitos';

  @override
  String get levelsEmptySubtitle =>
      'Completa check-ins para subir de nivel en cada categoría.';

  @override
  String levelNvl(int n) {
    return 'Nvl $n';
  }

  @override
  String get levelNvlShort => 'Nvl';

  @override
  String get levelMaxShort => 'Máx.';

  @override
  String get levelXpAccum => 'XP acumulado';

  @override
  String get levelHowToEarnXp => 'Cómo ganar XP';

  @override
  String get levelXpTipCheckin => '+10 XP por cada check-in completado';

  @override
  String get levelXpTipStreak => '+5 XP por día de racha activa (máx. +50)';

  @override
  String get levelXpTipAchievement => '+50 XP por cada logro desbloqueado';

  @override
  String levelXpToNext(int xp, String title) {
    return 'Faltan $xp XP para $title';
  }

  @override
  String get levelMaxReached => '¡Nivel máximo alcanzado!';

  @override
  String get levelSalud1 => 'Novato';

  @override
  String get levelSalud2 => 'Atleta';

  @override
  String get levelSalud3 => 'Guerrero';

  @override
  String get levelSalud4 => 'Campeón';

  @override
  String get levelSalud5 => 'Titán';

  @override
  String get levelProductividad1 => 'Aprendiz';

  @override
  String get levelProductividad2 => 'Organizado';

  @override
  String get levelProductividad3 => 'Estratega';

  @override
  String get levelProductividad4 => 'Ejecutor';

  @override
  String get levelProductividad5 => 'Maestro';

  @override
  String get levelBienestar1 => 'Inquieto';

  @override
  String get levelBienestar2 => 'Sereno';

  @override
  String get levelBienestar3 => 'Equilibrado';

  @override
  String get levelBienestar4 => 'Zen';

  @override
  String get levelBienestar5 => 'Iluminado';

  @override
  String get levelSocial1 => 'Tímido';

  @override
  String get levelSocial2 => 'Amigable';

  @override
  String get levelSocial3 => 'Conector';

  @override
  String get levelSocial4 => 'Líder';

  @override
  String get levelSocial5 => 'Embajador';

  @override
  String get levelAprendizaje1 => 'Curioso';

  @override
  String get levelAprendizaje2 => 'Estudiante';

  @override
  String get levelAprendizaje3 => 'Erudito';

  @override
  String get levelAprendizaje4 => 'Sabio';

  @override
  String get levelAprendizaje5 => 'Maestro';

  @override
  String get levelFinanzas1 => 'Ahorrador';

  @override
  String get levelFinanzas2 => 'Prudente';

  @override
  String get levelFinanzas3 => 'Inversor';

  @override
  String get levelFinanzas4 => 'Magnate';

  @override
  String get levelFinanzas5 => 'Mecenas';

  @override
  String get profileTitle => 'Perfil';

  @override
  String get profileNoHabits => 'Sin hábitos activos';

  @override
  String get profileMastery => 'Maestría';

  @override
  String get profileEditButton => 'Editar perfil';

  @override
  String get profileOpenSettings => 'Ajustes';

  @override
  String get editProfileTitle => 'Editar perfil';

  @override
  String get editProfileSave => 'Guardar';

  @override
  String get editProfileNameLabel => 'Nombre';

  @override
  String get editProfileBioLabel => 'Biografía';

  @override
  String get editProfileBioHint => 'Cuéntale al mundo sobre tus hábitos…';

  @override
  String get editProfileChangePhoto => 'Cambiar foto';

  @override
  String get editProfileUsernameLabel => 'Nombre de usuario';

  @override
  String get editProfileChooseUsername => 'Elegir nombre de usuario';

  @override
  String get editProfileUsernameHint =>
      'Se guarda al instante, sin pulsar Guardar.';

  @override
  String get editProfileUsernameUpdated => 'Nombre de usuario actualizado';

  @override
  String get editProfileSaved => 'Perfil actualizado';

  @override
  String get editProfileSaveError => 'No se pudo guardar el perfil';

  @override
  String get commonSaveError => 'No se pudo guardar el cambio';

  @override
  String get profileActiveHabits => 'Hábitos activos';

  @override
  String get profileEdit => 'Editar';

  @override
  String get profileStreak => 'Racha';

  @override
  String get profileHabits => 'Hábitos';

  @override
  String get profileBestStreak => 'Mejor racha';

  @override
  String get profileLevel => 'Nivel';

  @override
  String get profileFollowers => 'seguidores';

  @override
  String get profileFollowing => 'siguiendo';

  @override
  String profileBestStreakShort(int days) {
    return 'máx ${days}d';
  }

  @override
  String get exploreTitle => 'HabitAI';

  @override
  String get exploreSubtitle => 'Descubre hábitos\ny creadores';

  @override
  String get exploreSearchHint => 'Buscar personas, plantillas…';

  @override
  String get exploreChallenges => 'Retos';

  @override
  String get exploreSeeAll => 'Ver todos';

  @override
  String get exploreSeeAllAlt => 'Ver todas';

  @override
  String get exploreCreateChallenge => 'Crea tu primer reto';

  @override
  String get exploreChallengeSubtitle =>
      'Reta a un amigo a un hábito compartido';

  @override
  String get exploreFeaturedTemplates => 'Plantillas destacadas';

  @override
  String get exploreNoTemplates => 'Aún no hay plantillas publicadas';

  @override
  String get exploreFeaturedCreators => 'Creadores destacados';

  @override
  String get exploreNoProfiles => 'Aún no hay perfiles públicos';

  @override
  String get explorePeople => 'Personas';

  @override
  String get exploreTemplates => 'Plantillas';

  @override
  String get exploreNoResults => 'Sin resultados';

  @override
  String get exploreNoResultsHint => 'Prueba con otro término de búsqueda.';

  @override
  String get explorePending => 'Pendiente de aceptar';

  @override
  String get exploreFollowing => 'Siguiendo';

  @override
  String get exploreFollow => 'Seguir';

  @override
  String get exploreRequest => 'Solicitar';

  @override
  String get exploreRequested => 'Solicitado';

  @override
  String get exploreImport => 'Importar';

  @override
  String exploreChallengeDays(int days) {
    return '$days días';
  }

  @override
  String exploreHabitCount(int count) {
    return '$count hábitos';
  }

  @override
  String exploreHabitCountShort(int count) {
    return '$count hab.';
  }

  @override
  String exploreByAuthor(String username) {
    return 'Por @$username';
  }

  @override
  String get snackbarRetry => 'Reintentar';

  @override
  String get weekdayMonday => 'Lunes';

  @override
  String get weekdayTuesday => 'Martes';

  @override
  String get weekdayWednesday => 'Miércoles';

  @override
  String get weekdayThursday => 'Jueves';

  @override
  String get weekdayFriday => 'Viernes';

  @override
  String get weekdaySaturday => 'Sábado';

  @override
  String get weekdaySunday => 'Domingo';

  @override
  String get weekdayMonShort => 'Lun';

  @override
  String get weekdayTueShort => 'Mar';

  @override
  String get weekdayWedShort => 'Mié';

  @override
  String get weekdayThuShort => 'Jue';

  @override
  String get weekdayFriShort => 'Vie';

  @override
  String get weekdaySatShort => 'Sáb';

  @override
  String get weekdaySunShort => 'Dom';

  @override
  String get weekdayTodayShort => 'Hoy';

  @override
  String get weekdayLShort => 'L';

  @override
  String get weekdayMShort => 'M';

  @override
  String get weekdayXShort => 'X';

  @override
  String get weekdayJShort => 'J';

  @override
  String get weekdayVShort => 'V';

  @override
  String get weekdaySShort => 'S';

  @override
  String get weekdayDShort => 'D';

  @override
  String get monthJan => 'ene';

  @override
  String get monthFeb => 'feb';

  @override
  String get monthMar => 'mar';

  @override
  String get monthApr => 'abr';

  @override
  String get monthMay => 'may';

  @override
  String get monthJun => 'jun';

  @override
  String get monthJul => 'jul';

  @override
  String get monthAug => 'ago';

  @override
  String get monthSep => 'sep';

  @override
  String get monthOct => 'oct';

  @override
  String get monthNov => 'nov';

  @override
  String get monthDec => 'dic';

  @override
  String get habitFieldTitle => 'Título';

  @override
  String get habitFieldDescription => 'Descripción';

  @override
  String get habitFieldOptional => 'Opcional';

  @override
  String get habitFieldCategory => 'Categoría';

  @override
  String get habitFieldWeekdays => 'Días de la semana';

  @override
  String get habitFieldReminder => 'Recordatorio';

  @override
  String get habitNoReminder => 'Sin recordatorio';

  @override
  String get createHabitTitle => 'Nuevo hábito';

  @override
  String get createHabitTitleHint => 'Ej: Leer 20 minutos';

  @override
  String get createHabitGroupLabel => 'Grupo';

  @override
  String get createHabitGroupHint =>
      'Agrupa este hábito con otros relacionados';

  @override
  String get createHabitNoGroup => 'Sin grupo';

  @override
  String get createHabitChainLabel => 'Encadenar después de...';

  @override
  String get createHabitChainHint =>
      'Se mostrará como siguiente paso al completar el hábito ancla';

  @override
  String get createHabitChainNone => 'Ninguno';

  @override
  String get createHabitCta => 'Crear hábito';

  @override
  String get editHabitTitle => 'Editar hábito';

  @override
  String get editHabitTitleHint => 'Ej: Correr 30 minutos';

  @override
  String get editHabitRoutineLabel => 'Rutina';

  @override
  String get editHabitNoRoutine => 'Sin rutina';

  @override
  String get editHabitChainLabel => 'Cadena de hábitos';

  @override
  String editHabitChainedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hábitos encadenados',
      one: '1 hábito encadenado',
    );
    return '$_temp0';
  }

  @override
  String get editHabitChainThis => '← este';

  @override
  String get editHabitChainRemove => 'Quitar de la cadena';

  @override
  String get editHabitNoChain =>
      'Este hábito no pertenece a ninguna cadena. Puedes encadenarlo al crear hábitos nuevos.';

  @override
  String get editHabitSaveCta => 'Guardar cambios';

  @override
  String get commonDelete => 'Eliminar';

  @override
  String get commonCancel => 'Cancelar';

  @override
  String get commonEdit => 'Editar';

  @override
  String habitCardAfter(String title) {
    return 'Después de \"$title\"';
  }

  @override
  String get habitCardNext => '¡Siguiente!';

  @override
  String get habitCardCoachLabel => '– COACH · PREGUNTA DEL DÍA';

  @override
  String get habitCardCoachApply => 'SÍ, HAZLO →';

  @override
  String get habitCardCoachDismiss => 'OTRA OPCIÓN';

  @override
  String get createChoiceHabitTitle => 'Nuevo hábito';

  @override
  String get createChoiceHabitSubtitle => 'Un hábito individual';

  @override
  String get createChoiceGroupTitle => 'Nueva rutina';

  @override
  String get createChoiceGroupSubtitle => 'Grupo de hábitos relacionados';

  @override
  String get createGroupTitle => 'Nueva rutina';

  @override
  String get createGroupNameLabel => 'Nombre de la rutina';

  @override
  String get createGroupNameHint => 'Ej: Rutina matutina';

  @override
  String get createGroupDescHint => 'Opcional — para qué sirve esta rutina';

  @override
  String get createGroupEmojiLabel => 'Emoji';

  @override
  String get createGroupEmojiHint => 'Pega un emoji o selecciona abajo';

  @override
  String get createGroupCta => 'Crear rutina';

  @override
  String get emptyHabitsTitle => '¡Empieza tu camino!';

  @override
  String get emptyHabitsSubtitle =>
      'Cuéntale a la IA tus metas y te creará\nun plan de hábitos personalizado.';

  @override
  String get emptyHabitsAction => 'Crear mi plan con IA';

  @override
  String get stackCompleteTitle => '¡CADENA COMPLETA!';

  @override
  String stackCompleteCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hábitos seguidos. ¡Imparable!',
      one: '1 hábito seguido. ¡Imparable!',
    );
    return '$_temp0';
  }

  @override
  String get stackCompleteSubtitle => 'Así se construye un hábito atómico.';

  @override
  String allHabitsTotal(int count) {
    return '$count en total';
  }

  @override
  String get allHabitsCancelSelection => 'Cancelar selección';

  @override
  String get allHabitsTabActive => 'Activos';

  @override
  String get allHabitsTabArchived => 'Archivados';

  @override
  String get allHabitsTabRoutines => 'Rutinas';

  @override
  String get allHabitsEmptyActiveTitle => 'No tienes hábitos creados';

  @override
  String get allHabitsEmptyActiveSubtitle =>
      'Crea hábitos desde la pantalla principal o con la IA.';

  @override
  String get allHabitsEmptyArchivedTitle => 'No tienes hábitos archivados';

  @override
  String get allHabitsEmptyRoutinesTitle => 'No tienes rutinas creadas';

  @override
  String get allHabitsEmptyRoutinesSubtitle =>
      'Crea una rutina desde el \"+\" de la pantalla principal.';

  @override
  String get allHabitsNoHabitsYet => 'Sin hábitos aún';

  @override
  String get allHabitsHardDeleteTitle => 'Borrar definitivamente';

  @override
  String allHabitsHardDeleteContent(String title) {
    return '¿Seguro que quieres borrar \"$title\" para siempre?\n\nEsto borra el hábito y todos sus registros. No se puede deshacer.';
  }

  @override
  String get allHabitsHardDeleteConfirm => 'Borrar definitivo';

  @override
  String allHabitsHardDeleted(String title) {
    return '\"$title\" borrado permanentemente';
  }

  @override
  String get allHabitsHardDeleteError => 'Error al borrar el hábito';

  @override
  String allHabitsBulkDeleteTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Borrar $count hábitos',
      one: 'Borrar 1 hábito',
    );
    return '$_temp0';
  }

  @override
  String get allHabitsBulkDeleteContent =>
      'Se borrarán definitivamente con todos sus registros. No se puede deshacer.';

  @override
  String get allHabitsDeleteButton => 'Borrar';

  @override
  String allHabitsBulkDeleted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hábitos borrados',
      one: '1 hábito borrado',
    );
    return '$_temp0';
  }

  @override
  String get allHabitsBulkDeleteError => 'Error al borrar los hábitos';

  @override
  String allHabitsBulkDeleteGroupsTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Eliminar $count rutinas',
      one: 'Eliminar 1 rutina',
    );
    return '$_temp0';
  }

  @override
  String get allHabitsBulkDeleteGroupsContent =>
      '¿Qué quieres hacer con los hábitos de las rutinas seleccionadas?';

  @override
  String get allHabitsBulkDeleteGroupsOnly => 'Solo las rutinas';

  @override
  String get allHabitsBulkDeleteGroupsAndHabits => 'Rutinas y hábitos';

  @override
  String allHabitsGroupsDeleted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count rutinas eliminadas',
      one: '1 rutina eliminada',
    );
    return '$_temp0';
  }

  @override
  String get allHabitsGroupsDeleteError => 'Error al eliminar las rutinas';

  @override
  String get groupDetailEditTitle => 'Editar grupo';

  @override
  String get groupDetailAddHabitError => 'Error al añadir el hábito';

  @override
  String get groupDetailHabitAdded => 'Hábito añadido a la rutina';

  @override
  String get groupDetailGroupUpdated => 'Grupo actualizado';

  @override
  String get groupDetailGroupUpdateError => 'Error al actualizar el grupo';

  @override
  String get groupDetailPublishNoHabits =>
      'El grupo no tiene hábitos, añade al menos uno.';

  @override
  String get groupDetailPublishNeedPublic =>
      'Activa tu perfil público en Ajustes antes de publicar.';

  @override
  String get groupDetailPublishNeedPublicTitle => 'Necesitas un perfil público';

  @override
  String get groupDetailPublishNeedPublicBody =>
      'Para compartir una plantilla con la comunidad necesitas un perfil público con username. ¿Crear el tuyo ahora?';

  @override
  String get groupDetailPublishCreateProfileCta => 'Crear perfil público';

  @override
  String get groupDetailPublishReactivateBody =>
      'Tu perfil público está desactivado. Reactívalo para compartir esta plantilla con tu username.';

  @override
  String get groupDetailPublishReactivateCta => 'Reactivar perfil';

  @override
  String get groupDetailPublishTitle => 'Publicar como plantilla';

  @override
  String groupDetailPublishBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Se publicarán $count hábitos sin datos personales (sin rachas ni historial).',
      one:
          'Se publicará 1 hábito sin datos personales (sin rachas ni historial).',
    );
    return '$_temp0';
  }

  @override
  String get groupDetailPublishDescLabel => 'Descripción (opcional)';

  @override
  String get groupDetailPublishDescHint => 'Explica para quién es este plan…';

  @override
  String get groupDetailPublishConfirm => 'Publicar';

  @override
  String get groupDetailPublishSuccess => 'Plantilla publicada en la comunidad';

  @override
  String get groupDetailViewAction => 'Ver';

  @override
  String get groupDetailPublishError => 'Error al publicar la plantilla';

  @override
  String get groupDetailUnpublishTitle => 'Retirar plantilla';

  @override
  String get groupDetailUnpublishContent =>
      'La plantilla desaparecerá del marketplace. Las copias importadas por otros usuarios no se verán afectadas.';

  @override
  String get groupDetailUnpublishConfirm => 'Retirar';

  @override
  String get groupDetailUnpublishSuccess =>
      'Plantilla retirada del marketplace';

  @override
  String get groupDetailUnpublishError => 'Error al retirar la plantilla';

  @override
  String get groupDetailUnpublishTooltip => 'Retirar del marketplace';

  @override
  String get groupDetailPublishTooltip => 'Publicar como plantilla';

  @override
  String get groupDetailNotFound => 'Este grupo ya no existe.';

  @override
  String get groupDetailHabitsHeader => 'Hábitos del grupo';

  @override
  String get groupDetailEmptyTitle => 'Sin hábitos en este grupo';

  @override
  String get groupDetailEmptySubtitle => 'Añade hábitos con el botón +';

  @override
  String get groupDetailEditNameLabel => 'Título del grupo';

  @override
  String get groupDetailEditNameHint => 'Ej: Rutina de gimnasio';

  @override
  String get groupDetailEditEmojiHint => 'Pega un emoji o déjalo vacío';

  @override
  String get commonApply => 'Aplicar';

  @override
  String get monthFullJan => 'Enero';

  @override
  String get monthFullFeb => 'Febrero';

  @override
  String get monthFullMar => 'Marzo';

  @override
  String get monthFullApr => 'Abril';

  @override
  String get monthFullMay => 'Mayo';

  @override
  String get monthFullJun => 'Junio';

  @override
  String get monthFullJul => 'Julio';

  @override
  String get monthFullAug => 'Agosto';

  @override
  String get monthFullSep => 'Septiembre';

  @override
  String get monthFullOct => 'Octubre';

  @override
  String get monthFullNov => 'Noviembre';

  @override
  String get monthFullDec => 'Diciembre';

  @override
  String get butterflyNotFound =>
      'No se encontró la proyección o puede que haya expirado.';

  @override
  String butterflyCheckins(int count) {
    return '$count check-ins';
  }

  @override
  String butterflyStreakDays(int count) {
    return '${count}d racha';
  }

  @override
  String butterflyCompletion(int percent) {
    return '$percent% completitud';
  }

  @override
  String get butterflyKeyMoments => 'Momentos clave';

  @override
  String get patternInsightsNeedConnection =>
      'Necesitas conexión para regenerar los patrones';

  @override
  String get patternInsightsNeedMore =>
      'Necesitas al menos 14 días con datos y 3 hábitos activos.';

  @override
  String get patternInsightsUpdated => 'Patrones actualizados.';

  @override
  String patternInsightsEmptyTitle(String period) {
    return 'Sin insights para $period';
  }

  @override
  String get patternInsightsEmptySubtitle =>
      'Genera los patrones desde el dashboard o espera a que el sistema los procese automáticamente.';

  @override
  String get patternInsightsRegenerate => 'Regenerar patrones';

  @override
  String get patternInsightsLimitedData => 'Datos limitados';

  @override
  String patternInsightsDetected(int count) {
    return '$count patrones detectados';
  }

  @override
  String get patternInsightsConfidenceHigh => 'Alta confianza';

  @override
  String get patternInsightsConfidenceMedium => 'Media';

  @override
  String get patternInsightsConfidenceLow => 'Baja';

  @override
  String get weeklyReviewNotFound => 'No se encontró esta revisión';

  @override
  String get weeklyReviewLoadError => 'Error al cargar la revisión';

  @override
  String get weeklyReviewHabitGone => 'Este hábito ya no existe';

  @override
  String get weeklyReviewWins => 'Lo que funcionó';

  @override
  String get weeklyReviewStruggles => 'Dónde fallaste';

  @override
  String weeklyReviewWeekLabel(String weekId) {
    return 'Semana $weekId';
  }

  @override
  String get weeklyReviewStatCheckins => 'Check-ins';

  @override
  String get weeklyReviewStatHabits => 'Hábitos';

  @override
  String get weeklyReviewStatAtRisk => 'En riesgo';

  @override
  String get weeklyReviewFocusTitle => 'Tu foco esta semana';

  @override
  String get weeklyReviewRecommendations => 'Recomendaciones';

  @override
  String get planCardSaved => 'Hábitos guardados';

  @override
  String get planCardAddSelected => 'Añadir hábitos seleccionados';

  @override
  String get planCardFrequencyDaily => 'Diario';

  @override
  String get planCardFrequencyWeekly => 'Semanal';

  @override
  String get planCardFrequencyCustom => 'Personalizado';

  @override
  String get challengesTitle => 'Mis retos';

  @override
  String get challengesNew => 'Nuevo reto';

  @override
  String get challengesEmptyTitle => 'Sin retos todavía';

  @override
  String get challengesEmptySubtitle =>
      'Reta a un amigo a completar un hábito juntos durante varios días';

  @override
  String get challengesSectionPending => 'Pendientes';

  @override
  String get challengesSectionActive => 'Activos';

  @override
  String get challengesSectionFinished => 'Finalizados';

  @override
  String get challengeCardWaiting => 'Esperando aceptación...';

  @override
  String get challengeStatusPending => 'Pendiente';

  @override
  String get challengeStatusActive => 'Activo';

  @override
  String get challengeStatusCompleted => 'Completado';

  @override
  String get challengeStatusDeclined => 'Rechazado';

  @override
  String get challengeStatusAbandoned => 'Abandonado';

  @override
  String get challengeDetailTitle => 'Reto compartido';

  @override
  String get challengeDetailNotFound => 'Reto no encontrado';

  @override
  String get challengeDetailAccepted =>
      '¡Reto aceptado! El hábito fue creado en tu lista';

  @override
  String get challengeDetailAcceptError => 'Error al aceptar el reto';

  @override
  String get challengeDetailDeclineTitle => 'Rechazar reto';

  @override
  String get challengeDetailDeclineContent =>
      '¿Seguro que quieres rechazar este reto?';

  @override
  String get challengeDetailDeclineConfirm => 'Rechazar';

  @override
  String get challengeDetailAbandonTitle => 'Abandonar reto';

  @override
  String get challengeDetailAbandonContent =>
      '¿Seguro que quieres abandonar? No podrás retomarlo.';

  @override
  String get challengeDetailAbandonConfirm => 'Abandonar';

  @override
  String get challengeDetailAbandonTooltip => 'Abandonar';

  @override
  String get challengeDetailYourProgress => 'Tu progreso';

  @override
  String get challengeDetailPartner => 'Compañero';

  @override
  String get challengeDetailCompletedTitle => '¡Reto completado!';

  @override
  String get challengeDetailCompletedSubtitle =>
      'Ambos habéis demostrado constancia';

  @override
  String get challengeDetailDeclinedState => 'Reto rechazado';

  @override
  String get challengeDetailAbandonedState => 'Reto abandonado';

  @override
  String challengeDetailWaitingPartner(String name) {
    return 'Esperando a que $name acepte el reto';
  }

  @override
  String get challengeDetailFallbackPartner => 'tu compañero';

  @override
  String get challengeDetailFallbackPartnerCap => 'Compañero';

  @override
  String get challengeDetailFallbackSomeone => 'Alguien';

  @override
  String challengeDetailYouChallenged(String name) {
    return 'Retaste a $name';
  }

  @override
  String challengeDetailChallengedYou(String name) {
    return '$name te ha retado';
  }

  @override
  String get challengeDetailAcceptQuestion => '¿Aceptas el reto?';

  @override
  String get challengeDetailAcceptHint =>
      'Se creará automáticamente el hábito en tu lista y empezareis juntos';

  @override
  String get challengeDetailAcceptCta => 'Aceptar reto';

  @override
  String get challengeDetailCompletedToday => '¡Completado hoy!';

  @override
  String get challengeDetailMarkToday => 'Marcar hoy como completado';

  @override
  String challengeDetailProgressDays(int completed, int total) {
    return '$completed / $total días';
  }

  @override
  String get createChallengeTitle => 'Crear reto';

  @override
  String createChallengeError(String error) {
    return 'Error al crear reto: $error';
  }

  @override
  String get createChallengeHabitName => 'Nombre del hábito';

  @override
  String get createChallengeHabitHint => 'Ej: Meditar 10 minutos';

  @override
  String get createChallengeDuration => 'Duración';

  @override
  String get createChallengePartnerLabel => 'Compañero de reto';

  @override
  String get createChallengeSearchUsername => 'Buscar por username';

  @override
  String get createChallengeFollowerChip => 'Seguidor';

  @override
  String get createChallengeSend => 'Enviar reto';

  @override
  String get communityTitle => 'Comunidad';

  @override
  String get communitySearchHint => 'Buscar plantillas…';

  @override
  String get communitySortPopular => 'Popular';

  @override
  String get communitySortRecent => 'Recientes';

  @override
  String get communityFilterAll => 'Todas';

  @override
  String get communityLoadMore => 'Cargar más';

  @override
  String get communityEndOfList => '— fin de la lista —';

  @override
  String get communityEmptyTitle => 'Todavía no hay plantillas';

  @override
  String get communityEmptySubtitle =>
      'Sé el primero en publicar un plan de hábitos.';

  @override
  String get communityEmptyFilterTitle => 'Sin resultados para ese filtro';

  @override
  String get communityEmptyFilterSubtitle =>
      'Prueba otra categoría o quita el filtro.';

  @override
  String get communityDetailNotFound => 'Plantilla no encontrada';

  @override
  String get communityDetailLoadError => 'Error al cargar la plantilla';

  @override
  String communityDetailImported(String emoji, String title) {
    return '$emoji \"$title\" importado a tus hábitos';
  }

  @override
  String get communityDetailImportError => 'Error al importar la plantilla';

  @override
  String get communityDetailReportTitle => 'Reportar plantilla';

  @override
  String get communityDetailReportContent =>
      '¿Quieres reportar esta plantilla por contenido inapropiado? Será revisada por el equipo.';

  @override
  String get communityDetailReportConfirm => 'Reportar';

  @override
  String get communityDetailReportSent => 'Reporte enviado, gracias';

  @override
  String communityDetailImports(int count) {
    return '$count imports';
  }

  @override
  String communityDetailByAuthor(String name) {
    return 'Por $name';
  }

  @override
  String get communityDetailHabitsIncluded => 'Hábitos incluidos';

  @override
  String get communityDetailMyTemplate => 'Esta es tu plantilla';

  @override
  String get communityDetailImporting => 'Importando…';

  @override
  String get communityDetailImportCta => 'Importar a mis hábitos';

  @override
  String streakDaysShort(int count) {
    return '${count}d';
  }

  @override
  String get categoryDetailTitle => 'Categorías';

  @override
  String get categoryDetailDistribution => 'Distribución';

  @override
  String categoryDetailWeeklyPct(int percent) {
    return '$percent% semanal';
  }

  @override
  String get streaksDetailTitle => 'Rachas';

  @override
  String get streaksDetailBestGlobal => 'Mejor racha global';

  @override
  String get streaksDetailOnStreak => 'En racha';

  @override
  String get streaksDetailNoStreak => 'Sin racha';

  @override
  String streaksDetailBestShort(int count) {
    return 'mejor: ${count}d';
  }

  @override
  String get weeklyDetailTitle => 'Progreso mensual';

  @override
  String get weeklyDetailDailyBreakdown => 'Desglose diario';

  @override
  String get weeklyDetailAverage => 'Media';

  @override
  String get weeklyDetailLast30Days => 'Últimos 30 días';

  @override
  String get usernameSheetTitleNew => 'Elige tu username';

  @override
  String get usernameSheetTitleChange => 'Cambiar username';

  @override
  String get usernameSheetSubtitle =>
      'Tu username es único y público. Aparecerá en tu perfil y en los retos.';

  @override
  String get usernameSheetHelperIdle => 'Te identifica en la comunidad';

  @override
  String get usernameSheetChecking => 'Comprobando...';

  @override
  String get usernameSheetVisibleData => 'Datos visibles en tu perfil:';

  @override
  String get usernameSheetDataName => 'Nombre y @username';

  @override
  String get usernameSheetDataStreaks => 'Rachas actuales';

  @override
  String get usernameSheetDataHabits => 'Hábitos activos (título y categoría)';

  @override
  String get usernameSheetDataLevel => 'Nivel y logros';

  @override
  String get usernameSheetPrivacy =>
      'Nunca se comparten: email, notas, recordatorios.';

  @override
  String get usernameSheetConfirm => 'Confirmar';

  @override
  String get errorDefault => 'Algo salió mal';

  @override
  String get habitDetailInfo => 'Información';

  @override
  String get habitDetailAIGenerated => 'Generado por IA';

  @override
  String get habitDetailFrequency => 'Frecuencia';

  @override
  String get habitsOrderSaveError => 'Error al guardar el orden';

  @override
  String get habitsDeleteGroup => 'Eliminar grupo';

  @override
  String get notificationsTitle => 'Notificaciones';

  @override
  String get notificationsClearActivity => 'Limpiar actividad';

  @override
  String get notificationsActiveReminders => 'Recordatorios activos';

  @override
  String notificationsAdjustSuggested(String habitTitle) {
    return 'Ajuste sugerido: $habitTitle';
  }

  @override
  String get notificationsWeeklyReviewReady => 'Revisión semanal lista';

  @override
  String get notificationsMonthlyProjection => 'Proyección mensual 🦋';

  @override
  String get notificationsChallengeReceived => '¡Te han retado!';

  @override
  String get notificationsChallengeAccepted => '¡Tu reto fue aceptado!';

  @override
  String notificationsReminderAt(String time) {
    return 'Recordatorio a las $time';
  }

  @override
  String get notificationsYesterday => 'Ayer';

  @override
  String notificationsDaysAgo(int days) {
    return 'Hace ${days}d';
  }

  @override
  String notificationsWeeksAgo(int weeks) {
    return 'Hace ${weeks}sem';
  }

  @override
  String notificationsMonthsAgo(int months) {
    return 'Hace ${months}mes';
  }

  @override
  String get notificationsEmpty => 'Sin notificaciones';

  @override
  String get notificationsEmptySubtitle =>
      'Aquí aparecerán tus logros, recordatorios y sugerencias de la IA.';

  @override
  String get notificationsNoActivity => 'Sin actividad reciente';

  @override
  String get notificationsLoadError =>
      'No se pudieron cargar las notificaciones.';

  @override
  String get followersTabFollowers => 'Seguidores';

  @override
  String get followersTabFollowing => 'Siguiendo';

  @override
  String get followersTabRequests => 'Solicitudes';

  @override
  String get followersMutual => 'Mutuo';

  @override
  String get followersFollowsYou => 'Te sigue';

  @override
  String get followersUnfollow => 'Dejar de seguir';

  @override
  String get followersRemoveTitle => 'Eliminar seguidor';

  @override
  String followersRemoveContent(String username) {
    return '¿Eliminar a @$username de tus seguidores?';
  }

  @override
  String followersUnfollowContent(String username) {
    return '¿Dejar de seguir a @$username?';
  }

  @override
  String get followersRequestAlreadySent => 'Solicitud ya enviada';

  @override
  String followersRequestSent(String username) {
    return 'Solicitud enviada a @$username';
  }

  @override
  String followersNowFollowing(String username) {
    return 'Siguiendo a @$username';
  }

  @override
  String get followersRemoved => 'Seguidor eliminado';

  @override
  String followersUnfollowed(String username) {
    return 'Dejaste de seguir a @$username';
  }

  @override
  String followersRequestsError(String error) {
    return 'Error al cargar solicitudes: $error';
  }

  @override
  String get followersEmptyTitle => 'Aún no tienes seguidores';

  @override
  String get followersEmptySubtitle =>
      'Busca usuarios por @username para seguirlos o que te sigan';

  @override
  String get followingEmptyTitle => 'No sigues a nadie';

  @override
  String get followingEmptySubtitle =>
      'Busca usuarios en la pestaña Seguidores';

  @override
  String get followersRequestsEmptyTitle => 'Sin solicitudes pendientes';

  @override
  String get followersRequestsEmptySubtitle =>
      'Aquí aparecerán las solicitudes de seguimiento que recibas';

  @override
  String get followersSearchHint => 'Buscar por @username';

  @override
  String get publicProfileNotAvailable => 'Perfil no disponible';

  @override
  String publicProfileMemberSince(String month) {
    return 'Miembro desde $month';
  }

  @override
  String get publicProfileMutualFollower => 'Seguidor mutuo';

  @override
  String get publicProfilePrivate => 'Esta cuenta es privada';

  @override
  String get publicProfileRequestPending =>
      'Tu solicitud está pendiente de aprobación.';

  @override
  String get publicProfileFollowToSee =>
      'Síguelo para ver sus hábitos y estadísticas.';

  @override
  String get publicProfileNoHabits => 'Sin hábitos visibles';

  @override
  String get publicProfileMore => 'más';

  @override
  String get publicProfilesFeedTitle => 'Explorar perfiles';

  @override
  String get publicProfilesFeedSearchHint => 'Buscar por @username…';

  @override
  String get publicProfilesFeedEmptySubtitle =>
      'Activa tu perfil en Ajustes para aparecer aquí.';

  @override
  String get publicProfilesFeedNoResultsSubtitle => 'Prueba con otro @username';

  @override
  String get avatarPickerTitle => 'Foto de perfil';

  @override
  String get avatarPickerGallery => 'Elegir de la galería';

  @override
  String get avatarPickerCamera => 'Hacer una foto';

  @override
  String get avatarPickerRemove => 'Quitar foto';

  @override
  String get avatarPickerCropNote => 'Se recortará al centro automáticamente';

  @override
  String get avatarPickerUpdated => 'Foto de perfil actualizada';

  @override
  String get avatarPickerUploadError => 'No se pudo subir la foto';

  @override
  String get avatarPickerRemoved => 'Foto eliminada';

  @override
  String get avatarPickerRemoveError => 'No se pudo eliminar la foto';

  @override
  String get avatarPickerProcessing => 'Procesando foto…';

  @override
  String publicProfileLevelShort(String level) {
    return 'Niv. $level';
  }

  @override
  String get publicProfileAverageLevel => 'Nivel medio';

  @override
  String get privacySectionVisibility => 'Visibilidad';

  @override
  String get privacyPublicProfileTitle => 'Perfil público';

  @override
  String get privacyPublicProfileDescOn =>
      'Apareces en el directorio, cualquiera puede seguirte';

  @override
  String get privacyPublicProfileDescOff => 'Solo tus seguidores pueden verte';

  @override
  String get privacyChangeUsername => 'Cambiar username';

  @override
  String get privacyUsernameTaken => 'El username ya está ocupado';

  @override
  String get privacyUsernameHint =>
      'Elige un nombre de usuario para que otros puedan encontrarte.';

  @override
  String get privacyDisableTitle => 'Desactivar perfil público';

  @override
  String get privacyDisableContent =>
      'Tu perfil desaparecerá del directorio. Tus seguidores actuales podrán seguir viéndote hasta que los elimines.';

  @override
  String get privacyDisableButton => 'Desactivar';

  @override
  String get privacyNoHabits => 'No tienes hábitos activos';

  @override
  String get privacyPublicViewLabel => 'Qué ve todo el mundo';

  @override
  String get privacyFollowersViewLabel => 'Qué ven tus seguidores';

  @override
  String get privacyChallengesTitle => 'Quién puede enviarme retos';

  @override
  String get privacyChallengesDesc =>
      'Controla quién puede invitarte a competir en un hábito';

  @override
  String get privacyVisibleHabitsSection => 'Hábitos visibles en tu perfil';

  @override
  String get privacyHabitsLabel => 'Hábitos activos';

  @override
  String get privacyStatsLabel => 'Estadísticas';

  @override
  String get privacyFollowersLabel => 'Seguidores / Siguiendo';

  @override
  String get privacyOptionPublic => 'Público';

  @override
  String get privacyOptionFollowers => 'Seguidores';

  @override
  String get privacyOptionPrivate => 'Privado';

  @override
  String get privacyLevelEveryone => 'Todos';

  @override
  String get privacyLevelNobody => 'Nadie';

  @override
  String get privacySocialReactionsTitle => 'Reacciones en logros';

  @override
  String get privacySocialReactionsSubtitle =>
      'Permite que tus seguidores reaccionen a tus logros con 🔥 💪 👏';

  @override
  String get achievementFirstHabitTitle => 'Primer paso';

  @override
  String get achievementFirstHabitDesc => 'Crea tu primer hábito';

  @override
  String get achievementAiPlanTitle => 'Asistente personal';

  @override
  String get achievementAiPlanDesc => 'Genera un plan con la IA';

  @override
  String get achievementPerfectDayTitle => 'Día perfecto';

  @override
  String get achievementPerfectDayDesc => 'Completa todos los hábitos del día';

  @override
  String get achievementStreak3Title => 'En marcha';

  @override
  String get achievementStreak3Desc => 'Consigue una racha de 3 días';

  @override
  String get achievementStreak7Title => 'Semana de fuego';

  @override
  String get achievementStreak7Desc => 'Consigue una racha de 7 días';

  @override
  String get achievementStreak14Title => 'Imparable';

  @override
  String get achievementStreak14Desc => 'Consigue una racha de 14 días';

  @override
  String get achievementStreak30Title => 'Leyenda';

  @override
  String get achievementStreak30Desc => 'Consigue una racha de 30 días';

  @override
  String get achievementHabits5Title => 'Cinco en acción';

  @override
  String get achievementHabits5Desc => 'Ten 5 hábitos activos';

  @override
  String get achievementTotal50Title => 'Medio centenar';

  @override
  String get achievementTotal50Desc => 'Completa 50 check-ins en total';

  @override
  String get achievementTotal100Title => 'Centenario';

  @override
  String get achievementTotal100Desc => 'Completa 100 check-ins en total';

  @override
  String get achievementPerfectWeekTitle => 'Semana impecable';

  @override
  String get achievementPerfectWeekDesc => '7 días seguidos completando todo';

  @override
  String get achievementChallengeTitle => 'Compañeros de reto';

  @override
  String get achievementChallengeDesc => 'Completa un reto compartido';

  @override
  String get moodTitle => 'Mi ánimo';

  @override
  String get moodHowAreYou => '¿Cómo te sientes?';

  @override
  String get moodSave => 'Guardar ánimo';

  @override
  String get moodNotePlaceholder => 'Añade una nota (opcional)';

  @override
  String get moodTimeBlockLabel => 'Momento del día';

  @override
  String get moodTimeBlockMorning => 'Mañana';

  @override
  String get moodTimeBlockMidday => 'Mediodía';

  @override
  String get moodTimeBlockAfternoon => 'Tarde';

  @override
  String get moodTimeBlockNight => 'Noche';

  @override
  String get moodHabitsToday => 'Hábitos completados hoy';

  @override
  String get moodEmptyState => 'Aún no hay registros de ánimo';

  @override
  String get moodEmptyStateCta => 'Registra tu primer ánimo';

  @override
  String get moodWeekChart => 'Ánimo últimos 7 días';

  @override
  String get moodLabelAnxiety => 'Ansiedad';

  @override
  String get moodLabelTiredness => 'Cansancio';

  @override
  String get moodLabelMotivation => 'Motivación';

  @override
  String get moodLabelCalm => 'Calma';

  @override
  String get moodLabelStress => 'Estrés';

  @override
  String get moodLabelSadness => 'Tristeza';

  @override
  String get moodLabelEnergy => 'Energía';

  @override
  String get moodLabelAnger => 'Enfado';

  @override
  String get moodLabelGratitude => 'Gratitud';

  @override
  String get moodLabelFocus => 'Concentración';

  @override
  String get moodCalendarTitle => 'Calendario de ánimo';

  @override
  String get moodCalendarLegend => 'Leyenda';

  @override
  String get moodDeleteEntry => 'Eliminar registro';

  @override
  String get moodNoEntriesDay => 'Sin registros este día';

  @override
  String get drawerMoodCalendar => 'Mi ánimo';

  @override
  String get drawerMoodCalendarSubtitle =>
      'Historial mensual de estado de ánimo';

  @override
  String get moodCorrelationTitle => 'Ánimo y hábitos';

  @override
  String get moodCorrelationNotEnoughData =>
      'Necesitas más registros para ver correlaciones';

  @override
  String get moodCorrelationDays7 => '7 días';

  @override
  String get moodCorrelationDays30 => '30 días';

  @override
  String get moodChartLegendHabits => '% hábitos';

  @override
  String get moodChartLegendMood => 'ánimo';

  @override
  String get moodInsightsTitle => 'Insights de ánimo';

  @override
  String get moodInsightsAllCategories => 'Todas las categorías';

  @override
  String get moodCorrelationDaysCompleted => 'días completado';

  @override
  String get moodConfidenceLow => 'Poca fiabilidad';

  @override
  String get moodConfidenceMedium => 'Fiabilidad media';

  @override
  String get moodConfidenceHigh => 'Alta fiabilidad';

  @override
  String moodStreakBoost(String diff) {
    return 'Con 5+ días seguidos: $diff';
  }

  @override
  String get moodInsightsDelayedHeader => 'Efecto al día siguiente';

  @override
  String moodDelayedBoost(String habitName, String diff) {
    return 'Hacer $habitName hoy mejora tu ánimo de mañana en $diff';
  }

  @override
  String moodCorrelationBoost(String emoji, String diff, String habitName) {
    return 'Tu ánimo $emoji sube $diff los días que haces $habitName';
  }

  @override
  String moodCorrelationDrop(String habitName, String diff) {
    return 'Los días sin $habitName, tu ánimo baja $diff';
  }

  @override
  String get moodInsightsPositiveHeader => 'Te hacen bien';

  @override
  String get moodInsightsNegativeHeader => 'Mejor no faltar';

  @override
  String get weeklyReviewMoodInsights => 'Análisis emocional';

  @override
  String get moodBannerMorning => '¡Buenos días! ¿Cómo has dormido?';

  @override
  String get moodBannerAfternoon => '¿Qué tal va la tarde?';

  @override
  String get moodBannerNight => '¿Cómo ha ido el día?';

  @override
  String get moodRating1 => 'Fatal';

  @override
  String get moodRating2 => 'Regular';

  @override
  String get moodRating3 => 'Normal';

  @override
  String get moodRating4 => 'Bien';

  @override
  String get moodRating5 => 'Genial';

  @override
  String get moodLoggedToday => 'Registrado';

  @override
  String moodStreakDays(int count) {
    return 'Racha de $count días';
  }

  @override
  String get moodQuickSave => 'Guardar rápido';

  @override
  String get moodTellMore => '¿Quieres añadir detalles?';

  @override
  String get moodSkip => 'Saltar';

  @override
  String get moodNext => 'Siguiente';

  @override
  String get moodAnythingOnMind => '¿Algo que quieras anotar?';

  @override
  String get moodSaveError =>
      'No se pudo guardar el ánimo. Inténtalo de nuevo.';

  @override
  String get moodDeleteError => 'No se pudo eliminar el registro';

  @override
  String get moodDeleteConfirm => '¿Eliminar este registro de ánimo?';

  @override
  String get moodLabelsPositive => 'Lo que sientes bien';

  @override
  String get moodLabelsNegative => 'Lo que pesa hoy';

  @override
  String get updateForceTitle => 'Actualización obligatoria';

  @override
  String get updateSoftTitle => 'Nueva versión disponible';

  @override
  String get updateNow => 'Actualizar ahora';

  @override
  String get updateLater => 'Ahora no';
}
