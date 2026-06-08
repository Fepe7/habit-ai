import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../features/habits/domain/habit_model.dart';
import 'push_notification_service.dart';

// Servicio singleton de notificaciones locales
// Programa recordatorios semanales por dia de la semana para cada habito
class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  static const _prefsKey = 'notifications_enabled';
  static const _channelId = 'habit_reminders';
  static const _channelName = 'Recordatorios de hábitos';
  static const _channelDesc = 'Avisos para completar tus hábitos a la hora prevista';

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  // Inicializa timezone y el plugin. Llamar una vez en main()
  Future<void> init() async {
    if (_initialized) return;

    tz.initializeTimeZones();
    // Android/iOS reportan zona a traves del sistema; usamos la del dispositivo
    // sin forzar una concreta para que los recordatorios respeten la hora local

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _plugin.initialize(
      settings: const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // crear canal Android explicitamente (en iOS no es necesario)
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.createNotificationChannel(const AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDesc,
      importance: Importance.high,
    ));
    await android?.createNotificationChannel(const AndroidNotificationChannel(
      'social_notifications',
      'Notificaciones sociales',
      description: 'Solicitudes de seguimiento y actualizaciones sociales',
      importance: Importance.high,
    ));
    // canal por defecto para los push de FCM en background (debe coincidir con
    // el meta-data default_notification_channel_id del AndroidManifest)
    await android?.createNotificationChannel(const AndroidNotificationChannel(
      'push_default',
      'Avisos de HabitAI',
      description: 'Revisión semanal, seguidores y otros avisos remotos',
      importance: Importance.high,
    ));

    _initialized = true;
  }

  // Pide permisos en runtime (Android 13+ / iOS)
  Future<bool> requestPermissions() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      return granted ?? true;
    }
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      final granted = await ios.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }
    return true;
  }

  // Lee el toggle global del usuario
  Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefsKey) ?? true;
  }

  Future<void> setEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, value);
  }

  // Programa los avisos del habito (uno por cada dia en targetDays)
  Future<void> scheduleHabitReminders(HabitModel habit) async {
    await cancelHabitReminders(habit.id);

    if (!habit.isActive) return;
    if (habit.reminderTime == null || habit.reminderTime!.isEmpty) return;
    if (habit.targetDays.isEmpty) return;
    if (!await isEnabled()) return;

    final time = _parseTime(habit.reminderTime!);
    if (time == null) return;

    for (final weekday in habit.targetDays) {
      try {
        await _plugin.zonedSchedule(
          id: _notifId(habit.id, weekday),
          title: _buildTitle(habit),
          body: _buildBody(habit),
          scheduledDate: _nextInstanceOfWeekdayTime(weekday, time.hour, time.minute),
          notificationDetails: _details(),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
          payload: habit.id,
        );
      } catch (e, st) {
        // no queremos que un error de plataforma rompa la creacion del habito
        debugPrint('[NotificationService] fallo schedule ${habit.id}/$weekday: $e\n$st');
      }
    }
  }

  // Cancela todas las ocurrencias de un habito
  Future<void> cancelHabitReminders(String habitId) async {
    for (int weekday = 1; weekday <= 7; weekday++) {
      await _plugin.cancel(id: _notifId(habitId, weekday));
    }
  }

  // Cancela solo la notificacion del dia actual (tras check-in)
  // Al ser recurrente semanal, basta con cancelar la del weekday de hoy
  // y reprogramarla: flutter_local_notifications no permite saltar una
  // ocurrencia sin cancelar, asi que la volvemos a programar desde la
  // proxima semana
  Future<void> cancelTodayReminder(HabitModel habit) async {
    final today = DateTime.now().weekday;
    if (!habit.targetDays.contains(today)) return;

    final id = _notifId(habit.id, today);
    await _plugin.cancel(id: id);

    // reprogramar: zonedSchedule con matchDateTimeComponents apuntara al
    // proximo dia-de-semana que toque, saltando asi el dia de hoy
    if (habit.reminderTime == null || habit.reminderTime!.isEmpty) return;
    final time = _parseTime(habit.reminderTime!);
    if (time == null) return;
    if (!await isEnabled()) return;

    try {
      await _plugin.zonedSchedule(
        id: id,
        title: _buildTitle(habit),
        body: _buildBody(habit),
        scheduledDate: _nextInstanceOfWeekdayTime(today, time.hour, time.minute, skipToday: true),
        notificationDetails: _details(),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        payload: habit.id,
      );
    } catch (e) {
      debugPrint('[NotificationService] fallo reschedule tras check-in: $e');
    }
  }

  // Reprograma todos los habitos (tras login o al activar el toggle global)
  Future<void> rescheduleAll(List<HabitModel> habits) async {
    await _plugin.cancelAll();
    if (!await isEnabled()) return;
    for (final habit in habits) {
      await scheduleHabitReminders(habit);
    }
  }

  Future<void> cancelAll() => _plugin.cancelAll();

  // Muestra una notificacion inmediata para eventos sociales (follow request,
  // aceptacion) y para los push de FCM recibidos en primer plano.
  // [payload] opcional = ruta de deep link a la que navegar al tocarla.
  Future<void> showSocialNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_initialized) return;
    await _plugin.show(
      id: DateTime.now().millisecondsSinceEpoch & 0x7FFFFFFF,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'social_notifications',
          'Notificaciones sociales',
          channelDescription: 'Solicitudes de seguimiento y actualizaciones sociales',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: payload,
    );
  }

  // Tap en una notificacion local: traduce el payload a una ruta y navega.
  // Convención: payload que empieza por '/' es una ruta directa; cualquier otro
  // valor se interpreta como el id de un habito (recordatorios).
  void _onNotificationTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null || payload.isEmpty) return;
    final route = payload.startsWith('/') ? payload : '/habit/$payload';
    PushNotificationService.instance.navigateTo(route);
  }

  // ==================== helpers ====================

  NotificationDetails _details() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDesc,
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );
  }

  String _buildTitle(HabitModel habit) {
    return '⏰ ${habit.title}';
  }

  String _buildBody(HabitModel habit) {
    if (habit.description.isNotEmpty) return habit.description;
    return '¡Es hora de completar tu hábito!';
  }

  // ID determinista para poder cancelar sin guardar nada extra
  // 28 bits del hash + 3 bits del weekday → siempre positivo y unico por par
  int _notifId(String habitId, int weekday) =>
      (habitId.hashCode & 0x0FFFFFFF) ^ weekday;

  ({int hour, int minute})? _parseTime(String hhmm) {
    final parts = hhmm.split(':');
    if (parts.length != 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    if (h < 0 || h > 23 || m < 0 || m > 59) return null;
    return (hour: h, minute: m);
  }

  // Calcula el proximo TZDateTime con ese weekday + hora.
  // Si skipToday=true y hoy coincide, salta a la semana siguiente
  tz.TZDateTime _nextInstanceOfWeekdayTime(
    int weekday,
    int hour,
    int minute, {
    bool skipToday = false,
  }) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);

    // avanzar hasta que caiga en el weekday objetivo
    while (scheduled.weekday != weekday) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    // si ya paso hoy (o nos piden saltar hoy), +7 dias
    final alreadyPassed = scheduled.isBefore(now);
    if (alreadyPassed || (skipToday && scheduled.weekday == now.weekday && scheduled.day == now.day)) {
      scheduled = scheduled.add(const Duration(days: 7));
    }

    return scheduled;
  }
}
