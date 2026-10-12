final RegExp _whitespace = RegExp(r'\s+');
final RegExp _disallowed = RegExp(r"[^\p{L}\p{M}\p{N} '\-]", unicode: true);
final RegExp _sentenceBreak = RegExp(r'(?<=[.?!])\s+');

/// Normalizes text for phrasebook indexing and lookup.
///
/// Lowercases, straightens curly quotes, drops everything except letters
/// (including ñ and accents), digits, spaces, apostrophes and hyphens, and
/// collapses whitespace.
String normalize(String s) {
  final straightened = s
      .toLowerCase()
      .replaceAll('\u2018', "'")
      .replaceAll('\u2019', "'")
      .replaceAll('\u201B', "'")
      .replaceAll('\u2032', "'");
  return straightened
      .replaceAll(_whitespace, ' ')
      .replaceAll(_disallowed, '')
      .replaceAll(_whitespace, ' ')
      .trim();
}

/// Splits [s] after `.`, `?` or `!` that are followed by whitespace.
List<String> splitSentences(String s) => s
    .split(_sentenceBreak)
    .map((segment) => segment.trim())
    .where((segment) => segment.isNotEmpty)
    .toList();
