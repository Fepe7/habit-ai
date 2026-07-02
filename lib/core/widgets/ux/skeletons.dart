import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Placeholder que imita la estructura de HabitCard mientras carga
class HabitCardSkeleton extends StatelessWidget {
  const HabitCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surfaceContainerHighest;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          _Bone(width: 24, height: 24, radius: 12, color: surface),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Bone(width: double.infinity, height: 14, color: surface),
                const SizedBox(height: 8),
                _Bone(width: 100, height: 11, color: surface),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _Bone(width: 32, height: 32, radius: 8, color: surface),
        ],
      ),
    )
        .animate(onPlay: (c) => c.repeat())
        .shimmer(duration: 1400.ms, color: Colors.white.withValues(alpha: 0.45));
  }
}

/// N HabitCardSkeleton con header gris — simula una sección de grupo
class SectionSkeleton extends StatelessWidget {
  const SectionSkeleton({super.key, this.itemCount = 3});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surfaceContainerHighest;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // header del grupo
          Row(
            children: [
              _Bone(width: 28, height: 28, radius: 8, color: surface),
              const SizedBox(width: 12),
              _Bone(width: 120, height: 14, color: surface),
            ],
          )
              .animate(onPlay: (c) => c.repeat())
              .shimmer(duration: 1400.ms, color: Colors.white.withValues(alpha: 0.45)),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                for (int i = 0; i < itemCount; i++) ...[
                  if (i > 0)
                    Divider(
                      height: 1,
                      color: Theme.of(context)
                          .colorScheme
                          .outlineVariant
                          .withValues(alpha: 0.08),
                    ),
                  HabitCardSkeleton(),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Skeleton para un tile cuadrado (logros, niveles)
class GridTileSkeleton extends StatelessWidget {
  const GridTileSkeleton({super.key, this.aspectRatio = 1.0});

  final double aspectRatio;

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surfaceContainerHighest;

    return AspectRatio(
      aspectRatio: aspectRatio,
      child: _Bone(
        width: double.infinity,
        height: double.infinity,
        radius: 16,
        color: surface,
      )
          .animate(onPlay: (c) => c.repeat())
          .shimmer(duration: 1400.ms, color: Colors.white.withValues(alpha: 0.45)),
    );
  }
}

/// Fila de 3 stat cards skeleton — replica _buildStatCards del dashboard
class StatRowSkeleton extends StatelessWidget {
  const StatRowSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surfaceContainerHighest;

    return Row(
      children: [
        for (int i = 0; i < 3; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(
            child: Container(
              height: 96,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _Bone(width: 36, height: 36, radius: 10, color: surface),
                  const SizedBox(height: 10),
                  _Bone(width: 40, height: 16, color: surface),
                  const SizedBox(height: 6),
                  _Bone(width: 56, height: 10, color: surface),
                ],
              ),
            )
                .animate(onPlay: (c) => c.repeat())
                .shimmer(
                  duration: 1400.ms,
                  color: Colors.white.withValues(alpha: 0.45),
                ),
          ),
        ],
      ],
    );
  }
}

/// Tile de lista con avatar circular + dos líneas + acción — para listas
/// de personas (seguidores, resultados de búsqueda, feed de comunidad)
class ListTileSkeleton extends StatelessWidget {
  const ListTileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surfaceContainerHighest;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          _Bone(width: 44, height: 44, radius: 22, color: surface),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Bone(width: 130, height: 13, color: surface),
                const SizedBox(height: 7),
                _Bone(width: 80, height: 10, color: surface),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _Bone(width: 72, height: 30, radius: 15, color: surface),
        ],
      ),
    )
        .animate(onPlay: (c) => c.repeat())
        .shimmer(duration: 1400.ms, color: Colors.white.withValues(alpha: 0.45));
  }
}

/// Bloque rectangular shimmer — para gráficas
class ChartSkeleton extends StatelessWidget {
  const ChartSkeleton({super.key, this.height = 180});

  final double height;

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surfaceContainerHighest;

    return _Bone(
      width: double.infinity,
      height: height,
      radius: 16,
      color: surface,
    )
        .animate(onPlay: (c) => c.repeat())
        .shimmer(duration: 1400.ms, color: Colors.white.withValues(alpha: 0.45));
  }
}

// pieza base de hueso skeleton
class _Bone extends StatelessWidget {
  const _Bone({
    required this.width,
    required this.height,
    this.radius = 6,
    required this.color,
  });

  final double width;
  final double height;
  final double radius;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
