import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../app.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/widgets/app_drawer.dart';
import '../../../core/widgets/avatar_circle.dart';
import '../../../core/widgets/ux/app_snackbar.dart';
import '../../auth/data/user_repository.dart';
import '../../auth/domain/user_model.dart';
import '../../habits/data/habit_repository.dart';
import '../../profile/data/public_profile_repository.dart';
import '../../profile/presentation/widgets/username_input_sheet.dart';
import '../../../services/notification_service.dart';

/// Pantalla de ajustes — Editorial Vitality
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final UserRepository _userRepo;
  late final PublicProfileRepository _publicProfileRepo;

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser!.uid;
    _userRepo = UserRepository(uid: uid);
    _publicProfileRepo = PublicProfileRepository(uid: uid);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final auth = AuthProvider.of(context);
    final user = auth.currentUser;
    final themeProvider = ThemeProvider.of(context);

    return StreamBuilder<UserModel>(
      stream: _userRepo.watchUser(),
      builder: (context, snapshot) {
        final userData = snapshot.data;

    return Scaffold(
      backgroundColor: scheme.surfaceContainerLow,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 100),
          children: [
            // header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
              child: Row(
                children: [
                  const DrawerMenuButton(),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Ajustes',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // tarjeta de perfil con gradiente hero
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: AppTheme.heroGradient,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: AppTheme.ambientShadow(opacity: 0.14),
                ),
                child: Row(
                  children: [
                    // avatar grande: foto o iniciales
                    _buildSettingsAvatar(
                      context,
                      photoUrl: userData?.photoUrl,
                      initials: _initials(user?.displayName, user?.email),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  (FirebaseAuth.instance.currentUser?.displayName?.isNotEmpty == true
                                          ? FirebaseAuth.instance.currentUser!.displayName!
                                          : FirebaseAuth.instance.currentUser?.email?.split('@').first) ??
                                      'Usuario',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () => _editName(context),
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.18),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.edit_rounded,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.auto_awesome_rounded,
                                  size: 13,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  'HabitAI',
                                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.05),

            const SizedBox(height: 8),

            // perfil público y social
            _SectionLabel(label: 'Comunidad'),
            _SectionGroup(
              children: [
                _PublicProfileTile(
                  userData: userData,
                  publicProfileRepo: _publicProfileRepo,
                  onExplore: () => context.pushNamed('public-profiles-feed'),
                ),
                _SettingsTile(
                  icon: Icons.people_rounded,
                  title: 'Seguidores',
                  subtitle: 'Gestiona tus seguidores y seguidos',
                  onTap: () => context.pushNamed('followers'),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // apariencia
            _SectionLabel(label: 'Apariencia'),
            _SectionGroup(
              children: [
                _ThemeTile(
                  currentMode: themeProvider.themeMode,
                  onChanged: (mode) => themeProvider.setThemeMode(mode),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // general
            _SectionLabel(label: 'General'),
            _SectionGroup(
              children: [
                _SettingsTile(
                  icon: Icons.emoji_events_rounded,
                  title: 'Logros',
                  subtitle: 'Tus logros desbloqueados',
                  onTap: () => context.goNamed('achievements'),
                ),
                const _NotificationsTile(),
              ],
            ),

            const SizedBox(height: 12),

            // informacion
            _SectionLabel(label: 'Información'),
            _SectionGroup(
              children: [
                _SettingsTile(
                  icon: Icons.info_outline_rounded,
                  title: 'Acerca de HabitAI',
                  subtitle: 'Versión 1.0.0 — TFG 2º DAM',
                  onTap: () => _showAbout(context),
                ),
                _SettingsTile(
                  icon: Icons.shield_outlined,
                  title: 'Privacidad',
                  subtitle: 'Retos, perfil y visibilidad',
                  onTap: () => context.pushNamed('privacy-settings'),
                  divider: false,
                ),
              ],
            ),

            const SizedBox(height: 12),

            // sección de escudos de racha y modo enfermedad
            _SectionLabel(label: 'Protección de rachas'),
            _SectionGroup(
              children: [
                // contador de escudos
                _ShieldCountTile(shieldsCount: userData?.shieldsCount ?? 0),
                // modo enfermedad
                _SickModeTile(
                  userData: userData,
                  userRepo: _userRepo,
                ),
              ],
            ),

            const SizedBox(height: 12),

            // cerrar sesion en su propio grupo con color de error
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: AppTheme.ambientShadow(),
                ),
                clipBehavior: Clip.antiAlias,
                child: _SettingsTile(
                  icon: Icons.logout_rounded,
                  title: 'Cerrar sesión',
                  subtitle: null,
                  isDestructive: true,
                  onTap: () => _confirmSignOut(context, auth),
                  divider: false,
                ),
              ),
            ),
          ],
        ),
      ),
    );
    }, // StreamBuilder builder
    ); // StreamBuilder
  }

  Widget _buildSettingsAvatar(
    BuildContext context, {
    required String? photoUrl,
    required String initials,
  }) {
    if (photoUrl != null && photoUrl.isNotEmpty) {
      return SizedBox(
        width: 64,
        height: 64,
        child: ClipOval(
          child: Image.network(
            photoUrl,
            width: 64,
            height: 64,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _buildInitialsAvatar(context, initials),
          ),
        ),
      );
    }
    return _buildInitialsAvatar(context, initials);
  }

  Widget _buildInitialsAvatar(BuildContext context, String initials) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.25),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initials,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
        ),
      ),
    );
  }

  String _initials(String? name, String? email) {
    if (name != null && name.isNotEmpty) {
      final parts = name.split(' ');
      if (parts.length >= 2) {
        return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      }
      return name[0].toUpperCase();
    }
    if (email != null && email.isNotEmpty) return email[0].toUpperCase();
    return 'U';
  }

  void _confirmSignOut(BuildContext context, dynamic auth) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Estás seguro de que quieres cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              auth.signOut();
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
  }

  Future<void> _editName(BuildContext context) async {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) return;

    final current = firebaseUser.displayName ?? '';

    // _EditNameDialog gestiona su propio controller y lo dispone en dispose(),
    // evitando el crash _dependents.isEmpty que ocurre con dispose() manual
    // justo cuando la animación de salida del diálogo todavía corre.
    final newName = await showDialog<String>(
      context: context,
      builder: (_) => _EditNameDialog(initialName: current),
    );

    if (newName == null || newName.isEmpty || newName == current) return;

    try {
      await firebaseUser.updateDisplayName(newName);
      if (mounted) setState(() {});
      if (mounted) AppSnackBar.showSuccess(context, 'Nombre actualizado'); // ignore: use_build_context_synchronously
    } catch (_) {
      if (mounted) AppSnackBar.showError(context, 'No se pudo actualizar el nombre'); // ignore: use_build_context_synchronously
    }
  }

  void _showAbout(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'HabitAI',
      applicationVersion: '1.0.0',
      applicationLegalese: 'Trabajo Final de Grado — 2º DAM\nAndrei Felipe Staicu',
    );
  }
}

