import 'package:flutter/material.dart';

/// Visor de foto de perfil a pantalla completa estilo Instagram:
/// la foto se expande desde el avatar (Hero) y se descarta arrastrando
/// en cualquier dirección — el fondo se desvanece según la distancia.
class ProfilePhotoViewer extends StatefulWidget {
  final String photoUrl;
  final String heroTag;

  /// Acción opcional (solo perfil propio): botón para cambiar la foto.
  final VoidCallback? onEdit;
  final String? editLabel;

  const ProfilePhotoViewer({
    super.key,
    required this.photoUrl,
    required this.heroTag,
    this.onEdit,
    this.editLabel,
  });

  /// Abre el visor como ruta transparente sobre la pantalla actual.
  static Future<void> show(
    BuildContext context, {
    required String photoUrl,
    required String heroTag,
    VoidCallback? onEdit,
    String? editLabel,
  }) {
    return Navigator.of(context, rootNavigator: true).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.transparent,
        transitionDuration: const Duration(milliseconds: 260),
        reverseTransitionDuration: const Duration(milliseconds: 220),
        pageBuilder: (_, _, _) => ProfilePhotoViewer(
          photoUrl: photoUrl,
          heroTag: heroTag,
          onEdit: onEdit,
          editLabel: editLabel,
        ),
        transitionsBuilder: (_, animation, _, child) => FadeTransition(
          opacity: animation,
          child: child,
        ),
      ),
    );
  }

  @override
  State<ProfilePhotoViewer> createState() => _ProfilePhotoViewerState();
}

class _ProfilePhotoViewerState extends State<ProfilePhotoViewer>
    with SingleTickerProviderStateMixin {
  // Desplazamiento acumulado del drag; al soltar, o se cierra o vuelve a cero.
  Offset _drag = Offset.zero;
  late final AnimationController _restoreController;
  Animation<Offset>? _restoreAnimation;

  static const _dismissDistance = 110.0;
  static const _dismissVelocity = 700.0;

  @override
  void initState() {
    super.initState();
    _restoreController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    )..addListener(() {
        setState(() => _drag = _restoreAnimation!.value);
      });
  }

  @override
  void dispose() {
    _restoreController.dispose();
    super.dispose();
  }

  double get _dragProgress => (_drag.distance / 280).clamp(0.0, 1.0);

  void _onPanStart(DragStartDetails _) => _restoreController.stop();

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() => _drag += details.delta);
  }

  void _onPanEnd(DragEndDetails details) {
    final velocity = details.velocity.pixelsPerSecond.distance;
    if (_drag.distance > _dismissDistance || velocity > _dismissVelocity) {
      Navigator.of(context).pop();
      return;
    }
    // vuelve suavemente a la posición original
    _restoreAnimation = Tween<Offset>(begin: _drag, end: Offset.zero).animate(
      CurvedAnimation(parent: _restoreController, curve: Curves.easeOutCubic),
    );
    _restoreController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final photoDiameter = size.width - 72;
    final backdropOpacity = (1 - _dragProgress * 0.9).clamp(0.0, 1.0);
    final photoScale = (1 - _dragProgress * 0.15).clamp(0.85, 1.0);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => Navigator.of(context).pop(),
        onPanStart: _onPanStart,
        onPanUpdate: _onPanUpdate,
        onPanEnd: _onPanEnd,
        child: Stack(
          children: [
            // fondo oscuro que se desvanece al arrastrar
            Positioned.fill(
              child: ColoredBox(
                color: Colors.black.withValues(alpha: 0.9 * backdropOpacity),
              ),
            ),
            Center(
              child: Transform.translate(
                offset: _drag,
                child: Transform.scale(
                  scale: photoScale,
                  child: Hero(
                    tag: widget.heroTag,
                    child: ClipOval(
                      child: Image.network(
                        widget.photoUrl,
                        width: photoDiameter,
                        height: photoDiameter,
                        fit: BoxFit.cover,
                        loadingBuilder: (_, child, progress) {
                          if (progress == null) return child;
                          return SizedBox(
                            width: photoDiameter,
                            height: photoDiameter,
                            child: const Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (_, _, _) => Container(
                          width: photoDiameter,
                          height: photoDiameter,
                          color: Colors.white12,
                          child: const Icon(
                            Icons.broken_image_outlined,
                            color: Colors.white54,
                            size: 48,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // botón cerrar arriba y acción de editar abajo (si procede)
            SafeArea(
              child: Opacity(
                opacity: backdropOpacity,
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.topRight,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(
                            Icons.close_rounded,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (widget.onEdit != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 28),
                        child: FilledButton.tonalIcon(
                          onPressed: () {
                            Navigator.of(context).pop();
                            widget.onEdit!();
                          },
                          icon: const Icon(Icons.camera_alt_rounded, size: 18),
                          label: Text(widget.editLabel ?? ''),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.white.withValues(alpha: 0.16),
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
