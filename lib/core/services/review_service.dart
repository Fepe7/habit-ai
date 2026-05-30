import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

/// Gestiona la solicitud de valoración en Play Store.
class ReviewService {
  ReviewService._();
  static final ReviewService instance = ReviewService._();

  static const _storeUrl =
      'https://play.google.com/store/apps/details?id=com.habitai.habitai';
  static const _prefKey = 'review_last_prompt_ms';
  // mínimo 30 días entre peticiones automáticas
  static const _throttleMs = 30 * 24 * 60 * 60 * 1000;

  final _review = InAppReview.instance;

  /// Abre directamente la ficha de la store (desde botón en Settings).
  Future<void> openStoreListing() async {
    try {
      await _review.openStoreListing();
    } catch (_) {
      await launchUrl(
        Uri.parse(_storeUrl),
        mode: LaunchMode.externalApplication,
      );
    }
  }

  /// Solicita la In-App Review nativa si está disponible y no se ha pedido
  /// recientemente. Llamar tras un hito positivo (racha 7 días, logro, etc.).
  Future<void> requestReview() async {
    if (!await _review.isAvailable()) return;
    if (!await _canPrompt()) return;

    await _review.requestReview();
    await _savePromptTimestamp();
  }

  Future<bool> _canPrompt() async {
    final prefs = await SharedPreferences.getInstance();
    final last = prefs.getInt(_prefKey) ?? 0;
    return DateTime.now().millisecondsSinceEpoch - last >= _throttleMs;
  }

  Future<void> _savePromptTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefKey, DateTime.now().millisecondsSinceEpoch);
  }
}
