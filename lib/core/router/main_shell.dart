import 'dart:async';
import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/data/user_repository.dart';
import '../../features/habits/data/habit_repository.dart';
import '../../features/social/data/follow_repository.dart';
import '../../features/social/domain/follow_request_model.dart';
import '../../services/notification_service.dart';
import '../widgets/app_drawer.dart';

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
  int _knownPendingCount = -1;
  int _knownAcceptedCount = -1;
  // badge reactivo: se actualiza con cada snapshot del stream
  int _pendingBadgeCount = 0;

  @override
  void initState() {
    super.initState();
    // reprogramar notificaciones una vez por sesion (por si el SO las purgo
    // o el usuario reinstalo la app). No bloquea el primer render
    _rescheduleNotifications();
    // migrar usuarios existentes al nuevo user_directory si aun no tienen entrada
    _ensureUserDirectory();
    _watchSocialNotifications();
  }

  @override
  void dispose() {
    _pendingFollowSub?.cancel();
    _acceptedFollowSub?.cancel();
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
        NotificationService.instance.showSocialNotification(
          title: 'Nueva solicitud de seguimiento',
          body: '@${newest.fromUsername} quiere seguirte',
        );
      }
      _knownPendingCount = requests.length;
      setState(() => _pendingBadgeCount = requests.length);
    });

    _acceptedFollowSub = repo.watchAcceptedSentRequests().listen((accepted) {
      if (_knownAcceptedCount == -1) {
        _knownAcceptedCount = accepted.length;
        return;
      }
      if (accepted.length > _knownAcceptedCount && accepted.isNotEmpty) {
        final newest = accepted.first;
        NotificationService.instance.showSocialNotification(
          title: '¡Solicitud aceptada!',
          body: '@${newest.toUsername} aceptó tu solicitud',
        );
      }
      _knownAcceptedCount = accepted.length;
    });
  }

  Future<void> _ensureUserDirectory() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final repo = UserRepository(uid: uid);
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

  static const _tabs = [
    _TabInfo(
      path: '/',
      icon: Icons.check_circle_outline_rounded,
      activeIcon: Icons.check_circle_rounded,
      label: 'Hábitos',
    ),
    _TabInfo(
      path: '/dashboard',
      icon: Icons.bar_chart_outlined,
      activeIcon: Icons.bar_chart_rounded,
      label: 'Progreso',
    ),
    _TabInfo(
      path: '/ai',
      icon: Icons.auto_awesome_outlined,
      activeIcon: Icons.auto_awesome_rounded,
      label: 'Asistente',
    ),
    _TabInfo(
      path: '/explore',
      icon: Icons.search_rounded,
      activeIcon: Icons.search_rounded,
      label: 'Explorar',
    ),
    _TabInfo(
      path: '/profile',
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
      label: 'Perfil',
    ),
  ];

  @override
  Widget build(BuildContext context) {
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
              onDestinationSelected: (index) => context.go(_tabs[index].path),
              labelType: NavigationRailLabelType.all,
              backgroundColor: scheme.surfaceContainerLowest,
              indicatorColor: scheme.primaryContainer.withValues(alpha: 0.3),
              destinations: List.generate(_tabs.length, (index) {
                final tab = _tabs[index];
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
            Expanded(child: widget.child),
          ],
        ),
      );
    }

    return Scaffold(
      key: MainShell.scaffoldKey,
      extendBody: true,
      drawer: const AppDrawer(),
      body: widget.child,
      bottomNavigationBar: _GlassNavBar(
        selectedIndex: selected,
        scheme: scheme,
        onDestinationSelected: (index) => context.go(_tabs[index].path),
        tabs: _tabs,
        pendingCount: _pendingBadgeCount,
      ),
    );
  }

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/dashboard')) return 1;
    if (location.startsWith('/ai')) return 2;
    if (location.startsWith('/explore') ||
        location.startsWith('/community') ||
        location.startsWith('/profiles')) {
      return 3;
    }
    if (location.startsWith('/profile')) return 4;
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

/// Alto fijo de la barra de navegación (sin safe area inferior)
const double kBottomNavBarHeight = 72.0;

extension BottomNavInset on BuildContext {
  /// Espacio inferior para que el contenido scrollable no quede
  /// tapado por _GlassNavBar cuando extendBody=true en MainShell.
  double get bottomNavInset =>
      kBottomNavBarHeight + MediaQuery.viewPaddingOf(this).bottom + 16;
}
