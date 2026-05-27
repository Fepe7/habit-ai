import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  AnalyticsService._();
  static final instance = AnalyticsService._();

  final _analytics = FirebaseAnalytics.instance;

  FirebaseAnalyticsObserver get observer =>
      FirebaseAnalyticsObserver(analytics: _analytics);

  Future<void> logLogin(String method) =>
      _analytics.logLogin(loginMethod: method);

  Future<void> logSignUp(String method) =>
      _analytics.logSignUp(signUpMethod: method);

  Future<void> logHabitCreated(String category) =>
      _analytics.logEvent(name: 'habit_created', parameters: {'category': category});

  Future<void> logHabitCheckin(String habitId) =>
      _analytics.logEvent(name: 'habit_checkin', parameters: {'habit_id': habitId});

  Future<void> logAIChat() =>
      _analytics.logEvent(name: 'ai_chat_sent');

  Future<void> logWeeklyReviewViewed() =>
      _analytics.logEvent(name: 'weekly_review_viewed');

  Future<void> logTemplateImported(String templateId) =>
      _analytics.logEvent(name: 'template_imported', parameters: {'template_id': templateId});

  Future<void> logAchievementUnlocked(String achievementId) =>
      _analytics.logEvent(name: 'achievement_unlocked', parameters: {'achievement_id': achievementId});

  Future<void> logAccountDeleted() =>
      _analytics.logEvent(name: 'account_deleted');

  Future<void> setUserId(String? uid) =>
      _analytics.setUserId(id: uid);
}
