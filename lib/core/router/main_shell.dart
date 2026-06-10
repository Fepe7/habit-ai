import 'dart:async';
import 'dart:ui';

import 'package:flutter/services.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/data/user_repository.dart';
import '../../features/habits/data/habit_repository.dart';
import '../../features/habits/presentation/habits_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/ai/presentation/ai_screen.dart';
import '../../features/explore/presentation/explore_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/social/data/follow_repository.dart';
import '../../features/social/data/reaction_repository.dart';
import '../../features/social/domain/follow_request_model.dart';
import '../../features/social/domain/reaction_model.dart';
import '../../features/social/presentation/widgets/reaction_received_overlay.dart';
import '../../services/notification_service.dart';
import '../../services/push_notification_service.dart';
import '../services/feedback_service.dart';
import '../services/analytics_service.dart';
import '../widgets/app_drawer.dart';
import '../widgets/ux/offline_banner.dart';
import '../../l10n/app_localizations.dart';

/// Shell principal con glassmorphism bottom nav
/// BackdropFilter + superficie translucida para que el scroll se vea detras
class MainShell extends StatefulWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  /// Key global para abrir el drawer desde cualquier widget hijo.
  static final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  StreamSubscription<List<FollowRequestModel>>? _pendingFollowSub;
  StreamSubscription<List<FollowRequestModel>>? _acceptedFollowSub;
  StreamSubscription<List<ReactionModel>>? _reactionsSub;
  int _knownPendingCount = -1;
  int _knownAcceptedCount = -1;
  int _knownReactionsCount = -1;
  int _pendingBadgeCount = 0;

  // se crea perezosamente en la pestaña correcta cada vez que se entra al
  // PageView (incl. al volver desde una ruta hija como /settings) y se libera
  // al salir; así el PageView nunca reaparece en la pestaña anterior
  PageController? _pageController;
  // evita bucle: swipe → context.go() → rebuild → jumpToPage → onPageChanged
  bool _isSwiping = false;

  static const _mainPaths = {'/', '/dashboard', '/ai', '/explore', '/profile'};

  @override
  void initState() {
    super.initState();
    _rescheduleNotifications();
    _ensureUserDirectory();
    _watchSocialNotifications();
    // registrar el token de FCM del dispositivo para este usuario (push remotos)
    PushNotificationService.instance.registerForCurrentUser();
    AnalyticsService.instance.setUserId(FirebaseAuth.instance.currentUser?.uid);
  }

  @override
  void dispose() {
    _pageController?.dispose();
    _pendingFollowSub?.cancel();
    _acceptedFollowSub?.cancel();
    _reactionsSub?.cancel();
    super.dispose();
  }

  void _watchSocialNotifications() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final repo = FollowRepository(uid: uid);

    _pendingFollowSub = repo.watchPendingFollowRequests().listen((requests) {
      if (_knownPendingCount == -1) {
        // primer snapshot: inicializar sin disparar notif, pero sí mostrar badge
        _knownPendingCount = requests.length;
        setState(() => _pendingBadgeCount = requests.length);
        return;
      }
      if (requests.length > _knownPendingCount && requests.isNotEmpty) {
        final newest = requests.first;
        final s = S.of(context);
        NotificationService.instance.showSocialNotification(
          title: s?.navNewFollowRequest ?? 'Nueva solicitud de seguimiento',
          body: s?.navFollowRequestBody(newest.fromUsername) ?? '@${newest.fromUsername} quiere seguirte',
        );
      }
      _knownPendingCount = requests.length;
      setState(() => _pendingBadgeCount = requests.length);
    }, onError: (_) {});

    _acceptedFollowSub = repo.watchAcceptedSentRequests().listen((accepted) {
      if (_knownAcceptedCount == -1) {
        _knownAcceptedCount = accepted.length;
        return;
      }
      if (accepted.length > _knownAcceptedCount && accepted.isNotEmpty) {
        final newest = accepted.first;
        final s = S.of(context);
        NotificationService.instance.showSocialNotification(
          title: s?.navFollowAccepted ?? '¡Solicitud aceptada!',
          body: s?.navFollowAcceptedBody(newest.toUsername) ?? '@${newest.toUsername} aceptó tu solicitud',
        );
      }
      _knownAcceptedCount = accepted.length;
    }, onError: (_) {});

    final reactRepo = ReactionRepository();
    _reactionsSub = reactRepo.watchMyReceivedReactions(uid).listen((reactions) {
      if (_knownReactionsCount == -1) {
        _knownReactionsCount = reactions.length;
        return;
      }
      if (reactions.length > _knownReactionsCount && reactions.isNotEmpty) {
        final newest = reactions.first;
        FeedbackService.instance.reactionReceived();

        if (mounted) {
          ReactionReceivedOverlay.show(
            context,
            reactorUsername: newest.reactorUsername,
            emoji: newest.emoji,
          );
        }

        NotificationService.instance.showSocialNotification(
          title: '¡Nueva reacción!',
          body: '@${newest.reactorUsername} reaccionó a tu perfil',
        );
      }
      _knownReactionsCount = reactions.length;
    }, onError: (_) {});
  }

  Future<void> _ensureUserDirectory() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final repo = UserRepository(uid: uid);
    // marca de última actividad (una vez por sesión, para detectar abandono)
    unawaited(repo.touchLastActive());
    await repo.ensureDirectoryEntry();
  }

  Future<void> _rescheduleNotifications() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    if (!await NotificationService.instance.isEnabled()) return;
    // pedir permiso si aun no se ha concedido (Android 13+)
    await NotificationService.instance.requestPermissions();
    final repo = HabitRepository(uid: uid);
    final habits = await repo.getActiveHabits();
    await NotificationService.instance.rescheduleAll(habits);
  }

  List<_TabInfo> _buildTabs(BuildContext context) {
    final s = S.of(context)!;
    return [
      _TabInfo(
        path: '/',
        icon: Icons.check_circle_outline_rounded,
        activeIcon: Icons.check_circle_rounded,
        label: s.navHabits,
      ),
      _TabInfo(
        path: '/dashboard',
        icon: Icons.bar_chart_outlined,
        activeIcon: Icons.bar_chart_rounded,
        label: s.navProgress,
      ),
      _TabInfo(
        path: '/ai',
        icon: Icons.auto_awesome_outlined,
        activeIcon: Icons.auto_awesome_rounded,
        label: s.navAssistant,
      ),
      _TabInfo(
        path: '/explore',
        icon: Icons.search_rounded,
        activeIcon: Icons.search_rounded,
        label: s.navExplore,
      ),
      _TabInfo(
        path: '/profile',
        icon: Icons.person_outline_rounded,
        activeIcon: Icons.person_rounded,
        label: s.navProfile,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final tabs = _buildTabs(context);
    final selected = _currentIndex(context);
    final scheme = Theme.of(context).colorScheme;
    final isWide = MediaQuery.of(context).size.width >= 600;

    // tablets: rail lateral en lugar de bottom bar
    if (isWide) {
      return Scaffold(
        key: MainShell.scaffoldKey,
        drawer: const AppDrawer(),
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: selected,
              onDestinationSelected: (index) => context.go(tabs[index].path),
              labelType: NavigationRailLabelType.all,
              backgroundColor: scheme.surfaceContainerLowest,
              indicatorColor: scheme.primaryContainer.withValues(alpha: 0.3),
              destinations: List.generate(tabs.length, (index) {
                final tab = tabs[index];
                // índice 4 = Perfil: mostrar badge con solicitudes pendientes
                final icon = (index == 4 && _pendingBadgeCount > 0)
                    ? Badge(
                        label: Text('$_pendingBadgeCount'),
                        child: Icon(tab.icon),
                      )
                    : Icon(tab.icon);
                final selectedIcon = (index == 4 && _pendingBadgeCount > 0)
                    ? Badge(
                        label: Text('$_pendingBadgeCount'),
                        child: Icon(tab.activeIcon),
                      )
                    : Icon(tab.activeIcon);
                return NavigationRailDestination(
                  icon: icon,
                  selectedIcon: selectedIcon,
                  label: Text(tab.label),
                );
              }),
            ),
            VerticalDivider(
              thickness: 1,
              width: 1,
              color: scheme.outlineVariant.withValues(alpha: 0.15),
            ),
            Expanded(
              child: Column(
                children: [
                  const OfflineBanner(),
                  Expanded(child: widget.child),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final location = GoRouterState.of(context).uri.path;
    final isMainRoute = _mainPaths.contains(location);

    if (isMainRoute) {
      // crear el controller en la pestaña correcta la primera vez que se monta
      // el PageView (también al volver desde una ruta hija como /settings),
      // evitando que reaparezca en la pestaña anterior
      if (_pageController == null) {
        _pageController = PageController(initialPage: selected);
      } else if (_pageController!.hasClients && !_isSwiping) {
        // ya montado: sincronizar con la ruta actual (deep links, back button)
        final currentPage = _pageController!.page?.round() ?? selected;
        if (currentPage != selected) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_pageController?.hasClients ?? false) {
              _pageController!.jumpToPage(selected);
            }
          });
        }
      }
    } else if (_pageController != null) {
      // salimos del PageView (ruta hija): liberar el controller para que al
      // volver se recree posicionado en la pestaña correcta
      final old = _pageController!;
      _pageController = null;
      WidgetsBinding.instance.addPostFrameCallback((_) => old.dispose());
    }

    return Scaffold(
      key: MainShell.scaffoldKey,
      extendBody: true,
      drawer: const AppDrawer(),
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(
            child: isMainRoute
                ? PageView(
                    controller: _pageController!,
                    physics: const _QuickSwipePhysics(),
                    onPageChanged: (index) {
                      _isSwiping = true;
                      // vibración ligera al cambiar de tab con swipe
                      // lightImpact usa VIRTUAL_KEY en Android, fiable en casi todos los dispositivos
                      HapticFeedback.lightImpact();
                      context.go(tabs[index].path);
                      Future.microtask(() => _isSwiping = false);
                    },
                    children: const [
                      HabitsScreen(),
                      DashboardScreen(),
                      AIScreen(),
                      ExploreScreen(),
                      ProfileScreen(),
                    ],
                  )
                : widget.child,
          ),
        ],
      ),
      bottomNavigationBar: _GlassNavBar(
        selectedIndex: selected,
        scheme: scheme,
        onDestinationSelected: (index) {
          if (isMainRoute && (_pageController?.hasClients ?? false)) {
            // tap en nav bar → salto instantáneo (sin animación de deslizamiento)
            _pageController!.jumpToPage(index);
          } else {
            context.go(tabs[index].path);
          }
        },
        tabs: tabs,
        pendingCount: _pendingBadgeCount,
      ),
    );
  }

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/dashboard')) return 1;
    if (location.startsWith('/ai')) return 2;
    // sección Explorar: feeds de comunidad, perfiles públicos y retos
    if (location.startsWith('/explore') ||
        location.startsWith('/community') ||
        location.startsWith('/profiles') ||
        location.startsWith('/challenges')) {
      return 3;
    }
    // sección Perfil: ajustes, seguidores y edición de perfil cuelgan de aquí
    // (startsWith('/profile') no captura '/profiles', ya resuelto arriba)
    if (location.startsWith('/profile') ||
        location.startsWith('/settings') ||
        location.startsWith('/followers') ||
        location.startsWith('/edit-profile') ||
        location.startsWith('/privacy-settings')) {
      return 4;
    }
    return 0;
  }
}

