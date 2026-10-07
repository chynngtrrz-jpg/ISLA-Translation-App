import '../models/language.dart';
import '../models/translation_result.dart';

abstract interface class TranslatorService {
  bool get isReady;

  Future<TranslationResult> translate({
    required String text,
    required Language source,
    required Language target,
  });
}
