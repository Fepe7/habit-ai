import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/update_service.dart';
import '../../../l10n/app_localizations.dart';

/// Muestra el diálogo de actualización según [status]:
/// - force: no descartable, solo botón "Actualizar"
/// - soft:  descartable con "Ahora no"
///
/// Llamar con [status] != none. No hace nada si status es none.
Future<void> showUpdateDialogIfNeeded(
  BuildContext context,
  UpdateStatus status,
) async {
  if (status == UpdateStatus.none) return;
  final force = status == UpdateStatus.force;
  final message = UpdateService.instance.updateMessage;
  final storeUrl = UpdateService.instance.storeUrl;
  final s = S.of(context);

  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => PopScope(
      // bloquear el back button en force update
      canPop: !force,
      child: AlertDialog(
        icon: Icon(
          Icons.system_update_rounded,
          size: 40,
          color: Theme.of(ctx).colorScheme.primary,
        ),
        title: Text(
          force ? s.updateForceTitle : s.updateSoftTitle,
          textAlign: TextAlign.center,
        ),
        content: Text(
          message,
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          if (!force)
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(s.updateLater),
            ),
          FilledButton.icon(
            icon: const Icon(Icons.open_in_new_rounded, size: 18),
            label: Text(s.updateNow),
            onPressed: () async {
              await launchUrl(
                Uri.parse(storeUrl),
                mode: LaunchMode.externalApplication,
              );
              // en force update no cerramos el diálogo
              if (!force && ctx.mounted) Navigator.of(ctx).pop();
            },
          ),
        ],
      ),
    ),
  );
}
