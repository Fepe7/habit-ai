import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../services/notification_service.dart';

// Paso 4: pedir permiso de notificaciones CON contexto — se muestra una
// preview de cómo se verá un recordatorio real antes del diálogo del sistema.
class NotificationsStep extends StatefulWidget {
  final VoidCallback onFinished;

  const NotificationsStep({super.key, required this.onFinished});

  @override
  State<NotificationsStep> createState() => _NotificationsStepState();
}

class _NotificationsStepState extends State<NotificationsStep> {
  bool _isRequesting = false;

  Future<void> _allow() async {
    if (_isRequesting) return;
    setState(() => _isRequesting = true);
    try {
      final granted = await NotificationService.instance.requestPermissions();
      await NotificationService.instance.setEnabled(granted);
    } catch (_) {
      // Si el plugin falla seguimos adelante: el usuario puede activarlo en Ajustes
    }
    if (mounted) widget.onFinished();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Spacer(flex: 2),
          Text(
            s.onbNotifTitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2),
          const SizedBox(height: 10),
          Text(
            s.onbNotifBody,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white.withValues(alpha: 0.8),
                ),
          ).animate().fadeIn(delay: 150.ms, duration: 400.ms),
          const SizedBox(height: 32),
          // Preview de notificación real: entra desde arriba como un aviso
          _NotificationPreview(
            title: s.appTitle,
            body: s.onbNotifPreview,
            timeLabel: s.onbNotifPreviewTime,
          )
              .animate()
              .fadeIn(delay: 400.ms, duration: 450.ms)
              .slideY(begin: -0.5, delay: 400.ms, curve: Curves.easeOutBack)
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .moveY(begin: 0, end: 4, duration: 2.seconds),
          const Spacer(flex: 3),
          FilledButton.icon(
            onPressed: _isRequesting ? null : _allow,
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF064E3B),
              padding: const EdgeInsets.symmetric(vertical: 18),
              textStyle: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            icon: const Icon(Icons.notifications_active_rounded),
            label: Text(s.onbNotifAllow),
          ).animate().fadeIn(delay: 600.ms, duration: 400.ms),
          TextButton(
            onPressed: _isRequesting ? null : widget.onFinished,
            style: TextButton.styleFrom(foregroundColor: Colors.white),
            child: Text(s.onbNotifLater),
          ).animate().fadeIn(delay: 750.ms, duration: 400.ms),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

// Card que imita una notificación del sistema
class _NotificationPreview extends StatelessWidget {
  final String title;
  final String body;
  final String timeLabel;

  const _NotificationPreview({
    required this.title,
    required this.body,
    required this.timeLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset(
              'assets/images/app_icon.png',
              width: 38,
              height: 38,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: Color(0xFF0B1C30),
                        ),
                      ),
                    ),
                    Text(
                      timeLabel,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black.withValues(alpha: 0.45),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  body,
                  style: TextStyle(
                    fontSize: 13.5,
                    color: Colors.black.withValues(alpha: 0.65),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
