import '../../../l10n/app_localizations.dart';
import '../domain/achievement_model.dart';

/// Resuelve título y descripción localizada de logros sin tocar la capa de dominio.
class AchievementL10n {
  static String title(String type, S l10n) {
    switch (type) {
      case AchievementModel.firstHabit:
        return l10n.achievementFirstHabitTitle;
      case AchievementModel.aiPlan:
        return l10n.achievementAiPlanTitle;
      case AchievementModel.allCompleted:
        return l10n.achievementPerfectDayTitle;
      case AchievementModel.streak3:
        return l10n.achievementStreak3Title;
      case AchievementModel.streak7:
        return l10n.achievementStreak7Title;
      case AchievementModel.streak14:
        return l10n.achievementStreak14Title;
      case AchievementModel.streak30:
        return l10n.achievementStreak30Title;
      case AchievementModel.habits5:
        return l10n.achievementHabits5Title;
      case AchievementModel.total50:
        return l10n.achievementTotal50Title;
      case AchievementModel.total100:
        return l10n.achievementTotal100Title;
      case AchievementModel.perfectWeek:
        return l10n.achievementPerfectWeekTitle;
      case AchievementModel.challengeCompleted:
        return l10n.achievementChallengeTitle;
      default:
        return type;
    }
  }

  static String description(String type, S l10n) {
    switch (type) {
      case AchievementModel.firstHabit:
        return l10n.achievementFirstHabitDesc;
      case AchievementModel.aiPlan:
        return l10n.achievementAiPlanDesc;
      case AchievementModel.allCompleted:
        return l10n.achievementPerfectDayDesc;
      case AchievementModel.streak3:
        return l10n.achievementStreak3Desc;
      case AchievementModel.streak7:
        return l10n.achievementStreak7Desc;
      case AchievementModel.streak14:
        return l10n.achievementStreak14Desc;
      case AchievementModel.streak30:
        return l10n.achievementStreak30Desc;
      case AchievementModel.habits5:
        return l10n.achievementHabits5Desc;
      case AchievementModel.total50:
        return l10n.achievementTotal50Desc;
      case AchievementModel.total100:
        return l10n.achievementTotal100Desc;
      case AchievementModel.perfectWeek:
        return l10n.achievementPerfectWeekDesc;
      case AchievementModel.challengeCompleted:
        return l10n.achievementChallengeDesc;
      default:
        return '';
    }
  }
}
