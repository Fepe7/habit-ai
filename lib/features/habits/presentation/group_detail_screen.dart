import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../data/habit_repository.dart';
import '../data/habit_group_repository.dart';
import '../domain/habit_model.dart';
import '../domain/habit_group_model.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_bottom_sheet.dart';
import '../../../core/widgets/ux/app_snackbar.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/widgets/avatar_circle.dart';
import '../../../features/profile/data/public_profile_repository.dart';
import '../../../features/profile/presentation/widgets/username_input_sheet.dart';
import '../../../core/widgets/ux/gradient_fab.dart';
import '../../../core/widgets/ux/empty_state_view.dart';
import '../../../core/widgets/ux/error_state_view.dart';
import '../../../core/widgets/ux/skeletons.dart';
import '../../../features/community/data/community_template_repository.dart';
import 'widgets/edit_habit_sheet.dart';
import 'widgets/create_habit_sheet.dart';
import 'widgets/create_choice_sheet.dart';
import 'widgets/create_group_sheet.dart';
import '../../../features/achievements/data/achievement_repository.dart';
import '../../../features/achievements/data/achievement_checker.dart';
import '../../../features/achievements/presentation/achievement_overlay.dart';
import '../../../features/auth/data/user_repository.dart';
import '../../../core/router/main_shell.dart';

// Pantalla de edicion de un grupo de habitos:
// - cabecera editable (emoji + titulo)
// - lista completa de habitos del grupo (sin filtrar por dia)
// - editar/eliminar cada habito
class GroupDetailScreen extends StatefulWidget {
  final String groupId;

  const GroupDetailScreen({super.key, required this.groupId});

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> {
  late final HabitRepository _habitRepo;
  late final HabitGroupRepository _groupRepo;
  late final CommunityTemplateRepository _communityRepo;
  late final AchievementChecker _achievementChecker;
  late final Stream<HabitGroupModel?> _groupStream;
  late final Stream<List<HabitModel>> _habitsStream;

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser!.uid;
    _habitRepo = HabitRepository(uid: uid);
    _groupRepo = HabitGroupRepository(uid: uid);
    _communityRepo = CommunityTemplateRepository(uid: uid);
    _achievementChecker = AchievementChecker(
      achievementRepo: AchievementRepository(uid: uid),
      habitRepo: _habitRepo,
      userRepo: UserRepository(uid: uid),
      publicProfileRepo: PublicProfileRepository(uid: uid),
    );
    _groupStream = _groupRepo.watchGroup(widget.groupId);
    _habitsStream = _habitRepo.watchAllHabitsByGroup(widget.groupId);
  }

  Future<void> _handleFabTap() async {
    final choice = await CreateChoiceSheet.show(context);
    if (choice == null) return;

    if (choice == CreateChoice.habit) {
      await _doAddHabit();
    } else {
      await _doCreateGroup();
    }
  }

