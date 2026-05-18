import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/ux/app_snackbar.dart' show AppSnackBar;
import '../../auth/data/user_repository.dart';
import '../../auth/domain/user_model.dart';
import '../../social/data/user_directory_repository.dart';
import '../../social/domain/privacy_level.dart';

/// Pantalla de ajustes de privacidad: quién puede retar al usuario y ver su perfil.
class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  late final UserRepository _userRepo;
  late final UserDirectoryRepository _dirRepo;

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser!.uid;
    _userRepo = UserRepository(uid: uid);
    _dirRepo = UserDirectoryRepository(uid: uid);
  }

  Future<void> _updateChallengePrivacy(
    UserModel user,
    PrivacyLevel level,
  ) async {
    try {
      await _dirRepo.updatePrivacySettings(challengePrivacy: level);
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, 'Error al guardar: $e');
      }
    }
  }

  Future<void> _updateProfileVisibility(
    UserModel user,
    PrivacyLevel level,
  ) async {
    try {
      await _dirRepo.updatePrivacySettings(profileVisibility: level);
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, 'Error al guardar: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacidad'),
        backgroundColor: scheme.surface,
        scrolledUnderElevation: 0,
      ),
      body: StreamBuilder<UserModel>(
        stream: _userRepo.watchUser(),
        builder: (context, snap) {
          final user = snap.data;
          if (user == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final challengeLevel = PrivacyLevelX.fromString(user.challengePrivacy);
          final profileLevel = PrivacyLevelX.fromString(user.profileVisibility);
          final hasUsername = user.username != null;

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            children: [
              if (!hasUsername)
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: scheme.tertiaryContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline_rounded,
                          color: scheme.onTertiaryContainer),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Necesitas un nombre de usuario para que otros puedan encontrarte.',
                          style: textTheme.bodySmall?.copyWith(
                            color: scheme.onTertiaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(),

              _SectionLabel(label: 'Retos'),
              _PrivacyCard(
                icon: Icons.sports_score_rounded,
                title: 'Quién puede enviarme retos',
                description: 'Controla quién puede invitarte a competir en un hábito',
                selected: challengeLevel,
                enabled: hasUsername,
                onChanged: (level) => _updateChallengePrivacy(user, level),
              ).animate().fadeIn(delay: 100.ms),

              const SizedBox(height: 20),

              _SectionLabel(label: 'Perfil'),
              _PrivacyCard(
                icon: Icons.person_outline_rounded,
                title: 'Quién puede ver mi perfil completo',
                description: 'Stats, hábitos activos y logros en el directorio público',
                selected: profileLevel,
                enabled: hasUsername,
                onChanged: (level) => _updateProfileVisibility(user, level),
              ).animate().fadeIn(delay: 200.ms),

              const SizedBox(height: 20),

              _SectionLabel(label: 'Seguimiento'),
              Container(
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: AppTheme.ambientShadow(),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: SwitchListTile(
                  value: !user.isProfilePublic,
                  onChanged: hasUsername
                      ? (val) {
                          _userRepo.setProfilePublic(!val).catchError((e) {
                            if (mounted) {
                              AppSnackBar.showError(
                                  context, 'Error al guardar: $e');
                            }
                          });
                        }
                      : null,
                  title: const Text(
                    'Perfil privado',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text(
                    'Las solicitudes de seguimiento requieren aprobación',
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
              ).animate().fadeIn(delay: 300.ms),

              const SizedBox(height: 24),

              OutlinedButton.icon(
                onPressed: () => context.pushNamed('followers'),
                icon: const Icon(Icons.people_outline_rounded),
                label: const Text('Gestionar seguidores'),
              ).animate().fadeIn(delay: 300.ms),
            ],
          );
        },
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
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

class _PrivacyCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final PrivacyLevel selected;
  final bool enabled;
  final ValueChanged<PrivacyLevel> onChanged;
  // niveles a mostrar — por defecto los 3, para solicitudes solo 2
  final List<PrivacyLevel> options;

  const _PrivacyCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.selected,
    required this.enabled,
    required this.onChanged,
    this.options = PrivacyLevel.values,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.ambientShadow(),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: scheme.onPrimaryContainer),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    Text(description,
                        style: textTheme.bodySmall
                            ?.copyWith(color: scheme.onSurfaceVariant)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: options.map((level) {
              final isSelected = selected == level;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: GestureDetector(
                    onTap: enabled ? () => onChanged(level) : null,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? scheme.primary
                            : scheme.surfaceContainerHighest
                                .withValues(alpha: enabled ? 0.5 : 0.25),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          level.label,
                          style: textTheme.labelSmall?.copyWith(
                            color: isSelected
                                ? scheme.onPrimary
                                : enabled
                                    ? scheme.onSurface
                                    : scheme.onSurface
                                        .withValues(alpha: 0.4),
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
