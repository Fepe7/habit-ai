import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/theme/app_theme.dart';
import '../../../features/achievements/data/archivement_repository.dart';
import '../../../features/achievements/domain/achivement_model.dart';
import '../../../features/ai/data/ai_repository.dart';
import '../../../features/ai/domain/butterfly_projection_model.dart';
import '../../../features/ai/domain/renegotiation_model.dart';
import '../../../features/ai/domain/weekly_review_model.dart';
import '../../../features/habits/data/habit_repository.dart';
import '../../../features/habits/domain/habit_model.dart';
import '../../../features/challenges/data/challenge_repository.dart';
import '../../../features/challenges/domain/challenge_model.dart';

/// Gestiona el estado de "visto" y "borrado" de las notificaciones vía SharedPreferences.
class NotificationsService {
  static const _keyLastSeen = 'notif_last_seen_ms';
  static const _keyCleared = 'notif_cleared_at_ms';

  /// Devuelve true si hay notificaciones nuevas desde la última visita.
  /// Hace dos queries Firestore ligeras (limit 1 cada una).
  static Future<bool> hasNew(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    // El badge desaparece si el usuario vio o borró las notificaciones
    final lastSeenMs = prefs.getInt(_keyLastSeen);
    final clearedMs = prefs.getInt(_keyCleared);
    final referenceMs = [lastSeenMs, clearedMs]
        .whereType<int>()
        .fold<int?>(null, (a, b) => a == null ? b : (b > a ? b : a));
    final reference = referenceMs != null
        ? DateTime.fromMillisecondsSinceEpoch(referenceMs)
        : null;

    final db = FirebaseFirestore.instance;
    final userRef = db.collection('users').doc(uid);

    // Último logro desbloqueado
    final achievSnap = await userRef
        .collection('achievements')
        .orderBy('unlockedAt', descending: true)
        .limit(1)
        .get();
    if (achievSnap.docs.isNotEmpty) {
      final d =
          (achievSnap.docs.first.data()['unlockedAt'] as Timestamp).toDate();
      if (reference == null || d.isAfter(reference)) return true;
    }

    // Invitaciones de reto pendientes (filtro status en cliente)
    final challengeSnap = await db
        .collection('challenges')
        .where('invitedUid', isEqualTo: uid)
        .limit(5)
        .get();
    for (final doc in challengeSnap.docs) {
      if (doc.data()['status'] != 'pending') continue;
      final d = (doc.data()['createdAt'] as Timestamp).toDate();
      if (reference == null || d.isAfter(reference)) return true;
    }

    // Reto aceptado por el compañero (soy el creador)
    final acceptedSnap = await db
        .collection('challenges')
        .where('creatorUid', isEqualTo: uid)
        .where('status', isEqualTo: 'active')
        .limit(5)
        .get();
    for (final doc in acceptedSnap.docs) {
      final startDate = doc.data()['startDate'];
      if (startDate != null) {
        final d = (startDate as Timestamp).toDate();
        if (reference == null || d.isAfter(reference)) return true;
      }
    }

    // Última renegociación generada por la IA
    final renegSnap = await userRef
        .collection('renegotiations')
        .orderBy('generatedAt', descending: true)
        .limit(1)
        .get();
    if (renegSnap.docs.isNotEmpty) {
      final d =
          (renegSnap.docs.first.data()['generatedAt'] as Timestamp).toDate();
      if (reference == null || d.isAfter(reference)) return true;
    }

    return false;
  }

  /// Marca el momento actual como "último visto".
  static Future<void> markSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyLastSeen, DateTime.now().millisecondsSinceEpoch);
  }

  /// Oculta todas las notificaciones actuales de la lista.
  /// Los items con fecha anterior a este momento no volverán a aparecer.
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now().millisecondsSinceEpoch;
    await prefs.setInt(_keyCleared, now);
    await prefs.setInt(_keyLastSeen, now);
  }

  /// Devuelve la fecha a partir de la cual mostrar notificaciones (null = mostrar todo).
  static Future<DateTime?> getClearedAt() async {
    final prefs = await SharedPreferences.getInstance();
    final ms = prefs.getInt(_keyCleared);
    return ms != null ? DateTime.fromMillisecondsSinceEpoch(ms) : null;
  }
}

// DTO interno — une los datos de distintas colecciones en un formato común
class _NotifItem {
  final String title;
  final String subtitle;
  final DateTime date;
  final IconData icon;
  final Color color;
  final String routeName;
  final Map<String, String> routeParams;

  const _NotifItem({
    required this.title,
    required this.subtitle,
    required this.date,
    required this.icon,
    required this.color,
    required this.routeName,
    this.routeParams = const {},
  });
}

/// Panel de notificaciones recientes — muestra logros, recordatorios,
/// renegociaciones y revisiones de IA ordenados por fecha.
class NotificationsBottomSheet extends StatefulWidget {
  const NotificationsBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    // marcar visto antes de mostrar el panel
    NotificationsService.markSeen();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const NotificationsBottomSheet(),
    );
  }

  @override
  State<NotificationsBottomSheet> createState() =>
      _NotificationsBottomSheetState();
}