  Future<void> _doAddHabit() async {
    final habit = await CreateHabitSheet.show(context, groupId: widget.groupId);
    if (habit == null) return;
    try {
      await _habitRepo.createHabit(habit);
      await _groupRepo.incrementHabitCount(widget.groupId, 1);
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, S.of(context).groupDetailAddHabitError);
      }
      return;
    }
    if (mounted) {
      AppSnackBar.showSuccess(context, S.of(context).groupDetailHabitAdded);
    }
    try {
      final unlocked = await _achievementChecker.checkAfterCreate();
      if (unlocked.isNotEmpty && mounted) {
        AchievementOverlay.showUnlocked(context, unlocked);
      }
    } catch (_) {}
  }

  Future<void> _doCreateGroup() async {
    final group = await CreateGroupSheet.show(context);
    if (group == null || !mounted) return;
    try {
      final groupId = await _groupRepo.createGroup(group);
      if (mounted) context.go('/group/$groupId');
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, S.of(context).habitsGroupCreateError);
      }
    }
  }

  Future<void> _editGroup(HabitGroupModel group) async {
    final result = await _EditGroupSheet.show(context, group);
    if (result == null) return;

    try {
      await _groupRepo.updateGroup(group.id, {
        'title': result.title,
        'emoji': result.emoji,
      });
      if (mounted) {
        AppSnackBar.showSuccess(context, S.of(context).groupDetailGroupUpdated);
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, S.of(context).groupDetailGroupUpdateError);
      }
    }
  }

  /// Garantiza que el usuario tenga un perfil público ACTIVO antes de publicar.
  /// - Si ya lo tiene activo, devuelve sus datos.
  /// - Si nunca lo creó, le ofrece crearlo (username + perfil) en línea.
  /// - Si lo tiene desactivado, le ofrece reactivarlo.
  /// Devuelve el doc del perfil público ya activo, o null si el usuario cancela.
  Future<Map<String, dynamic>?> _ensureActivePublicProfile(String uid) async {
    final profileRepo = PublicProfileRepository(uid: uid);
    final existing = await _communityRepo.getAuthorPublicProfile(uid);

    // Ya tiene perfil; un flag ausente se considera activo (perfil recién creado).
    if (existing != null && (existing['isProfilePublic'] as bool? ?? true)) {
      return existing;
    }

    if (!mounted) return null;
    final s = S.of(context);
    final isDisabled = existing != null; // doc existe pero isProfilePublic == false

    // Diálogo explicativo según el caso (crear vs reactivar)
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.groupDetailPublishNeedPublicTitle),
        content: Text(isDisabled
            ? s.groupDetailPublishReactivateBody
            : s.groupDetailPublishNeedPublicBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(s.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(isDisabled
                ? s.groupDetailPublishReactivateCta
                : s.groupDetailPublishCreateProfileCta),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return null;

    if (isDisabled) {
      // Reactivar: ya tiene username y doc, solo cambia el flag.
      await profileRepo.reenablePublicProfile();
    } else {
      // Primera vez: pedir username y crear el perfil (patrón de privacy_settings_screen).
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;
      final chosenUsername = await UsernameInputSheet.show(context, profileRepo);
      if (chosenUsername == null || !mounted) return null;
      final displayName = user.displayName ?? user.email ?? 'Usuario';
      final initials = AvatarCircle.fromName(user.displayName, user.email);
      final ok = await profileRepo.enablePublicProfile(
        username: chosenUsername,
        displayName: displayName,
        avatarInitials: initials,
        photoUrl: user.photoURL,
      );
      if (!ok) {
        if (mounted) AppSnackBar.showInfo(context, s.privacyUsernameTaken);
        return null;
      }
    }

    // Releer el perfil ya activo para usar sus datos en la publicación.
    return _communityRepo.getAuthorPublicProfile(uid);
  }

  // Muestra un dialogo para pedir descripcion y publica el grupo como plantilla
  Future<void> _publishTemplate(
      HabitGroupModel group, List<HabitModel> habits) async {
    if (habits.isEmpty) {
      AppSnackBar.showInfo(context, S.of(context).groupDetailPublishNoHabits);
      return;
    }

    // Verificar perfil público ANTES del diálogo — no exponer datos de usuarios privados.
    // Si no tiene perfil público (o lo tiene desactivado), se le guía a crearlo/reactivarlo
    // en línea en vez de cortar el flujo. Devuelve null si el usuario se echa atrás.
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final profileDoc = await _ensureActivePublicProfile(uid);
    if (profileDoc == null) return;

    final username = profileDoc['username'] as String? ?? uid;
    final displayName = profileDoc['displayName'] as String? ??
        FirebaseAuth.instance.currentUser?.displayName ??
        '';
    final authorPhotoUrl = profileDoc['photoUrl'] as String?;

    if (!mounted) return;

    final descCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final s = S.of(ctx);
        return AlertDialog(
          title: Text(s.groupDetailPublishTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(s.groupDetailPublishBody(habits.length)),
              const SizedBox(height: 16),
              TextField(
                controller: descCtrl,
                maxLength: 200,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: s.groupDetailPublishDescLabel,
                  hintText: s.groupDetailPublishDescHint,
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(s.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(s.groupDetailPublishConfirm),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    try {
      final templateId = await _communityRepo.publishTemplate(
        group: group,
        habits: habits,
        authorUsername: username,
        authorDisplayName: displayName,
        description: descCtrl.text.trim(),
        authorPhotoUrl: authorPhotoUrl,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(S.of(context).groupDetailPublishSuccess),
          backgroundColor: AppTheme.success,
          action: SnackBarAction(
            label: S.of(context).groupDetailViewAction,
            onPressed: () => context.push('/community/$templateId'),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.showError(context, S.of(context).groupDetailPublishError);
    }
  }

  Future<void> _unpublishTemplate(
      String templateId, HabitGroupModel group) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final s = S.of(ctx);
        return AlertDialog(
          title: Text(s.groupDetailUnpublishTitle),
          content: Text(s.groupDetailUnpublishContent),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(s.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style:
                  FilledButton.styleFrom(backgroundColor: AppTheme.error),
              child: Text(s.groupDetailUnpublishConfirm),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) return;

    try {
      await _communityRepo.unpublishTemplate(
        templateId: templateId,
        sourceGroupId: widget.groupId,
      );
      if (!mounted) return;
      AppSnackBar.showSuccess(context, S.of(context).groupDetailUnpublishSuccess);
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.showError(context, S.of(context).groupDetailUnpublishError);
    }
  }

  Future<void> _editHabit(HabitModel habit) async {
    final updated = await EditHabitSheet.show(context, habit);
    if (updated == null) return;

    try {
      await _habitRepo.updateHabit(habit.id, {
        'title': updated.title,
        'description': updated.description,
        'category': updated.category,
        'frequency': updated.frequency,
        'targetDays': updated.targetDays,
        'reminderTime': updated.reminderTime,
      });
      if (updated.groupId != habit.groupId) {
        await _habitRepo.reassignGroup(habit.id, habit.groupId, updated.groupId);
      }
      if (mounted) AppSnackBar.showSuccess(context, S.of(context).habitsUpdated);
    } catch (e) {
      if (mounted) AppSnackBar.showError(context, S.of(context).habitsUpdateError);
    }
  }

  Future<void> _deleteHabit(HabitModel habit) async {
    final s = S.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.habitsDeleteSingleTitle),
        content: Text(s.habitsDeleteSingleContent(habit.title)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(s.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppTheme.error),
            child: Text(s.habitDetailDelete),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _habitRepo.deactivateHabit(habit.id);

      // decrementar el contador del grupo
      try {
        await _groupRepo.incrementHabitCount(widget.groupId, -1);
      } catch (_) {}

      if (mounted) AppSnackBar.showSuccess(context, S.of(context).habitsDeleteSingleSuccess(habit.title));
    } catch (e) {
      if (mounted) AppSnackBar.showError(context, S.of(context).habitsDeleteSingleError);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final s = S.of(context);

    return StreamBuilder<HabitGroupModel?>(
      stream: _groupStream,
      builder: (context, groupHeaderSnap) {
        final groupForHeader = groupHeaderSnap.data;
        return StreamBuilder<List<HabitModel>>(
          stream: _habitsStream,
          builder: (context, habitsHeaderSnap) {
            final habitsForHeader = habitsHeaderSnap.data ?? [];
            final isPublished =
                groupForHeader?.publishedTemplateId != null;
            return Scaffold(
              appBar: AppBar(
                title: Text(s.groupDetailEditTitle),
                actions: [
                  if (groupForHeader != null)
                    IconButton(
                      tooltip: isPublished
                          ? s.groupDetailUnpublishTooltip
                          : s.groupDetailPublishTooltip,
                      icon: Icon(
                        isPublished
                            ? Icons.cloud_done_rounded
                            : Icons.cloud_upload_outlined,
                        color: isPublished ? colorScheme.primary : null,
                      ),
                      onPressed: () => isPublished
                          ? _unpublishTemplate(
                              groupForHeader.publishedTemplateId!,
                              groupForHeader,
                            )
                          : _publishTemplate(
                              groupForHeader,
                              habitsForHeader,
                            ),
                    ),
                ],
              ),
              floatingActionButton: Padding(
                padding: const EdgeInsets.only(bottom: 100),
                child: GradientFab(
                  tooltip: s.habitsCreate,
                  onTap: _handleFabTap,
                ),
              ),
              // Reutilizamos los snapshots ya resueltos por los StreamBuilders de
              // arriba: los streams de Firestore (snapshots()) son de suscripción
              // única, así que no podemos volver a escucharlos dentro de _GroupBody
              // o el body se quedaría cargando indefinidamente.
              body: _GroupBody(
                group: groupForHeader,
                groupWaiting:
                    groupHeaderSnap.connectionState == ConnectionState.waiting,
                habits: habitsForHeader,
                habitsWaiting:
                    habitsHeaderSnap.connectionState == ConnectionState.waiting,
                onEditGroup: _editGroup,
                onEditHabit: _editHabit,
                onDeleteHabit: _deleteHabit,
              ),
            );
          },
        );
      },
    );
  }
}

// Renderiza el body a partir de los snapshots YA resueltos por los StreamBuilders
// de GroupDetailScreen. No vuelve a escuchar los streams (serían una segunda
// suscripción sobre un stream de suscripción única de Firestore → carga infinita).
class _GroupBody extends StatelessWidget {
  final HabitGroupModel? group;
  final bool groupWaiting;
  final List<HabitModel> habits;
  final bool habitsWaiting;
  final Future<void> Function(HabitGroupModel) onEditGroup;
  final Future<void> Function(HabitModel) onEditHabit;
  final Future<void> Function(HabitModel) onDeleteHabit;

  const _GroupBody({
    required this.group,
    required this.groupWaiting,
    required this.habits,
    required this.habitsWaiting,
    required this.onEditGroup,
    required this.onEditHabit,
    required this.onDeleteHabit,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final s = S.of(context);

    if (groupWaiting) {
      return const SectionSkeleton(itemCount: 4);
    }

    final group = this.group;
    if (group == null || !group.isActive) {
      return ErrorStateView(
        message: s.groupDetailNotFound,
        icon: Icons.folder_off_rounded,
        onRetry: () => context.go('/'),
      );
    }

    return CustomScrollView(
      slivers: [
        // cabecera editable
        SliverToBoxAdapter(
          child: _GroupHeader(
            group: group,
            habitCount: habits.length,
            onEdit: () => onEditGroup(group),
          ),
        ),

        // separador
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: Row(
              children: [
                Icon(Icons.list_alt_rounded,
                    size: 18, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  s.groupDetailHabitsHeader,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${habits.length}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ),

        if (habitsWaiting)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: SectionSkeleton(itemCount: 3),
            ),
          )
        else if (habits.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: EmptyStateView(
              icon: Icons.inbox_rounded,
              title: s.groupDetailEmptyTitle,
              subtitle: s.groupDetailEmptySubtitle,
            ),
          )
        else
          SliverList.builder(
            itemCount: habits.length,
            itemBuilder: (context, i) {
              final habit = habits[i];
              return Padding(
                key: ValueKey(habit.id),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: _GroupHabitTile(
                  habit: habit,
                  onTap: () => context.push('/habit/${habit.id}'),
                  onEdit: () => onEditHabit(habit),
                  onDelete: () => onDeleteHabit(habit),
                ),
              ).animate().fadeIn(
                    delay: Duration(milliseconds: 50 * i),
                    duration: 250.ms,
                  );
            },
          ),

        SliverPadding(padding: EdgeInsets.only(bottom: context.bottomNavInset)),
      ],
    );
  }
}

// ==================== CABECERA DEL GRUPO ====================

class _GroupHeader extends StatelessWidget {
  final HabitGroupModel group;
  final int habitCount;
  final VoidCallback onEdit;

  const _GroupHeader({
    required this.group,
    required this.habitCount,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onEdit,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // emoji grande o icono de carpeta
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  alignment: Alignment.center,
                  child: group.emoji != null
                      ? Text(group.emoji!, style: const TextStyle(fontSize: 32))
                      : Icon(Icons.star,
                          size: 32, color: colorScheme.primary),
                ),
                const SizedBox(width: 16),

                // titulo y conteo
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group.title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        S.of(context).exploreHabitCount(habitCount),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),

                Icon(Icons.edit_outlined,
                    size: 20, color: colorScheme.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ==================== TILE DE HABITO EN LA LISTA ====================

class _GroupHabitTile extends StatelessWidget {
  final HabitModel habit;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _GroupHabitTile({
    required this.habit,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final s = S.of(context);
    final dayLabels = [
      s.weekdayLShort,
      s.weekdayMShort,
      s.weekdayXShort,
      s.weekdayJShort,
      s.weekdayVShort,
      s.weekdaySShort,
      s.weekdayDShort,
    ];
    final catBg = AppTheme.categoryBg(habit.category, colorScheme.brightness);
    final catFg = AppTheme.categoryFg(habit.category, colorScheme.brightness);
    final catIcon = AppTheme.categoryIcon(habit.category);

    return Card(
      child: InkWell(
        onTap: onTap,
        onLongPress: onEdit,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
          child: Row(
            children: [
              // icono de categoria
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: catBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(catIcon, color: catFg, size: 20),
              ),
              const SizedBox(width: 12),

              // info del habito
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      habit.title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (habit.description.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        habit.description,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 6),
                    // dias activos del habito
                    Row(
                      children: [
                        ...List.generate(7, (i) {
                          final day = i + 1;
                          final active = habit.targetDays.contains(day);
                          return Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Container(
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: active
                                    ? colorScheme.primary
                                    : Colors.transparent,
                                border: Border.all(
                                  color: active
                                      ? colorScheme.primary
                                      : colorScheme.outlineVariant,
                                  width: 1,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                dayLabels[i],
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: active
                                      ? colorScheme.onPrimary
                                      : colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          );
                        }),
                        if (habit.reminderTime != null) ...[
                          const SizedBox(width: 8),
                          Icon(Icons.schedule,
                              size: 12, color: colorScheme.onSurfaceVariant),
                          const SizedBox(width: 2),
                          Text(
                            habit.reminderTime!,
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // menu editar/eliminar
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert,
                    size: 20, color: colorScheme.onSurfaceVariant),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onSelected: (value) {
                  if (value == 'edit') onEdit();
                  if (value == 'delete') onDelete();
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        const Icon(Icons.edit_outlined, size: 20),
                        const SizedBox(width: 12),
                        Text(s.commonEdit),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        const Icon(Icons.delete_outline, size: 20, color: AppTheme.error),
                        const SizedBox(width: 12),
                        Text(s.habitDetailDelete, style: const TextStyle(color: AppTheme.error)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================== BOTTOM SHEET PARA EDITAR EL GRUPO ====================

class _EditGroupSheet extends StatefulWidget {
  final HabitGroupModel group;

  const _EditGroupSheet({required this.group});

  static Future<HabitGroupModel?> show(
      BuildContext context, HabitGroupModel group) {
    return showAppBottomSheet<HabitGroupModel>(
      context: context,
      builder: (_) => _EditGroupSheet(group: group),
    );
  }

  @override
  State<_EditGroupSheet> createState() => _EditGroupSheetState();
}

class _EditGroupSheetState extends State<_EditGroupSheet> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _emojiCtrl;

  // emojis sugeridos para elegir rapido
  static const _suggestedEmojis = [
    '🏋️', '🏃', '🧘', '📚', '✍️', '💻', '🎨', '🎵',
    '🥗', '💧', '😴', '🌱', '💡', '🎯', '⭐', '🔥',
  ];

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.group.title);
    _emojiCtrl = TextEditingController(text: widget.group.emoji ?? '');
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _emojiCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) return;

    final emoji = _emojiCtrl.text.trim();
    // construimos el modelo directamente porque copyWith hace `emoji ?? this.emoji`
    // y no permitiria borrar el emoji existente
    final updated = HabitGroupModel(
      id: widget.group.id,
      title: title,
      emoji: emoji.isEmpty ? null : emoji,
      createdAt: widget.group.createdAt,
      conversationId: widget.group.conversationId,
      habitCount: widget.group.habitCount,
      isActive: widget.group.isActive,
    );
    Navigator.of(context).pop(updated);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final s = S.of(context);

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            Text(
              s.groupDetailEditTitle,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            // titulo
            TextField(
              controller: _titleCtrl,
              decoration: InputDecoration(
                labelText: s.groupDetailEditNameLabel,
                hintText: s.groupDetailEditNameHint,
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 20),

            // emoji
            Text(s.createGroupEmojiLabel, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            TextField(
              controller: _emojiCtrl,
              decoration: InputDecoration(
                hintText: s.groupDetailEditEmojiHint,
              ),
              maxLength: 2,
              // refrescar la paleta para que el chip activo cambie
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                // chip "sin emoji" para limpiarlo de un toque
                InkWell(
                  onTap: () => setState(() => _emojiCtrl.clear()),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _emojiCtrl.text.isEmpty
                          ? colorScheme.primaryContainer
                          : colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _emojiCtrl.text.isEmpty
                            ? colorScheme.primary
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.do_not_disturb_alt_rounded,
                      size: 22,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                ..._suggestedEmojis.map((e) {
                  final selected = _emojiCtrl.text == e;
                  return InkWell(
                    onTap: () => setState(() => _emojiCtrl.text = e),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: selected
                            ? colorScheme.primaryContainer
                            : colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: selected
                              ? colorScheme.primary
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(e, style: const TextStyle(fontSize: 22)),
                    ),
                  );
                }),
              ],
            ),
            const SizedBox(height: 24),

            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save_rounded),
              label: Text(s.editHabitSaveCta),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
