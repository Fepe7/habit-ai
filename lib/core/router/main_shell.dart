import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// Shell con bottom nav custom
class MainShell extends StatelessWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final selected = _currentIndex(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          border: Border(
            top: BorderSide(
              color: colorScheme.outlineVariant.withValues(alpha: 0.3),
            ),
          ),
        ),
        padding: EdgeInsets.only(
          top: 8,
          bottom: MediaQuery.of(context).padding.bottom + 8,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavItem(
              icon: Icons.check_circle_outline,
              activeIcon: Icons.check_circle,
              isSelected: selected == 0,
              color: colorScheme.primary,
              inactiveColor: colorScheme.onSurfaceVariant,
              onTap: () => _onTap(context, 0),
            ),
            _NavItem(
              icon: Icons.bar_chart_outlined,
              activeIcon: Icons.bar_chart_rounded,
              isSelected: selected == 1,
              color: colorScheme.primary,
              inactiveColor: colorScheme.onSurfaceVariant,
              onTap: () => _onTap(context, 1),
            ),
            _NavItem(
              icon: Icons.auto_awesome_outlined,
              activeIcon: Icons.auto_awesome,
              isSelected: selected == 2,
              color: colorScheme.primary,
              inactiveColor: colorScheme.onSurfaceVariant,
              onTap: () => _onTap(context, 2),
            ),
            _NavItem(
              icon: Icons.person_outline,
              activeIcon: Icons.person,
              isSelected: selected == 3,
              color: colorScheme.primary,
              inactiveColor: colorScheme.onSurfaceVariant,
              onTap: () => _onTap(context, 3),
            ),
          ],
        ),
      ),
    );
  }

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/dashboard')) return 1;
    if (location.startsWith('/ai')) return 2;
    if (location.startsWith('/settings')) return 3;
    return 0;
  }

  void _onTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/');
      case 1:
        context.go('/dashboard');
      case 2:
        context.go('/ai');
      case 3:
        context.go('/settings');
    }
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final bool isSelected;
  final Color color;
  final Color inactiveColor;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.isSelected,
    required this.color,
    required this.inactiveColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 56,
        height: 40,
        child: Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Icon(
              isSelected ? activeIcon : icon,
              key: ValueKey(isSelected),
              size: isSelected ? 28 : 24,
              color: isSelected ? color : inactiveColor,
            ),
          ),
        ),
      ),
    );
  }
}
