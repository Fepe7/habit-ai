import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/public_profile_repository.dart';

enum _UsernameState { idle, checking, available, taken, invalid }

/// Bottom sheet para elegir o cambiar username público.
/// Valida formato + disponibilidad con debounce 400ms.
class UsernameInputSheet extends StatefulWidget {
  final PublicProfileRepository repo;
  final String? currentUsername;

  const UsernameInputSheet({
    super.key,
    required this.repo,
    this.currentUsername,
  });

  /// Muestra el sheet y devuelve el username elegido o null si se cancela
  static Future<String?> show(
    BuildContext context,
    PublicProfileRepository repo, {
    String? currentUsername,
  }) {
    return showAppBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => UsernameInputSheet(
        repo: repo,
        currentUsername: currentUsername,
      ),
    );
  }

  @override
  State<UsernameInputSheet> createState() => _UsernameInputSheetState();
}

class _UsernameInputSheetState extends State<UsernameInputSheet> {
  final _controller = TextEditingController();
  _UsernameState _state = _UsernameState.idle;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    if (widget.currentUsername != null) {
      _controller.text = widget.currentUsername!;
    }
    _controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.removeListener(_onChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onChanged() {
    final value = _controller.text.trim();
    _debounce?.cancel();

    if (value.isEmpty) {
      setState(() => _state = _UsernameState.idle);
      return;
    }

    if (!PublicProfileRepository.isValidUsername(value)) {
      setState(() => _state = _UsernameState.invalid);
      return;
    }

    // Si no ha cambiado respecto al username actual, marcar como disponible
    if (value == widget.currentUsername) {
      setState(() => _state = _UsernameState.available);
      return;
    }

    setState(() => _state = _UsernameState.checking);
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      final available = await widget.repo.isUsernameAvailable(value);
      if (!mounted) return;
      setState(() {
        _state = available
            ? _UsernameState.available
            : _UsernameState.taken;
      });
    });
  }

  bool get _canConfirm => _state == _UsernameState.available;

  String? _helperText(S s) {
    switch (_state) {
      case _UsernameState.idle:
        return s.usernameSheetHelperIdle;
      case _UsernameState.checking:
        return s.usernameSheetChecking;
      case _UsernameState.available:
        return s.authUsernameAvailable;
      case _UsernameState.taken:
        return s.authUsernameTaken;
      case _UsernameState.invalid:
        return s.authUsernameFormat;
    }
  }

  Color? _helperColor(ColorScheme scheme) {
    switch (_state) {
      case _UsernameState.available:
        return Colors.green;
      case _UsernameState.taken:
      case _UsernameState.invalid:
        return scheme.error;
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final s = S.of(context);
    final keyboard = MediaQuery.of(context).viewInsets.bottom;
    // La nav bar custom mide 72dp. useSafeArea no la esquiva, hay que hacerlo a mano.
    // Cuando el teclado está abierto ya empuja el sheet hacia arriba,
    // así que solo sumamos la nav bar cuando el teclado está cerrado.
    const navBarHeight = 72.0;
    final bottomPadding = keyboard > 0 ? keyboard : navBarHeight;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(24, 16, 24, 24 + bottomPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: scheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          Text(
            widget.currentUsername == null
                ? s.usernameSheetTitleNew
                : s.usernameSheetTitleChange,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            s.usernameSheetSubtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),

          const SizedBox(height: 20),

          // campo de username
          TextField(
            controller: _controller,
            autofocus: true,
            autocorrect: false,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) {
              if (_canConfirm) Navigator.pop(context, _controller.text.trim());
            },
            decoration: InputDecoration(
              prefixText: '@',
              hintText: s.authUsernameHint,
              helperText: _helperText(s),
              helperStyle: TextStyle(color: _helperColor(scheme)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              suffixIcon: _state == _UsernameState.checking
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : _state == _UsernameState.available
                      ? const Icon(Icons.check_circle_rounded,
                          color: Colors.green)
                      : _state == _UsernameState.taken ||
                              _state == _UsernameState.invalid
                          ? Icon(Icons.error_outline_rounded,
                              color: scheme.error)
                          : null,
            ),
          ),

          const SizedBox(height: 8),

          // qué datos se muestran
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.usernameSheetVisibleData,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                _InfoRow(Icons.person_outline_rounded, s.usernameSheetDataName),
                _InfoRow(Icons.local_fire_department_rounded, s.usernameSheetDataStreaks),
                _InfoRow(Icons.checklist_rounded, s.usernameSheetDataHabits),
                _InfoRow(Icons.emoji_events_rounded, s.usernameSheetDataLevel),
                const SizedBox(height: 4),
                Text(
                  s.usernameSheetPrivacy,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context, null),
                  child: Text(s.cancel),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed: _canConfirm
                      ? () => Navigator.pop(context, _controller.text.trim())
                      : null,
                  child: Text(s.usernameSheetConfirm),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoRow(this.icon, this.label);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 14, color: scheme.primary),
          const SizedBox(width: 6),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
