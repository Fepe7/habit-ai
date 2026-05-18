import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../data/community_template_repository.dart';
import '../domain/community_template_model.dart';
import '../domain/template_habit_snapshot.dart';

/// Pantalla de detalle de una plantilla de la comunidad con preview de habitos
/// e importacion con un tap.
class CommunityTemplateDetailScreen extends StatefulWidget {
  final String templateId;

  const CommunityTemplateDetailScreen({super.key, required this.templateId});

  @override
  State<CommunityTemplateDetailScreen> createState() =>
      _CommunityTemplateDetailScreenState();
}

class _CommunityTemplateDetailScreenState
    extends State<CommunityTemplateDetailScreen> {
  late final CommunityTemplateRepository _repo;

  CommunityTemplateModel? _template;
  List<TemplateHabitSnapshot> _habits = [];
  Map<String, dynamic>? _authorProfile;
  bool _loading = true;
  bool _importing = false;
  String? _error;

  bool get _isMyTemplate =>
      _template?.authorUid == FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser!.uid;
    _repo = CommunityTemplateRepository(uid: uid);
    _load();
  }

  Future<void> _load() async {
    try {
      final template = await _repo.getTemplate(widget.templateId);
      if (template == null) {
        if (mounted) setState(() => _error = 'Plantilla no encontrada');
        return;
      }

      // cargar habitos y perfil del autor en paralelo
      final results = await Future.wait([
        _repo.getTemplateHabits(widget.templateId),
        _repo.getAuthorPublicProfile(template.authorUid),
      ]);

      if (!mounted) return;
      setState(() {
        _template = template;
        _habits = results[0] as List<TemplateHabitSnapshot>;
        _authorProfile = results[1] as Map<String, dynamic>?;
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _error = 'Error al cargar la plantilla');
    }
  }

  Future<void> _import() async {
    if (_template == null || _importing) return;

    setState(() => _importing = true);
    try {
      final groupId = await _repo.importTemplate(
        template: _template!,
        habits: _habits,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${_template!.emoji ?? "✨"} "${_template!.title}" importado a tus hábitos',
          ),
          backgroundColor: AppTheme.success,
        ),
      );
      // navegar al nuevo grupo
      context.go('/group/$groupId');
    } catch (e) {
      if (mounted) {
        setState(() => _importing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Error al importar la plantilla'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  Future<void> _report() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reportar plantilla'),
        content: const Text(
          '¿Quieres reportar esta plantilla por contenido inapropiado? '
          'Será revisada por el equipo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Reportar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await _repo.reportTemplate(widget.templateId);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Reporte enviado, gracias')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bottomPad =
        MediaQuery.of(context).padding.bottom + kBottomNavigationBarHeight + 16;

    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(_error!)),
      );
    }

    final t = _template!;
    final bgColor = AppTheme.categoryBg(t.category);
    final fgColor = AppTheme.categoryFg(t.category);

    // nombre para mostrar del autor (del perfil publico si existe)
    final authorName = (_authorProfile?['displayName'] as String?) ??
        (t.authorDisplayName.isNotEmpty
            ? t.authorDisplayName
            : '@${t.authorUsername}');
    final authorUid = t.authorUid;
    final hasPublicProfile = _authorProfile != null;

    return Scaffold(
      backgroundColor: scheme.surfaceContainerLow,
      body: CustomScrollView(
        slivers: [
          // cabecera
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            actions: [
              if (!_isMyTemplate)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded),
                  onSelected: (v) {
                    if (v == 'report') _report();
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: 'report',
                      child: Row(
                        children: [
                          Icon(Icons.flag_outlined, size: 18),
                          SizedBox(width: 8),
                          Text('Reportar'),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      bgColor,
                      scheme.surfaceContainerLow,
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 56, 20, 12),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            // emoji / icono
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: bgColor,
                                borderRadius: BorderRadius.circular(18),
                              ),
                              alignment: Alignment.center,
                              child: t.emoji != null
                                  ? Text(t.emoji!,
                                      style:
                                          const TextStyle(fontSize: 30))
                                  : Icon(
                                      AppTheme.categoryIcon(t.category),
                                      size: 28,
                                      color: fgColor,
                                    ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    t.title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  // chips de stats
                                  Row(
                                    children: [
                                      _StatChip(
                                        icon: Icons.checklist_rounded,
                                        label: '${t.habitCount} hábitos',
                                      ),
                                      const SizedBox(width: 6),
                                      _StatChip(
                                        icon: Icons.download_rounded,
                                        label: '${t.importCount} imports',
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // categoria
                  Wrap(
                    spacing: 8,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(AppTheme.categoryIcon(t.category),
                                size: 13, color: fgColor),
                            const SizedBox(width: 4),
                            Text(
                              AppTheme.categoryLabel(t.category),
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: fgColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // descripcion
                  if (t.description.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Text(
                      t.description,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],

                  // autor
                  const SizedBox(height: 14),
                  GestureDetector(
                    onTap: hasPublicProfile
                        ? () => context.go('/profiles/$authorUid')
                        : null,
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: scheme.primaryContainer,
                          child: Text(
                            authorName.isNotEmpty
                                ? authorName[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              fontSize: 12,
                              color: scheme.onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Por $authorName',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                        if (hasPublicProfile) ...[
                          const SizedBox(width: 4),
                          Icon(Icons.open_in_new_rounded,
                              size: 12,
                              color: scheme.primary),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                  Divider(color: scheme.outlineVariant.withValues(alpha: 0.3)),
                  const SizedBox(height: 12),

                  // header habitos
                  Row(
                    children: [
                      Icon(Icons.list_alt_rounded,
                          size: 18, color: scheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Hábitos incluidos',
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ).animate().fadeIn(duration: 300.ms),
          ),

          // lista de habitos preview
          SliverList.builder(
            itemCount: _habits.length,
            itemBuilder: (context, i) {
              final h = _habits[i];
              return _HabitPreviewTile(habit: h)
                  .animate()
                  .fadeIn(
                    delay: Duration(milliseconds: 50 * i),
                    duration: 250.ms,
                  );
            },
          ),

          // padding inferior + boton importar
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 20, 16, bottomPad),
              child: _isMyTemplate
                  ? OutlinedButton.icon(
                      onPressed: null,
                      icon: const Icon(Icons.check_circle_outline_rounded),
                      label: const Text('Esta es tu plantilla'),
                    )
                  : FilledButton.icon(
                      onPressed: _importing ? null : _import,
                      icon: _importing
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white),
                            )
                          : const Icon(Icons.download_rounded),
                      label: Text(_importing
                          ? 'Importando…'
                          : 'Importar a mis hábitos'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                      ),
                    ),
            ).animate().fadeIn(delay: 200.ms, duration: 300.ms),
          ),
        ],
      ),
    );
  }
}

// ==================== INTERNOS ====================

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _StatChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: scheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}

class _HabitPreviewTile extends StatelessWidget {
  final TemplateHabitSnapshot habit;

  const _HabitPreviewTile({required this.habit});

  static const _dayLabels = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bgColor = AppTheme.categoryBg(habit.category);
    final fgColor = AppTheme.categoryFg(habit.category);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // icono de categoria
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Icon(AppTheme.categoryIcon(habit.category),
                    size: 18, color: fgColor),
              ),
              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      habit.title,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    if (habit.description.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        habit.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                    ],
                    const SizedBox(height: 6),
                    // dias de la semana
                    Row(
                      children: [
                        ...List.generate(7, (i) {
                          final day = i + 1;
                          final active = habit.targetDays.contains(day);
                          return Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                color: active
                                    ? scheme.primary
                                    : scheme.surfaceContainerHigh,
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                _dayLabels[i],
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: active
                                      ? scheme.onPrimary
                                      : scheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          );
                        }),
                        // hora si existe
                        if (habit.reminderTime != null) ...[
                          const SizedBox(width: 8),
                          Icon(Icons.alarm_rounded,
                              size: 12, color: scheme.onSurfaceVariant),
                          const SizedBox(width: 3),
                          Text(
                            habit.reminderTime!,
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(color: scheme.onSurfaceVariant),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