typedef _NotifData = ({List<_NotifItem> events, List<_NotifItem> reminders});

class _NotificationsBottomSheetState extends State<NotificationsBottomSheet> {
  late Future<_NotifData> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadAll();
  }

  Future<void> _clearAll() async {
    await NotificationsService.clearAll();
    if (mounted) setState(() => _future = _loadAll());
  }

  Future<_NotifData> _loadAll() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final habitRepo = HabitRepository(uid: uid);
    final achievementRepo = AchievementRepository(uid: uid);
    final aiRepo = AIRepository(uid: uid);
    final challengeRepo = ChallengeRepository(uid: uid);

    final clearedAt = await NotificationsService.getClearedAt();

    // Challenges está en colección raíz — puede fallar por reglas Firestore
    // si aún no están desplegadas; aislamos para no romper el resto del panel
    List<ChallengeModel> pendingInvites = [];
    List<ChallengeModel> acceptedByOthers = [];
    try {
      final challengeResults = await Future.wait([
        challengeRepo.watchPendingInvites().first,
        challengeRepo.watchAcceptedByOthers().first,
      ]);
      pendingInvites = challengeResults[0] as List<ChallengeModel>;
      acceptedByOthers = challengeResults[1] as List<ChallengeModel>;
    } catch (_) {
      // Reglas Firestore para /challenges aún no desplegadas — se ignora
    }

    final results = await Future.wait([
      achievementRepo.watchAchievements().first,
      habitRepo.getActiveHabits(),
      aiRepo.watchActiveRenegotiations().first,
      aiRepo.watchLatestWeeklyReview().first,
      aiRepo.watchLatestButterfly().first,
    ]);

    bool afterCleared(DateTime d) =>
        clearedAt == null || d.isAfter(clearedAt);

    // ── Eventos borrables ──────────────────────────────────────────────────
    final events = <_NotifItem>[];

    for (final a in results[0] as List<AchievementModel>) {
      if (!afterCleared(a.unlockedAt)) continue;
      final info = AchievementCatalog.getInfo(a.type);
      events.add(_NotifItem(
        title: info.title,
        subtitle: info.description,
        date: a.unlockedAt,
        icon: info.icon,
        color: info.color,
        routeName: 'achievements',
      ));
    }

    for (final r
        in (results[2] as List<RenegotiationModel>).where((r) => r.isPending)) {
      if (!afterCleared(r.generatedAt)) continue;
      events.add(_NotifItem(
        title: 'Ajuste sugerido: ${r.habitTitle}',
        subtitle: r.strategy.label,
        date: r.generatedAt,
        icon: Icons.psychology_rounded,
        color: const Color(0xFFF59E0B),
        routeName: 'habit-detail',
        routeParams: {'habitId': r.habitId},
      ));
    }

    final review = results[3] as WeeklyReviewModel?;
    if (review != null && afterCleared(review.generatedAt)) {
      events.add(_NotifItem(
        title: 'Revisión semanal lista',
        subtitle: review.focus,
        date: review.generatedAt,
        icon: Icons.bar_chart_rounded,
        color: const Color(0xFF10B981),
        routeName: 'weekly-review',
        routeParams: {'weekId': review.weekId},
      ));
    }

    final butterfly = results[4] as ButterflyProjectionModel?;
    if (butterfly != null && afterCleared(butterfly.generatedAt)) {
      events.add(_NotifItem(
        title: 'Proyección mensual 🦋',
        subtitle: butterfly.titleKeep,
        date: butterfly.generatedAt,
        icon: Icons.timeline_rounded,
        color: const Color(0xFF8B5CF6),
        routeName: 'butterfly-projection',
        routeParams: {'monthId': butterfly.monthId},
      ));
    }

    // invitaciones de reto pendientes (soy el invitado)
    for (final c in pendingInvites) {
      if (!afterCleared(c.createdAt)) continue;
      events.add(_NotifItem(
        title: '¡Te han retado!',
        subtitle: '${c.habitTitle} — ${c.durationDays} días',
        date: c.createdAt,
        icon: Icons.handshake_rounded,
        color: const Color(0xFF6366F1),
        routeName: 'challenge-detail',
        routeParams: {'challengeId': c.id},
      ));
    }

    // retos aceptados por el compañero (soy el creador)
    for (final c in acceptedByOthers) {
      if (c.startDate == null) continue;
      if (!afterCleared(c.startDate!)) continue;
      events.add(_NotifItem(
        title: '¡Tu reto fue aceptado!',
        subtitle: c.habitTitle,
        date: c.startDate!,
        icon: Icons.celebration_rounded,
        color: const Color(0xFF10B981),
        routeName: 'challenge-detail',
        routeParams: {'challengeId': c.id},
      ));
    }

    events.sort((a, b) => b.date.compareTo(a.date));

    // ── Recordatorios permanentes (no afectados por clearAll) ─────────────
    final reminders = (results[1] as List<HabitModel>)
        .where((h) => h.reminderTime != null && h.reminderTime!.isNotEmpty)
        .map((h) => _NotifItem(
              title: h.title,
              subtitle: 'Recordatorio a las ${h.reminderTime}',
              date: h.createdAt,
              icon: Icons.alarm_rounded,
              color: const Color(0xFF38BDF8),
              routeName: 'habit-detail',
              routeParams: {'habitId': h.id},
            ))
        .toList();

    return (events: events, reminders: reminders);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: AppTheme.ambientShadow(),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: scheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          // Cabecera
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 8, 16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Notificaciones',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                TextButton(
                  onPressed: _clearAll,
                  style: TextButton.styleFrom(
                    foregroundColor: scheme.onSurfaceVariant,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  child: const Text('Limpiar actividad'),
                ),
              ],
            ),
          ),
          // Lista
          ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: 200,
              maxHeight: MediaQuery.of(context).size.height * 0.55,
            ),
            child: FutureBuilder<_NotifData>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const _LoadingState();
                }
                if (snap.hasError) {
                  return const _ErrorState();
                }
                final data = snap.data;
                final events = data?.events ?? [];
                final reminders = data?.reminders ?? [];
                if (events.isEmpty && reminders.isEmpty) {
                  return const _EmptyState();
                }
                return _TwoSectionList(
                  events: events,
                  reminders: reminders,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Lista con dos secciones: actividad borrable + recordatorios permanentes

class _TwoSectionList extends StatelessWidget {
  final List<_NotifItem> events;
  final List<_NotifItem> reminders;

  const _TwoSectionList({required this.events, required this.reminders});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    // Construimos una lista plana: items de eventos, luego cabecera de
    // recordatorios (si los hay), luego items de recordatorios.
    final rows = <Widget>[];

    if (events.isEmpty) {
      rows.add(Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
        child: Text(
          'Sin actividad reciente',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
              ),
        ),
      ));
    } else {
      for (int i = 0; i < events.length; i++) {
        rows.add(_NotifTile(item: events[i], index: i));
        if (i < events.length - 1) {
          rows.add(Divider(
              height: 1, color: scheme.outlineVariant.withValues(alpha: 0.5)));
        }
      }
    }

    if (reminders.isNotEmpty) {
      rows.add(Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
        child: Text(
          'Recordatorios activos',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
                letterSpacing: 0.8,
              ),
        ),
      ));
      for (int i = 0; i < reminders.length; i++) {
        rows.add(_NotifTile(item: reminders[i], index: events.length + i));
        if (i < reminders.length - 1) {
          rows.add(Divider(
              height: 1, color: scheme.outlineVariant.withValues(alpha: 0.5)));
        }
      }
    }

    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: rows,
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Tile individual de notificación

