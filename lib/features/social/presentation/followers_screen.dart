import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/avatar_circle.dart';
import '../../../core/widgets/ux/app_snackbar.dart' show AppSnackBar;
import '../../../core/widgets/ux/empty_state_view.dart';
import '../data/follow_repository.dart';
import '../data/user_directory_repository.dart';
import '../domain/follow_model.dart';
import '../domain/follow_request_model.dart';
import '../domain/privacy_level.dart';
import '../domain/user_directory_entry.dart';

/// Pantalla de seguidores/siguiendo estilo Instagram.
/// Tab 1: mis seguidores + búsqueda para encontrar usuarios.
/// Tab 2: a quién sigo.
/// Tab 3: solicitudes pendientes (solo relevante si perfil privado).
class FollowersScreen extends StatefulWidget {
  const FollowersScreen({super.key});

  @override
  State<FollowersScreen> createState() => _FollowersScreenState();
}

class _FollowersScreenState extends State<FollowersScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;
  late final FollowRepository _followRepo;
  late final UserDirectoryRepository _dirRepo;
  late final String _myUid;

  @override
  void initState() {
    super.initState();
    _myUid = FirebaseAuth.instance.currentUser!.uid;
    _followRepo = FollowRepository(uid: _myUid);
    _dirRepo = UserDirectoryRepository(uid: _myUid);
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Seguidores'),
        backgroundColor: scheme.surface,
        scrolledUnderElevation: 0,
        bottom: TabBar(
          controller: _tabCtrl,
          tabs: [
            const Tab(text: 'Seguidores'),
            const Tab(text: 'Siguiendo'),
            Tab(
              child: StreamBuilder<List<FollowRequestModel>>(
                stream: _followRepo.watchPendingFollowRequests(),
                builder: (context, snap) {
                  final count = snap.data?.length ?? 0;
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Solicitudes'),
                      if (count > 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: scheme.error,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$count',
                            style: TextStyle(
                              color: scheme.onError,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _FollowersTab(
            myUid: _myUid,
            followRepo: _followRepo,
            dirRepo: _dirRepo,
          ),
          _FollowingTab(
            myUid: _myUid,
            followRepo: _followRepo,
          ),
          _RequestsTab(
            myUid: _myUid,
            followRepo: _followRepo,
          ),
        ],
      ),
    );
  }
}

// ===== TAB 1: MIS SEGUIDORES + BÚSQUEDA =====

class _FollowersTab extends StatefulWidget {
  final String myUid;
  final FollowRepository followRepo;
  final UserDirectoryRepository dirRepo;

  const _FollowersTab({
    required this.myUid,
    required this.followRepo,
    required this.dirRepo,
  });

  @override
  State<_FollowersTab> createState() => _FollowersTabState();
}

class _FollowersTabState extends State<_FollowersTab> {
  final _searchCtrl = TextEditingController();
  List<UserDirectoryEntry> _searchResults = [];
  bool _searching = false;
  Timer? _debounce;
  Set<String> _followingUids = {};
  Set<String> _followerUids = {};
  Set<String> _pendingUids = {};

  @override
  void initState() {
    super.initState();
    _loadFollowState();
    _searchCtrl.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.removeListener(_onSearchChanged);
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadFollowState() async {
    final results = await Future.wait([
      widget.followRepo.getFollowingUids(),
      widget.followRepo.getFollowerUids(),
    ]);
    if (mounted) {
      setState(() {
        _followingUids = results[0].toSet();
        _followerUids = results[1].toSet();
      });
    }
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.length < 2) {
      setState(() {
        _searchResults = [];
        _searching = false;
      });
      return;
    }
    setState(() => _searching = true);
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      final results = await widget.dirRepo.searchByUsername(q);
      if (!mounted) return;
      setState(() {
        _searchResults = results
            .where((e) => e.uid != widget.myUid)
            .take(8)
            .toList();
        _searching = false;
      });
    });
  }

  String _chipLabel(String uid) {
    final iFollow = _followingUids.contains(uid);
    final followsMe = _followerUids.contains(uid);
    if (iFollow && followsMe) return 'Mutuo';
    if (iFollow) return 'Siguiendo';
    if (followsMe) return 'Te sigue';
    if (_pendingUids.contains(uid)) return 'Solicitado';
    return '';
  }

  Future<void> _followOrRequest(UserDirectoryEntry target) async {
    if (_followingUids.contains(target.uid)) return;

    final me = FirebaseAuth.instance.currentUser!;
    final myEntry = await widget.dirRepo.getEntry(widget.myUid);
    final myUsername = myEntry?.username ?? '';
    final myDisplayName = me.displayName ?? '';

    try {
      // perfil privado → solicitud
      if (target.profileVisibility != PrivacyLevel.everyone) {
        final hasPending =
            await widget.followRepo.hasPendingFollowRequest(target.uid);
        if (hasPending) {
          if (mounted) AppSnackBar.showInfo(context, 'Solicitud ya enviada');
          return;
        }
        final targetEntry = await widget.dirRepo.getEntry(target.uid);
        await widget.followRepo.sendFollowRequest(
          toUid: target.uid,
          fromUsername: myUsername,
          fromDisplayName: myDisplayName,
          fromPhotoUrl: me.photoURL,
          toUsername: target.username,
          toDisplayName: target.displayName,
          toPhotoUrl: targetEntry?.photoUrl,
        );
        if (mounted) {
          AppSnackBar.showInfo(
              context, 'Solicitud enviada a @${target.username}');
          setState(() => _pendingUids.add(target.uid));
        }
      } else {
        // perfil público → follow directo
        await widget.followRepo.follow(
          targetUid: target.uid,
          targetUsername: target.username,
          targetDisplayName: target.displayName,
          targetPhotoUrl: target.photoUrl,
          myUsername: myUsername,
          myDisplayName: myDisplayName,
          myPhotoUrl: me.photoURL,
        );
        if (mounted) {
          AppSnackBar.showInfo(context, 'Siguiendo a @${target.username}');
          setState(() {
            _followingUids.add(target.uid);
            _searchResults = [];
            _searchCtrl.clear();
          });
        }
      }
    } catch (e) {
      if (mounted) AppSnackBar.showError(context, 'Error: $e');
    }
  }

  Future<void> _removeFollower(FollowModel follower) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar seguidor'),
        content: Text('¿Eliminar a @${follower.username} de tus seguidores?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Eliminar',
              style: TextStyle(color: Theme.of(ctx).colorScheme.error),
            ),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await widget.followRepo.removeFollower(follower.uid);
    if (mounted) {
      AppSnackBar.showInfo(context, 'Seguidor eliminado');
      setState(() => _followerUids.remove(follower.uid));
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: TextField(
            controller: _searchCtrl,
            autocorrect: false,
            decoration: InputDecoration(
              hintText: 'Buscar por @username',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _searching
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() => _searchResults = []);
                          },
                        )
                      : null,
              filled: true,
              fillColor:
                  scheme.surfaceContainerHighest.withValues(alpha: 0.4),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),

        if (_searchResults.isNotEmpty)
          Container(
            margin: const EdgeInsets.fromLTRB(16, 6, 16, 0),
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: scheme.outlineVariant.withValues(alpha: 0.4)),
              boxShadow: AppTheme.ambientShadow(opacity: 0.08),
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _searchResults.length,
              itemBuilder: (_, i) {
                final entry = _searchResults[i];
                final chip = _chipLabel(entry.uid);
                final isPrivate =
                    entry.profileVisibility != PrivacyLevel.everyone;
                return ListTile(
                  leading: AvatarCircle(
                    initials: entry.avatarInitials,
                    photoUrl: entry.photoUrl,
                    size: 36,
                  ),
                  title: Text(entry.displayName,
                      style:
                          const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Row(
                    children: [
                      Text('@${entry.username}'),
                      if (isPrivate) ...[
                        const SizedBox(width: 4),
                        Icon(Icons.lock_rounded,
                            size: 12, color: scheme.onSurfaceVariant),
                      ],
                    ],
                  ),
                  trailing: chip.isNotEmpty
                      ? Chip(
                          label: Text(chip),
                          labelStyle: TextStyle(
                            fontSize: 11,
                            color: scheme.primary,
                          ),
                          side: BorderSide.none,
                          backgroundColor:
                              scheme.primaryContainer.withValues(alpha: 0.4),
                        )
                      : TextButton(
                          onPressed: () => _followOrRequest(entry),
                          child: Text(isPrivate ? 'Solicitar' : 'Seguir'),
                        ),
                  dense: true,
                );
              },
            ),
          ),

        const SizedBox(height: 8),

        Expanded(
          child: StreamBuilder<List<FollowModel>>(
            stream: widget.followRepo.watchMyFollowers(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final followers = snap.data ?? [];
              if (followers.isEmpty) {
                return const EmptyStateView(
                  icon: Icons.people_outline_rounded,
                  title: 'Aún no tienes seguidores',
                  subtitle:
                      'Busca usuarios por @username para seguirlos o que te sigan',
                );
              }
              return ListView.builder(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: followers.length,
                itemBuilder: (_, i) {
                  final f = followers[i];
                  return _FollowTile(
                    model: f,
                    trailingLabel: _followingUids.contains(f.uid)
                        ? 'Mutuo'
                        : 'Te sigue',
                    onAction: () => _removeFollower(f),
                    actionLabel: 'Eliminar',
                  ).animate().fadeIn(delay: Duration(milliseconds: i * 40));
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

// ===== TAB 2: SIGUIENDO =====

class _FollowingTab extends StatefulWidget {
  final String myUid;
  final FollowRepository followRepo;

  const _FollowingTab({
    required this.myUid,
    required this.followRepo,
  });

  @override
  State<_FollowingTab> createState() => _FollowingTabState();
}

class _FollowingTabState extends State<_FollowingTab> {
  Future<void> _unfollow(FollowModel f) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Dejar de seguir'),
        content: Text('¿Dejar de seguir a @${f.username}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Dejar de seguir',
              style:
                  TextStyle(color: Theme.of(ctx).colorScheme.error),
            ),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await widget.followRepo.unfollow(f.uid);
    if (mounted) AppSnackBar.showInfo(context, 'Dejaste de seguir a @${f.username}');
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<FollowModel>>(
      stream: widget.followRepo.watchMyFollowing(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final following = snap.data ?? [];
        if (following.isEmpty) {
          return const EmptyStateView(
            icon: Icons.person_search_rounded,
            title: 'No sigues a nadie',
            subtitle: 'Busca usuarios en la pestaña Seguidores',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: following.length,
          itemBuilder: (_, i) {
            final f = following[i];
            return _FollowTile(
              model: f,
              trailingLabel: 'Siguiendo',
              onAction: () => _unfollow(f),
              actionLabel: 'Dejar de seguir',
            ).animate().fadeIn(delay: Duration(milliseconds: i * 40));
          },
        );
      },
    );
  }
}

// ===== TAB 3: SOLICITUDES ENTRANTES =====

class _RequestsTab extends StatelessWidget {
  final String myUid;
  final FollowRepository followRepo;

  const _RequestsTab({required this.myUid, required this.followRepo});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<FollowRequestModel>>(
      stream: followRepo.watchPendingFollowRequests(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final requests = snap.data ?? [];
        if (requests.isEmpty) {
          return const EmptyStateView(
            icon: Icons.mark_email_unread_outlined,
            title: 'Sin solicitudes pendientes',
            subtitle:
                'Aquí aparecerán las solicitudes de seguimiento que recibas',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          itemCount: requests.length,
          itemBuilder: (_, i) {
            final req = requests[i];
            return _RequestTile(
              request: req,
              onAccept: () => followRepo.acceptFollowRequest(req.id),
              onDecline: () => followRepo.declineFollowRequest(req.id),
            ).animate().fadeIn(delay: Duration(milliseconds: i * 40));
          },
        );
      },
    );
  }
}

// ===== WIDGETS REUTILIZABLES =====

class _FollowTile extends StatelessWidget {
  final FollowModel model;
  final String trailingLabel;
  final VoidCallback onAction;
  final String actionLabel;

  const _FollowTile({
    required this.model,
    required this.trailingLabel,
    required this.onAction,
    required this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: scheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: AvatarCircle(
          initials: model.avatarInitials,
          photoUrl: model.photoUrl,
          size: 40,
        ),
        title: Text(model.displayName,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('@${model.username}'),
        trailing: PopupMenuButton<String>(
          onSelected: (v) {
            if (v == 'action') onAction();
          },
          itemBuilder: (_) => [
            PopupMenuItem(
              value: 'action',
              child: Row(
                children: [
                  Icon(Icons.person_remove_outlined,
                      size: 18, color: scheme.error),
                  const SizedBox(width: 8),
                  Text(actionLabel, style: TextStyle(color: scheme.error)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RequestTile extends StatelessWidget {
  final FollowRequestModel request;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const _RequestTile({
    required this.request,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final initials = () {
      final name = request.fromDisplayName.trim();
      if (name.isNotEmpty) {
        final parts = name.split(' ').where((p) => p.isNotEmpty).toList();
        if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
        if (parts.isNotEmpty) return parts[0][0].toUpperCase();
      }
      if (request.fromUsername.isNotEmpty) return request.fromUsername[0].toUpperCase();
      return '?';
    }();

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      color: scheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            AvatarCircle(
              initials: initials,
              photoUrl: request.fromPhotoUrl,
              size: 44,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    request.fromDisplayName,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    '@${request.fromUsername}',
                    style: TextStyle(
                      fontSize: 12,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            IconButton.filled(
              onPressed: onAccept,
              icon: const Icon(Icons.check_rounded, size: 20),
              style: IconButton.styleFrom(
                backgroundColor: scheme.primary,
                foregroundColor: scheme.onPrimary,
                minimumSize: const Size(36, 36),
              ),
            ),
            const SizedBox(width: 6),
            IconButton.outlined(
              onPressed: onDecline,
              icon: const Icon(Icons.close_rounded, size: 20),
              style: IconButton.styleFrom(
                minimumSize: const Size(36, 36),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
