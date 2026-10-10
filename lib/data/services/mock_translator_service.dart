import '../models/language.dart';
import '../models/translation_result.dart';
import 'translator_service.dart';

class MockTranslatorService implements TranslatorService {
  const MockTranslatorService();

  @override
  bool get isReady => true;

  @override
  Future<TranslationResult> translate({
    required String text,
    required Language source,
    required Language target,
  }) async {
    final normalized = text.trim().toLowerCase();
    if (source.id == 'en' &&
        target.id == 'ini' &&
        normalized ==
            'good morning. do you know how to travel to bonbon beach?') {
      return const TranslationResult(
        text: 'Maayong aga. Sayod mo ba kung paano ang pakadto sa Bonbon beach?',
        confidence: 0.86,
        latencyMs: 420,
      );
    }
    return TranslationResult(
      text: text.trim(),
      confidence: 0.50,
      latencyMs: 120,
    );
  }
}
