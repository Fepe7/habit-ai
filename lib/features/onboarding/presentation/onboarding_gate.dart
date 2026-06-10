import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../data/onboarding_repository.dart';
import 'onboarding_flow.dart';

// Envuelve el shell principal: si el usuario autenticado no ha completado
// el onboarding, muestra el flujo a pantalla completa en su lugar.
// Se consulta Firestore una sola vez por sesión/usuario.
class OnboardingGate extends StatefulWidget {
  final Widget child;

  const OnboardingGate({super.key, required this.child});

  @override
  State<OnboardingGate> createState() => _OnboardingGateState();
}

class _OnboardingGateState extends State<OnboardingGate> {
  String? _uid;
  Future<bool>? _isCompleted;
  bool _justFinished = false;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    // Sin sesión el redirect del router ya manda a /login
    if (user == null) return widget.child;

    // Nueva sesión o cambio de cuenta: re-consultar el flag
    if (user.uid != _uid) {
      _uid = user.uid;
      _justFinished = false;
      _isCompleted = OnboardingRepository(uid: user.uid).isCompleted();
    }

    if (_justFinished) return widget.child;

    return FutureBuilder<bool>(
      future: _isCompleted,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Pantalla neutra del color del splash para evitar parpadeo
          return const Scaffold(
            backgroundColor: Color(0xFF00668A),
            body: SizedBox.expand(),
          );
        }
        // Ante error de red no bloqueamos el acceso a la app
        final completed = snapshot.data ?? true;
        if (completed) return widget.child;

        return OnboardingFlow(
          onFinished: () => setState(() => _justFinished = true),
        );
      },
    );
  }
}
