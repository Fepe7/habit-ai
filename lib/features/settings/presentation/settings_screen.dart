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
import '../../profile/data/public_profile_repository.dart';
import '../../profile/presentation/widgets/username_input_sheet.dart';

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
                    // avatar grande con iniciales
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          _initials(user?.displayName, user?.email),
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.displayName ?? 'Usuario',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user?.email ?? '',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withValues(alpha: 0.8),
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

            // perfil público
            _SectionLabel(label: 'Comunidad'),
            _SectionGroup(
              children: [
                _PublicProfileTile(
                  userData: userData,
                  publicProfileRepo: _publicProfileRepo,
                  onExplore: () => context.pushNamed('public-profiles-feed'),
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
                _SettingsTile(
                  icon: Icons.notifications_outlined,
                  title: 'Notificaciones',
                  subtitle: 'Recordatorios de hábitos',
                  onTap: () {},
                  divider: false,
                ),
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
                  subtitle: 'Tus datos están protegidos',
                  onTap: () {},
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