// ==================== WIDGETS ====================

/// Etiqueta de sección tipo Manrope headline
class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: scheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

/// Contenedor de grupo de tiles sin divisores visuales duros
class _SectionGroup extends StatelessWidget {
  final List<Widget> children;
  const _SectionGroup({required this.children});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppTheme.ambientShadow(),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(children: children),
      ),
    );
  }
}

/// Tile genérico de ajustes con separador opcional
class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final bool isDestructive;
  final bool divider;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.isDestructive = false,
    this.divider = true,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = isDestructive ? scheme.error : scheme.onSurface;
    final iconColor = isDestructive ? scheme.error : scheme.primary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          leading: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isDestructive
                  ? scheme.errorContainer.withValues(alpha: 0.3)
                  : scheme.primaryContainer.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          title: Text(
            title,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: subtitle != null
              ? Text(
                  subtitle!,
                  style: Theme.of(context).textTheme.bodySmall,
                )
              : null,
          trailing: isDestructive
              ? null
              : Icon(
                  Icons.chevron_right_rounded,
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
                  size: 20,
                ),
          onTap: onTap,
        ),
        if (divider)
          Divider(
            height: 1,
            indent: 70,
            endIndent: 0,
            color: scheme.outlineVariant.withValues(alpha: 0.12),
          ),
      ],
    );
  }
}

