import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../data/ai_repository.dart';
import '../domain/chat_message.dart';
import '../domain/habit_plan_model.dart';
import '../../habits/data/habit_repository.dart';
import '../../habits/data/habit_group_repository.dart';
import '../../habits/domain/habit_group_model.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_drawer.dart';
import 'widgets/chat_bubble.dart';
import 'widgets/plan_card.dart';
import '../../achievements/data/archivement_repository.dart';
import '../../achievements/data/achievement_checker.dart';
import '../../achievements/presentation/achievement_overlay.dart';
import '../../auth/data/user_repository.dart';

/// Pantalla de chat con el asistente IA
class AIScreen extends StatefulWidget {
  const AIScreen({super.key});

  @override
  State<AIScreen> createState() => _AIScreenState();
}

class _AIScreenState extends State<AIScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _messages = <ChatMessage>[];
  late final AIRepository _aiRepo;
  late final HabitRepository _habitRepo;
  late final HabitGroupRepository _groupRepo;
  late final AchievementChecker _achievementChecker;
  bool _isLoading = false;

  static const _suggestions = [
    'Quiero hacer ejercicio y comer mejor',
    'Necesito ser más productivo',
    'Quiero leer más y dormir mejor',
    'Mejorar mi salud mental',
  ];

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser!.uid;
    _aiRepo = AIRepository(uid: uid);
    _habitRepo = HabitRepository(uid: uid);
    _groupRepo = HabitGroupRepository(uid: uid);
    _achievementChecker = AchievementChecker(
      achievementRepo: AchievementRepository(uid: uid),
      habitRepo: _habitRepo,
      userRepo: UserRepository(uid: uid),
    );

    _messages.add(ChatMessage(
      text: '¡Hola! Soy tu asistente de hábitos. Cuéntame tus metas '
          'y te generaré un plan personalizado.',
      isUser: false,
      timestamp: DateTime.now(),
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage([String? text]) async {
    final msg = text ?? _controller.text.trim();
    if (msg.isEmpty || _isLoading) return;

    _controller.clear();

    setState(() {
      _messages.add(ChatMessage(
        text: msg,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _isLoading = true;
    });

    _scrollToBottom();

    try {
      final plan = await _aiRepo.generatePlan(msg);

      HabitPlanData? planData;
      if (plan.habits.isNotEmpty) {
        planData = HabitPlanData(
          title: plan.planTitle,
          emoji: plan.planEmoji,
          description: plan.planDescription,
          habits: plan.habits
              .map((h) => HabitSuggestion(
                    title: h.title,
                    description: h.description,
                    category: h.category,
                    frequency: h.frequency,
                    targetDays: h.targetDays,
                    suggestedTime: h.suggestedTime,
                  ))
              .toList(),
        );
      }

      setState(() {
        _messages.add(ChatMessage(
          text: plan.coachMessage,
          isUser: false,
          timestamp: DateTime.now(),
          plan: planData,
        ));
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(
          text: e is String
              ? e
              : 'No pude conectar con el asistente. Comprueba tu conexión.',
          isUser: false,
          timestamp: DateTime.now(),
        ));
        _isLoading = false;
      });
    }

    _scrollToBottom();
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

  Future<void> _saveHabits(HabitPlanData plan) async {
    final accepted = plan.habits.where((h) => h.accepted).toList();
    if (accepted.isEmpty) return;

    try {
      final group = HabitGroupModel(
        id: '',
        title: plan.title,
        emoji: plan.emoji,
        createdAt: DateTime.now(),
        habitCount: accepted.length,
      );
      final groupId = await _groupRepo.createGroup(group);

      final habits = accepted
          .map((h) => GeneratedHabitModel(
                title: h.title,
                description: h.description,
                category: h.category,
                frequency: h.frequency,
                targetDays: h.targetDays,
                suggestedTime: h.suggestedTime,
              ).toHabitModel(groupId: groupId))
          .toList();

      await _habitRepo.createHabitsInGroup(habits, groupId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${plan.emoji ?? "✨"} "${plan.title}" — ${accepted.length} hábitos añadidos',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
      return;
    }

    try {
      final unlocked = await _achievementChecker.checkAfterAIPlan();
      if (unlocked.isNotEmpty && mounted) {
        AchievementOverlay.showUnlocked(context, unlocked);
      }
    } catch (_) {}
  }

  bool get _showSuggestions => _messages.length == 1 && !_isLoading;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surfaceContainerLow,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // header asimetrico
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
              child: Row(
                children: [
                  const DrawerMenuButton(),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Asistente IA',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'Powered by Gemini',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // indicador Gemini
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primaryContainer.withValues(alpha: 0.3),
                          AppTheme.primary.withValues(alpha: 0.12),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.auto_awesome_rounded,
                            size: 14, color: scheme.primary),
                        const SizedBox(width: 6),
                        Text(
                          'Gemini',
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: scheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // banner comunidad — solo visible cuando no hay conversación activa
            if (_showSuggestions)
              _CommunityBanner(),

            // lista de mensajes
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                itemCount: _messages.length +
                    (_isLoading ? 1 : 0) +
                    (_showSuggestions ? 1 : 0),
                itemBuilder: (context, index) {
                  if (_showSuggestions && index == _messages.length) {
                    return _SuggestionChips(
                      suggestions: _suggestions,
                      onTap: _sendMessage,
                    );
                  }

                  if (_isLoading &&
                      index == _messages.length + (_showSuggestions ? 1 : 0)) {
                    return const _TypingIndicator();
                  }

                  if (index >= _messages.length) return const SizedBox.shrink();

                  final message = _messages[index];
                  return Column(
                    children: [
                      ChatBubble(message: message)
                          .animate()
                          .fadeIn(duration: 250.ms)
                          .slideY(begin: 0.05),
                      if (message.plan != null)
                        PlanCard(
                          plan: message.plan!,
                          onSave: () => _saveHabits(message.plan!),
                        )
                            .animate()
                            .fadeIn(delay: 100.ms, duration: 350.ms)
                            .slideY(begin: 0.08),
                    ],
                  );
                },
              ),
            ),

            // input bar glassmorphism
            _InputBar(
              controller: _controller,
              isLoading: _isLoading,
              onSend: _sendMessage,
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== INPUT BAR GLASS ====================

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool isLoading;
  final VoidCallback onSend;

  const _InputBar({
    required this.controller,
    required this.isLoading,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bottom = MediaQuery.of(context).padding.bottom;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: EdgeInsets.fromLTRB(16, 10, 16, bottom + 10),
          decoration: BoxDecoration(
            color: scheme.surface.withValues(alpha: 0.72),
            border: Border(
              top: BorderSide(
                color: scheme.outlineVariant.withValues(alpha: 0.15),
              ),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: TextField(
                    controller: controller,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => onSend(),
                    maxLines: 4,
                    minLines: 1,
                    style: Theme.of(context).textTheme.bodyMedium,
                    decoration: InputDecoration(
                      hintText: 'Escribe tus metas...',
                      hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // boton enviar con gradiente
              GestureDetector(
                onTap: isLoading ? null : onSend,
                child: AnimatedOpacity(
                  opacity: isLoading ? 0.5 : 1,
                  duration: const Duration(milliseconds: 200),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: AppTheme.heroGradient,
                      shape: BoxShape.circle,
                      boxShadow: AppTheme.ambientShadow(opacity: 0.15),
                    ),
                    child: isLoading
                        ? const Padding(
                            padding: EdgeInsets.all(14),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                        : const Icon(Icons.send_rounded,
                            color: Colors.white, size: 20),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================== SUGGESTION CHIPS ====================

class _SuggestionChips extends StatelessWidget {
  final List<String> suggestions;
  final ValueChanged<String> onTap;

  const _SuggestionChips({required this.suggestions, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: suggestions.asMap().entries.map((entry) {
          return ActionChip(
            label: Text(
              entry.value,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: scheme.onSurface,
              ),
            ),
            avatar: Icon(Icons.auto_awesome_rounded,
                size: 14, color: scheme.primary),
            backgroundColor: scheme.surfaceContainerLowest,
            side: BorderSide.none,
            elevation: 0,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onPressed: () => onTap(entry.value),
          )
              .animate()
              .fadeIn(
                delay: Duration(milliseconds: 200 + entry.key * 80),
                duration: 300.ms,
              )
              .slideY(begin: 0.15);
        }).toList(),
      ),
    );
  }
}

// ==================== TYPING INDICATOR ====================

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLowest,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(20),
          ),
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: 0.15),
          ),
          boxShadow: AppTheme.ambientShadow(),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: scheme.primary,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Pensando...',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 250.ms);
  }
}

// Banner discreto que invita a explorar plantillas de la comunidad
class _CommunityBanner extends StatelessWidget {
  const _CommunityBanner();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      child: Material(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => context.go("/explore"),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Icon(Icons.storefront_rounded,
                    size: 18, color: scheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "¿Sin ideas? Explora plantillas de la comunidad",
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
                ),
                Icon(Icons.chevron_right_rounded,
                    size: 16, color: scheme.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms);
  }
}
