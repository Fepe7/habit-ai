import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';

// Paso 1: selección multi de áreas a mejorar. Las elegidas alimentan
// el prompt de la IA en el paso de generación del plan.
class CategoriesStep extends StatelessWidget {
  final Set<String> selected;
  final ValueChanged<String> onToggle;
  final VoidCallback onContinue;

  const CategoriesStep({
    super.key,
    required this.selected,
    required this.onToggle,
    required this.onContinue,
  });

  static const _icons = <String, IconData>{
    'salud': Icons.favorite_rounded,
    'productividad': Icons.bolt_rounded,
    'bienestar': Icons.self_improvement_rounded,
    'social': Icons.people_rounded,
    'aprendizaje': Icons.school_rounded,
    'finanzas': Icons.savings_rounded,
  };

  static String categoryLabel(BuildContext context, String key) {
    final s = S.of(context);
    switch (key) {
      case 'salud':
        return s.categorySalud;
      case 'productividad':
        return s.categoryProductividad;
      case 'bienestar':
        return s.categoryBienestar;
      case 'social':
        return s.categorySocial;
      case 'aprendizaje':
        return s.categoryAprendizaje;
      case 'finanzas':
        return s.categoryFinanzas;
      default:
        return key;
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final categories = _icons.keys.toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          Text(
            s.onbCategoriesTitle,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2),
          const SizedBox(height: 8),
          Text(
            s.onbCategoriesSubtitle,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white.withValues(alpha: 0.8),
                ),
          ).animate().fadeIn(delay: 150.ms, duration: 400.ms),
          const SizedBox(height: 24),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.45,
              physics: const BouncingScrollPhysics(),
              children: [
                for (int i = 0; i < categories.length; i++)
                  _CategoryCard(
                    categoryKey: categories[i],
                    label: categoryLabel(context, categories[i]),
                    icon: _icons[categories[i]]!,
                    isSelected: selected.contains(categories[i]),
                    onTap: () {
                      HapticFeedback.selectionClick();
                      onToggle(categories[i]);
                    },
                  )
                      .animate()
                      .fadeIn(delay: (200 + i * 80).ms, duration: 400.ms)
                      .slideY(
                        begin: 0.25,
                        delay: (200 + i * 80).ms,
                        duration: 400.ms,
                        curve: Curves.easeOutCubic,
                      ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Continuar solo activo con al menos un área elegida
          AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: selected.isEmpty ? 0.45 : 1,
            child: FilledButton(
              onPressed: selected.isEmpty ? null : onContinue,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF00668A),
                disabledBackgroundColor: Colors.white.withValues(alpha: 0.4),
                padding: const EdgeInsets.symmetric(vertical: 18),
                textStyle: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              child: Text(s.confirm),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// Card seleccionable con rebote elástico y check que aparece dibujándose
class _CategoryCard extends StatelessWidget {
  final String categoryKey;
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.categoryKey,
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = AppTheme.categoryBg(categoryKey);
    final fg = AppTheme.categoryFg(categoryKey);

    return AnimatedScale(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutBack,
      scale: isSelected ? 1.04 : 1,
      child: Material(
        color: isSelected ? bg : Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? fg.withValues(alpha: 0.6)
                    : Colors.white.withValues(alpha: 0.25),
                width: 1.5,
              ),
            ),
            child: Stack(
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(icon, color: isSelected ? fg : Colors.white, size: 28),
                    const SizedBox(height: 8),
                    Text(
                      label,
                      style: TextStyle(
                        color: isSelected ? fg : Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: AnimatedScale(
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeOutBack,
                    scale: isSelected ? 1 : 0,
                    child: Icon(Icons.check_circle_rounded, color: fg, size: 22),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
