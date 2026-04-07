import 'package:flutter/material.dart';
import '../../../app.dart';

// Pantalla de ajustes
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final auth = AuthProvider.of(context);
    final user = auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajustes'),
      ),
      body: ListView(
        children: [
          // info del usuario
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: colorScheme.primaryContainer,
                  child: Icon(
                    Icons.person,
                    color: colorScheme.primary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.displayName ?? 'Usuario',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user?.email ?? '',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // opciones
          _SettingsTile(
            icon: Icons.notifications_outlined,
            title: 'Notificaciones',
            subtitle: 'Próximamente',
            onTap: () {},
          ),
          _SettingsTile(
            icon: Icons.palette_outlined,
            title: 'Apariencia',
            subtitle: 'Sigue el tema del sistema',
            onTap: () {},
          ),
          _SettingsTile(
            icon: Icons.info_outline,
            title: 'Acerca de',
            subtitle: 'HabitAI v1.0.0',
            onTap: () {},
          ),

          const Divider(indent: 16, endIndent: 16, height: 32),

          // cerrar sesion
          _SettingsTile(
            icon: Icons.logout,
            title: 'Cerrar sesión',
            subtitle: null,
            isDestructive: true,
            onTap: () => auth.signOut(),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final bool isDestructive;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = isDestructive ? colorScheme.error : null;

    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: TextStyle(color: color),
      ),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      trailing: isDestructive ? null : const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
