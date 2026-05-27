import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../l10n/app_localizations.dart';

/// Helpers de SnackBar uniformes para toda la app
class AppSnackBar {
  AppSnackBar._();

  static void showSuccess(BuildContext context, String message) {
    HapticFeedback.lightImpact();
    _show(
      context,
      message: message,
      icon: Icons.check_circle_rounded,
      color: Theme.of(context).colorScheme.primary,
      duration: const Duration(seconds: 2),
    );
  }

  static void showError(
    BuildContext context,
    String message, {
    VoidCallback? onRetry,
  }) {
    HapticFeedback.heavyImpact();
    _show(
      context,
      message: message,
      icon: Icons.error_outline_rounded,
      color: Theme.of(context).colorScheme.error,
      duration: const Duration(seconds: 4),
      action: onRetry != null
          ? SnackBarAction(
              label: S.of(context)!.snackbarRetry,
              textColor: Colors.white,
              onPressed: onRetry,
            )
          : null,
    );
  }

  static void showInfo(BuildContext context, String message) {
    _show(
      context,
      message: message,
      icon: Icons.info_outline_rounded,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      iconColor: Theme.of(context).colorScheme.onSurfaceVariant,
      textColor: Theme.of(context).colorScheme.onSurfaceVariant,
      duration: const Duration(seconds: 2),
    );
  }

  static void _show(
    BuildContext context, {
    required String message,
    required IconData icon,
    required Color color,
    Color? iconColor,
    Color? textColor,
    Duration duration = const Duration(seconds: 2),
    SnackBarAction? action,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: iconColor ?? Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: textColor ?? Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        duration: duration,
        action: action,
      ),
    );
  }
}
