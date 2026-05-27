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
  String get profileTitle => 'Perfil';

  @override
  String get profileNoHabits => 'Sin hábitos activos';

  @override
  String get profileMastery => 'Maestría';

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
}
