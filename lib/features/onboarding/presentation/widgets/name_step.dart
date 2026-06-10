import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../l10n/app_localizations.dart';

// Paso 1: nombre del usuario. Viene prellenado si entró con Google/Apple
// o lo dio al registrarse; el saludo aparece en vivo mientras escribe.
class NameStep extends StatefulWidget {
  final String? initialName;
  final ValueChanged<String> onContinue;

  const NameStep({
    super.key,
    required this.initialName,
    required this.onContinue,
  });

  @override
  State<NameStep> createState() => _NameStepState();
}

class _NameStepState extends State<NameStep> {
  late final TextEditingController _controller;

  String get _name => _controller.text.trim();

  @override
  void initState() {
    super.initState();
    // Si el nombre viene del proveedor, nos quedamos con el nombre de pila
    final initial = (widget.initialName ?? '').trim().split(' ').first;
    _controller = TextEditingController(text: initial);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final hasName = _name.length >= 2;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Spacer(flex: 2),
          Text(
            s.onbNameTitle,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2),
          const SizedBox(height: 8),
          Text(
            s.onbNameSubtitle,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white.withValues(alpha: 0.8),
                ),
          ).animate().fadeIn(delay: 150.ms, duration: 400.ms),
          const SizedBox(height: 28),
          TextField(
            controller: _controller,
            onChanged: (_) => setState(() {}),
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) {
              if (hasName) widget.onContinue(_name);
            },
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
            cursorColor: Colors.white,
            decoration: InputDecoration(
              hintText: s.onbNameHint,
              hintStyle: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.12),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 18,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.3),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.3),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(color: Colors.white, width: 2),
              ),
            ),
          ).animate().fadeIn(delay: 300.ms, duration: 400.ms).slideY(
                begin: 0.15,
                delay: 300.ms,
                curve: Curves.easeOutCubic,
              ),
          const SizedBox(height: 18),
          // Saludo en vivo mientras escribe
          SizedBox(
            height: 32,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              child: hasName
                  ? Text(
                      s.onbNameGreeting(_name),
                      key: ValueKey(_name),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                    )
                  : const SizedBox.shrink(),
            ),
          ),
          const Spacer(flex: 3),
          AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: hasName ? 1 : 0.45,
            child: FilledButton(
              onPressed: hasName ? () => widget.onContinue(_name) : null,
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
              child: Text(S.of(context).confirm),
            ),
          ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }
}
