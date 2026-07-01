import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/ux/app_snackbar.dart';
import '../../../core/widgets/weekly_quota_chip.dart';
import '../../../l10n/app_localizations.dart';
import '../../habits/data/habit_group_repository.dart';
import '../../habits/data/habit_repository.dart';
import '../../habits/domain/habit_group_model.dart';
import '../data/ai_repository.dart';
import '../domain/chat_message.dart';
import '../domain/routine_chat_model.dart';
import 'widgets/chat_bubble.dart';

/// Chat IA sobre una rutina concreta (premium — la ruta va tras PremiumGuard).
/// La IA recibe en backend el contexto completo (hábitos, rachas, 30 días de
/// logs) y puede proponer cambios que se aplican con un toque.
class RoutineChatScreen extends StatefulWidget {
  const RoutineChatScreen({super.key, required this.groupId});

  final String groupId;

  @override
  State<RoutineChatScreen> createState() => _RoutineChatScreenState();
}

/// Mensaje del chat + cambios propuestos asociados (solo mensajes de la IA)
class _RoutineChatEntry {
  final ChatMessage message;
  final RoutineChanges? changes;
  bool applied;

  _RoutineChatEntry(this.message, {this.changes}) : applied = false;
}

class _RoutineChatScreenState extends State<RoutineChatScreen> {
  late final AIRepository _aiRepo;
  late final HabitRepository _habitRepo;
  late final HabitGroupRepository _groupRepo;

  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<_RoutineChatEntry> _entries = [];

  // historial role/text que se reenvía al callable en cada mensaje
  final List<Map<String, String>> _history = [];

  // id estable de esta sesión de chat: el backend cobra la cuota una vez por
  // conversación usando este id, no el history (falsificable). Se genera al
  // abrir la pantalla y no cambia mientras esté abierta.
  late final String _conversationId;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser!.uid;
    _aiRepo = AIRepository(uid: uid);
    _habitRepo = HabitRepository(uid: uid);
    _groupRepo = HabitGroupRepository(uid: uid);
    _conversationId =
        '${DateTime.now().microsecondsSinceEpoch}-${Random().nextInt(1 << 32)}';
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final msg = _controller.text.trim();
    if (msg.isEmpty || _isLoading) return;

    _controller.clear();
    setState(() {
      _entries.add(_RoutineChatEntry(
        ChatMessage(text: msg, isUser: true, timestamp: DateTime.now()),
      ));
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      final response = await _aiRepo.routineChat(
        groupId: widget.groupId,
        message: msg,
        history: _history,
        conversationId: _conversationId,
      );
      _history.add({'role': 'user', 'text': msg});
      _history.add({'role': 'model', 'text': response.coachMessage});

      setState(() {
        _entries.add(_RoutineChatEntry(
          ChatMessage(
            text: response.coachMessage,
            isUser: false,
            timestamp: DateTime.now(),
          ),
          changes: response.changes,
        ));
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _entries.add(_RoutineChatEntry(
          ChatMessage(
            text: e is String ? e : S.of(context).aiConnectionError,
            isUser: false,
            timestamp: DateTime.now(),
            isError: true,
          ),
        ));
        _isLoading = false;
      });
    }
    _scrollToBottom();
  }

  Future<void> _applyChanges(_RoutineChatEntry entry) async {
    final changes = entry.changes;
    if (changes == null || entry.applied) return;

    try {
      for (final update in changes.updates) {
        await _habitRepo.updateHabit(update.habitId, update.fields);
      }
      for (final habit in changes.newHabits) {
        await _habitRepo.createHabit(
          habit.toHabitModel(groupId: widget.groupId),
        );
      }
      if (changes.newHabits.isNotEmpty) {
        await _groupRepo.incrementHabitCount(
          widget.groupId,
          changes.newHabits.length,
        );
      }
      if (!mounted) return;
      setState(() => entry.applied = true);
      AppSnackBar.showSuccess(context, S.of(context).routineChatApplied);
    } catch (_) {
      if (!mounted) return;
      AppSnackBar.showError(context, S.of(context).routineChatApplyError);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final scheme = Theme.of(context).colorScheme;

    return StreamBuilder<HabitGroupModel?>(
      stream: _groupRepo.watchGroup(widget.groupId),
      builder: (context, snapshot) {
        final group = snapshot.data;
        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.routineChatTitle),
                if (group != null)
                  Text(
                    '${group.emoji ?? ''} ${group.title}'.trim(),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
              ],
            ),
            bottom: const PreferredSize(
              preferredSize: Size.fromHeight(34),
              child: Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: EdgeInsets.only(right: 12, bottom: 6),
                  child: WeeklyQuotaChip(featureKey: 'routineChat'),
                ),
              ),
            ),
          ),
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    // +1 por el saludo inicial fijo de la IA
                    itemCount: _entries.length + 1 + (_isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return ChatBubble(
                          message: ChatMessage(
                            text: s.routineChatGreeting(group?.title ?? '...'),
                            isUser: false,
                            timestamp: DateTime.now(),
                          ),
                        );
                      }
                      if (_isLoading && index == _entries.length + 1) {
                        return const Padding(
                          padding: EdgeInsets.all(12),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2.5),
                            ),
                          ),
                        );
                      }
                      final entry = _entries[index - 1];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ChatBubble(message: entry.message),
                          if (entry.changes != null)
                            _ChangesCard(
                              changes: entry.changes!,
                              applied: entry.applied,
                              onApply: () => _applyChanges(entry),
                            ),
                        ],
                      ).animate().fadeIn(duration: 250.ms);
                    },
                  ),
                ),
                // barra de entrada
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _send(),
                          decoration: InputDecoration(
                            hintText: s.routineChatHint,
                            filled: true,
                            fillColor: scheme.surfaceContainerLowest,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: AppTheme.heroGradient,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          onPressed: _isLoading ? null : _send,
                          icon: const Icon(
                            Icons.arrow_upward_rounded,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Tarjeta con los cambios propuestos por la IA y el botón de aplicarlos
class _ChangesCard extends StatelessWidget {
  const _ChangesCard({
    required this.changes,
    required this.applied,
    required this.onApply,
  });

  final RoutineChanges changes;
  final bool applied;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final scheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(left: 36, top: 4, bottom: 8),
      padding: const EdgeInsets.all(14),
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.72,
      ),
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: scheme.primary.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_fix_high_rounded, size: 18, color: scheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  s.routineChatChangesTitle,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          ),
          if (changes.summary.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(changes.summary,
                style: Theme.of(context).textTheme.bodySmall),
          ],
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              if (changes.updates.isNotEmpty)
                _CountChip(label: s.routineChatUpdateCount(changes.updates.length)),
              if (changes.newHabits.isNotEmpty)
                _CountChip(label: s.routineChatNewCount(changes.newHabits.length)),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: applied
                ? FilledButton.tonalIcon(
                    onPressed: null,
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: Text(s.routineChatApplied),
                  )
                : FilledButton.icon(
                    onPressed: onApply,
                    icon: const Icon(Icons.auto_fix_high_rounded, size: 18),
                    label: Text(s.routineChatApply),
                  ),
          ),
        ],
      ),
    );
  }
}

class _CountChip extends StatelessWidget {
  const _CountChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label, style: Theme.of(context).textTheme.labelSmall),
    );
  }
}
