import 'dart:collection';
import 'dart:convert';

import 'package:flutter/services.dart';

import '../../core/utils/phrase_normalizer.dart';
import '../../core/utils/text_similarity.dart';
import 'phrase_entry.dart';

const String kPhrasebookAsset = 'assets/phrasebook/phrasebook.json';

/// Bundled phrasebook with a per-language index of normalized phrases.
class Phrasebook {
  Phrasebook({AssetBundle? bundle, String assetPath = kPhrasebookAsset})
      : _bundle = bundle,
        _assetPath = assetPath;

  final AssetBundle? _bundle;
  final String _assetPath;

  final List<PhraseEntry> _entries = [];
  final Map<String, Map<String, int>> _index = {};
  bool _ready = false;

  bool get isReady => _ready;
  List<PhraseEntry> get entries => UnmodifiableListView(_entries);

  /// Loads the JSON asset and builds the index.
  Future<void> initialize() async {
    final json = await (_bundle ?? rootBundle).loadString(_assetPath);
    loadFromJson(json);
  }

  /// Builds the index from raw JSON text. Duplicates keep the first entry.
  void loadFromJson(String json) {
    final decoded = jsonDecode(json) as Map<String, dynamic>;
    final rows = (decoded['entries'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>();
    _entries
      ..clear()
      ..addAll(rows.map(PhraseEntry.fromJson));
    _index.clear();
    for (var i = 0; i < _entries.length; i++) {
      for (final MapEntry(:key, :value) in _entries[i].texts.entries) {
        final normalized = normalize(value);
        if (normalized.isEmpty) continue;
        (_index[key] ??= {}).putIfAbsent(normalized, () => i);
      }
    }
    _ready = true;
  }

  /// Entry index whose [langId] phrase equals [normalized], or null.
  /// With [targetId], entries lacking that language are ignored.
  int? lookupExact(String langId, String normalized, {String? targetId}) {
    final index = _index[langId]?[normalized];
    if (index == null) return null;
    if (targetId != null && _entries[index].textFor(targetId) == null) {
      return null;
    }
    return index;
  }

  /// Most similar entry for [langId], or null when there is no candidate.
  (int, double)? bestFuzzy(
    String langId,
    String normalized, {
    String? targetId,
  }) {
    final candidates = _index[langId];
    if (candidates == null) return null;
    (int, double)? best;
    for (final MapEntry(:key, :value) in candidates.entries) {
      if (targetId != null && _entries[value].textFor(targetId) == null) {
        continue;
      }
      final score = similarity(normalized, key);
      if (best == null || score > best.$2) best = (value, score);
    }
    return best;
  }

  /// Original [langId] phrases ordered by similarity, highest first, limited to
  /// entries that also have [targetId] filled.
  List<String> topSuggestions(
    String langId,
    String normalized,
    int n, {
    required String targetId,
  }) {
    final candidates = _index[langId];
    if (candidates == null || n <= 0) return const [];
    final scored = <(int, double)>[];
    for (final MapEntry(:key, :value) in candidates.entries) {
      if (_entries[value].textFor(targetId) == null) continue;
      scored.add((value, similarity(normalized, key)));
    }
    scored.sort((a, b) {
      final byScore = b.$2.compareTo(a.$2);
      return byScore != 0 ? byScore : a.$1.compareTo(b.$1);
    });
    return [
      for (final (index, _) in scored.take(n)) _entries[index].textFor(langId)!,
    ];
  }
}
