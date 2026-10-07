class TranslationResult {
  const TranslationResult({
    required this.text,
    required this.confidence,
    required this.latencyMs,
  });

  final String text;
  final double confidence;
  final int latencyMs;
}
