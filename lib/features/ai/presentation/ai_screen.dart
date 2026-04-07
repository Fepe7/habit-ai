import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser!.uid;
    _aiRepo = AIRepository(uid: uid);
    _habitRepo = HabitRepository(uid: uid);

    // Mensaje de bienvenida
    _messages.add(ChatMessage(
      text: '¡Hola! Soy tu asistente de hábitos. Cuéntame tus metas '
          'y te generaré un plan personalizado.\n\n'
          'Por ejemplo: "Quiero hacer ejercicio, dormir mejor y leer más"',
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

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isLoading) return;

    _controller.clear();

    setState(() {
      _messages.add(ChatMessage(
        text: text,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _isLoading = true;
    });

    _scrollToBottom();

    try {
      final plan = await _aiRepo.generatePlan(text);

      // Convertir a datos para la UI
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

  // Guarda los habitos aceptados del plan en Firestore
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
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Asistente IA'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
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
          // Lista de mensajes
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                // Indicador de carga al final
                if (index == _messages.length) {
                  return const _TypingIndicator();
                }

                final message = _messages[index];
                return Column(
                  children: [
                    ChatBubble(message: message),
                    // Mostrar plan si hay
                    if (message.plan != null)
                      PlanCard(
                        plan: message.plan!,
                        onSave: () => _saveHabits(message.plan!),
                      ),
                  ],
                );
              },
            ),
          ),

          // Input de texto
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
                  onPressed: _isLoading ? null : _sendMessage,
                  icon: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Animacion de "escribiendo..."
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
    );
  }
}
