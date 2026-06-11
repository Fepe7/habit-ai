import 'habit_plan_model.dart';

/// Campos de un hábito existente que la IA puede modificar desde el chat
/// de rutina. Cualquier otra clave que devuelva se descarta (whitelist).
const _allowedUpdateFields = {
  'title',
  'description',
  'frequency',
  'targetDays',
  'reminderTime',
};

/// Cambio propuesto sobre un hábito existente de la rutina
class RoutineHabitUpdate {
  final String habitId;

  /// Solo los campos que cambian, listos para HabitRepository.updateHabit
  final Map<String, dynamic> fields;

  const RoutineHabitUpdate({required this.habitId, required this.fields});

  static RoutineHabitUpdate? fromJson(Map<String, dynamic> json) {
    final habitId = json['habitId'] as String?;
    if (habitId == null || habitId.isEmpty) return null;
    final fields = <String, dynamic>{};
    for (final key in _allowedUpdateFields) {
      if (!json.containsKey(key)) continue;
      if (key == 'targetDays') {
        final days = json[key];
        if (days is List) {
          fields[key] = days.whereType<num>().map((d) => d.toInt()).toList();
        }
      } else {
        fields[key] = json[key];
      }
    }
    if (fields.isEmpty) return null;
    return RoutineHabitUpdate(habitId: habitId, fields: fields);
  }
}

/// Conjunto de cambios que propone la IA (null en conversación normal)
class RoutineChanges {
  final String summary;
  final List<RoutineHabitUpdate> updates;
  final List<GeneratedHabitModel> newHabits;

  const RoutineChanges({
    required this.summary,
    required this.updates,
    required this.newHabits,
  });

  bool get isEmpty => updates.isEmpty && newHabits.isEmpty;

  factory RoutineChanges.fromJson(Map<String, dynamic> json) {
    final updates = <RoutineHabitUpdate>[];
    for (final raw in (json['updates'] as List? ?? [])) {
      if (raw is! Map<String, dynamic>) continue;
      final update = RoutineHabitUpdate.fromJson(raw);
      if (update != null) updates.add(update);
    }

    final newHabits = <GeneratedHabitModel>[];
    for (final raw in (json['newHabits'] as List? ?? [])) {
      if (raw is! Map<String, dynamic> || raw['title'] == null) continue;
      // el prompt de rutina usa reminderTime; GeneratedHabitModel espera
      // suggestedTime — se normaliza aquí para reutilizar toHabitModel()
      newHabits.add(GeneratedHabitModel.fromJson({
        ...raw,
        'suggestedTime': raw['reminderTime'] ?? raw['suggestedTime'],
      }));
    }

    return RoutineChanges(
      summary: json['summary'] as String? ?? '',
      updates: updates,
      newHabits: newHabits,
    );
  }
}

/// Respuesta del callable routineChat
class RoutineChatResponse {
  final String coachMessage;
  final RoutineChanges? changes;

  const RoutineChatResponse({required this.coachMessage, this.changes});

  factory RoutineChatResponse.fromJson(Map<String, dynamic> json) {
    final rawChanges = json['changes'];
    RoutineChanges? changes;
    if (rawChanges is Map<String, dynamic>) {
      final parsed = RoutineChanges.fromJson(rawChanges);
      if (!parsed.isEmpty) changes = parsed;
    }
    return RoutineChatResponse(
      coachMessage: json['coachMessage'] as String? ?? '',
      changes: changes,
    );
  }
}
