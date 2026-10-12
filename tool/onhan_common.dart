// Shared helpers for the Onhan translation sheet tools.
//
// Onhan uses the ISO 639-3 locale code `loc` (like Asi = `bno` and
// Romblomanon = `rol`), so its ARB file is lib/l10n/app_loc.arb.
import 'dart:convert';
import 'dart:io';

const String onhanLocale = 'loc';
const String templateArbPath = 'lib/l10n/app_en.arb';
const String onhanArbPath = 'lib/l10n/app_loc.arb';
const String defaultSheetPath = 'tool/output/onhan_strings.csv';

/// Sheet header; optional language columns are inserted after English.
const String screenColumn = 'Screen';
const String keyColumn = 'Key';
const String englishColumn = 'English';
const String onhanColumn = 'Onhan';
const String placeholdersColumn = 'Placeholders';

/// Reads an ARB file, preserving key order.
Map<String, dynamic> readArb(String path) {
  final text = File(path).readAsStringSync();
  return json.decode(text.startsWith('\uFEFF') ? text.substring(1) : text)
      as Map<String, dynamic>;
}

/// Message keys of an ARB map (no `@` metadata), in file order.
List<String> messageKeys(Map<String, dynamic> arb) =>
    arb.keys.where((k) => !k.startsWith('@')).toList();

/// Returns `name:type` entries (sorted) for every argument in an ICU message,
/// or throws [FormatException] when the message is malformed.
List<String> icuArguments(String message) {
  final found = <String>{};
  final end = _parse(message, 0, found, nested: false);
  if (end != message.length) {
    throw const FormatException('unbalanced closing brace');
  }
  return found.toList()..sort();
}

// Parses a message body starting at [start]; stops at an unmatched '}' when
// [nested] is true. Returns the index where parsing stopped.
int _parse(String s, int start, Set<String> found, {required bool nested}) {
  var i = start;
  while (i < s.length) {
    final c = s[i];
    if (c == '}') {
      if (nested) return i;
      throw const FormatException('unbalanced closing brace');
    }
    if (c == '{') {
      i = _parseArgument(s, i + 1, found);
      continue;
    }
    i++;
  }
  if (nested) throw const FormatException('unbalanced opening brace');
  return i;
}

// Parses `name}` or `name, type, options}`; returns the index after '}'.
int _parseArgument(String s, int start, Set<String> found) {
  final close = _firstOf(s, start, [',', '}']);
  if (close == -1) throw const FormatException('unbalanced opening brace');
  final name = s.substring(start, close).trim();
  if (!RegExp(r'^[A-Za-z_][A-Za-z0-9_]*$').hasMatch(name)) {
    throw FormatException('invalid placeholder name "$name"');
  }
  if (s[close] == '}') {
    found.add('$name:simple');
    return close + 1;
  }
  final typeEnd = _firstOf(s, close + 1, [',', '}']);
  if (typeEnd == -1) throw const FormatException('unbalanced opening brace');
  final type = s.substring(close + 1, typeEnd).trim();
  if (type != 'plural' && type != 'select') {
    // Other types (number, date) carry no nested messages.
    found.add('$name:$type');
    if (s[typeEnd] == '}') return typeEnd + 1;
    final stop = _firstOf(s, typeEnd + 1, ['}']);
    if (stop == -1) throw const FormatException('unbalanced opening brace');
    return stop + 1;
  }
  if (s[typeEnd] == '}') {
    throw FormatException('$type needs options');
  }
  found.add('$name:$type');
  var i = typeEnd + 1;
  var options = 0;
  while (true) {
    while (i < s.length && s[i].trim().isEmpty) {
      i++;
    }
    if (i >= s.length) throw const FormatException('unbalanced opening brace');
    if (s[i] == '}') {
      if (options == 0) throw FormatException('$type needs options');
      return i + 1;
    }
    final open = s.indexOf('{', i);
    if (open == -1) throw FormatException('$type option is missing "{"');
    final selector = s.substring(i, open).trim();
    if (selector.isEmpty) throw FormatException('$type option has no selector');
    i = _parse(s, open + 1, found, nested: true) + 1;
    options++;
  }
}

int _firstOf(String s, int from, List<String> chars) {
  for (var i = from; i < s.length; i++) {
    if (chars.contains(s[i])) return i;
  }
  return -1;
}

/// Minimal RFC 4180 CSV encoder.
String encodeCsv(List<List<String>> rows) {
  String cell(String v) =>
      RegExp(r'[",\r\n]').hasMatch(v) ? '"${v.replaceAll('"', '""')}"' : v;
  return rows.map((r) => r.map(cell).join(',')).join('\r\n');
}

/// Minimal RFC 4180 CSV decoder (handles quotes, commas, and newlines).
List<List<String>> decodeCsv(String input) {
  final text = input.startsWith('\uFEFF') ? input.substring(1) : input;
  final rows = <List<String>>[];
  var row = <String>[];
  final cell = StringBuffer();
  var quoted = false;
  var i = 0;
  while (i < text.length) {
    final c = text[i];
    if (quoted) {
      if (c == '"') {
        if (i + 1 < text.length && text[i + 1] == '"') {
          cell.write('"');
          i++;
        } else {
          quoted = false;
        }
      } else {
        cell.write(c);
      }
    } else if (c == '"') {
      quoted = true;
    } else if (c == ',') {
      row.add(cell.toString());
      cell.clear();
    } else if (c == '\n' || c == '\r') {
      if (c == '\r' && i + 1 < text.length && text[i + 1] == '\n') i++;
      row.add(cell.toString());
      cell.clear();
      rows.add(row);
      row = <String>[];
    } else {
      cell.write(c);
    }
    i++;
  }
  if (cell.isNotEmpty || row.isNotEmpty) {
    row.add(cell.toString());
    rows.add(row);
  }
  return rows;
}