/// Selector de tema con SegmentedButton
class _ThemeTile extends StatelessWidget {
  final ThemeMode currentMode;
  final ValueChanged<ThemeMode> onChanged;

  const _ThemeTile({required this.currentMode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: scheme.primaryContainer.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.palette_outlined, size: 18, color: scheme.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tema',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 10),
                SegmentedButton<ThemeMode>(
                  style: SegmentedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    selectedBackgroundColor:
                        scheme.primaryContainer.withValues(alpha: 0.3),
                    selectedForegroundColor: scheme.primary,
                  ),
                  segments: const [
                    ButtonSegment(
                      value: ThemeMode.light,
                      icon: Icon(Icons.light_mode_outlined, size: 16),
                      label: Text('Claro'),
                    ),
                    ButtonSegment(
                      value: ThemeMode.system,
                      icon: Icon(Icons.phone_android_outlined, size: 16),
                      label: Text('Auto'),
                    ),
                    ButtonSegment(
                      value: ThemeMode.dark,
                      icon: Icon(Icons.dark_mode_outlined, size: 16),
                      label: Text('Oscuro'),
                    ),
                  ],
                  selected: {currentMode},
                  onSelectionChanged: (s) => onChanged(s.first),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Tile que muestra los escudos disponibles con tooltip explicativo
class _ShieldCountTile extends StatelessWidget {
  final int shieldsCount;
  const _ShieldCountTile({required this.shieldsCount});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // puntos visuales: hasta 5 escudos
    final shields = List.generate(
      5,
      (i) => Icon(
        i < shieldsCount ? Icons.shield_rounded : Icons.shield_outlined,
        size: 18,
        color: i < shieldsCount
            ? scheme.primary
            : scheme.outlineVariant.withValues(alpha: 0.5),
      ),
    );

    return Tooltip(
      message: 'Gana escudos completando rachas de 7, 30 y 90 días.\n'
          'Úsalos en HabitAI para proteger tu racha si fallas un día.',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            leading: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: scheme.primaryContainer.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.shield_rounded, size: 18, color: scheme.primary),
            ),
            title: Text(
              'Escudos de racha',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: Text(
              '$shieldsCount disponible${shieldsCount == 1 ? '' : 's'} de 5',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: shields,
            ),
          ),
          Divider(
            height: 1,
            indent: 70,
            color: Theme.of(context)
                .colorScheme
                .outlineVariant
                .withValues(alpha: 0.12),
          ),
        ],
      ),
    );
  }
}

/// Tile de perfil público con toggle y botón de explorar
class _PublicProfileTile extends StatefulWidget {
  final UserModel? userData;
  final PublicProfileRepository publicProfileRepo;
  final VoidCallback onExplore;

  const _PublicProfileTile({
    required this.userData,
    required this.publicProfileRepo,
    required this.onExplore,
  });

  @override
  State<_PublicProfileTile> createState() => _PublicProfileTileState();
}

class _PublicProfileTileState extends State<_PublicProfileTile> {
  bool _loading = false;

  bool get _isPublic => widget.userData?.isProfilePublic ?? false;
  String? get _username => widget.userData?.username;

