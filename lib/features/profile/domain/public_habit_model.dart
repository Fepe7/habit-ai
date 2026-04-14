/// Subconjunto seguro de HabitModel para perfiles públicos.
/// No incluye description, reminderTime, targetDays ni notas.
class PublicHabitModel {
  final String id;
  final String title;
  final String category;
  final String? emoji;
  final int currentStreak;
  final int bestStreak;

  const PublicHabitModel({
    required this.id,
    required this.title,
    required this.category,
    this.emoji,
    required this.currentStreak,
    required this.bestStreak,
  });

  factory PublicHabitModel.fromFirestore(
    Map<String, dynamic> data,
    String docId,
  ) {
    return PublicHabitModel(
      id: docId,
      title: data['title'] as String? ?? '',
      category: data['category'] as String? ?? 'productividad',
      emoji: data['emoji'] as String?,
      currentStreak: data['currentStreak'] as int? ?? 0,
      bestStreak: data['bestStreak'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'category': category,
      'emoji': emoji,
      'currentStreak': currentStreak,
      'bestStreak': bestStreak,
    };
  }
}
