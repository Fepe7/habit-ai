import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../l10n/app_localizations.dart';

// Paso 0: bienvenida cinemática — logo, título letra a letra,
// tagline rotando y CTA con pulso de atracción.
class WelcomeStep extends StatefulWidget {
  final VoidCallback onStart;

  const WelcomeStep({super.key, required this.onStart});

  @override
  State<WelcomeStep> createState() => _WelcomeStepState();
}

class _WelcomeStepState extends State<WelcomeStep> {
  Timer? _taglineTimer;
  int _taglineIndex = 0;

  @override
  void initState() {
    super.initState();
    _taglineTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted) setState(() => _taglineIndex = (_taglineIndex + 1) % 3);
    });
  }

  @override
  void dispose() {
    _taglineTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final taglines = [s.onbTagline1, s.onbTagline2, s.onbTagline3];
    const title = 'HabitAI';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Spacer(flex: 2),
          // Logo con entrada escala + fade y brillo periódico
          Image.asset(
            'assets/images/splash_icon.png',
            height: 110,
          )
              .animate()
              .fadeIn(duration: 600.ms)
              .scale(
                begin: const Offset(0.7, 0.7),
                end: const Offset(1, 1),
                duration: 700.ms,
                curve: Curves.easeOutBack,
              )
              .animate(onPlay: (c) => c.repeat())
              .shimmer(delay: 2500.ms, duration: 1800.ms),
          const SizedBox(height: 28),
          // Título letra a letra
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (int i = 0; i < title.length; i++)
                Text(
                  title[i],
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                )
                    .animate()
                    .fadeIn(delay: (400 + i * 70).ms, duration: 350.ms)
                    .slideY(
                      begin: 0.4,
                      delay: (400 + i * 70).ms,
                      duration: 350.ms,
                      curve: Curves.easeOutCubic,
                    ),
            ],
          ),
          const SizedBox(height: 14),
          // Tagline que rota con cross-fade
          SizedBox(
            height: 28,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              child: Text(
                taglines[_taglineIndex],
                key: ValueKey(_taglineIndex),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
              ),
            ),
          ).animate().fadeIn(delay: 1200.ms, duration: 500.ms),
          const Spacer(flex: 2),
          Text(
            s.onbWelcomeIntro,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white.withValues(alpha: 0.75),
                ),
          ).animate().fadeIn(delay: 1600.ms, duration: 500.ms),
          const SizedBox(height: 20),
          // CTA con pulso suave de atracción
          FilledButton(
            onPressed: widget.onStart,
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF00668A),
              padding: const EdgeInsets.symmetric(vertical: 18),
              textStyle: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            child: Text(s.onbStart),
          )
              .animate()
              .fadeIn(delay: 1900.ms, duration: 400.ms)
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(
                begin: const Offset(1, 1),
                end: const Offset(1.03, 1.03),
                duration: 2.seconds,
                curve: Curves.easeInOut,
              ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }
}
