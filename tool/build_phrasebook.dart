// Builds assets/phrasebook/phrasebook.json from an Excel (.xlsx) or UTF-8 CSV
// file.
//
// Usage: dart run tool/build_phrasebook.dart data/phrasebook.xlsx
//
// `excel` cannot be resolved next to `image` (conflicting `archive` ranges), so
// .xlsx files are read directly with `archive` and `xml`.
import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:isla_app/core/utils/phrase_normalizer.dart';
import 'package:xml/xml.dart';

const String kOutputJsonPath = 'assets/phrasebook/phrasebook.json';
const String kOutputReportPath = 'tool/output/phrasebook_report.md';
const int kMaxCellLength = 600;

/// Canonical language order used in the JSON output.
const List<String> kLanguageOrder = ['en', 'fil', 'ini', 'onh', 'asi'];

const Map<String, String> _tokenToLanguage = {
  'english': 'en',
  'en': 'en',
  'tagalog': 'fil',
  'filipino': 'fil',
  'fil': 'fil',
  'ini': 'ini',
  'romblomanon': 'ini',
  'onhan': 'onh',
  'asi': 'asi',
  'bantoanon': 'asi',
};

/// Thrown when a header cell cannot be mapped to a language.
class HeaderMappingException implements Exception {
  const HeaderMappingException(this.headers, this.reason);

  final List<String> headers;
  final String reason;

  @override
  String toString() =>
      'Cannot map headers ($reason). Headers found: ${headers.join(' | ')}';
}

/// A cell longer than [kMaxCellLength] characters.
class LongCell {
  const LongCell(this.row, this.language, this.length);

  final int row;
  final String language;
  final int length;
}

/// A normalized phrase that appears in several rows with differing
/// translations.
class PhraseConflict {
  const PhraseConflict(this.language, this.phrase, this.entryIds);

  final String language;
  final String phrase;
  final List<String> entryIds;
}

/// Statistics describing one phrasebook build.
class PhrasebookReport {
  const PhrasebookReport({
    required this.rowsRead,
    required this.entriesWritten,
    required this.filledPerLanguage,
    required this.emptyPerLanguage,
    required this.singleLanguageRows,
    required this.conflicts,
    required this.longCells,
  });

  final int rowsRead;
  final int entriesWritten;
  final Map<String, int> filledPerLanguage;
  final Map<String, int> emptyPerLanguage;

  /// 1-based spreadsheet row numbers dropped for having only one language.
  final List<int> singleLanguageRows;
  final List<PhraseConflict> conflicts;
  final List<LongCell> longCells;

  String toMarkdown() {
    final out = StringBuffer()
      ..writeln('# Phrasebook build report')
      ..writeln()
      ..writeln('- Rows read: $rowsRead')
      ..writeln('- Entries written: $entriesWritten')
      ..writeln('- Rows with only one language (dropped): '
          '${singleLanguageRows.length}'
          '${singleLanguageRows.isEmpty ? '' : ' (rows ${singleLanguageRows.join(', ')})'}')
      ..writeln()
      ..writeln('## Cells per language')
      ..writeln()
      ..writeln('| Language | Filled | Empty |')
      ..writeln('|----------|--------|-------|');
    for (final language in filledPerLanguage.keys) {
      out.writeln('| $language | ${filledPerLanguage[language]} '
          '| ${emptyPerLanguage[language]} |');
    }
    out
      ..writeln()
      ..writeln('## Conflicting duplicates (${conflicts.length})')
      ..writeln();
    if (conflicts.isEmpty) out.writeln('None.');
    for (final c in conflicts) {
      out.writeln('- [${c.language}] "${c.phrase}": ${c.entryIds.join(', ')}');
    }
    out
      ..writeln()
      ..writeln(
          '## Cells over $kMaxCellLength characters (${longCells.length})')
      ..writeln();
    if (longCells.isEmpty) out.writeln('None.');
    for (final c in longCells) {
      out.writeln('- row ${c.row}, ${c.language}: ${c.length} characters');
    }
    return out.toString();
  }
}

/// Result of [buildPhrasebook].
class PhrasebookBuild {
  const PhrasebookBuild({
    required this.entries,
    required this.languages,
    required this.report,
  });

  /// Entries in row order. Each map holds `id` plus the filled languages in
  /// [kLanguageOrder].
  final List<Map<String, String>> entries;
  final List<String> languages;
  final PhrasebookReport report;

  /// Deterministic JSON text, one entry per line.
  String toJson({required String generated}) {
    final out = StringBuffer()
      ..writeln('{')
      ..writeln('  "version": 1,')
      ..writeln('  "generated": ${jsonEncode(generated)},')
      ..writeln('  "languages": [${languages.map(jsonEncode).join(', ')}],')
      ..writeln('  "entries": [');
    for (var i = 0; i < entries.length; i++) {
      final fields = entries[i]
          .entries
          .map((e) => '${jsonEncode(e.key)}: ${jsonEncode(e.value)}')
          .join(', ');
      out.writeln('    {$fields}${i == entries.length - 1 ? '' : ','}');
    }
    out
      ..writeln('  ]')
      ..writeln('}');
    return out.toString();
  }
}

