import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../l10n/app_localizations.dart';

/// Widget genérico de estado de error con botón opcional de reintento
class ErrorStateView extends StatelessWidget {
  const ErrorStateView({
    super.key,
    required this.message,
    this.title,
    this.onRetry,
    this.icon = Icons.cloud_off_outlined,
  });

  final String message;
  final String? title;
  final VoidCallback? onRetry;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = S.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colorScheme.errorContainer.withValues(alpha: 0.25),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 56, color: colorScheme.error),
            )
                .animate()
                .fadeIn(duration: 400.ms)
                .scale(begin: const Offset(0.85, 0.85), curve: Curves.easeOutBack),

            const SizedBox(height: 24),

            Text(
              title ?? l10n.errorDefault,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            )
                .animate()
                .fadeIn(delay: 100.ms, duration: 350.ms)
                .slideY(begin: 0.2, curve: Curves.easeOutCubic),

            const SizedBox(height: 8),

            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            )
                .animate()
                .fadeIn(delay: 180.ms, duration: 350.ms)
                .slideY(begin: 0.2, curve: Curves.easeOutCubic),

            if (onRetry != null) ...[
              const SizedBox(height: 28),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(l10n.snackbarRetry),
                style: OutlinedButton.styleFrom(
                  foregroundColor: colorScheme.error,
                  side: BorderSide(color: colorScheme.error.withValues(alpha: 0.5)),
                ),
              )
                  .animate()
                  .fadeIn(delay: 280.ms, duration: 350.ms)
                  .slideY(begin: 0.2, curve: Curves.easeOutCubic),
            ],
          ],
        ),
      ),
    );
  }
}
