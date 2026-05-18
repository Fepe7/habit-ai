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
import '../../../core/widgets/ux/gradient_fab.dart';
import '../../../core/widgets/ux/empty_state_view.dart';
import '../../../core/widgets/ux/error_state_view.dart';
import '../../../core/widgets/ux/skeletons.dart';
import '../../../features/community/data/community_template_repository.dart';
import 'widgets/edit_habit_sheet.dart';
import 'widgets/create_habit_sheet.dart';
import 'widgets/create_choice_sheet.dart';
import 'widgets/create_group_sheet.dart';
import '../../../features/achievements/data/archivement_repository.dart';
import '../../../features/achievements/data/achievement_checker.dart';
import '../../../features/achievements/presentation/achievement_overlay.dart';
import '../../../features/auth/data/user_repository.dart';

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
        AppSnackBar.showError(context, 'Error al añadir el hábito');
      }
      return;
    }
    if (mounted) {
      AppSnackBar.showSuccess(context, 'Hábito añadido a la rutina');
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
        AppSnackBar.showError(context, 'Error al crear la rutina');
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
        AppSnackBar.showSuccess(context, 'Grupo actualizado');
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, 'Error al actualizar el grupo');
      }
    }
  }

  // Muestra un dialogo para pedir descripcion y publica el grupo como plantilla
  Future<void> _publishTemplate(
      HabitGroupModel group, List<HabitModel> habits) async {
    if (habits.isEmpty) {
      AppSnackBar.showInfo(context, 'El grupo no tiene hábitos, añade al menos uno.');
      return;
    }

    // Verificar perfil público ANTES del diálogo — no exponer datos de usuarios privados
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final profileDoc = await _communityRepo.getAuthorPublicProfile(uid);
    if (profileDoc == null) {
      if (mounted) {
        AppSnackBar.showInfo(
          context,
          'Activa tu perfil público en Ajustes antes de publicar.',
        );
      }
      return;
    }

    final username = profileDoc['username'] as String? ?? uid;
    final displayName = profileDoc['displayName'] as String? ??
        FirebaseAuth.instance.currentUser?.displayName ??
        '';
    final authorPhotoUrl = profileDoc['photoUrl'] as String?;

    if (!mounted) return;

    final descCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Publicar como plantilla'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Se publicarán ${habits.length} hábito${habits.length == 1 ? "" : "s"} '
              'sin datos personales (sin rachas ni historial).',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descCtrl,
              maxLength: 200,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Descripción (opcional)',
                hintText: 'Explica para quién es este plan…',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Publicar'),
          ),
        ],
      ),
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
          content: const Text('Plantilla publicada en la comunidad'),
          backgroundColor: AppTheme.success,
          action: SnackBarAction(
            label: 'Ver',
            onPressed: () => context.go('/community/$templateId'),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.showError(context, 'Error al publicar la plantilla');
    }
  }

  Future<void> _unpublishTemplate(
      String templateId, HabitGroupModel group) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Retirar plantilla'),
        content: const Text(
          'La plantilla desaparecerá del marketplace. '
          'Las copias importadas por otros usuarios no se verán afectadas.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style:
                FilledButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Retirar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await _communityRepo.unpublishTemplate(
        templateId: templateId,
        sourceGroupId: widget.groupId,
      );
      if (!mounted) return;
      AppSnackBar.showSuccess(context, 'Plantilla retirada del marketplace');
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.showError(context, 'Error al retirar la plantilla');
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
      if (mounted) AppSnackBar.showSuccess(context, 'Hábito actualizado');
    } catch (e) {
      if (mounted) AppSnackBar.showError(context, 'Error al actualizar el hábito');
    }
  }

  Future<void> _deleteHabit(HabitModel habit) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar hábito'),
        content: Text(
          '¿Seguro que quieres eliminar "${habit.title}"?\n\n'
          'Se desactivará pero se conservará el historial.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Eliminar'),
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

      if (mounted) AppSnackBar.showSuccess(context, '"${habit.title}" eliminado');
    } catch (e) {
      if (mounted) AppSnackBar.showError(context, 'Error al eliminar el hábito');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

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
                title: const Text('Editar grupo'),
                actions: [
                  if (groupForHeader != null)
                    IconButton(
                      tooltip: isPublished
                          ? 'Retirar del marketplace'
                          : 'Publicar como plantilla',
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
                  tooltip: 'Crear',
                  onTap: _handleFabTap,
                ),
              ),
              body: _GroupBody(
                groupStream: _groupStream,
                habitsStream: _habitsStream,
                groupId: widget.groupId,
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

// Extrae el body para no duplicar los StreamBuilders
class _GroupBody extends StatelessWidget {
  final Stream<HabitGroupModel?> groupStream;
  final Stream<List<HabitModel>> habitsStream;
  final String groupId;
  final Future<void> Function(HabitGroupModel) onEditGroup;
  final Future<void> Function(HabitModel) onEditHabit;
  final Future<void> Function(HabitModel) onDeleteHabit;

  const _GroupBody({
    required this.groupStream,
    required this.habitsStream,
    required this.groupId,
    required this.onEditGroup,
    required this.onEditHabit,
    required this.onDeleteHabit,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return StreamBuilder<HabitGroupModel?>(
      stream: groupStream,
      builder: (context, groupSnap) {
        if (groupSnap.connectionState == ConnectionState.waiting) {
          return const SectionSkeleton(itemCount: 4);
        }

        final group = groupSnap.data;
        if (group == null || !group.isActive) {
          return ErrorStateView(
            message: 'Este grupo ya no existe.',
            icon: Icons.folder_off_rounded,
            onRetry: () => context.go('/'),
          );
        }

        return StreamBuilder<List<HabitModel>>(
          stream: habitsStream,
          builder: (context, habitsSnap) {
            final habits = habitsSnap.data ?? [];

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
                          'Hábitos del grupo',
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${habits.length}',
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(
                                  color: colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ),

                if (habitsSnap.connectionState == ConnectionState.waiting)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: SectionSkeleton(itemCount: 3),
                    ),
                  )
                else if (habits.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyStateView(
                      icon: Icons.inbox_rounded,
                      title: 'Sin hábitos en este grupo',
                      subtitle: 'Añade hábitos con el botón +',
                    ),
                  )
                else
                  SliverList.builder(
                    itemCount: habits.length,
                    itemBuilder: (context, i) {
                      final habit = habits[i];
                      return Padding(
                        key: ValueKey(habit.id),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        child: _GroupHabitTile(
                          habit: habit,
                          onTap: () => context.go('/habit/${habit.id}'),
                          onEdit: () => onEditHabit(habit),
                          onDelete: () => onDeleteHabit(habit),
                        ),
                      ).animate().fadeIn(
                            delay: Duration(milliseconds: 50 * i),
                            duration: 250.ms,
                          );
                    },
                  ),

                const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
              ],
            );
          },
        );
      },
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
                        '$habitCount ${habitCount == 1 ? "hábito" : "hábitos"}',
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

  static const _dayLabels = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final catBg = AppTheme.categoryBg(habit.category);
    final catFg = AppTheme.categoryFg(habit.category);
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
                                _dayLabels[i],
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
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 20),
                        SizedBox(width: 12),
                        Text('Editar'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, size: 20, color: AppTheme.error),
                        const SizedBox(width: 12),
                        Text('Eliminar', style: TextStyle(color: AppTheme.error)),
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
              'Editar grupo',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            // titulo
            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Título del grupo',
                hintText: 'Ej: Rutina de gimnasio',
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 20),

            // emoji
            Text('Emoji', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            TextField(
              controller: _emojiCtrl,
              decoration: const InputDecoration(
                hintText: 'Pega un emoji o déjalo vacío',
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
              label: const Text('Guardar cambios'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
