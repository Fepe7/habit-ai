import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:home_widget/home_widget.dart';

import '../features/habits/data/habit_repository.dart';
import '../features/habits/domain/habit_log_model.dart';
import '../features/habits/domain/habit_model.dart';
import '../firebase_options.dart';

/// Publica el estado del día al widget de pantalla de inicio (Android + iOS)
/// y procesa los check-ins hechos desde el propio widget sin abrir la app.
class HomeWidgetService {
  HomeWidgetService._();
  static final HomeWidgetService instance = HomeWidgetService._();

  // App Group compartido con la extensión WidgetKit (iOS)
  static const String appGroupId = 'group.com.andreistaicu.habitai';
  static const String _androidProvider = 'HabitWidgetProvider';
  static const String _iosWidgetName = 'HabitWidget';

  // clave única con el payload JSON que leen ambos providers nativos
  static const String payloadKey = 'widget_payload';

  // check-ins hechos desde el widget de iOS (App Intent marca optimista y
  // encola aquí; la app los escribe en Firestore al abrirse)
  static const String pendingKey = 'pending_checkins';

  // máximo de hábitos listados en el widget mediano
  static const int _maxHabits = 4;

  Future<void> init() async {
    await HomeWidget.setAppGroupId(appGroupId);
    await HomeWidget.registerInteractivityCallback(
      homeWidgetBackgroundCallback,
    );
  }

  /// Recalcula el día desde Firestore (caché incluida) y refresca el widget.
  /// Llamar tras cada check-in y al abrir la app.
  Future<void> syncToday() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        await _publish(_emptyPayload());
        return;
      }

      final repo = HabitRepository(uid: uid);
      await _applyPendingCheckins(repo);
      final habits = await _getTodayHabits(repo);

      // estado de completado de hoy, en paralelo (lecturas servidas de caché)
      final logs = await Future.wait(
        habits.map((h) => repo.getTodayLog(h.id)),
      );
      final done = <String>{};
      for (var i = 0; i < habits.length; i++) {
        final log = logs[i];
        if (log != null && (log.completed || log.shielded)) {
          done.add(habits[i].id);
        }
      }

      // pendientes primero (en su orden de lista), completados al final
      final sorted = [...habits]
        ..sort((a, b) {
          final aDone = done.contains(a.id) ? 1 : 0;
          final bDone = done.contains(b.id) ? 1 : 0;
          if (aDone != bDone) return aDone - bDone;
          return a.sortOrder.compareTo(b.sortOrder);
        });

      final payload = <String, dynamic>{
        'date': _todayKey(),
        'completed': done.length,
        'total': habits.length,
        'habits': [
          for (final h in sorted.take(_maxHabits))
            {
              'id': h.id,
              'title': h.title,
              'done': done.contains(h.id),
            },
        ],
      };
      await _publish(payload);
    } catch (_) {
      // el widget nunca debe romper el flujo principal de la app
    }
  }

  // aplica los check-ins encolados por el widget de iOS y limpia la cola
  Future<void> _applyPendingCheckins(HabitRepository repo) async {
    try {
      final raw = await HomeWidget.getWidgetData<List<dynamic>>(pendingKey);
      if (raw == null || raw.isEmpty) return;
      for (final habitId in raw.whereType<String>()) {
        final existing = await repo.getTodayLog(habitId);
        if (existing == null || !(existing.completed || existing.shielded)) {
          await repo.addLog(
            habitId,
            HabitLogModel(id: '', date: DateTime.now(), completed: true),
          );
          try {
            await repo.updateStreak(habitId);
          } catch (_) {}
        }
      }
      await HomeWidget.saveWidgetData<String?>(pendingKey, null);
    } catch (_) {
      // nunca bloquear el sync por la cola del widget
    }
  }

  Map<String, dynamic> _emptyPayload() => {
        'date': _todayKey(),
        'completed': 0,
        'total': 0,
        'habits': const <Map<String, dynamic>>[],
      };

  static String _todayKey() {
    final now = DateTime.now();
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return '${now.year}-$m-$d';
  }

  // hábitos que tocan hoy, versión one-shot del stream watchTodayHabits
  Future<List<HabitModel>> _getTodayHabits(HabitRepository repo) async {
    final all = await repo.getActiveHabits();
    final today = DateTime.now().weekday;
    return all.where((h) => h.targetDays.contains(today)).toList();
  }

  Future<void> _publish(Map<String, dynamic> payload) async {
    await HomeWidget.saveWidgetData<String>(payloadKey, jsonEncode(payload));
    await HomeWidget.updateWidget(
      name: _androidProvider,
      qualifiedAndroidName: 'com.habitai.habitai.$_androidProvider',
      iOSName: _iosWidgetName,
    );
  }
}

/// Entry point del isolate de fondo: se invoca al tocar un check en el widget
/// (Android siempre; iOS 17+ via App Intent) sin que la app esté abierta.
@pragma('vm:entry-point')
Future<void> homeWidgetBackgroundCallback(Uri? uri) async {
  if (uri == null) return;
  WidgetsFlutterBinding.ensureInitialized();
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
  await HomeWidget.setAppGroupId(HomeWidgetService.appGroupId);

  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return;
  final repo = HabitRepository(uid: uid);

  if (uri.host == 'checkin') {
    final habitId = uri.queryParameters['habitId'];
    if (habitId != null && habitId.isNotEmpty) {
      // idempotente: si ya está completado hoy, no duplicar el log
      final existing = await repo.getTodayLog(habitId);
      if (existing == null || !(existing.completed || existing.shielded)) {
        await repo.addLog(
          habitId,
          HabitLogModel(id: '', date: DateTime.now(), completed: true),
        );
        try {
          await repo.updateStreak(habitId);
        } catch (_) {
          // cancelar el recordatorio local puede fallar en el isolate de
          // fondo (plugin sin init); la racha ya quedó escrita antes
        }
      }
    }
  }
  // tanto para checkin como para el refresco periódico ('sync')
  await HomeWidgetService.instance.syncToday();
}