/// Maps header cells to language ids; throws [HeaderMappingException] if a
/// non-empty header is unknown or a language is mapped twice.
Map<int, String> mapHeaders(List<String> headers) {
  final mapping = <int, String>{};
  for (var i = 0; i < headers.length; i++) {
    final header = headers[i].trim();
    if (header.isEmpty) continue;
    final tokens = header
        .toLowerCase()
        .split(RegExp(r'[^a-z]+'))
        .where((t) => t.isNotEmpty);
    final language = tokens
        .map((t) => _tokenToLanguage[t])
        .firstWhere((l) => l != null, orElse: () => null);
    if (language == null) {
      throw HeaderMappingException(headers, 'unknown header "$header"');
    }
    if (mapping.containsValue(language)) {
      throw HeaderMappingException(headers, 'duplicate language "$language"');
    }
    mapping[i] = language;
  }
  if (mapping.length < 2) {
    throw HeaderMappingException(headers, 'fewer than two languages found');
  }
  return mapping;
}

/// Pure conversion of spreadsheet [rows] (header first) into phrasebook
/// entries and a report.
PhrasebookBuild buildPhrasebook(List<List<String>> rows) {
  final headerIndex = rows.indexWhere((r) => r.any((c) => c.trim().isNotEmpty));
  if (headerIndex < 0) {
    throw const HeaderMappingException([], 'no header row');
  }
  final mapping = mapHeaders(rows[headerIndex]);
  final languages = [
    for (final language in kLanguageOrder)
      if (mapping.containsValue(language)) language,
  ];

  var rowsRead = 0;
  final filled = {for (final l in languages) l: 0};
  final empty = {for (final l in languages) l: 0};
  final singleLanguageRows = <int>[];
  final longCells = <LongCell>[];
  final entries = <Map<String, String>>[];

  for (var r = headerIndex + 1; r < rows.length; r++) {
    final cells = <String, String>{};
    for (final MapEntry(:key, :value) in mapping.entries) {
      final raw = key < rows[r].length ? rows[r][key].trim() : '';
      if (raw.isNotEmpty) cells[value] = raw;
    }
    if (cells.isEmpty) continue;
    rowsRead++;
    for (final language in languages) {
      final text = cells[language];
      if (text == null) {
        empty[language] = empty[language]! + 1;
      } else {
        filled[language] = filled[language]! + 1;
        if (text.length > kMaxCellLength) {
          longCells.add(LongCell(r + 1, language, text.length));
        }
      }
    }
    if (cells.length < 2) {
      singleLanguageRows.add(r + 1);
      continue;
    }
    entries.add({
      'id': 'p${(entries.length + 1).toString().padLeft(4, '0')}',
      for (final language in languages)
        if (cells.containsKey(language)) language: cells[language]!,
    });
  }

  return PhrasebookBuild(
    entries: entries,
    languages: languages,
    report: PhrasebookReport(
      rowsRead: rowsRead,
      entriesWritten: entries.length,
      filledPerLanguage: filled,
      emptyPerLanguage: empty,
      singleLanguageRows: singleLanguageRows,
      conflicts: _findConflicts(entries, languages),
      longCells: longCells,
    ),
  );
}

List<PhraseConflict> _findConflicts(
  List<Map<String, String>> entries,
  List<String> languages,
) {
  final conflicts = <PhraseConflict>[];
  for (final language in languages) {
    final groups = <String, List<Map<String, String>>>{};
    for (final entry in entries) {
      final text = entry[language];
      if (text == null) continue;
      final key = normalize(text);
      if (key.isEmpty) continue;
      (groups[key] ??= []).add(entry);
    }
    for (final MapEntry(:key, :value) in groups.entries) {
      if (value.length < 2) continue;
      final differs = languages.where((l) => l != language).any(
            (other) =>
                value.map((e) => normalize(e[other] ?? '')).toSet().length > 1,
          );
      if (differs) {
        conflicts.add(
          PhraseConflict(language, key, [for (final e in value) e['id']!]),
        );
      }
    }
  }
  return conflicts;
}

