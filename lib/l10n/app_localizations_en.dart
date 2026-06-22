// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class SEn extends S {
  SEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'HabitAI';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get confirm => 'Continue';

  @override
  String get activate => 'Activate';

  @override
  String get days => 'Days';

  @override
  String daysLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsSectionCommunity => 'Community';

  @override
  String get settingsExploreDirectory => 'Explore directory';

  @override
  String get settingsExploreDirectorySubtitle =>
      'Discover public profiles of other users';

  @override
  String get settingsFollowers => 'Followers';

  @override
  String get settingsFollowersSubtitle => 'Manage your followers and following';

  @override
  String get settingsSectionAppearance => 'Appearance';

  @override
  String get settingsThemeLabel => 'Theme';

  @override
  String get settingsSectionLanguage => 'Language';

  @override
  String get settingsSectionGeneral => 'General';

  @override
  String get settingsAchievements => 'Achievements';

  @override
  String get settingsAchievementsSubtitle => 'Your unlocked achievements';

  @override
  String get settingsSectionInfo => 'Information';

  @override
  String get settingsAbout => 'About HabitAI';

  @override
  String get settingsAboutSubtitle => 'Version 1.0.0 — Final Project';

  @override
  String get settingsPrivacy => 'Privacy';

  @override
  String get settingsPrivacySubtitle => 'Challenges, profile and visibility';

  @override
  String get settingsRateApp => 'Rate HabitAI';

  @override
  String get settingsRateAppSubtitle => 'Enjoying the app? Leave us a review';

  @override
  String get settingsSectionLegal => 'Legal';

  @override
  String get settingsPrivacyPolicy => 'Privacy policy';

  @override
  String get settingsPrivacyPolicySubtitle => 'How we handle your data';

  @override
  String get settingsTerms => 'Terms of use';

  @override
  String get settingsTermsSubtitle => 'Service conditions';

  @override
  String get settingsSectionStreakProtection => 'Streak protection';

  @override
  String get settingsSignOut => 'Sign out';

  @override
  String get settingsSignOutConfirmTitle => 'Sign out';

  @override
  String get settingsSignOutConfirmContent =>
      'Are you sure you want to sign out?';

  @override
  String get settingsDeleteAccount => 'Delete account';

  @override
  String get settingsDeleteAccountSubtitle => 'All your data will be deleted';

  @override
  String get settingsDeleteAccountConfirmContent =>
      'All your data will be permanently deleted: habits, streaks, achievements, AI conversations, followers and your profile.\n\nThis action cannot be undone.';

  @override
  String get settingsDeleteConfirmTitle => 'Confirm deletion';

  @override
  String get settingsDeleteConfirmPrompt => 'Type ELIMINAR to confirm:';

  @override
  String get settingsEditNameTitle => 'Change name';

  @override
  String get settingsEditNameHint => 'Your name';

  @override
  String get settingsNameUpdated => 'Name updated';

  @override
  String get settingsNameUpdateError => 'Could not update name';

  @override
  String get settingsDeleteRequiresRelogin =>
      'For security reasons, sign out, sign back in and try again';

  @override
  String settingsDeleteAccountError(String error) {
    return 'Error deleting account: $error';
  }

  @override
  String get settingsFallbackUsername => 'User';

  @override
  String get settingsNotifications => 'Notifications';

  @override
  String get settingsNotificationsEnabled => 'You will receive habit reminders';

  @override
  String get settingsNotificationsDisabled => 'Reminders disabled';

  @override
  String get settingsNotificationsSystemPrompt =>
      'Enable notifications in system settings';

  @override
  String get settingsSickMode => 'Sick mode';

  @override
  String get settingsSickModeSubtitle =>
      'Protect all streaks without spending shields';

  @override
  String settingsSickModeActive(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days',
      one: '1 day',
    );
    return 'Active — ends in $_temp0';
  }

  @override
  String get settingsSickModeDialogTitle => 'Sick mode';

  @override
  String get settingsSickModeDialogContent =>
      'Your streaks will be protected during this period. Maximum 7 days.';

  @override
  String get settingsShieldsTile => 'Streak shields';

  @override
  String settingsShieldsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count available of 5',
      one: '$count available of 5',
    );
    return '$_temp0';
  }

  @override
  String get settingsShieldsTooltip =>
      'Earn shields by completing 7, 30 and 90 day streaks.\nUse them in HabitAI to protect your streak if you miss a day.';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeAuto => 'Auto';

  @override
  String get languageSelectorLabel => 'Language';

  @override
  String get languageEs => 'Español';

  @override
  String get languageEn => 'English';

  @override
  String get authLoginTitle => 'Sign in';

  @override
  String get authRegisterTitle => 'Create account';

  @override
  String get authTagline => 'Your habits, powered by AI';

  @override
  String get authRegisterTagline => 'Start building better habits';

  @override
  String get authEmail => 'Email';

  @override
  String get authEmailHint => 'Enter your email';

  @override
  String get authEmailInvalid => 'Enter a valid email';

  @override
  String get authPassword => 'Password';

  @override
  String get authPasswordHint => 'Enter your password';

  @override
  String get authPasswordMin => 'At least 6 characters';

  @override
  String get authPasswordConfirm => 'Confirm password';

  @override
  String get authPasswordMismatch => 'Passwords don\'t match';

  @override
  String get authName => 'Name';

  @override
  String get authNameHint => 'Your real name';

  @override
  String get authNameRequired => 'Enter your name';

  @override
  String get authUsername => 'Username';

  @override
  String get authUsernameHint => 'yourname';

  @override
  String get authUsernameAvailable => 'Available!';

  @override
  String get authUsernameTaken => 'Already taken, try another';

  @override
  String get authUsernameHelp =>
      'Identifies you in challenges and friends • 3-20 characters';

  @override
  String get authUsernameRequired => 'Choose a username';

  @override
  String get authUsernameFormat =>
      'Lowercase letters, numbers and _ only (3-20 characters)';

  @override
  String get authUsernameCheckFirst => 'Check username availability first';

  @override
  String get authUsernameRequiredFull =>
      'Choose a valid and available username';

  @override
  String get authOrSeparator => 'or';

  @override
  String get authContinueWithGoogle => 'Continue with Google';

  @override
  String get authContinueWithApple => 'Continue with Apple';

  @override
  String get authSignIn => 'Sign in';

  @override
  String get authNoAccount => 'Don\'t have an account? ';

  @override
  String get authRegisterLink => 'Sign up';

  @override
  String get authHaveAccount => 'Already have an account? ';

  @override
  String get authSignInLink => 'Sign in';

  @override
  String get authPrivacyPrefix => 'By creating your account you agree to the ';

  @override
  String get authPrivacyPolicy => 'Privacy Policy';

  @override
  String get authPrivacyMiddle => ' and ';

  @override
  String get authTermsOfUse => 'Terms of Use';

  @override
  String get navHabits => 'Habits';

  @override
  String get navProgress => 'Progress';

  @override
  String get navAssistant => 'Assistant';

  @override
  String get navExplore => 'Explore';

  @override
  String get navProfile => 'Profile';

  @override
  String get navNewFollowRequest => 'New follow request';

  @override
  String navFollowRequestBody(String username) {
    return '@$username wants to follow you';
  }

  @override
  String get navFollowAccepted => 'Request accepted!';

  @override
  String navFollowAcceptedBody(String username) {
    return '@$username accepted your request';
  }

  @override
  String get drawerProgress => 'Your progress';

  @override
  String get drawerAchievements => 'Achievements';

  @override
  String get drawerAchievementsSubtitle => 'What you\'ve unlocked';

  @override
  String get drawerLevels => 'Levels';

  @override
  String get drawerLevelsSubtitle => 'Your progress by category';

  @override
  String get drawerAllHabits => 'All my habits';

  @override
  String get drawerAllHabitsSubtitle => 'Active and archived';

  @override
  String get drawerWeeklyReview => 'Weekly review';

  @override
  String get drawerWeeklyReviewSubtitle => 'AI analysis';

  @override
  String get drawerButterfly => 'Butterfly Effect';

  @override
  String get drawerButterflySubtitle => '3-year projection';

  @override
  String get drawerQuickActions => 'Quick actions';

  @override
  String get drawerCreateHabit => 'Create habit';

  @override
  String get drawerCreateHabitSubtitle => 'Manual, no AI';

  @override
  String get drawerChatAI => 'Chat with AI';

  @override
  String get drawerChatAISubtitle => 'Generate a new plan';

  @override
  String get drawerPreferences => 'Preferences';

  @override
  String get drawerSettings => 'Settings';

  @override
  String get drawerSettingsSubtitle => 'Theme, notifications, account';

  @override
  String get drawerMenu => 'Menu';

  @override
  String get drawerNoWeeklyReview => 'No weekly review yet';

  @override
  String get drawerNoButterfly => 'No monthly projection yet';

  @override
  String get drawerHabitCreated => 'Habit created';

  @override
  String get drawerHabitCreateError => 'Error creating habit';

  @override
  String drawerShields(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count shields',
      one: '$count shield',
    );
    return '$_temp0';
  }

  @override
  String get drawerStreakFreeze => 'Freeze streaks if you miss';

  @override
  String get drawerSickMode => 'Sick mode';

  @override
  String get dashboardTitle => 'Progress';

  @override
  String dashboardGreeting(String name) {
    return 'Hello, $name';
  }

  @override
  String get dashboardWeekProgress => 'Your progress this week';

  @override
  String get dashboardWeeklyReviewNeedMore =>
      'You need at least 3 check-ins this week to generate the review';

  @override
  String get dashboardButterflyNeedMore =>
      'You need at least 10 check-ins this month to generate the projection';

  @override
  String get dashboardPatternsNeedMore =>
      'You need at least 14 days of data and 3 active habits to detect patterns';

  @override
  String get dashboardSmartAdjust => 'Smart adjust';

  @override
  String get dashboardInsightsTitle => 'AI Insights';

  @override
  String get dashboardInsightsChipAdjust => 'Adjustments';

  @override
  String get dashboardInsightsChipWeekly => 'Weekly';

  @override
  String get dashboardInsightsChipButterfly => 'Butterfly';

  @override
  String get dashboardInsightsChipPatterns => 'Patterns';

  @override
  String get dashboardAIPersonalized => 'AI · Personalized';

  @override
  String get dashboardAdjustDescription =>
      'Any habit not taking off? AI analyzes your patterns and suggests concrete changes.';

  @override
  String get dashboardAnalyzing => 'Analyzing…';

  @override
  String get dashboardRequestAdjust => 'Request adjust';

  @override
  String get dashboardSuggestedAdjusts => 'Suggested adjustments';

  @override
  String get dashboardSelectHabit => 'Select a habit';

  @override
  String get dashboardNoActiveHabits => 'No active habits';

  @override
  String dashboardStreakDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days',
      one: '1 day',
    );
    return 'Streak: $_temp0';
  }

  @override
  String get dashboardAdjustGenerated =>
      'Suggestion generated. Check it above.';

  @override
  String get dashboardAdjustNotNeeded =>
      'This habit doesn\'t need adjusting yet — it fails less than 3 days in a row.';

  @override
  String get dashboardAdjustPending =>
      'There\'s already a pending suggestion for this habit.';

  @override
  String dashboardAdjustError(String reason) {
    return 'Could not generate the adjust ($reason).';
  }

  @override
  String get dashboardPatternsTitle => 'AI Patterns';

  @override
  String get dashboardPatternsSubtitle =>
      'Discover hidden correlations between your habits';

  @override
  String get dashboardDetectPatterns => 'Detect patterns';

  @override
  String get dashboardGenerating => 'Generating…';

  @override
  String get dashboardButterflyTitle => 'Butterfly Effect';

  @override
  String get dashboardButterflySubtitle =>
      'Discover who you\'ll be in 3 years if you keep your habits';

  @override
  String get dashboardGenerateProjection => 'Generate projection';

  @override
  String get dashboardWeeklyReviewTitle => 'Weekly review';

  @override
  String get dashboardWeeklyReviewSubtitle =>
      'Ask AI to analyze your week: streaks, wins and areas to improve';

  @override
  String get dashboardGenerateNow => 'Generate now';

  @override
  String get dashboardRegenerate => 'Regenerate';

  @override
  String get dashboardRegenerating => 'Regenerating…';

  @override
  String get dashboardNoData => 'No data yet';

  @override
  String get dashboardNoDataSubtitle =>
      'Create habits and complete check-ins to see your stats here';

  @override
  String get dashboardCreateFirstHabit => 'Create first habit';

  @override
  String get dashboardPerfectDay => 'Perfect day!';

  @override
  String get dashboardToday => 'Today';

  @override
  String get dashboardNoHabitsToday => 'No habits scheduled for today';

  @override
  String get dashboardBestStreak => 'Best streak';

  @override
  String get dashboardCompleted => 'Completed';

  @override
  String get dashboardPerfectDays => 'Perfect days';

  @override
  String get dashboardLastWeek => 'Last week';

  @override
  String get dashboardByCategory => 'By category';

  @override
  String get dashboardActiveStreaks => 'Active streaks';

  @override
  String get dashboardAchievements => 'Achievements';

  @override
  String get dashboardUnlockAchievements =>
      'Complete habits to unlock achievements';

  @override
  String get dashboardMasteryProfile => 'Mastery Profile';

  @override
  String get dashboardStartMastery =>
      'Complete habits to unlock your mastery profile.';

  @override
  String get habitsTitle => 'My habits';

  @override
  String habitsGreeting(String name) {
    return 'Hello, $name';
  }

  @override
  String habitsDateFormat(String day, String date) {
    return '$day, $date';
  }

  @override
  String get habitsSelectHabits => 'Select habits';

  @override
  String habitsSelected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count selected',
      one: '1 selected',
    );
    return '$_temp0';
  }

  @override
  String get habitsMoveToGroup => 'Move to group';

  @override
  String get habitsDeleteSelected => 'Delete selected';

  @override
  String habitsDeleteTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Delete $count habits',
      one: 'Delete 1 habit',
    );
    return '$_temp0';
  }

  @override
  String get habitsDeleteSubtitle =>
      'They will be deactivated but history will be preserved.';

  @override
  String habitsDeleted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count habits deleted',
      one: '1 habit deleted',
    );
    return '$_temp0';
  }

  @override
  String get habitsDeleteError => 'Error deleting habits';

  @override
  String get habitsDeleteSingleTitle => 'Delete habit';

  @override
  String habitsDeleteSingleContent(String title) {
    return 'Are you sure you want to delete \"$title\"?\n\nIt will be deactivated but history will be preserved.';
  }

  @override
  String habitsDeleteSingleSuccess(String title) {
    return '\"$title\" deleted';
  }

  @override
  String get habitsDeleteSingleError => 'Error deleting habit';

  @override
  String get habitsUpdated => 'Habit updated';

  @override
  String get habitsUpdateError => 'Error updating habit';

  @override
  String get habitsAdjusted => 'Habit adjusted ✓';

  @override
  String get habitsNoGroup => 'No group';

  @override
  String habitsMoved(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count habits moved',
      one: '1 habit moved',
    );
    return '$_temp0';
  }

  @override
  String get habitsMoveError => 'Error moving habits';

  @override
  String get habitsGroupCreateError => 'Error creating routine';

  @override
  String habitsDeleteGroupTitle(String title) {
    return 'Delete \"$title\"';
  }

  @override
  String get habitsDeleteGroupContent =>
      'What do you want to do with this routine\'s habits?';

  @override
  String get habitsDeleteGroupOnly => 'Routine only';

  @override
  String get habitsDeleteGroupAndHabits => 'Routine and habits';

  @override
  String habitsGroupDeleted(String title) {
    return 'Routine \"$title\" deleted';
  }

  @override
  String get habitsGroupDeleteError => 'Error deleting routine';

  @override
  String get habitsDragToReorder => 'Drag to reorder';

  @override
  String get habitsDone => 'Done';

  @override
  String get habitsCreate => 'Create';

  @override
  String get habitsChainLabel => 'CHAIN';

  @override
  String habitsTotalCount(int count) {
    return '·  $count habits';
  }

  @override
  String get habitsProgressToday => 'Today\'s progress';

  @override
  String get habitsAllDone => 'All done!';

  @override
  String get habitsCompletedTodaySection => 'Completed today';

  @override
  String habitsCompletedOf(int completed, int total) {
    return '$completed of $total habits completed';
  }

  @override
  String get habitsEditGroup => 'Edit group';

  @override
  String get habitsTapToAdd => 'Tap to add habits';

  @override
  String get habitsLoadError =>
      'Could not load your habits. Check your connection.';

  @override
  String get habitsFirstChain => 'First chain created!';

  @override
  String get habitsAtomicTitle => 'How the atomic habit works';

  @override
  String get habitsAtomicStep1 => 'Complete the anchor habit';

  @override
  String get habitsAtomicStep1Desc =>
      'The first habit in the chain is highlighted when you finish it.';

  @override
  String get habitsAtomicStep2 => 'The next one lights up';

  @override
  String get habitsAtomicStep2Desc =>
      'You\'ll see \"After X\" on the chained habit. That\'s your cue.';

  @override
  String get habitsAtomicStep3 => 'Complete the whole chain';

  @override
  String get habitsAtomicStep3Desc =>
      'When you finish all of them you get a special celebration 🔥';

  @override
  String get habitsAtomicGotIt => 'Got it!';

  @override
  String get habitsXpBonus => '+5 XP · Atomic habit';

  @override
  String get habitDetailDescription => 'Description';

  @override
  String get habitDetailDays => 'days';

  @override
  String get habitDetailCurrentStreak => 'Current streak';

  @override
  String get habitDetailBestStreak => 'Best streak';

  @override
  String get habitDetailCompletedToday => 'Completed today';

  @override
  String get habitDetailShieldedToday => 'Streak protected today';

  @override
  String get habitDetailMarkComplete => 'Mark as completed';

  @override
  String habitDetailUseShield(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count available',
      one: '1 available',
    );
    return 'Use shield ($_temp0)';
  }

  @override
  String get habitDetailShieldTitle => 'Use streak shield';

  @override
  String habitDetailShieldContent(String title, int count) {
    return 'You\'ll spend 1 shield to protect \"$title\"\'s streak today.\n\nYou have $count shields left.';
  }

  @override
  String get habitDetailUseShieldButton => 'Use shield';

  @override
  String get habitDetailShieldUsed => '🛡️ Shield used — streak protected';

  @override
  String get habitDetailNoShields => 'No shields available';

  @override
  String get habitDetailDeleteTitle => 'Delete habit';

  @override
  String habitDetailDeleteContent(String title) {
    return 'Are you sure you want to delete \"$title\"?\n\nIt will be deactivated and won\'t appear in your list, but history will be preserved.';
  }

  @override
  String get habitDetailDelete => 'Delete';

  @override
  String get habitDetailAISuggestion => 'AI suggestion';

  @override
  String get habitDetailApplyAdjust => 'Apply adjustment';

  @override
  String get habitDetailLater => 'Not now';

  @override
  String get habitDetailNotFound => 'Habit not found or was deleted.';

  @override
  String get habitDetailLogCompleted => 'Completed';

  @override
  String get habitDetailLogShield => 'Shield';

  @override
  String get habitDetailLogSick => 'Sick';

  @override
  String get habitDetailLogSickMode => 'Sick mode';

  @override
  String get habitDetailLogMissed => 'Missed';

  @override
  String get habitDetailFilterAll => 'All';

  @override
  String get habitDetailFilterDaily => 'Daily';

  @override
  String get aiTitle => 'AI Assistant';

  @override
  String get aiSubtitle => 'Powered by Gemini';

  @override
  String get aiWelcome =>
      'Hi! I\'m your habit assistant. Tell me your goals and I\'ll create a personalized plan for you.';

  @override
  String get aiOfflineError => 'AI assistant needs an internet connection';

  @override
  String get aiConnectionError =>
      'Could not connect to the assistant. Check your connection.';

  @override
  String aiHabitsAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count habits added',
      one: '1 habit added',
    );
    return '$_temp0';
  }

  @override
  String get aiSaveError => 'Error saving habits';

  @override
  String get aiGeminiLabel => 'Gemini';

  @override
  String get aiInputHint => 'Write your goals...';

  @override
  String get aiThinking => 'Thinking...';

  @override
  String get aiExploreTemplates => 'No ideas? Explore community templates';

  @override
  String get aiSuggestion1 => 'I want to exercise and eat better';

  @override
  String get aiSuggestion2 => 'I need to be more productive';

  @override
  String get aiSuggestion3 => 'I want to read more and sleep better';

  @override
  String get aiSuggestion4 => 'Improve my mental health';

  @override
  String get createHabitVisibilityLabel => 'Visibility';

  @override
  String get challengeVisibilityToggleTitle => 'Public challenge';

  @override
  String get challengeVisibilityToggleSubtitle =>
      'Visible on your public profile';

  @override
  String get challengesSectionTitle => 'Challenges';

  @override
  String get challengeAnonymousPartner => 'Partner';

  @override
  String get aiPausedBanner =>
      'AI temporarily paused — the rest of the app works normally.';

  @override
  String get aiPausedMessage =>
      'The AI assistant is temporarily paused. The rest of the app works normally.';

  @override
  String get categorySalud => 'Health';

  @override
  String get categoryProductividad => 'Productivity';

  @override
  String get categoryBienestar => 'Wellbeing';

  @override
  String get categorySocial => 'Social';

  @override
  String get categoryAprendizaje => 'Learning';

  @override
  String get categoryFinanzas => 'Finance';

  @override
  String get achievementsTitle => 'Achievements';

  @override
  String get achievementUnlockedBanner => 'Achievement unlocked!';

  @override
  String achievementsUnlocked(int count) {
    return '$count achievements unlocked';
  }

  @override
  String get levelsTitle => 'Mastery Profile';

  @override
  String get levelsMedium => 'Medium level';

  @override
  String levelsTotalXp(int xp) {
    return '$xp XP total';
  }

  @override
  String get levelsStronger => 'Stronger';

  @override
  String get levelsByCategory => 'By category';

  @override
  String get levelsRadar => 'Skills radar';

  @override
  String get levelsEmpty => 'Start creating habits';

  @override
  String get levelsEmptySubtitle =>
      'Complete check-ins to level up in each category.';

  @override
  String levelNvl(int n) {
    return 'Lvl $n';
  }

  @override
  String get levelNvlShort => 'Lvl';

  @override
  String get levelMaxShort => 'Max.';

  @override
  String get levelXpAccum => 'Accumulated XP';

  @override
  String get levelHowToEarnXp => 'How to earn XP';

  @override
  String get levelXpTipCheckin => '+10 XP for each completed check-in';

  @override
  String get levelXpTipStreak => '+5 XP per active streak day (max. +50)';

  @override
  String get levelXpTipAchievement => '+50 XP for each unlocked achievement';

  @override
  String levelXpToNext(int xp, String title) {
    return '$xp XP until $title';
  }

  @override
  String get levelMaxReached => 'Maximum level reached!';

  @override
  String get levelSalud1 => 'Novice';

  @override
  String get levelSalud2 => 'Athlete';

  @override
  String get levelSalud3 => 'Warrior';

  @override
  String get levelSalud4 => 'Champion';

  @override
  String get levelSalud5 => 'Titan';

  @override
  String get levelProductividad1 => 'Apprentice';

  @override
  String get levelProductividad2 => 'Organized';

  @override
  String get levelProductividad3 => 'Strategist';

  @override
  String get levelProductividad4 => 'Executor';

  @override
  String get levelProductividad5 => 'Master';

  @override
  String get levelBienestar1 => 'Restless';

  @override
  String get levelBienestar2 => 'Serene';

  @override
  String get levelBienestar3 => 'Balanced';

  @override
  String get levelBienestar4 => 'Zen';

  @override
  String get levelBienestar5 => 'Enlightened';

  @override
  String get levelSocial1 => 'Shy';

  @override
  String get levelSocial2 => 'Friendly';

  @override
  String get levelSocial3 => 'Connector';

  @override
  String get levelSocial4 => 'Leader';

  @override
  String get levelSocial5 => 'Ambassador';

  @override
  String get levelAprendizaje1 => 'Curious';

  @override
  String get levelAprendizaje2 => 'Student';

  @override
  String get levelAprendizaje3 => 'Scholar';

  @override
  String get levelAprendizaje4 => 'Wise';

  @override
  String get levelAprendizaje5 => 'Master';

  @override
  String get levelFinanzas1 => 'Saver';

  @override
  String get levelFinanzas2 => 'Prudent';

  @override
  String get levelFinanzas3 => 'Investor';

  @override
  String get levelFinanzas4 => 'Magnate';

  @override
  String get levelFinanzas5 => 'Patron';

  @override
  String get profileTitle => 'Profile';

  @override
  String get profileNoHabits => 'No active habits';

  @override
  String get profileMastery => 'Mastery';

  @override
  String get profileEditButton => 'Edit profile';

  @override
  String get profileOpenSettings => 'Settings';

  @override
  String get editProfileTitle => 'Edit profile';

  @override
  String get editProfileSave => 'Save';

  @override
  String get editProfileNameLabel => 'Name';

  @override
  String get editProfileBioLabel => 'Bio';

  @override
  String get editProfileBioHint => 'Tell the world about your habits…';

  @override
  String get editProfileChangePhoto => 'Change photo';

  @override
  String get editProfileUsernameLabel => 'Username';

  @override
  String get editProfileChooseUsername => 'Choose a username';

  @override
  String get editProfileUsernameHint => 'Saved instantly, no need to tap Save.';

  @override
  String get editProfileUsernameUpdated => 'Username updated';

  @override
  String get editProfileSaved => 'Profile updated';

  @override
  String get editProfileSaveError => 'Couldn\'t save profile';

  @override
  String get commonSaveError => 'Couldn\'t save the change';

  @override
  String get profileActiveHabits => 'Active habits';

  @override
  String get profileEdit => 'Edit';

  @override
  String get profileStreak => 'Streak';

  @override
  String get profileHabits => 'Habits';

  @override
  String get profileBestStreak => 'Best streak';

  @override
  String get profileLevel => 'Level';

  @override
  String get profileFollowers => 'followers';

  @override
  String get profileFollowing => 'following';

  @override
  String profileBestStreakShort(int days) {
    return 'max ${days}d';
  }

  @override
  String get exploreTitle => 'HabitAI';

  @override
  String get exploreSubtitle => 'Discover habits\nand creators';

  @override
  String get exploreSearchHint => 'Search people, templates…';

  @override
  String get exploreChallenges => 'Challenges';

  @override
  String get exploreSeeAll => 'See all';

  @override
  String get exploreSeeAllAlt => 'See all';

  @override
  String get exploreCreateChallenge => 'Create your first challenge';

  @override
  String get exploreChallengeSubtitle => 'Challenge a friend to a shared habit';

  @override
  String get exploreFeaturedTemplates => 'Featured templates';

  @override
  String get exploreNoTemplates => 'No templates published yet';

  @override
  String get exploreFeaturedCreators => 'Featured creators';

  @override
  String get exploreNoProfiles => 'No public profiles yet';

  @override
  String get explorePeople => 'People';

  @override
  String get exploreTemplates => 'Templates';

  @override
  String get exploreNoResults => 'No results';

  @override
  String get exploreNoResultsHint => 'Try a different search term.';

  @override
  String get explorePending => 'Pending acceptance';

  @override
  String get exploreFollowing => 'Following';

  @override
  String get exploreFollow => 'Follow';

  @override
  String get exploreRequest => 'Request';

  @override
  String get exploreRequested => 'Requested';

  @override
  String get exploreImport => 'Import';

  @override
  String exploreChallengeDays(int days) {
    return '$days days';
  }

  @override
  String exploreHabitCount(int count) {
    return '$count habits';
  }

  @override
  String exploreHabitCountShort(int count) {
    return '$count hab.';
  }

  @override
  String exploreByAuthor(String username) {
    return 'By @$username';
  }

  @override
  String get snackbarRetry => 'Retry';

  @override
  String get weekdayMonday => 'Monday';

  @override
  String get weekdayTuesday => 'Tuesday';

  @override
  String get weekdayWednesday => 'Wednesday';

  @override
  String get weekdayThursday => 'Thursday';

  @override
  String get weekdayFriday => 'Friday';

  @override
  String get weekdaySaturday => 'Saturday';

  @override
  String get weekdaySunday => 'Sunday';

  @override
  String get weekdayMonShort => 'Mon';

  @override
  String get weekdayTueShort => 'Tue';

  @override
  String get weekdayWedShort => 'Wed';

  @override
  String get weekdayThuShort => 'Thu';

  @override
  String get weekdayFriShort => 'Fri';

  @override
  String get weekdaySatShort => 'Sat';

  @override
  String get weekdaySunShort => 'Sun';

  @override
  String get weekdayTodayShort => 'Today';

  @override
  String get weekdayLShort => 'M';

  @override
  String get weekdayMShort => 'T';

  @override
  String get weekdayXShort => 'W';

  @override
  String get weekdayJShort => 'T';

  @override
  String get weekdayVShort => 'F';

  @override
  String get weekdaySShort => 'S';

  @override
  String get weekdayDShort => 'S';

  @override
  String get monthJan => 'jan';

  @override
  String get monthFeb => 'feb';

  @override
  String get monthMar => 'mar';

  @override
  String get monthApr => 'apr';

  @override
  String get monthMay => 'may';

  @override
  String get monthJun => 'jun';

  @override
  String get monthJul => 'jul';

  @override
  String get monthAug => 'aug';

  @override
  String get monthSep => 'sep';

  @override
  String get monthOct => 'oct';

  @override
  String get monthNov => 'nov';

  @override
  String get monthDec => 'dec';

  @override
  String get habitFieldTitle => 'Title';

  @override
  String get habitFieldDescription => 'Description';

  @override
  String get habitFieldOptional => 'Optional';

  @override
  String get habitFieldCategory => 'Category';

  @override
  String get habitFieldWeekdays => 'Days of the week';

  @override
  String get habitFieldReminder => 'Reminder';

  @override
  String get habitNoReminder => 'No reminder';

  @override
  String get createHabitTitle => 'New habit';

  @override
  String get createHabitTitleHint => 'E.g. Read 20 minutes';

  @override
  String get createHabitGroupLabel => 'Group';

  @override
  String get createHabitGroupHint => 'Group this habit with related ones';

  @override
  String get createHabitNoGroup => 'No group';

  @override
  String get createHabitChainLabel => 'Chain after...';

  @override
  String get createHabitChainHint =>
      'It will show as the next step when you complete the anchor habit';

  @override
  String get createHabitChainNone => 'None';

  @override
  String get createHabitCta => 'Create habit';

  @override
  String get editHabitTitle => 'Edit habit';

  @override
  String get editHabitTitleHint => 'E.g. Run 30 minutes';

  @override
  String get editHabitRoutineLabel => 'Routine';

  @override
  String get editHabitNoRoutine => 'No routine';

  @override
  String get editHabitChainLabel => 'Habit chain';

  @override
  String editHabitChainedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count chained habits',
      one: '1 chained habit',
    );
    return '$_temp0';
  }

  @override
  String get editHabitChainThis => '← this one';

  @override
  String get editHabitChainRemove => 'Remove from chain';

  @override
  String get editHabitNoChain =>
      'This habit isn\'t part of any chain. You can chain it when creating new habits.';

  @override
  String get editHabitSaveCta => 'Save changes';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonEdit => 'Edit';

  @override
  String habitCardAfter(String title) {
    return 'After \"$title\"';
  }

  @override
  String get habitCardNext => 'Next!';

  @override
  String get habitCardCoachLabel => '– HABIT SUGGESTION';

  @override
  String get habitCardCoachApply => 'YES, DO IT →';

  @override
  String get habitCardCoachDismiss => 'NO, DON\'T';

  @override
  String get renoInboxTitle => 'Get back on track';

  @override
  String renoInboxCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'The AI has $count suggestions for you',
      one: 'The AI has 1 suggestion for you',
    );
    return '$_temp0';
  }

  @override
  String get renoInboxSheetTitle => 'AI suggestions';

  @override
  String get renoUnavailable => 'That habit is no longer available';

  @override
  String get createChoiceHabitTitle => 'New habit';

  @override
  String get createChoiceHabitSubtitle => 'A single habit';

  @override
  String get createChoiceGroupTitle => 'New routine';

  @override
  String get createChoiceGroupSubtitle => 'Group of related habits';

  @override
  String get createGroupTitle => 'New routine';

  @override
  String get createGroupNameLabel => 'Routine name';

  @override
  String get createGroupNameHint => 'E.g. Morning routine';

  @override
  String get createGroupDescHint => 'Optional — what this routine is for';

  @override
  String get createGroupEmojiLabel => 'Emoji';

  @override
  String get createGroupEmojiHint => 'Paste an emoji or pick one below';

  @override
  String get createGroupCta => 'Create routine';

  @override
  String get emptyHabitsTitle => 'Start your journey!';

  @override
  String get emptyHabitsSubtitle =>
      'Tell the AI your goals and it will create\na personalized habit plan for you.';

  @override
  String get emptyHabitsAction => 'Create my AI plan';

  @override
  String get stackCompleteTitle => 'CHAIN COMPLETE!';

  @override
  String stackCompleteCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count habits in a row. Unstoppable!',
      one: '1 habit in a row. Unstoppable!',
    );
    return '$_temp0';
  }

  @override
  String get stackCompleteSubtitle => 'That\'s how an atomic habit is built.';

  @override
  String allHabitsTotal(int count) {
    return '$count total';
  }

  @override
  String get allHabitsCancelSelection => 'Cancel selection';

  @override
  String get allHabitsTabActive => 'Active';

  @override
  String get allHabitsTabArchived => 'Archived';

  @override
  String get allHabitsTabRoutines => 'Routines';

  @override
  String get allHabitsEmptyActiveTitle => 'You have no habits yet';

  @override
  String get allHabitsEmptyActiveSubtitle =>
      'Create habits from the main screen or with the AI.';

  @override
  String get allHabitsEmptyArchivedTitle => 'You have no archived habits';

  @override
  String get allHabitsEmptyRoutinesTitle => 'You have no routines yet';

  @override
  String get allHabitsEmptyRoutinesSubtitle =>
      'Create a routine from the \"+\" on the main screen.';

  @override
  String get allHabitsNoHabitsYet => 'No habits yet';

  @override
  String get allHabitsHardDeleteTitle => 'Delete permanently';

  @override
  String allHabitsHardDeleteContent(String title) {
    return 'Are you sure you want to delete \"$title\" forever?\n\nThis deletes the habit and all its records. It cannot be undone.';
  }

  @override
  String get allHabitsHardDeleteConfirm => 'Delete forever';

  @override
  String allHabitsHardDeleted(String title) {
    return '\"$title\" deleted permanently';
  }

  @override
  String get allHabitsHardDeleteError => 'Error deleting the habit';

  @override
  String allHabitsBulkDeleteTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Delete $count habits',
      one: 'Delete 1 habit',
    );
    return '$_temp0';
  }

  @override
  String get allHabitsBulkDeleteContent =>
      'They will be deleted permanently with all their records. It cannot be undone.';

  @override
  String get allHabitsDeleteButton => 'Delete';

  @override
  String allHabitsBulkDeleted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count habits deleted',
      one: '1 habit deleted',
    );
    return '$_temp0';
  }

  @override
  String get allHabitsBulkDeleteError => 'Error deleting the habits';

  @override
  String allHabitsBulkDeleteGroupsTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Delete $count routines',
      one: 'Delete 1 routine',
    );
    return '$_temp0';
  }

  @override
  String get allHabitsBulkDeleteGroupsContent =>
      'What do you want to do with the habits in the selected routines?';

  @override
  String get allHabitsBulkDeleteGroupsOnly => 'Routines only';

  @override
  String get allHabitsBulkDeleteGroupsAndHabits => 'Routines and habits';

  @override
  String allHabitsGroupsDeleted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count routines deleted',
      one: '1 routine deleted',
    );
    return '$_temp0';
  }

  @override
  String get allHabitsGroupsDeleteError => 'Error deleting the routines';

  @override
  String get groupDetailEditTitle => 'Edit group';

  @override
  String get groupDetailAddHabitError => 'Error adding the habit';

  @override
  String get groupDetailHabitAdded => 'Habit added to the routine';

  @override
  String get groupDetailGroupUpdated => 'Group updated';

  @override
  String get groupDetailGroupUpdateError => 'Error updating the group';

  @override
  String get groupDetailPublishNoHabits =>
      'The group has no habits, add at least one.';

  @override
  String get groupDetailPublishNeedPublic =>
      'Enable your public profile in Settings before publishing.';

  @override
  String get groupDetailPublishNeedPublicTitle => 'You need a public profile';

  @override
  String get groupDetailPublishNeedPublicBody =>
      'To share a template with the community you need a public profile with a username. Create yours now?';

  @override
  String get groupDetailPublishCreateProfileCta => 'Create public profile';

  @override
  String get groupDetailPublishReactivateBody =>
      'Your public profile is disabled. Reactivate it to share this template under your username.';

  @override
  String get groupDetailPublishReactivateCta => 'Reactivate profile';

  @override
  String get groupDetailPublishTitle => 'Publish as template';

  @override
  String groupDetailPublishBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count habits will be published without personal data (no streaks or history).',
      one:
          '1 habit will be published without personal data (no streaks or history).',
    );
    return '$_temp0';
  }

  @override
  String get groupDetailPublishDescLabel => 'Description (optional)';

  @override
  String get groupDetailPublishDescHint => 'Explain who this plan is for…';

  @override
  String get groupDetailPublishConfirm => 'Publish';

  @override
  String get groupDetailPublishSuccess => 'Template published to the community';

  @override
  String get groupDetailViewAction => 'View';

  @override
  String get groupDetailPublishError => 'Error publishing the template';

  @override
  String get groupDetailUnpublishTitle => 'Withdraw template';

  @override
  String get groupDetailUnpublishContent =>
      'The template will disappear from the marketplace. Copies imported by other users won\'t be affected.';

  @override
  String get groupDetailUnpublishConfirm => 'Withdraw';

  @override
  String get groupDetailUnpublishSuccess =>
      'Template withdrawn from the marketplace';

  @override
  String get groupDetailUnpublishError => 'Error withdrawing the template';

  @override
  String get groupDetailUnpublishTooltip => 'Withdraw from marketplace';

  @override
  String get groupDetailPublishTooltip => 'Publish as template';

  @override
  String get groupDetailNotFound => 'This group no longer exists.';

  @override
  String get groupDetailHabitsHeader => 'Group habits';

  @override
  String get groupDetailEmptyTitle => 'No habits in this group';

  @override
  String get groupDetailEmptySubtitle => 'Add habits with the + button';

  @override
  String get groupDetailEditNameLabel => 'Group title';

  @override
  String get groupDetailEditNameHint => 'E.g. Gym routine';

  @override
  String get groupDetailEditEmojiHint => 'Paste an emoji or leave it empty';

  @override
  String get commonApply => 'Apply';

  @override
  String get monthFullJan => 'January';

  @override
  String get monthFullFeb => 'February';

  @override
  String get monthFullMar => 'March';

  @override
  String get monthFullApr => 'April';

  @override
  String get monthFullMay => 'May';

  @override
  String get monthFullJun => 'June';

  @override
  String get monthFullJul => 'July';

  @override
  String get monthFullAug => 'August';

  @override
  String get monthFullSep => 'September';

  @override
  String get monthFullOct => 'October';

  @override
  String get monthFullNov => 'November';

  @override
  String get monthFullDec => 'December';

  @override
  String get butterflyNotFound =>
      'Projection not found or it may have expired.';

  @override
  String butterflyCheckins(int count) {
    return '$count check-ins';
  }

  @override
  String butterflyStreakDays(int count) {
    return '${count}d streak';
  }

  @override
  String butterflyCompletion(int percent) {
    return '$percent% completion';
  }

  @override
  String get butterflyKeyMoments => 'Key moments';

  @override
  String get patternInsightsNeedConnection =>
      'You need a connection to regenerate the patterns';

  @override
  String get patternInsightsNeedMore =>
      'You need at least 14 days of data and 3 active habits.';

  @override
  String get patternInsightsUpdated => 'Patterns updated.';

  @override
  String patternInsightsEmptyTitle(String period) {
    return 'No insights for $period';
  }

  @override
  String get patternInsightsEmptySubtitle =>
      'Generate the patterns from the dashboard or wait for the system to process them automatically.';

  @override
  String get patternInsightsRegenerate => 'Regenerate patterns';

  @override
  String get patternInsightsLimitedData => 'Limited data';

  @override
  String patternInsightsDetected(int count) {
    return '$count patterns detected';
  }

  @override
  String get patternInsightsConfidenceHigh => 'High confidence';

  @override
  String get patternInsightsConfidenceMedium => 'Medium';

  @override
  String get patternInsightsConfidenceLow => 'Low';

  @override
  String get weeklyReviewNotFound => 'This review was not found';

  @override
  String get weeklyReviewLoadError => 'Error loading the review';

  @override
  String get weeklyReviewHabitGone => 'This habit no longer exists';

  @override
  String get weeklyReviewWins => 'What worked';

  @override
  String get weeklyReviewStruggles => 'Where you struggled';

  @override
  String weeklyReviewWeekLabel(String weekId) {
    return 'Week $weekId';
  }

  @override
  String get weeklyReviewStatCheckins => 'Check-ins';

  @override
  String get weeklyReviewStatHabits => 'Habits';

  @override
  String get weeklyReviewStatAtRisk => 'At risk';

  @override
  String get weeklyReviewFocusTitle => 'Your focus this week';

  @override
  String get weeklyReviewRecommendations => 'Recommendations';

  @override
  String get planCardSaved => 'Habits saved';

  @override
  String get planCardAddSelected => 'Add selected habits';

  @override
  String get planCardFrequencyDaily => 'Daily';

  @override
  String get planCardFrequencyWeekly => 'Weekly';

  @override
  String get planCardFrequencyCustom => 'Custom';

  @override
  String get challengesTitle => 'My challenges';

  @override
  String get challengesNew => 'New challenge';

  @override
  String get challengesEmptyTitle => 'No challenges yet';

  @override
  String get challengesEmptySubtitle =>
      'Challenge a friend to complete a habit together for several days';

  @override
  String get challengesSectionPending => 'Pending';

  @override
  String get challengesSectionActive => 'Active';

  @override
  String get challengesSectionFinished => 'Finished';

  @override
  String get challengeCardWaiting => 'Waiting for acceptance...';

  @override
  String get challengeStatusPending => 'Pending';

  @override
  String get challengeStatusActive => 'Active';

  @override
  String get challengeStatusCompleted => 'Completed';

  @override
  String get challengeStatusDeclined => 'Declined';

  @override
  String get challengeStatusAbandoned => 'Abandoned';

  @override
  String get challengeDetailTitle => 'Shared challenge';

  @override
  String get challengeDetailNotFound => 'Challenge not found';

  @override
  String get challengeDetailAccepted =>
      'Challenge accepted! The habit was created in your list';

  @override
  String get challengeDetailAcceptError => 'Error accepting the challenge';

  @override
  String get challengeDetailDeclineTitle => 'Decline challenge';

  @override
  String get challengeDetailDeclineContent =>
      'Are you sure you want to decline this challenge?';

  @override
  String get challengeDetailDeclineConfirm => 'Decline';

  @override
  String get challengeDetailAbandonTitle => 'Abandon challenge';

  @override
  String get challengeDetailAbandonContent =>
      'Are you sure you want to abandon it? You won\'t be able to resume it.';

  @override
  String get challengeDetailAbandonConfirm => 'Abandon';

  @override
  String get challengeDetailAbandonTooltip => 'Abandon';

  @override
  String get challengeDetailYourProgress => 'Your progress';

  @override
  String get challengeDetailPartner => 'Partner';

  @override
  String get challengeDetailCompletedTitle => 'Challenge completed!';

  @override
  String get challengeDetailCompletedSubtitle => 'You both showed consistency';

  @override
  String get challengeDetailDeclinedState => 'Challenge declined';

  @override
  String get challengeDetailAbandonedState => 'Challenge abandoned';

  @override
  String challengeDetailWaitingPartner(String name) {
    return 'Waiting for $name to accept the challenge';
  }

  @override
  String get challengeDetailFallbackPartner => 'your partner';

  @override
  String get challengeDetailFallbackPartnerCap => 'Partner';

  @override
  String get challengeDetailFallbackSomeone => 'Someone';

  @override
  String challengeDetailYouChallenged(String name) {
    return 'You challenged $name';
  }

  @override
  String challengeDetailChallengedYou(String name) {
    return '$name has challenged you';
  }

  @override
  String get challengeDetailAcceptQuestion => 'Do you accept the challenge?';

  @override
  String get challengeDetailAcceptHint =>
      'The habit will be created automatically in your list and you\'ll start together';

  @override
  String get challengeDetailAcceptCta => 'Accept challenge';

  @override
  String get challengeDetailCompletedToday => 'Completed today!';

  @override
  String get challengeDetailMarkToday => 'Mark today as completed';

  @override
  String challengeDetailProgressDays(int completed, int total) {
    return '$completed / $total days';
  }

  @override
  String get createChallengeTitle => 'Create challenge';

  @override
  String createChallengeError(String error) {
    return 'Error creating challenge: $error';
  }

  @override
  String get createChallengeHabitName => 'Habit name';

  @override
  String get createChallengeHabitHint => 'E.g. Meditate 10 minutes';

  @override
  String get createChallengeDuration => 'Duration';

  @override
  String get createChallengePartnerLabel => 'Challenge partner';

  @override
  String get createChallengeSearchUsername => 'Search by username';

  @override
  String get createChallengeFollowerChip => 'Follower';

  @override
  String get createChallengeSend => 'Send challenge';

  @override
  String get communityTitle => 'Community';

  @override
  String get communitySearchHint => 'Search templates…';

  @override
  String get communitySortPopular => 'Popular';

  @override
  String get communitySortRecent => 'Recent';

  @override
  String get communityFilterAll => 'All';

  @override
  String get communityLoadMore => 'Load more';

  @override
  String get communityEndOfList => '— end of list —';

  @override
  String get communityEmptyTitle => 'No templates yet';

  @override
  String get communityEmptySubtitle => 'Be the first to publish a habit plan.';

  @override
  String get communityEmptyFilterTitle => 'No results for that filter';

  @override
  String get communityEmptyFilterSubtitle =>
      'Try another category or clear the filter.';

  @override
  String get communityDetailNotFound => 'Template not found';

  @override
  String get communityDetailLoadError => 'Error loading the template';

  @override
  String communityDetailImported(String emoji, String title) {
    return '$emoji \"$title\" imported to your habits';
  }

  @override
  String get communityDetailImportError => 'Error importing the template';

  @override
  String get communityDetailReportTitle => 'Report template';

  @override
  String get communityDetailReportContent =>
      'Do you want to report this template for inappropriate content? It will be reviewed by the team.';

  @override
  String get communityDetailReportConfirm => 'Report';

  @override
  String get communityDetailReportSent => 'Report sent, thanks';

  @override
  String communityDetailImports(int count) {
    return '$count imports';
  }

  @override
  String communityDetailByAuthor(String name) {
    return 'By $name';
  }

  @override
  String get communityDetailHabitsIncluded => 'Included habits';

  @override
  String get communityDetailMyTemplate => 'This is your template';

  @override
  String get communityDetailImporting => 'Importing…';

  @override
  String get communityDetailImportCta => 'Import to my habits';

  @override
  String streakDaysShort(int count) {
    return '${count}d';
  }

  @override
  String get categoryDetailTitle => 'Categories';

  @override
  String get categoryDetailDistribution => 'Distribution';

  @override
  String categoryDetailWeeklyPct(int percent) {
    return '$percent% weekly';
  }

  @override
  String get streaksDetailTitle => 'Streaks';

  @override
  String get streaksDetailBestGlobal => 'Best overall streak';

  @override
  String get streaksDetailOnStreak => 'On a streak';

  @override
  String get streaksDetailNoStreak => 'No streak';

  @override
  String streaksDetailBestShort(int count) {
    return 'best: ${count}d';
  }

  @override
  String get weeklyDetailTitle => 'Monthly progress';

  @override
  String get weeklyDetailDailyBreakdown => 'Daily breakdown';

  @override
  String get weeklyDetailAverage => 'Average';

  @override
  String get weeklyDetailLast30Days => 'Last 30 days';

  @override
  String get usernameSheetTitleNew => 'Choose your username';

  @override
  String get usernameSheetTitleChange => 'Change username';

  @override
  String get usernameSheetSubtitle =>
      'Your username is unique and public. It will appear on your profile and in challenges.';

  @override
  String get usernameSheetHelperIdle => 'Identifies you in the community';

  @override
  String get usernameSheetChecking => 'Checking...';

  @override
  String get usernameSheetVisibleData => 'Visible data on your profile:';

  @override
  String get usernameSheetDataName => 'Name and @username';

  @override
  String get usernameSheetDataStreaks => 'Current streaks';

  @override
  String get usernameSheetDataHabits => 'Active habits (title and category)';

  @override
  String get usernameSheetDataLevel => 'Level and achievements';

  @override
  String get usernameSheetPrivacy => 'Never shared: email, notes, reminders.';

  @override
  String get usernameSheetConfirm => 'Confirm';

  @override
  String get errorDefault => 'Something went wrong';

  @override
  String get habitDetailInfo => 'Information';

  @override
  String get habitDetailAIGenerated => 'AI Generated';

  @override
  String get habitDetailFrequency => 'Frequency';

  @override
  String get habitsOrderSaveError => 'Error saving order';

  @override
  String get habitsDeleteGroup => 'Delete group';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get notificationsClearActivity => 'Clear activity';

  @override
  String get notificationsActiveReminders => 'Active reminders';

  @override
  String notificationsAdjustSuggested(String habitTitle) {
    return 'Suggested adjustment: $habitTitle';
  }

  @override
  String get notificationsWeeklyReviewReady => 'Weekly review ready';

  @override
  String get notificationsMonthlyProjection => 'Monthly projection 🦋';

  @override
  String get notificationsChallengeReceived => 'You\'ve been challenged!';

  @override
  String get notificationsChallengeAccepted => 'Your challenge was accepted!';

  @override
  String notificationsReminderAt(String time) {
    return 'Reminder at $time';
  }

  @override
  String get notificationsYesterday => 'Yesterday';

  @override
  String notificationsDaysAgo(int days) {
    return '${days}d ago';
  }

  @override
  String notificationsWeeksAgo(int weeks) {
    return '${weeks}w ago';
  }

  @override
  String notificationsMonthsAgo(int months) {
    return '${months}mo ago';
  }

  @override
  String get notificationsEmpty => 'No notifications';

  @override
  String get notificationsEmptySubtitle =>
      'Your achievements, reminders and AI suggestions will appear here.';

  @override
  String get notificationsNoActivity => 'No recent activity';

  @override
  String get notificationsLoadError => 'Could not load notifications.';

  @override
  String get followersTabFollowers => 'Followers';

  @override
  String get followersTabFollowing => 'Following';

  @override
  String get followersTabRequests => 'Requests';

  @override
  String get followersMutual => 'Mutual';

  @override
  String get followersFollowsYou => 'Follows you';

  @override
  String get followersUnfollow => 'Unfollow';

  @override
  String get followersRemoveTitle => 'Remove follower';

  @override
  String followersRemoveContent(String username) {
    return 'Remove @$username from your followers?';
  }

  @override
  String followersUnfollowContent(String username) {
    return 'Unfollow @$username?';
  }

  @override
  String get followersRequestAlreadySent => 'Request already sent';

  @override
  String followersRequestSent(String username) {
    return 'Request sent to @$username';
  }

  @override
  String followersNowFollowing(String username) {
    return 'Now following @$username';
  }

  @override
  String get followersRemoved => 'Follower removed';

  @override
  String followersUnfollowed(String username) {
    return 'You unfollowed @$username';
  }

  @override
  String followersRequestsError(String error) {
    return 'Error loading requests: $error';
  }

  @override
  String get followersEmptyTitle => 'No followers yet';

  @override
  String get followersEmptySubtitle =>
      'Search users by @username to follow them or be followed';

  @override
  String get followingEmptyTitle => 'You\'re not following anyone';

  @override
  String get followingEmptySubtitle => 'Search users in the Followers tab';

  @override
  String get followersRequestsEmptyTitle => 'No pending requests';

  @override
  String get followersRequestsEmptySubtitle =>
      'Follow requests you receive will appear here';

  @override
  String get followersSearchHint => 'Search by @username';

  @override
  String get publicProfileNotAvailable => 'Profile not available';

  @override
  String publicProfileMemberSince(String month) {
    return 'Member since $month';
  }

  @override
  String get publicProfileMutualFollower => 'Mutual follower';

  @override
  String get publicProfilePrivate => 'This account is private';

  @override
  String get publicProfileRequestPending => 'Your request is pending approval.';

  @override
  String get publicProfileFollowToSee =>
      'Follow them to see their habits and stats.';

  @override
  String get publicProfileNoHabits => 'No visible habits';

  @override
  String get publicProfileMore => 'more';

  @override
  String get publicProfilesFeedTitle => 'Explore profiles';

  @override
  String get publicProfilesFeedSearchHint => 'Search by @username…';

  @override
  String get publicProfilesFeedEmptySubtitle =>
      'Enable your profile in Settings to appear here.';

  @override
  String get publicProfilesFeedNoResultsSubtitle => 'Try another @username';

  @override
  String get avatarPickerTitle => 'Profile photo';

  @override
  String get avatarPickerGallery => 'Choose from gallery';

  @override
  String get avatarPickerCamera => 'Take a photo';

  @override
  String get avatarPickerRemove => 'Remove photo';

  @override
  String get avatarPickerCropNote => 'Will be automatically cropped to center';

  @override
  String get avatarPickerUpdated => 'Profile photo updated';

  @override
  String get avatarPickerUploadError => 'Could not upload photo';

  @override
  String get avatarPickerRemoved => 'Photo removed';

  @override
  String get avatarPickerRemoveError => 'Could not remove photo';

  @override
  String get avatarPickerProcessing => 'Processing photo…';

  @override
  String publicProfileLevelShort(String level) {
    return 'Lv. $level';
  }

  @override
  String get publicProfileAverageLevel => 'Average level';

  @override
  String get privacySectionVisibility => 'Visibility';

  @override
  String get privacyPublicProfileTitle => 'Public profile';

  @override
  String get privacyPublicProfileDescOn =>
      'You appear in the directory, anyone can follow you';

  @override
  String get privacyPublicProfileDescOff => 'Only your followers can see you';

  @override
  String get privacyChangeUsername => 'Change username';

  @override
  String get privacyUsernameTaken => 'Username already taken';

  @override
  String get privacyUsernameHint => 'Choose a username so others can find you.';

  @override
  String get privacyDisableTitle => 'Disable public profile';

  @override
  String get privacyDisableContent =>
      'Your profile will disappear from the directory. Your current followers will still be able to see you until you remove them.';

  @override
  String get privacyDisableButton => 'Disable';

  @override
  String get privacyNoHabits => 'You have no active habits';

  @override
  String get privacyPublicViewLabel => 'What everyone sees';

  @override
  String get privacyFollowersViewLabel => 'What your followers see';

  @override
  String get privacyChallengesTitle => 'Who can send me challenges';

  @override
  String get privacyChallengesDesc =>
      'Control who can invite you to compete in a habit';

  @override
  String get privacyVisibleHabitsSection => 'Visible habits on your profile';

  @override
  String get privacyHabitsLabel => 'Active habits';

  @override
  String get privacyStatsLabel => 'Statistics';

  @override
  String get privacyFollowersLabel => 'Followers / Following';

  @override
  String get privacyOptionPublic => 'Public';

  @override
  String get privacyOptionFollowers => 'Followers';

  @override
  String get privacyOptionPrivate => 'Private';

  @override
  String get privacyLevelEveryone => 'Everyone';

  @override
  String get privacyLevelNobody => 'Nobody';

  @override
  String get privacySocialReactionsTitle => 'Reactions on achievements';

  @override
  String get privacySocialReactionsSubtitle =>
      'Let your followers react to your achievements with 🔥 💪 👏';

  @override
  String get achievementFirstHabitTitle => 'First step';

  @override
  String get achievementFirstHabitDesc => 'Create your first habit';

  @override
  String get achievementAiPlanTitle => 'Personal assistant';

  @override
  String get achievementAiPlanDesc => 'Generate a plan with AI';

  @override
  String get achievementPerfectDayTitle => 'Perfect day';

  @override
  String get achievementPerfectDayDesc => 'Complete all habits of the day';

  @override
  String get achievementStreak3Title => 'On the move';

  @override
  String get achievementStreak3Desc => 'Achieve a 3-day streak';

  @override
  String get achievementStreak7Title => 'Week of fire';

  @override
  String get achievementStreak7Desc => 'Achieve a 7-day streak';

  @override
  String get achievementStreak14Title => 'Unstoppable';

  @override
  String get achievementStreak14Desc => 'Achieve a 14-day streak';

  @override
  String get achievementStreak30Title => 'Legend';

  @override
  String get achievementStreak30Desc => 'Achieve a 30-day streak';

  @override
  String get achievementHabits5Title => 'Five in action';

  @override
  String get achievementHabits5Desc => 'Have 5 active habits';

  @override
  String get achievementTotal50Title => 'Half hundred';

  @override
  String get achievementTotal50Desc => 'Complete 50 check-ins in total';

  @override
  String get achievementTotal100Title => 'Centenary';

  @override
  String get achievementTotal100Desc => 'Complete 100 check-ins in total';

  @override
  String get achievementPerfectWeekTitle => 'Impeccable week';

  @override
  String get achievementPerfectWeekDesc =>
      '7 days in a row completing everything';

  @override
  String get achievementChallengeTitle => 'Challenge companions';

  @override
  String get achievementChallengeDesc => 'Complete a shared challenge';

  @override
  String get moodTitle => 'Mood';

  @override
  String get moodHowAreYou => 'How are you feeling?';

  @override
  String get moodSave => 'Save mood';

  @override
  String get moodNotePlaceholder => 'Add a note (optional)…';

  @override
  String get moodTimeBlockLabel => 'Time of day';

  @override
  String get moodTimeBlockMorning => 'Morning';

  @override
  String get moodTimeBlockMidday => 'Midday';

  @override
  String get moodTimeBlockAfternoon => 'Afternoon';

  @override
  String get moodTimeBlockNight => 'Night';

  @override
  String get moodHabitsToday => 'Habits completed today';

  @override
  String get moodEmptyState => 'No mood entries yet';

  @override
  String get moodEmptyStateCta => 'How are you feeling today?';

  @override
  String get moodWeekChart => 'Mood this week';

  @override
  String get moodLabelAnxiety => 'Anxiety';

  @override
  String get moodLabelTiredness => 'Tiredness';

  @override
  String get moodLabelMotivation => 'Motivation';

  @override
  String get moodLabelCalm => 'Calm';

  @override
  String get moodLabelStress => 'Stress';

  @override
  String get moodLabelSadness => 'Sadness';

  @override
  String get moodLabelEnergy => 'Energy';

  @override
  String get moodLabelAnger => 'Anger';

  @override
  String get moodLabelGratitude => 'Gratitude';

  @override
  String get moodLabelFocus => 'Focus';

  @override
  String get moodCalendarTitle => 'Mood calendar';

  @override
  String get moodCalendarLegend => 'Legend';

  @override
  String get moodDeleteEntry => 'Delete entry';

  @override
  String get moodNoEntriesDay => 'No entries for this day';

  @override
  String get drawerMoodCalendar => 'Mood';

  @override
  String get drawerMoodCalendarSubtitle => 'Your emotional calendar';

  @override
  String get moodCorrelationTitle => 'Mood & habits';

  @override
  String get moodCorrelationNotEnoughData =>
      'Log your mood for a few days to see how your habits affect it.';

  @override
  String get moodCorrelationDays7 => '7 days';

  @override
  String get moodCorrelationDays30 => '30 days';

  @override
  String get moodChartLegendHabits => '% habits';

  @override
  String get moodChartLegendMood => 'mood';

  @override
  String get moodInsightsTitle => 'Mood insights';

  @override
  String get moodInsightsAllCategories => 'All';

  @override
  String get moodCorrelationDaysCompleted => 'days completed';

  @override
  String get moodConfidenceLow => 'Low confidence';

  @override
  String get moodConfidenceMedium => 'Medium confidence';

  @override
  String get moodConfidenceHigh => 'High confidence';

  @override
  String moodStreakBoost(String diff) {
    return 'On 5+ day streaks: $diff';
  }

  @override
  String get moodInsightsDelayedHeader => 'Next-day effect';

  @override
  String moodDelayedBoost(String habitName, String diff) {
    return 'Doing $habitName today boosts tomorrow\'s mood by $diff';
  }

  @override
  String moodCorrelationBoost(String emoji, String diff, String habitName) {
    return 'Your mood $emoji rises $diff on days you do $habitName';
  }

  @override
  String moodCorrelationDrop(String habitName, String diff) {
    return 'On days without $habitName, your mood drops $diff';
  }

  @override
  String get moodInsightsPositiveHeader => 'Good for you';

  @override
  String get moodInsightsNegativeHeader => 'Don\'t skip these';

  @override
  String get weeklyReviewMoodInsights => 'Emotional analysis';

  @override
  String get moodBannerMorning => 'Good morning! How did you wake up?';

  @override
  String get moodBannerAfternoon => 'How\'s your afternoon going?';

  @override
  String get moodBannerNight => 'How was your day?';

  @override
  String get moodRating1 => 'Awful';

  @override
  String get moodRating2 => 'Not great';

  @override
  String get moodRating3 => 'Okay';

  @override
  String get moodRating4 => 'Good';

  @override
  String get moodRating5 => 'Amazing';

  @override
  String get moodLoggedToday => 'Logged';

  @override
  String moodStreakDays(int count) {
    return '$count day streak';
  }

  @override
  String get moodQuickSave => 'Quick save';

  @override
  String get moodTellMore => 'Want to add details?';

  @override
  String get moodSkip => 'Skip';

  @override
  String get moodNext => 'Next';

  @override
  String get moodAnythingOnMind => 'Anything on your mind?';

  @override
  String get moodSaveError => 'Couldn\'t save your mood. Try again.';

  @override
  String get moodDeleteError => 'Couldn\'t delete the entry';

  @override
  String get moodDeleteConfirm => 'Delete this mood entry?';

  @override
  String get moodLabelsPositive => 'Feeling good';

  @override
  String get moodLabelsNegative => 'Feeling tough';

  @override
  String get updateForceTitle => 'Update required';

  @override
  String get updateSoftTitle => 'New version available';

  @override
  String get updateNow => 'Update now';

  @override
  String get updateLater => 'Later';

  @override
  String get onbStart => 'Get started';

  @override
  String get onbSkip => 'Skip';

  @override
  String get onbTagline1 => 'Build habits that last';

  @override
  String get onbTagline2 => 'Your personal habit AI';

  @override
  String get onbTagline3 => 'Small steps, big changes';

  @override
  String get onbWelcomeIntro =>
      'Let\'s create your first habit plan in under 2 minutes.';

  @override
  String get onbCategoriesTitle => 'What do you want to improve?';

  @override
  String get onbCategoriesSubtitle =>
      'Pick one or more areas. The AI will design your plan around them.';

  @override
  String get onbLifestyleTitle => 'Tell us about your day';

  @override
  String get onbLifestyleSubtitle =>
      'Three quick questions to fit the plan to your real life.';

  @override
  String get onbQ1 => 'When do you have the most energy?';

  @override
  String get onbQ1Morning => 'In the morning';

  @override
  String get onbQ1Afternoon => 'In the afternoon';

  @override
  String get onbQ1Night => 'At night';

  @override
  String get onbQ2 => 'How much time can you commit per day?';

  @override
  String get onbQ2Short => '10 minutes';

  @override
  String get onbQ2Medium => '20-30 minutes';

  @override
  String get onbQ2Long => '1 hour or more';

  @override
  String get onbQ3 => 'What usually holds you back?';

  @override
  String get onbQ3Start => 'Getting started is hard';

  @override
  String get onbQ3Consistency => 'I start but don\'t stick with it';

  @override
  String get onbQ3Plan => 'I just need a plan';

  @override
  String get onbGeneratePlan => 'Generate my plan';

  @override
  String get onbGenPhase1 => 'Analyzing your goals…';

  @override
  String get onbGenPhase2 => 'Designing your routine…';

  @override
  String get onbGenPhase3 => 'Tuning schedule and difficulty…';

  @override
  String get onbPlanReadyTitle => 'Your plan is ready!';

  @override
  String get onbAcceptPlan => 'Start with this plan';

  @override
  String get onbRegenerate => 'Try another plan';

  @override
  String get onbPlanError =>
      'We couldn\'t generate your plan. Check your connection and try again.';

  @override
  String get onbRetry => 'Retry';

  @override
  String get onbNotifTitle => 'A nudge at just the right time';

  @override
  String get onbNotifBody =>
      'We\'ll remind you of each habit at its time. No spam — you choose which ones.';

  @override
  String get onbNotifPreview => '💪 Time for your first habit';

  @override
  String get onbNotifPreviewTime => 'now';

  @override
  String get onbNotifAllow => 'Enable reminders';

  @override
  String get onbNotifLater => 'Not now';

  @override
  String onbAiPrompt(String areas, String energy, String time, String blocker) {
    return 'I want to improve these areas: $areas. I have the most energy $energy. I can spend $time per day on my habits. About me: $blocker. Generate my initial habit plan.';
  }

  @override
  String get onbRegeneratePrompt =>
      'I\'m not fully convinced, generate a different plan with other habits.';

  @override
  String get onbAiFeaturesTitle => 'Your AI copilot';

  @override
  String get onbAiFeaturesSubtitle =>
      'The plan is just the beginning. Here\'s everything the AI will do for you:';

  @override
  String get onbFeatChatTitle => 'Chat with your coach';

  @override
  String get onbFeatChatDesc =>
      'Ask for new plans or tweaks anytime, just by chatting.';

  @override
  String get onbFeatReviewTitle => 'Weekly review';

  @override
  String get onbFeatReviewDesc =>
      'Every week it analyzes your progress and mood, with concrete advice.';

  @override
  String get onbFeatButterflyTitle => 'Butterfly effect';

  @override
  String get onbFeatButterflyDesc =>
      'Projects how your life will change if you keep your habits over time.';

  @override
  String get onbFeatRenegotiationTitle => 'Smart renegotiation';

  @override
  String get onbFeatRenegotiationDesc =>
      'Stuck on a habit? The AI suggests an easier version you can keep.';

  @override
  String get onbFeatPatternsTitle => 'Pattern detection';

  @override
  String get onbFeatPatternsDesc =>
      'Discover which days and time slots work best for you.';

  @override
  String get onbWhereAssistantTab => 'Assistant tab';

  @override
  String get onbWhereProgressTab => 'Progress tab';

  @override
  String get onbWhereHabitDetail => 'On each habit';

  @override
  String get onbNameTitle => 'What should we call you?';

  @override
  String get onbNameSubtitle =>
      'Your AI coach will use your name when talking to you.';

  @override
  String get onbNameHint => 'Your name';

  @override
  String onbNameGreeting(String name) {
    return 'Great, $name! 👋';
  }

  @override
  String onbAiPromptName(String name) {
    return 'My name is $name.';
  }

  @override
  String get onbRecipePlanFor => 'A plan for ';

  @override
  String get onbRecipeImprove => ' to improve ';

  @override
  String get onbRecipeImproveNoName => 'A plan to improve ';

  @override
  String get onbRecipeEnergy => ' · energy ';

  @override
  String get onbRecipePerDay => ' a day';

  @override
  String get onbCheckinTitle => 'Start right now!';

  @override
  String get onbCheckinSubtitle =>
      'The first win is the one that counts the most. Which one can you complete today?';

  @override
  String get onbCheckinStreak => '1-day streak! 🔥';

  @override
  String get onbCheckinLater => 'I\'ll do it later';

  @override
  String get paywallTitle => 'HabitAI Premium';

  @override
  String get paywallSubtitle => 'Unlock the full power of your habit coach';

  @override
  String get paywallPrice => '€3.99/month';

  @override
  String get paywallBenefitHabits => 'Unlimited habits and habit stacking';

  @override
  String get paywallBenefitChat => '24/7 AI coach with unlimited messages';

  @override
  String get paywallBenefitWeekly => 'Personalized AI weekly review';

  @override
  String get paywallBenefitInsights =>
      'Butterfly effect, patterns and smart renegotiation';

  @override
  String get paywallBenefitMood => 'Mood-habit correlation insights';

  @override
  String get paywallBenefitShields =>
      'Extra streak shields and extended sick mode';

  @override
  String get paywallCta => 'Go Premium';

  @override
  String get paywallLater => 'Maybe later';

  @override
  String get paywallComingSoon => 'Subscriptions are coming very soon 🚀';

  @override
  String get paywallFreePlanNote =>
      'Your free plan includes 7 habits, challenges with friends and one AI-generated routine every month.';

  @override
  String get paywallRestore => 'Restore purchases';

  @override
  String get paywallPurchaseSuccess => 'Welcome to Premium! 🎉';

  @override
  String get paywallPurchaseError =>
      'Couldn\'t complete the purchase. Please try again.';

  @override
  String get paywallRestoreSuccess => 'Purchase restored. Premium activated.';

  @override
  String get paywallRestoreNone =>
      'We couldn\'t find any previous purchases to restore.';

  @override
  String get paywallCancelAnytime => 'Auto-renews monthly · Cancel anytime';

  @override
  String get lockedChatTitle => 'AI routine chat';

  @override
  String get lockedChatDesc =>
      'Talk to your coach to fine-tune your whole routine: it suggests changes and new habits instantly.';

  @override
  String get lockedWeeklyTitle => 'AI weekly review';

  @override
  String get lockedWeeklyDesc =>
      'Every week, the AI analyzes your progress and gives you a personalized summary with next steps.';

  @override
  String get lockedButterflyTitle => 'Butterfly effect';

  @override
  String get lockedButterflyDesc =>
      'Discover how your habits today transform your life a few months down the road.';

  @override
  String get lockedPatternsTitle => 'Pattern detection';

  @override
  String get lockedPatternsDesc =>
      'The AI finds hidden patterns between your habits, your mood and your schedule.';

  @override
  String get lockedMoodTitle => 'Mood correlation';

  @override
  String get lockedMoodDesc =>
      'Find out which habits boost your energy and your mood.';

  @override
  String get paywallBadge => 'PREMIUM';

  @override
  String get paywallSocialProof =>
      'Join others already building better habits with AI';

  @override
  String get premiumRequiredSnack => 'This feature is part of HabitAI Premium';

  @override
  String get freeHabitLimitTitle => 'You\'ve reached the free plan limit';

  @override
  String freeHabitLimitBody(int count) {
    return 'The free plan includes $count active habits. With Premium you can create as many as you want.';
  }

  @override
  String freePlanMessagesLeft(int count) {
    return '$count free messages this month';
  }

  @override
  String get freePlanQuotaExhausted =>
      'You\'ve used this month\'s free generation. With Premium your coach has no limits.';

  @override
  String get routineChatTitle => 'Routine chat';

  @override
  String routineChatGreeting(String title) {
    return 'I know \"$title\" inside out: its habits, streaks and the last 30 days. Ask me anything or request changes.';
  }

  @override
  String get routineChatHint => 'Ask or request a change...';

  @override
  String get routineChatChangesTitle => 'Proposed changes';

  @override
  String routineChatUpdateCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count habits adjusted',
      one: '1 habit adjusted',
    );
    return '$_temp0';
  }

  @override
  String routineChatNewCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count new habits',
      one: '1 new habit',
    );
    return '$_temp0';
  }

  @override
  String get routineChatApply => 'Apply changes';

  @override
  String get routineChatApplied => 'Changes applied to the routine ✅';

  @override
  String get routineChatApplyError => 'Couldn\'t apply the changes';

  @override
  String get authForgotPassword => 'Forgot your password?';

  @override
  String get authForgotPasswordTitle => 'Reset password';

  @override
  String get authForgotPasswordBody =>
      'We\'ll email you a link to create a new password.';

  @override
  String get authForgotPasswordSend => 'Send link';

  @override
  String get authForgotPasswordSent =>
      'If an account exists for that email, you\'ll receive a link in a few minutes. Check spam too.';

  @override
  String get authForgotPasswordInvalid => 'Enter a valid email';

  @override
  String get authErrorInvalidCredential =>
      'Incorrect email or password. Check them and try again.';

  @override
  String get authErrorInvalidEmail => 'The email format isn\'t valid.';

  @override
  String get authErrorUserDisabled =>
      'This account is disabled. Contact support.';

  @override
  String get authErrorTooManyRequests =>
      'Too many attempts. Wait a few minutes and try again.';

  @override
  String get authErrorNetwork =>
      'No internet connection. Check your network and try again.';

  @override
  String get authErrorEmailInUse =>
      'An account already exists with this email. Sign in instead.';

  @override
  String get authErrorWeakPassword =>
      'The password is too weak. Use at least 6 characters.';

  @override
  String get authErrorAccountExists =>
      'An account already exists with this email using a different sign-in method.';

  @override
  String get authErrorOperationNotAllowed =>
      'This sign-in method isn\'t enabled.';

  @override
  String get authErrorRequiresPassword => 'Enter your password to continue.';

  @override
  String get authErrorGeneric =>
      'Couldn\'t complete the operation. Please try again.';
}
