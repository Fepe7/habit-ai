import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/main_shell.dart';
import '../data/ai_repository.dart';
import '../domain/chat_message.dart';
import '../domain/habit_plan_model.dart';
import '../../habits/data/habit_repository.dart';
import '../../habits/data/habit_group_repository.dart';
import '../../habits/domain/habit_group_model.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_drawer.dart';
import '../../../core/widgets/ux/app_snackbar.dart';
import '../../../l10n/app_localizations.dart';
import 'widgets/chat_bubble.dart';
import 'widgets/plan_card.dart';
import '../../achievements/data/achievement_repository.dart';
import '../../../core/services/ai_availability_service.dart';
import '../../../core/services/analytics_service.dart';
import '../../../core/services/connectivity_service.dart';
import '../../achievements/data/achievement_checker.dart';
import '../../profile/data/public_profile_repository.dart';
import '../../achievements/presentation/achievement_overlay.dart';
import '../../auth/data/user_repository.dart';

/// Pantalla de chat con el asistente IA
class AIScreen extends StatefulWidget {
  const AIScreen({super.key});

  @override
  State<AIScreen> createState() => _AIScreenState();
}

class _AIScreenState extends State<AIScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _messages = <ChatMessage>[];
  late final AIRepository _aiRepo;
  late final HabitRepository _habitRepo;
  late final HabitGroupRepository _groupRepo;
  late final AchievementChecker _achievementChecker;
  bool _isLoading = false;
  bool _isAiPaused = false;
  String? _lastUserMessage;
  String? _userName;

  @override
  void initState() {
    super.initState();
    final firebaseUser = FirebaseAuth.instance.currentUser!;
    final uid = firebaseUser.uid;
    _userName =
        firebaseUser.displayName ?? firebaseUser.email?.split('@').first;
    _aiRepo = AIRepository(uid: uid);
    _habitRepo = HabitRepository(uid: uid);
    _groupRepo = HabitGroupRepository(uid: uid);
    _achievementChecker = AchievementChecker(
      achievementRepo: AchievementRepository(uid: uid),
      habitRepo: _habitRepo,
      userRepo: UserRepository(uid: uid),
      publicProfileRepo: PublicProfileRepository(uid: uid),
    );

    _isAiPaused = AiAvailabilityService.instance.isPaused.value;
    AiAvailabilityService.instance.isPaused.addListener(_onAiPausedChanged);

    _messages.add(
      ChatMessage(
        // TODO: i18n — no se puede usar S.of(context) en initState
        text:
            '¡Hola! Soy tu asistente de hábitos. Cuéntame tus metas '
            'y te generaré un plan personalizado.',
        isUser: false,
        timestamp: DateTime.now(),
      ),
    );
  }

  void _onAiPausedChanged() {
    if (mounted)
      setState(
        () => _isAiPaused = AiAvailabilityService.instance.isPaused.value,
      );
  }

  @override
  void dispose() {
    AiAvailabilityService.instance.isPaused.removeListener(_onAiPausedChanged);
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage([String? text]) async {
    final msg = text ?? _controller.text.trim();
    if (msg.isEmpty || _isLoading) return;

    // el asistente IA necesita red (las llamadas van a Cloud Functions)
    if (!ConnectivityService.instance.isOnline.value) {
      if (mounted) {
        AppSnackBar.showInfo(context, S.of(context).aiOfflineError);
      }
      return;
    }

    if (_isAiPaused) {
      if (mounted) {
        AppSnackBar.showInfo(context, S.of(context).aiPausedMessage);
      }
      return;
    }

    _controller.clear();
    _lastUserMessage = msg;

    setState(() {
      _messages.add(
        ChatMessage(text: msg, isUser: true, timestamp: DateTime.now()),
      );
      _isLoading = true;
    });

    _scrollToBottom();

    try {
      AnalyticsService.instance.logAIChat();
      final plan = await _aiRepo.generatePlan(msg);

      HabitPlanData? planData;
      if (plan.habits.isNotEmpty) {
        planData = HabitPlanData(
          title: plan.planTitle,
          emoji: plan.planEmoji,
          description: plan.planDescription,
          habits: plan.habits
              .map(
                (h) => HabitSuggestion(
                  title: h.title,
                  description: h.description,
                  category: h.category,
                  frequency: h.frequency,
                  targetDays: h.targetDays,
                  suggestedTime: h.suggestedTime,
                ),
              )
              .toList(),
        );
      }

      setState(() {
        _messages.add(
          ChatMessage(
            text: plan.coachMessage,
            isUser: false,
            timestamp: DateTime.now(),
            plan: planData,
          ),
        );
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _messages.add(
          ChatMessage(
            text: S.of(context).aiConnectionError,
            isUser: false,
            timestamp: DateTime.now(),
            isError: true,
          ),
        );
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
          .map(
            (h) => GeneratedHabitModel(
              title: h.title,
              description: h.description,
              category: h.category,
              frequency: h.frequency,
              targetDays: h.targetDays,
              suggestedTime: h.suggestedTime,
            ).toHabitModel(groupId: groupId),
          )
          .toList();

      await _habitRepo.createHabitsInGroup(habits, groupId);

      if (mounted) {
        AppSnackBar.showSuccess(
          context,
          '${plan.emoji ?? "✨"} "${plan.title}" — ${S.of(context).aiHabitsAdded(accepted.length)}',
        );
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, S.of(context).aiSaveError);
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
    super.build(context);
    final scheme = Theme.of(context).colorScheme;
    final s = S.of(context);
    final suggestions = [
      s.aiSuggestion1,
      s.aiSuggestion2,
      s.aiSuggestion3,
      s.aiSuggestion4,
    ];

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
                          s.aiTitle,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          _userName != null ? 'Hola, $_userName' : s.aiSubtitle,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // banner comunidad — solo visible cuando no hay conversación activa
            if (_showSuggestions) _CommunityBanner(),

            // lista de mensajes
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: EdgeInsets.fromLTRB(16, 8, 16, context.bottomNavInset),
                itemCount:
                    _messages.length +
                    (_isLoading ? 1 : 0) +
                    (_showSuggestions ? 1 : 0),
                itemBuilder: (context, index) {
                  if (_showSuggestions && index == _messages.length) {
                    return _SuggestionChips(
                      suggestions: suggestions,
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
                      ChatBubble(
                        message: message,
                        onRetry: message.isError && _lastUserMessage != null
                            ? () => _sendMessage(_lastUserMessage)
                            : null,
                      ).animate().fadeIn(duration: 250.ms).slideY(begin: 0.05),
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

            // banner de IA en pausa
            if (_isAiPaused)
              Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.pause_circle_outline_rounded,
                      size: 16,
                      color: Color(0xFFF59E0B),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        S.of(context).aiPausedBanner,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF92400E),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // input bar glassmorphism
            _InputBar(
              controller: _controller,
              isLoading: _isLoading,
              isPaused: _isAiPaused,
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
  final bool isPaused;
  final VoidCallback onSend;

  const _InputBar({
    required this.controller,
    required this.isLoading,
    required this.isPaused,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bottom = MediaQuery.of(context).padding.bottom;
    final s = S.of(context);

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
                    color: scheme.surfaceContainerHighest.withValues(
                      alpha: 0.4,
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: TextField(
                    controller: controller,
                    enabled: !isLoading && !isPaused,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => onSend(),
                    maxLines: 4,
                    minLines: 1,
                    style: Theme.of(context).textTheme.bodyMedium,
                    decoration: InputDecoration(
                      hintText: s.aiInputHint,
                      hintStyle: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(
                            color: scheme.onSurfaceVariant.withValues(
                              alpha: 0.6,
                            ),
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
                onTap: isLoading || isPaused ? null : onSend,
                child: AnimatedOpacity(
                  opacity: isLoading || isPaused ? 0.5 : 1,
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
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                        : const Icon(
                            Icons.send_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
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
                  style: Theme.of(
                    context,
                  ).textTheme.labelMedium?.copyWith(color: scheme.onSurface),
                ),
                avatar: Icon(
                  Icons.auto_awesome_rounded,
                  size: 14,
                  color: scheme.primary,
                ),
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
              S.of(context).aiThinking,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
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
                Icon(Icons.storefront_rounded, size: 18, color: scheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    S.of(context).aiExploreTemplates,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 16,
                  color: scheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms);
  }
}
