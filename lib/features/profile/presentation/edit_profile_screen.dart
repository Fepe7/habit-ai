import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/avatar_circle.dart';
import '../../../core/widgets/ux/app_snackbar.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/data/user_repository.dart';
import '../../auth/domain/user_model.dart';
import '../data/public_profile_repository.dart';
import 'widgets/avatar_picker_sheet.dart';
import 'widgets/username_input_sheet.dart';
import '../../../core/router/main_shell.dart';

/// Pantalla unificada de edición de perfil, estilo Instagram.
/// Reúne en un solo sitio la foto, el nombre, el nombre de usuario y la bio.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final UserRepository _userRepo;
  late final PublicProfileRepository _publicProfileRepo;

  final _nameController = TextEditingController();
  final _bioController = TextEditingController();

  bool _saving = false;
  bool _usernameBusy = false;
  bool _prefilled = false;

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser!.uid;
    _userRepo = UserRepository(uid: uid);
    _publicProfileRepo = PublicProfileRepository(uid: uid);
    _prefill();
    // rehabilitar/inhabilitar "Guardar" según el nombre sea válido
    _nameController.addListener(_onNameChanged);
  }

  void _onNameChanged() {
    if (mounted) setState(() {});
  }

  // Precargar nombre y bio una sola vez desde Firestore (los controllers no
  // deben sobreescribirse mientras el usuario escribe).
  Future<void> _prefill() async {
    final user = await _userRepo.getUser();
    if (!mounted || _prefilled) return;
    final authUser = FirebaseAuth.instance.currentUser;
    final name = (user.displayName?.isNotEmpty == true)
        ? user.displayName!
        : (authUser?.displayName ?? '');
    setState(() {
      _nameController.text = name;
      _bioController.text = user.bio ?? '';
      _prefilled = true;
    });
  }

  @override
  void dispose() {
    _nameController.removeListener(_onNameChanged);
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    final name = _nameController.text.trim();
    final bio = _bioController.text.trim();
    if (name.isEmpty) return; // el nombre es obligatorio

    setState(() => _saving = true);
    try {
      await Future.wait([
        _userRepo.updateProfile(displayName: name, bio: bio),
        if (name.isNotEmpty)
          FirebaseAuth.instance.currentUser!.updateDisplayName(name),
        _publicProfileRepo.syncProfileFields(displayName: name, bio: bio),
      ]);
      if (!mounted) return;
      AppSnackBar.showSuccess(context, S.of(context).editProfileSaved);
      context.pop();
    } catch (_) {
      if (!mounted) return;
      AppSnackBar.showError(context, S.of(context).editProfileSaveError);
      setState(() => _saving = false);
    }
  }

  // Reutiliza el UsernameInputSheet y la misma lógica que PrivacySettings:
  // primera vez → enablePublicProfile; ya tiene → changeUsername.
  Future<void> _editUsername(UserModel user) async {
    if (_usernameBusy) return;
    final authUser = FirebaseAuth.instance.currentUser;
    if (authUser == null) return;

    final current = user.username;
    final chosen = await UsernameInputSheet.show(
      context,
      _publicProfileRepo,
      currentUsername: current,
    );
    if (chosen == null || chosen == current || !mounted) return;

    setState(() => _usernameBusy = true);
    try {
      final displayName =
          _nameController.text.trim().isNotEmpty
              ? _nameController.text.trim()
              : (authUser.displayName ?? authUser.email ?? 'Usuario');
      final initials = AvatarCircle.fromName(displayName, authUser.email);
      bool ok;
      if (current == null) {
        ok = await _publicProfileRepo.enablePublicProfile(
          username: chosen,
          displayName: displayName,
          avatarInitials: initials,
          photoUrl: user.photoUrl,
          bio: _bioController.text.trim(),
        );
      } else {
        ok = await _publicProfileRepo.changeUsername(
          current,
          chosen,
          displayName,
          initials,
        );
      }
      if (!mounted) return;
      if (!ok) {
        AppSnackBar.showInfo(context, S.of(context).privacyUsernameTaken);
      } else {
        AppSnackBar.showSuccess(context, S.of(context).editProfileUsernameUpdated);
      }
    } finally {
      if (mounted) setState(() => _usernameBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final s = S.of(context);
    final canSave = _nameController.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        backgroundColor: scheme.surface,
        scrolledUnderElevation: 0,
        title: Text(s.editProfileTitle),
        actions: [
          _saving
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                )
              : TextButton(
                  onPressed: canSave ? _save : null,
                  child: Text(
                    s.editProfileSave,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
        ],
      ),
      body: StreamBuilder<UserModel>(
        stream: _userRepo.watchUser(),
        builder: (context, snap) {
          final user = snap.data ??
              UserModel(
                uid: FirebaseAuth.instance.currentUser!.uid,
                email: FirebaseAuth.instance.currentUser?.email ?? '',
              );
          final authUser = FirebaseAuth.instance.currentUser;
          final initials = AvatarCircle.fromName(
            user.displayName ?? authUser?.displayName,
            user.email,
          );

          return ListView(
            padding: EdgeInsets.fromLTRB(20, 8, 20, context.bottomNavInset),
            children: [
              // avatar + cambiar foto
              Center(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: () => AvatarPickerSheet.show(
                        context,
                        currentPhotoUrl: user.photoUrl,
                      ),
                      child: Stack(
                        children: [
                          AvatarCircle(
                            initials: initials,
                            size: 104,
                            photoUrl: user.photoUrl,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: scheme.primary,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: scheme.surface,
                                  width: 2.5,
                                ),
                              ),
                              child: Icon(
                                Icons.camera_alt_rounded,
                                size: 16,
                                color: scheme.onPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: () => AvatarPickerSheet.show(
                        context,
                        currentPhotoUrl: user.photoUrl,
                      ),
                      child: Text(s.editProfileChangePhoto),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.04, end: 0),

              const SizedBox(height: 8),

              // nombre
              _FieldLabel(s.editProfileNameLabel),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.words,
              ),

              const SizedBox(height: 20),

              // nombre de usuario (abre el sheet)
              _FieldLabel(s.editProfileUsernameLabel),
              const SizedBox(height: 8),
              _UsernameField(
                username: user.username,
                busy: _usernameBusy,
                placeholder: s.editProfileChooseUsername,
                onTap: () => _editUsername(user),
              ),
              const SizedBox(height: 6),
              // el username se reserva al instante (no espera al botón Guardar)
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Text(
                  s.editProfileUsernameHint,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
              ),

              const SizedBox(height: 20),

              // bio
              _FieldLabel(s.editProfileBioLabel),
              const SizedBox(height: 8),
              TextField(
                controller: _bioController,
                maxLines: 4,
                maxLength: 150,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: s.editProfileBioHint,
                  alignLabelWithHint: true,
                ),
              ),

            ],
          );
        },
      ),
    );
  }

}

class _FieldLabel extends StatelessWidget {
  final String label;
  const _FieldLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
      ),
    );
  }
}

/// Campo tappable que muestra el username actual o invita a elegir uno.
class _UsernameField extends StatelessWidget {
  final String? username;
  final bool busy;
  final String placeholder;
  final VoidCallback onTap;

  const _UsernameField({
    required this.username,
    required this.busy,
    required this.placeholder,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasUsername = username != null;

    return Material(
      // mismo fill y radio que los TextField del tema, para que los tres campos coincidan
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: busy ? null : onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Row(
            children: [
              Icon(
                Icons.alternate_email_rounded,
                size: 20,
                color: hasUsername ? scheme.primary : scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  hasUsername ? '@$username' : placeholder,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight:
                            hasUsername ? FontWeight.w700 : FontWeight.w400,
                        color: hasUsername
                            ? scheme.onSurface
                            : scheme.onSurfaceVariant,
                      ),
                ),
              ),
              if (busy)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Icon(
                  Icons.chevron_right_rounded,
                  color: scheme.onSurfaceVariant,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
