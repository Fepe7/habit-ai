import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/widgets/ux/app_snackbar.dart';
import '../../../l10n/app_localizations.dart';
import '../../ai/data/ai_repository.dart';
import '../../ai/domain/habit_plan_model.dart';
import '../../auth/data/user_repository.dart';
import '../../habits/data/habit_group_repository.dart';
import '../../habits/data/habit_repository.dart';
import '../../habits/domain/habit_group_model.dart';
import '../../habits/domain/habit_model.dart';
import '../data/onboarding_repository.dart';
import 'widgets/ai_features_step.dart';
import 'widgets/categories_step.dart';
import 'widgets/first_checkin_step.dart';
import 'widgets/lifestyle_step.dart';
import 'widgets/name_step.dart';
import 'widgets/notifications_step.dart';
import 'widgets/onboarding_background.dart';
import 'widgets/onboarding_progress_bar.dart';
import 'widgets/plan_step.dart';
import 'widgets/welcome_step.dart';

// Flujo de onboarding: 8 pasos sobre fondo vivo. El objetivo es que el
// usuario salga con su primer plan generado por la IA y su primera victoria.
//   0 bienvenida → 1 nombre → 2 áreas → 3 estilo de vida → 4 plan IA
//   → 5 primer check-in → 6 tour de funciones IA → 7 notificaciones
class OnboardingFlow extends StatefulWidget {
  // Avisar al gate de que el onboarding terminó (ya persistido en Firestore)
  final VoidCallback onFinished;

  const OnboardingFlow({super.key, required this.onFinished});

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  static const _totalSteps = 8;

  final _pageController = PageController();
  final _planStepKey = GlobalKey<PlanStepState>();
  int _step = 0;

  late final OnboardingRepository _onboardingRepo;
  late final AIRepository _aiRepo;
  late final HabitRepository _habitRepo;
  late final HabitGroupRepository _groupRepo;
  late final UserRepository _userRepo;

  final Set<String> _selectedCategories = {};
  final _lifestyle = LifestyleAnswers();
  String? _userName;
  List<HabitModel> _createdHabits = [];
  bool _planAccepted = false;
  bool _isFinishing = false;

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser!.uid;
    _onboardingRepo = OnboardingRepository(uid: uid);
    _aiRepo = AIRepository(uid: uid);
    _habitRepo = HabitRepository(uid: uid);
    _groupRepo = HabitGroupRepository(uid: uid);
    _userRepo = UserRepository(uid: uid);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goTo(int step) {
    HapticFeedback.lightImpact();
    setState(() => _step = step);
    _pageController
        .animateToPage(
      step,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
    )
        .then((_) {
      // El plan se genera al llegar al paso 4 (no antes, para no gastar
      // cuota). Hay que esperar a que acabe la animación: el PageView
      // construye las páginas de forma perezosa y hasta entonces el
      // estado del PlanStep no existe
      if (step == 4 && mounted) {
        _planStepKey.currentState?.startGeneration();
      }
    });
  }