  Future<void> _toggle(BuildContext context) async {
    if (_loading) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (_isPublic && _username != null) {
      // desactivar
      final confirm = await _showDisableConfirm(context);
      if (confirm != true) return;

      setState(() => _loading = true);
      try {
        await widget.publicProfileRepo.disablePublicProfile(_username!);
      } finally {
        if (mounted) setState(() => _loading = false);
      }
    } else {
      // activar: pedir username
      final chosenUsername = await UsernameInputSheet.show(
        context,
        widget.publicProfileRepo,
      );
      if (chosenUsername == null || !mounted) return;

      setState(() => _loading = true);
      try {
        final displayName =
            user.displayName ?? user.email ?? 'Usuario';
        final initials = AvatarCircle.fromName(user.displayName, user.email);
        final ok = await widget.publicProfileRepo.enablePublicProfile(
          username: chosenUsername,
          displayName: displayName,
          avatarInitials: initials,
          photoUrl: widget.userData?.photoUrl,
        );
        if (!mounted) return;
        if (!ok) {
          AppSnackBar.showInfo(context, 'El username ya está ocupado'); // ignore: use_build_context_synchronously
        }
      } finally {
        if (mounted) setState(() => _loading = false);
      }
    }
  }

  Future<void> _changeUsername(BuildContext context) async {
    if (_loading || _username == null) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final newUsername = await UsernameInputSheet.show(
      context,
      widget.publicProfileRepo,
      currentUsername: _username,
    );
    if (newUsername == null || newUsername == _username || !mounted) return;

    setState(() => _loading = true);
    try {
      final displayName = user.displayName ?? user.email ?? 'Usuario';
      final initials = AvatarCircle.fromName(user.displayName, user.email);
      final ok = await widget.publicProfileRepo.changeUsername(
        _username!,
        newUsername,
        displayName,
        initials,
      );
      if (!mounted) return;
      if (!ok) {
        AppSnackBar.showInfo(context, 'El username ya está ocupado'); // ignore: use_build_context_synchronously
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<bool?> _showDisableConfirm(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Desactivar perfil público'),
        content: const Text(
          '¿Seguro? Tu perfil desaparecerá del directorio y liberarás el username.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: const Text('Desactivar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          leading: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: scheme.primaryContainer.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.public_rounded, size: 18, color: scheme.primary),
          ),
          title: Text(
            'Perfil público',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: Text(
            _isPublic && _username != null
                ? '@$_username — visible en el directorio'
                : 'Aparece en el directorio de la comunidad',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          trailing: _loading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Switch(
                  value: _isPublic,
                  onChanged: (_) => _toggle(context),
                ),
        ),
        if (_isPublic) ...[
          Divider(
            height: 1,
            indent: 70,
            color: scheme.outlineVariant.withValues(alpha: 0.12),
          ),
          // Cambiar username
          ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
            leading: const SizedBox(width: 36),
            title: Text(
              'Cambiar @username',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: scheme.primary,
              ),
            ),
            trailing: Icon(Icons.chevron_right_rounded,
                size: 18, color: scheme.onSurfaceVariant.withValues(alpha: 0.4)),
            onTap: () => _changeUsername(context),
          ),
          Divider(
            height: 1,
            indent: 70,
            color: scheme.outlineVariant.withValues(alpha: 0.12),
          ),
        ] else ...[
          Divider(
            height: 1,
            indent: 70,
            color: scheme.outlineVariant.withValues(alpha: 0.12),
          ),
        ],
      ],
    );
  }
}

/// Tile con switch para activar/desactivar todas las notificaciones locales
class _NotificationsTile extends StatefulWidget {
  const _NotificationsTile();

  @override
  State<_NotificationsTile> createState() => _NotificationsTileState();
}

