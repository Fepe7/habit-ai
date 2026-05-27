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
}