  // Guarda el nombre localmente y lo persiste si cambió (perfil + Auth)
  void _onNameContinue(String name) {
    _userName = name;
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.displayName != name) {
      // Fire-and-forget: un fallo de red aquí no debe frenar el flujo
      user.updateDisplayName(name).catchError((_) {});
      _userRepo.updateProfile(displayName: name).catchError((_) {});
    }
    _goTo(2);
  }

  // Prompt para Gemini construido con las respuestas del usuario
  String _buildPrompt() {
    final s = S.of(context);
    final areas = _selectedCategories
        .map((c) => CategoriesStep.categoryLabel(context, c))
        .join(', ');
    final prompt = s.onbAiPrompt(
      areas,
      _lifestyle.energyMoment ?? '',
      _lifestyle.timeBudget ?? '',
      _lifestyle.blocker ?? '',
    );
    final name = _userName;
    if (name == null || name.isEmpty) return prompt;
    return '${s.onbAiPromptName(name)} $prompt';
  }

  // Receta visual que se auto-escribe mientras la IA genera: confirma al
  // usuario que sus respuestas se han tenido en cuenta
  List<RecipeSegment> _buildRecipe() {
    final s = S.of(context);
    final areas = _selectedCategories
        .map((c) => CategoriesStep.categoryLabel(context, c))
        .join(', ');
    final name = _userName;
    return [
      if (name != null && name.isNotEmpty) ...[
        RecipeSegment(s.onbRecipePlanFor),
        RecipeSegment(name, highlighted: true),
        RecipeSegment(s.onbRecipeImprove),
      ] else
        RecipeSegment(s.onbRecipeImproveNoName),
      RecipeSegment(areas, highlighted: true),
      RecipeSegment(s.onbRecipeEnergy),
      RecipeSegment(
        (_lifestyle.energyMoment ?? '').toLowerCase(),
        highlighted: true,
      ),
      const RecipeSegment(' · '),
      RecipeSegment(_lifestyle.timeBudget ?? '', highlighted: true),
      RecipeSegment(s.onbRecipePerDay),
    ];
  }

  Future<HabitPlanModel> _generatePlan({required bool regenerate}) {
    final s = S.of(context);
    // En regeneración se conserva el historial del chat para que la IA
    // proponga algo distinto al plan anterior
    return _aiRepo.generatePlan(
      regenerate ? s.onbRegeneratePrompt : _buildPrompt(),
    );
  }

  // Guarda el plan como grupo + hábitos (mismo patrón que el chat de IA)
  Future<void> _acceptPlan(
    HabitPlanModel plan,
    List<GeneratedHabitModel> accepted,
  ) async {
    try {
      final group = HabitGroupModel(
        id: '',
        title: plan.planTitle,
        emoji: plan.planEmoji,
        createdAt: DateTime.now(),
        habitCount: accepted.length,
      );
      final groupId = await _groupRepo.createGroup(group);
      final habits =
          accepted.map((h) => h.toHabitModel(groupId: groupId)).toList();
      // Guardamos los hábitos con ID para el paso de primer check-in
      _createdHabits = await _habitRepo.createHabitsInGroup(habits, groupId);

      _planAccepted = true;
      _goTo(5);
    } catch (_) {
      if (mounted) {
        AppSnackBar.showError(context, S.of(context).aiSaveError);
      }
    }
  }

  // Marca el flag en Firestore y devuelve el control al gate
  Future<void> _finish() async {
    if (_isFinishing) return;
    setState(() => _isFinishing = true);
    try {
      await _onboardingRepo.markCompleted(
        goals: _selectedCategories.toList(),
      );
    } catch (_) {
      // Sin red: no bloqueamos la salida, el gate volverá a preguntar
      // en el próximo arranque si el flag no llegó a escribirse
    }
    if (mounted) widget.onFinished();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    // Sobre el gradiente oscuro los iconos de la barra de estado van en claro
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: Stack(
          children: [
            Positioned.fill(child: OnboardingBackground(step: _step)),
            SafeArea(
              child: Column(
                children: [
                  // Barra superior: atrás + progreso + saltar
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 48,
                          child: _step >= 1 && _step <= 3
                              ? IconButton(
                                  onPressed: () => _goTo(_step - 1),
                                  icon: const Icon(
                                    Icons.arrow_back_rounded,
                                    color: Colors.white,
                                  ),
                                )
                              : null,
                        ),
                        Expanded(
                          child: OnboardingProgressBar(
                            step: _step,
                            totalSteps: _totalSteps,
                          ),
                        ),
                        SizedBox(
                          width: 72,
                          child: _step < 5 && !_planAccepted
                              ? TextButton(
                                  onPressed: _isFinishing ? null : _finish,
                                  child: Text(
                                    s.onbSkip,
                                    style: TextStyle(
                                      color:
                                          Colors.white.withValues(alpha: 0.8),
                                    ),
                                  ),
                                )
                              : null,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      // La navegación es solo por botones: cada paso valida
                      // su estado antes de dejar avanzar
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        WelcomeStep(onStart: () => _goTo(1)),
                        NameStep(
                          initialName:
                              FirebaseAuth.instance.currentUser?.displayName,
                          onContinue: _onNameContinue,
                        ),
                        CategoriesStep(
                          selected: _selectedCategories,
                          onToggle: (category) => setState(() {
                            _selectedCategories.contains(category)
                                ? _selectedCategories.remove(category)
                                : _selectedCategories.add(category);
                          }),
                          onContinue: () => _goTo(3),
                        ),
                        LifestyleStep(
                          answers: _lifestyle,
                          onChanged: () => setState(() {}),
                          onContinue: () => _goTo(4),
                        ),
                        PlanStep(
                          key: _planStepKey,
                          generate: _generatePlan,
                          onAccept: _acceptPlan,
                          buildRecipe: _buildRecipe,
                        ),
                        FirstCheckinStep(
                          habits: _createdHabits,
                          habitRepo: _habitRepo,
                          onContinue: () => _goTo(6),
                        ),
                        AIFeaturesStep(onContinue: () => _goTo(7)),
                        NotificationsStep(onFinished: _finish),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