class _NotificationsTileState extends State<_NotificationsTile> {
  bool _enabled = true;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final v = await NotificationService.instance.isEnabled();
    if (mounted) setState(() { _enabled = v; _loading = false; });
  }

  Future<void> _toggle(bool value) async {
    setState(() => _loading = true);
    try {
      if (value) {
        // al activar, pedimos permiso del SO. si lo deniega, no guardamos
        final granted = await NotificationService.instance.requestPermissions();
        if (!granted) {
          if (mounted) {
            AppSnackBar.showInfo(context,
                'Activa las notificaciones en los ajustes del sistema'); // ignore: use_build_context_synchronously
          }
          return;
        }
        await NotificationService.instance.setEnabled(true);
        final uid = FirebaseAuth.instance.currentUser?.uid;
        if (uid != null) {
          final repo = HabitRepository(uid: uid);
          final habits = await repo.getActiveHabits();
          await NotificationService.instance.rescheduleAll(habits);
        }
      } else {
        await NotificationService.instance.setEnabled(false);
        await NotificationService.instance.cancelAll();
      }
      if (mounted) setState(() => _enabled = value);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: scheme.primaryContainer.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(Icons.notifications_outlined, size: 18, color: scheme.primary),
      ),
      title: Text(
        'Notificaciones',
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        _enabled
            ? 'Recibirás recordatorios de tus hábitos'
            : 'Recordatorios desactivados',
        style: Theme.of(context).textTheme.bodySmall,
      ),
      trailing: _loading
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Switch(
              value: _enabled,
              onChanged: _toggle,
            ),
    );
  }
}

/// Tile para activar/desactivar el modo enfermedad
class _SickModeTile extends StatefulWidget {
  final UserModel? userData;
  final UserRepository userRepo;

  const _SickModeTile({required this.userData, required this.userRepo});

  @override
  State<_SickModeTile> createState() => _SickModeTileState();
}

class _SickModeTileState extends State<_SickModeTile> {
  bool _loading = false;

  bool get _isActive {
    final until = widget.userData?.sickModeUntil;
    if (until == null) return false;
    return until.isAfter(DateTime.now());
  }

  String get _subtitle {
    if (_isActive) {
      final until = widget.userData!.sickModeUntil!;
      final diff = until.difference(DateTime.now()).inDays + 1;
      return 'Activo — termina en $diff día${diff == 1 ? '' : 's'}';
    }
    return 'Protege todas las rachas sin gastar escudos';
  }

  Future<void> _toggle() async {
    if (_loading) return;
    setState(() => _loading = true);

    try {
      if (_isActive) {
        await widget.userRepo.cancelSickMode();
      } else {
        // mostrar selector de días
        if (!mounted) return;
        final days = await _showDaysPicker(context);
        if (days == null) {
          setState(() => _loading = false);
          return;
        }
        await widget.userRepo.activateSickMode(days);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<int?> _showDaysPicker(BuildContext context) async {
    int selectedDays = 1;
    return showDialog<int>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          title: const Text('Modo enfermedad'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tus rachas quedarán protegidas durante este período. '
                'Máximo 7 días.',
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('Días: '),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Slider(
                      value: selectedDays.toDouble(),
                      min: 1,
                      max: 7,
                      divisions: 6,
                      label: '$selectedDays día${selectedDays == 1 ? '' : 's'}',
                      onChanged: (v) =>
                          setDlg(() => selectedDays = v.round()),
                    ),
                  ),
                  Text('$selectedDays'),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(null),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(selectedDays),
              child: const Text('Activar'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: scheme.primaryContainer.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(Icons.medical_services_outlined,
            size: 18, color: scheme.primary),
      ),
      title: Text(
        'Modo enfermedad',
        style: Theme.of(context)
            .textTheme
            .bodyLarge
            ?.copyWith(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        _subtitle,
        style: Theme.of(context).textTheme.bodySmall,
      ),
      trailing: _loading
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Switch(
              value: _isActive,
              onChanged: (_) => _toggle(),
            ),
    );
  }
}

/// Diálogo para editar el nombre — gestiona su propio TextEditingController
/// para que dispose() ocurra después de la animación de salida, evitando
/// el assert _dependents.isEmpty que causa crash con dispose() manual prematuro.
class _EditNameDialog extends StatefulWidget {
  final String initialName;
  const _EditNameDialog({required this.initialName});

  @override
  State<_EditNameDialog> createState() => _EditNameDialogState();
}

class _EditNameDialogState extends State<_EditNameDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Cambiar nombre'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        decoration: const InputDecoration(
          hintText: 'Tu nombre',
          counterText: '',
        ),
        maxLength: 40,
        onSubmitted: (v) => Navigator.of(context).pop(v.trim()),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
