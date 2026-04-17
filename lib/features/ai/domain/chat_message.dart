// Mensaje en el chat con la IA
class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final HabitPlanData? plan;
  final bool isError;

  const ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.plan,
    this.isError = false,
  });
}

// Datos del plan para mostrar en el chat (sin acoplar al modelo de Firestore)
class HabitPlanData {
  final String title;
  final String? emoji;
  final String description;
  final List<HabitSuggestion> habits;

  const HabitPlanData({
    required this.title,
    this.emoji,
    required this.description,
    required this.habits,
  });
}

class HabitSuggestion {
  final String title;
  final String description;
  final String category;
  final String frequency;
  final List<int> targetDays;
  final String? suggestedTime;
  bool accepted;

  HabitSuggestion({
    required this.title,
    required this.description,
    required this.category,
    required this.frequency,
    required this.targetDays,
    this.suggestedTime,
    this.accepted = true,
  });
}
