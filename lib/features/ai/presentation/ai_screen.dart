import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/ai_repository.dart';
import '../domain/chat_message.dart';
import '../domain/habit_plan_model.dart';
import '../../habits/data/habit_repository.dart';
import '../../../core/theme/app_theme.dart';
import 'widgets/chat_bubble.dart';
import 'widgets/plan_card.dart';

// Pantalla de chat con el asistente IA
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
  bool _isLoading = false;

  // sugerencias rapidas para guiar al usuario
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

    final habits = accepted
        .map((h) => GeneratedHabitModel(
              title: h.title,
              description: h.description,
              category: h.category,
              frequency: h.frequency,
              targetDays: h.targetDays,
              suggestedTime: h.suggestedTime,
            ).toHabitModel())
        .toList();

    await _habitRepo.createHabits(habits);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${accepted.length} hábitos añadidos'),
          backgroundColor: AppTheme.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  // solo mostrar sugerencias si es el primer mensaje (bienvenida)
  bool get _showSuggestions => _messages.length == 1 && !_isLoading;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Asistente IA'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Nueva conversación',
            onPressed: () {
              _aiRepo.resetChat();
              setState(() {
                _messages.clear();
                _messages.add(ChatMessage(
                  text: '¡Conversación reiniciada! Cuéntame, ¿qué metas tienes?',
                  isUser: false,
                  timestamp: DateTime.now(),
                ));
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // lista de mensajes
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _messages.length +
                  (_isLoading ? 1 : 0) +
                  (_showSuggestions ? 1 : 0),
              itemBuilder: (context, index) {
                // sugerencias al final si aplica
                if (_showSuggestions && index == _messages.length) {
                  return _SuggestionChips(
                    suggestions: _suggestions,
                    onTap: (s) => _sendMessage(s),
                  );
                }

                // indicador de carga
                if (index == _messages.length + (_showSuggestions ? 1 : 0) ||
                    (_isLoading && index == _messages.length)) {
                  return const _TypingIndicator();
                }

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
                      ).animate().fadeIn(delay: 100.ms, duration: 350.ms).slideY(begin: 0.08),
                  ],
                );
              },
            ),
          ),

          // input de texto
          Container(
            padding: EdgeInsets.only(
              left: 16,
              right: 8,
              top: 8,
              bottom: MediaQuery.of(context).padding.bottom + 8,
            ),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              border: Border(
                top: BorderSide(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                    maxLines: 4,
                    minLines: 1,
                    decoration: InputDecoration(
                      hintText: 'Escribe tus metas...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _isLoading ? null : () => _sendMessage(),
                  icon: const Icon(Icons.send_rounded),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// chips de sugerencias rapidas
class _SuggestionChips extends StatelessWidget {
  final List<String> suggestions;
  final ValueChanged<String> onTap;

  const _SuggestionChips({required this.suggestions, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: suggestions.asMap().entries.map((entry) {
          return ActionChip(
            label: Text(
              entry.value,
              style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
            ),
            avatar: Icon(Icons.auto_awesome, size: 16, color: colorScheme.primary),
            backgroundColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
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

// animacion de "pensando..."
class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Pensando...',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 250.ms);
  }
}
