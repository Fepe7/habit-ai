import 'dart:io';
import 'dart:math' as math;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../core/widgets/ux/app_snackbar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/data/avatar_storage_repository.dart';
import '../../../auth/data/user_repository.dart';
import '../../data/public_profile_repository.dart';

// Bottom sheet para cambiar o quitar la foto de perfil del usuario.
// El recorte cuadrado se hace en Dart puro (sin Activity nativa) para evitar
// problemas de edge-to-edge en Android 15+.
class AvatarPickerSheet extends StatefulWidget {
  final String? currentPhotoUrl;

  const AvatarPickerSheet({super.key, this.currentPhotoUrl});

  static Future<void> show(BuildContext context, {String? currentPhotoUrl}) {
    return showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => AvatarPickerSheet(currentPhotoUrl: currentPhotoUrl),
    );
  }

  @override
  State<AvatarPickerSheet> createState() => _AvatarPickerSheetState();
}

class _AvatarPickerSheetState extends State<AvatarPickerSheet> {
  bool _loading = false;

  Future<void> _pick(ImageSource source) async {
    final picker = ImagePicker();
    // Limitar tamaño antes de procesar para que sea rápido en Dart
    final xFile = await picker.pickImage(
      source: source,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 90,
    );
    if (xFile == null || !mounted) return;

    setState(() => _loading = true);
    try {
      // Recorte cuadrado centrado + resize a 512px (todo en Dart, sin UCrop)
      final bytes = await xFile.readAsBytes();
      final original = img.decodeImage(bytes);
      if (original == null) throw Exception('Imagen inválida');

      final size = math.min(original.width, original.height);
      final x = (original.width - size) ~/ 2;
      final y = (original.height - size) ~/ 2;
      final cropped = img.copyCrop(original, x: x, y: y, width: size, height: size);
      final resized = img.copyResize(cropped, width: 512, height: 512);
      final jpeg = img.encodeJpg(resized, quality: 80);

      final tmp = await getTemporaryDirectory();
      final file = await File('${tmp.path}/avatar_upload.jpg').writeAsBytes(jpeg);

      final uid = FirebaseAuth.instance.currentUser!.uid;
      final url = await AvatarStorageRepository(uid: uid).uploadAvatar(file);
      await UserRepository(uid: uid).updatePhotoUrl(url);
      await PublicProfileRepository(uid: uid).syncPhotoUrl(url);

      if (!mounted) return;
      AppSnackBar.showSuccess(context, S.of(context).avatarPickerUpdated);
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      AppSnackBar.showError(context, S.of(context).avatarPickerUploadError);
      setState(() => _loading = false);
    }
  }

  Future<void> _removePhoto() async {
    setState(() => _loading = true);
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      await AvatarStorageRepository(uid: uid).deleteAvatar();
      await UserRepository(uid: uid).updatePhotoUrl(null);
      await PublicProfileRepository(uid: uid).syncPhotoUrl(null);

      if (!mounted) return;
      AppSnackBar.showSuccess(context, S.of(context).avatarPickerRemoved);
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      AppSnackBar.showError(context, S.of(context).avatarPickerRemoveError);
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (_loading) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 32),
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            S.of(context).avatarPickerProcessing,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 32),
        ],
      );
    }

    final hasPhoto =
        widget.currentPhotoUrl != null && widget.currentPhotoUrl!.isNotEmpty;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: scheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: Text(
                S.of(context).avatarPickerTitle,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            ListTile(
              leading: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.photo_library_rounded,
                    size: 18, color: scheme.primary),
              ),
              title: Text(S.of(context).avatarPickerGallery),
              subtitle: Text(S.of(context).avatarPickerCropNote),
              onTap: () => _pick(ImageSource.gallery),
            ),
            ListTile(
              leading: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.camera_alt_rounded,
                    size: 18, color: scheme.primary),
              ),
              title: Text(S.of(context).avatarPickerCamera),
              subtitle: Text(S.of(context).avatarPickerCropNote),
              onTap: () => _pick(ImageSource.camera),
            ),
            if (hasPhoto)
              ListTile(
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: scheme.errorContainer.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.delete_outline_rounded,
                      size: 18, color: scheme.error),
                ),
                title: Text(
                  S.of(context).avatarPickerRemove,
                  style: TextStyle(color: scheme.error),
                ),
                onTap: _removePhoto,
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
