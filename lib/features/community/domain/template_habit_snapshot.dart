// Snapshot inmutable de un habito dentro de una plantilla de comunidad.
// No contiene uid, groupId, rachas ni estado — solo configuracion del habito.
class TemplateHabitSnapshot {
  final String id;
  final String title;
  final String description;
  final String category;
  final String frequency;
  final List<int> targetDays;
  final String? reminderTime;

  const TemplateHabitSnapshot({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.frequency,
    required this.targetDays,
    this.reminderTime,
  });

  factory TemplateHabitSnapshot.fromJson(
      Map<String, dynamic> json, String docId) {
    return TemplateHabitSnapshot(
      id: docId,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? 'productividad',
      frequency: json['frequency'] as String? ?? 'daily',
      targetDays: List<int>.from(json['targetDays'] ?? []),
      reminderTime: json['reminderTime'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'frequency': frequency,
      'targetDays': targetDays,
      'reminderTime': reminderTime,
    };
  }
}