/// NavigationBar envuelto en BackdropFilter para efecto glass
class _GlassNavBar extends StatelessWidget {
  const _GlassNavBar({
    required this.selectedIndex,
    required this.scheme,
    required this.onDestinationSelected,
    required this.tabs,
    required this.pendingCount,
  });

  final int selectedIndex;
  final ColorScheme scheme;
  final ValueChanged<int> onDestinationSelected;
  final List<_TabInfo> tabs;
  // solicitudes de seguimiento pendientes → badge en tab Perfil
  final int pendingCount;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: scheme.surface.withValues(alpha: 0.72),
            border: Border(
              top: BorderSide(
                color: scheme.outlineVariant.withValues(alpha: 0.15),
                width: 1,
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 72,
              child: Row(
                children: List.generate(tabs.length, (index) {
                  final tab = tabs[index];
                  final isSelected = index == selectedIndex;
                  return Expanded(
                    child: _NavItem(
                      icon: tab.icon,
                      activeIcon: tab.activeIcon,
                      label: tab.label,
                      selected: isSelected,
                      scheme: scheme,
                      onTap: () => onDestinationSelected(index),
                      // badge solo en el tab Perfil (índice 4)
                      badgeCount: index == 4 ? pendingCount : 0,
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.selected,
    required this.scheme,
    required this.onTap,
    this.badgeCount = 0,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool selected;
  final ColorScheme scheme;
  final VoidCallback onTap;
  // 0 = sin badge; >0 = muestra el número
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    final color = selected ? scheme.primary : scheme.onSurfaceVariant;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              decoration: BoxDecoration(
                color: selected
                    ? scheme.primaryContainer.withValues(alpha: 0.25)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Badge(
                isLabelVisible: badgeCount > 0,
                label: Text('$badgeCount'),
                child: Icon(
                  selected ? activeIcon : icon,
                  color: color,
                  size: 24,
                ),
              ),
            ),
            const SizedBox(height: 2),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: Theme.of(context).textTheme.labelSmall!.copyWith(
                color: color,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabInfo {
  final String path;
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _TabInfo({
    required this.path,
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

/// Física de PageView con umbral reducido para cambiar de tab.
/// Dos ajustes combinados:
///   1. applyPhysicsToUserOffset × 2.5 → arrastre lento: con ~20% del ancho ya cambia
///   2. minFlingVelocity bajo → swipe rápido y corto también dispara el cambio
class _QuickSwipePhysics extends PageScrollPhysics {
  const _QuickSwipePhysics({super.parent});

  @override
  _QuickSwipePhysics applyTo(ScrollPhysics? ancestor) =>
      _QuickSwipePhysics(parent: buildParent(ancestor));

  /// Amplifica el desplazamiento físico del dedo para que el PageView
  /// "llegue" al 50% de umbral con mucho menos recorrido real.
  @override
  double applyPhysicsToUserOffset(ScrollMetrics position, double offset) =>
      super.applyPhysicsToUserOffset(position, offset) * 2.5;

  /// Velocidad mínima para que un swipe rápido cuente como fling.
  /// Valor por defecto en Android ronda 365 px/s — reducirlo a 100
  /// hace que swipes cortos pero veloces también cambien de tab.
  @override
  double get minFlingVelocity => 100.0;
}

/// Alto fijo de la barra de navegación (sin safe area inferior)
const double kBottomNavBarHeight = 72.0;

extension BottomNavInset on BuildContext {
  /// Espacio inferior para que el contenido scrollable no quede
  /// tapado por _GlassNavBar cuando extendBody=true en MainShell.
  double get bottomNavInset =>
      kBottomNavBarHeight + MediaQuery.viewPaddingOf(this).bottom + 16;
}
