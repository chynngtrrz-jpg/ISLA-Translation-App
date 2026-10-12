/// One phrasebook row: the same phrase in every language that has it filled.
class PhraseEntry {
  const PhraseEntry({required this.id, required this.texts});

  factory PhraseEntry.fromJson(Map<String, dynamic> json) {
    final texts = <String, String>{};
    for (final MapEntry(:key, :value) in json.entries) {
      if (key == 'id' || value is! String) continue;
      final trimmed = value.trim();
      if (trimmed.isNotEmpty) texts[key] = trimmed;
    }
    return PhraseEntry(id: json['id'] as String? ?? '', texts: texts);
  }

  final String id;

  /// Language id to phrase text; languages without a phrase are omitted.
  final Map<String, String> texts;

  String? textFor(String languageId) => texts[languageId];
}
