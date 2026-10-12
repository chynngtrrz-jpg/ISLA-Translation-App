enum TranslationOrigin { phrasebook, model }

class TranslationResult {
  const TranslationResult({
    required this.text,
    required this.confidence,
    required this.latencyMs,
    this.origin = TranslationOrigin.model,
  });

  final String text;
  final double confidence;
  final int latencyMs;
  final TranslationOrigin origin;
}
