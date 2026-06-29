import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/widgets/app_emoji.dart';
import '../../domain/reaction_model.dart';

/// Píldora de reacciones al perfil: chips de AppEmoji.reactionKeys + contador total.
/// Usada tanto en ProfileScreen (lectura, isOwnProfile=true)
/// como en PublicProfileScreen (interactiva, isOwnProfile=false).
class ProfileReactionsPill extends StatelessWidget {
  final String myUid;
  final List<ReactionModel> reactions;
  final bool isOwnProfile;
  final Future<void> Function(String emoji) onTap;

  const ProfileReactionsPill({
    super.key,
    required this.myUid,
    required this.reactions,
    required this.isOwnProfile,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final total = reactions.length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: ReactionBar(
              myUid: myUid,
              reactions: reactions,
              isOwnProfile: isOwnProfile,
              onTap: onTap,
            ),
          ),
          if (total > 0) ...[
            const SizedBox(width: 8),
            Text(
              total == 1 ? '1 reacción' : '$total reacciones',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Fila de chips (AppEmoji.reactionKeys) con contadores para reaccionar a un perfil.
/// El chip activo lleva borde primary. Al tocar, rebota con animación de escala.
class ReactionBar extends StatefulWidget {
  final String myUid;
  final List<ReactionModel> reactions;
  final bool isOwnProfile;
  /// Recibe el emoji tocado; el padre decide si reaccionar o quitar reacción
  final Future<void> Function(String emoji) onTap;

  const ReactionBar({
    super.key,
    required this.myUid,
    required this.reactions,
    required this.isOwnProfile,
    required this.onTap,
  });

  @override
  State<ReactionBar> createState() => _ReactionBarState();
}

class _ReactionBarState extends State<ReactionBar> {
  bool _busy = false;
  String? _bouncing;

  String? get _myEmoji => widget.reactions
      .where((r) => r.reactorUid == widget.myUid)
      .map((r) => r.emoji)
      .firstOrNull;

  Map<String, int> get _counts {
    final map = <String, int>{};
    for (final r in widget.reactions) {
      map[r.emoji] = (map[r.emoji] ?? 0) + 1;
    }
    return map;
  }

  Future<void> _handleTap(String emoji) async {
    if (_busy || widget.isOwnProfile) return;
    setState(() {
      _busy = true;
      _bouncing = emoji;
    });
    try {
      await widget.onTap(emoji);
    } finally {
      if (mounted) setState(() { _busy = false; _bouncing = null; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final counts = _counts;
    final myEmoji = _myEmoji;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final emoji in AppEmoji.reactionKeys)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: _EmojiChip(
                emoji: emoji,
                count: counts[emoji] ?? 0,
                active: myEmoji == emoji,
                bouncing: _bouncing == emoji,
                disabled: widget.isOwnProfile,
                onTap: () => _handleTap(emoji),
                scheme: scheme,
              ),
            ),
        ],
      ),
    );
  }
}

class _EmojiChip extends StatelessWidget {
  final String emoji;
  final int count;
  final bool active;
  final bool bouncing;
  final bool disabled;
  final VoidCallback onTap;
  final ColorScheme scheme;

  const _EmojiChip({
    required this.emoji,
    required this.count,
    required this.active,
    required this.bouncing,
    required this.disabled,
    required this.onTap,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    Widget chip = GestureDetector(
      onTap: disabled ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: active
              ? scheme.primary.withValues(alpha: 0.12)
              : scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active
                ? scheme.primary.withValues(alpha: 0.6)
                : scheme.outlineVariant.withValues(alpha: 0.3),
            width: active ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppEmoji.reaction(emoji, size: 22),
            if (count > 0) ...[
              const SizedBox(width: 5),
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: active ? scheme.primary : scheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );

    if (bouncing) {
      chip = chip
          .animate()
          .scale(
            begin: const Offset(1, 1),
            end: const Offset(1.3, 1.3),
            duration: 120.ms,
            curve: Curves.easeOut,
          )
          .then()
          .scale(
            begin: const Offset(1.3, 1.3),
            end: const Offset(1, 1),
            duration: 100.ms,
            curve: Curves.easeIn,
          );
    }
    return chip;
  }
}