class _NotifTile extends StatelessWidget {
  final _NotifItem item;
  final int index;

  const _NotifTile({required this.item, required this.index});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: item.color.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(item.icon, color: item.color, size: 22),
      ),
      title: Text(
        item.title,
        style: Theme.of(context)
            .textTheme
            .bodyMedium
            ?.copyWith(fontWeight: FontWeight.w600),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        item.subtitle,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Text(
        _formatDate(item.date),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
      ),
      onTap: () {
        // Capturar el router antes de cerrar el bottom sheet
        final router = GoRouter.of(context);
        Navigator.of(context).pop();
        router.goNamed(item.routeName, pathParameters: item.routeParams);
      },
    )
        .animate()
        .fadeIn(
          delay: Duration(milliseconds: index * 40),
          duration: const Duration(milliseconds: 300),
        )
        .slideY(begin: 0.06, curve: Curves.easeOutCubic);
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      final h = date.hour.toString().padLeft(2, '0');
      final m = date.minute.toString().padLeft(2, '0');
      return '$h:$m';
    }
    if (diff.inDays == 1) return 'Ayer';
    if (diff.inDays < 7) return 'Hace ${diff.inDays}d';
    if (diff.inDays < 30) return 'Hace ${(diff.inDays / 7).floor()}sem';
    return 'Hace ${(diff.inDays / 30).floor()}mes';
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Estados auxiliares

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListView.separated(
      shrinkWrap: true,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      itemCount: 5,
      separatorBuilder: (context, index) =>
          Divider(height: 1, color: scheme.outlineVariant.withValues(alpha: 0.5)),
      itemBuilder: (context, i) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
            )
                .animate(onPlay: (c) => c.repeat())
                .shimmer(duration: 1200.ms, color: scheme.surface),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 13,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  )
                      .animate(onPlay: (c) => c.repeat())
                      .shimmer(duration: 1200.ms, color: scheme.surface),
                  const SizedBox(height: 6),
                  Container(
                    height: 11,
                    width: 160,
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  )
                      .animate(onPlay: (c) => c.repeat())
                      .shimmer(duration: 1200.ms, color: scheme.surface),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.notifications_none_rounded,
              size: 56,
              color: scheme.onSurfaceVariant.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 12),
            Text(
              'Sin notificaciones',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Aquí aparecerán tus logros, recordatorios y sugerencias de la IA.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Text(
        'No se pudieron cargar las notificaciones.',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