/// Parses UTF-8 CSV text (RFC 4180 quoting) into rows.
List<List<String>> parseCsv(String text) {
  final rows = <List<String>>[];
  var row = <String>[];
  final cell = StringBuffer();
  var inQuotes = false;
  var hasData = false;
  final input = text.startsWith('\uFEFF') ? text.substring(1) : text;

  void endCell() {
    row.add(cell.toString());
    cell.clear();
  }

  void endRow() {
    endCell();
    rows.add(row);
    row = <String>[];
    hasData = false;
  }

  for (var i = 0; i < input.length; i++) {
    final ch = input[i];
    if (inQuotes) {
      if (ch == '"') {
        if (i + 1 < input.length && input[i + 1] == '"') {
          cell.write('"');
          i++;
        } else {
          inQuotes = false;
        }
      } else {
        cell.write(ch);
      }
    } else if (ch == '"') {
      inQuotes = true;
      hasData = true;
    } else if (ch == ',') {
      endCell();
      hasData = true;
    } else if (ch == '\n' || ch == '\r') {
      if (ch == '\r' && i + 1 < input.length && input[i + 1] == '\n') i++;
      endRow();
    } else {
      cell.write(ch);
      hasData = true;
    }
  }
  if (hasData || cell.isNotEmpty) endRow();
  return rows;
}

/// Reads the first worksheet of an .xlsx file into rows of strings.
List<List<String>> readXlsx(List<int> bytes) {
  final archive = ZipDecoder().decodeBytes(bytes);
  String? read(String name) {
    final file = archive.findFile(name);
    return file == null ? null : utf8.decode(file.content as List<int>);
  }

  final sharedStrings = <String>[];
  final sharedXml = read('xl/sharedStrings.xml');
  if (sharedXml != null) {
    for (final si in XmlDocument.parse(sharedXml).findAllElements('si')) {
      sharedStrings.add(si.findAllElements('t').map((t) => t.innerText).join());
    }
  }

  final sheetXml =
      read(_firstSheetPath(read)) ?? read('xl/worksheets/sheet1.xml');
  if (sheetXml == null) throw const FormatException('No worksheet found.');

  final rows = <List<String>>[];
  for (final rowElement in XmlDocument.parse(sheetXml).findAllElements('row')) {
    final rowNumber = int.tryParse(rowElement.getAttribute('r') ?? '');
    while (rowNumber != null && rows.length < rowNumber - 1) {
      rows.add(<String>[]);
    }
    final row = <String>[];
    for (final c in rowElement.findElements('c')) {
      final column = _columnIndex(c.getAttribute('r') ?? '');
      while (column != null && row.length < column) {
        row.add('');
      }
      final type = c.getAttribute('t');
      final value = c.getElement('v')?.innerText ?? '';
      row.add(switch (type) {
        's' => sharedStrings[int.parse(value)],
        'inlineStr' => c.findAllElements('t').map((t) => t.innerText).join(),
        _ => value,
      });
    }
    rows.add(row);
  }
  return rows;
}

String _firstSheetPath(String? Function(String) read) {
  final workbook = read('xl/workbook.xml');
  final rels = read('xl/_rels/workbook.xml.rels');
  if (workbook == null || rels == null) return 'xl/worksheets/sheet1.xml';
  final sheet = XmlDocument.parse(workbook).findAllElements('sheet').first;
  final relId = sheet.attributes.firstWhere((a) => a.name.local == 'id').value;
  final target = XmlDocument.parse(rels)
      .findAllElements('Relationship')
      .firstWhere((r) => r.getAttribute('Id') == relId)
      .getAttribute('Target')!;
  return target.startsWith('/') ? target.substring(1) : 'xl/$target';
}

int? _columnIndex(String cellRef) {
  final letters = RegExp(r'^[A-Za-z]+').stringMatch(cellRef);
  if (letters == null) return null;
  var index = 0;
  for (final unit in letters.toUpperCase().codeUnits) {
    index = index * 26 + (unit - 64);
  }
  return index - 1;
}

String _today() {
  final now = DateTime.now();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${now.year}-${two(now.month)}-${two(now.day)}';
}

Future<void> main(List<String> args) async {
  if (args.length != 1) {
    stderr
        .writeln('Usage: dart run tool/build_phrasebook.dart <file.xlsx|csv>');
    exit(64);
  }
  final input = File(args.single);
  if (!input.existsSync()) {
    stderr.writeln('File not found: ${input.path}');
    exit(66);
  }

  final List<List<String>> rows;
  if (input.path.toLowerCase().endsWith('.csv')) {
    rows = parseCsv(utf8.decode(await input.readAsBytes()));
  } else {
    rows = readXlsx(await input.readAsBytes());
  }

  final PhrasebookBuild build;
  try {
    build = buildPhrasebook(rows);
  } on HeaderMappingException catch (error) {
    stderr.writeln(error);
    exit(65);
  }

  File(kOutputJsonPath)
    ..createSync(recursive: true)
    ..writeAsStringSync(build.toJson(generated: _today()), encoding: utf8);
  final report = build.report.toMarkdown();
  File(kOutputReportPath)
    ..createSync(recursive: true)
    ..writeAsStringSync(report, encoding: utf8);
  stdout
    ..writeln(report)
    ..writeln('Wrote $kOutputJsonPath and $kOutputReportPath');
}
