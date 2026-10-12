// Builds lib/l10n/app_loc.arb (Onhan) from a filled translation sheet.
//
// Usage: dart run tool/import_onhan.dart [tool/output/onhan_strings.csv]
//
// Non-empty Onhan cells override the English value; empty cells keep English.
// Every filled value must have the same placeholders (name and ICU type) as
// English and valid, balanced ICU syntax. On any problem nothing is written.
// Translations are never invented or edited by this tool.
import 'dart:convert';
import 'dart:io';

import 'onhan_common.dart';

/// Outcome of [buildOnhanArb].
class OnhanImportResult {
  OnhanImportResult({
    required this.arbText,
    required this.errors,
    required this.translatedByScreen,
    required this.pendingByScreen,
  });

  /// Serialized ARB, or null when [errors] is not empty.
  final String? arbText;
  final List<String> errors;
  final Map<String, int> translatedByScreen;
  final Map<String, int> pendingByScreen;

  int get translated => translatedByScreen.values.fold(0, (a, b) => a + b);
  int get pending => pendingByScreen.values.fold(0, (a, b) => a + b);
}

/// Pure import logic: [sheetRows] includes the header row.
OnhanImportResult buildOnhanArb(
  Map<String, dynamic> template,
  List<List<String>> sheetRows,
) {
  final errors = <String>[];
  final translatedByScreen = <String, int>{};
  final pendingByScreen = <String, int>{};
  final keys = messageKeys(template);

  if (sheetRows.isEmpty) {
    errors.add('sheet: empty file');
    return OnhanImportResult(
      arbText: null,
      errors: errors,
      translatedByScreen: translatedByScreen,
      pendingByScreen: pendingByScreen,
    );
  }
  final header = sheetRows.first.map((c) => c.trim()).toList();
  final keyIndex = header.indexOf(keyColumn);
  final onhanIndex = header.indexOf(onhanColumn);
  final screenIndex = header.indexOf(screenColumn);
  if (keyIndex == -1 || onhanIndex == -1) {
    errors.add('sheet: missing "$keyColumn" or "$onhanColumn" column');
  }

  final filled = <String, String>{};
  final screens = <String, String>{};
  if (errors.isEmpty) {
    for (final row in sheetRows.skip(1)) {
      if (row.every((c) => c.trim().isEmpty)) continue;
      final key = keyIndex < row.length ? row[keyIndex].trim() : '';
      if (!keys.contains(key)) {
        errors.add('$key: key is not in ${templateArbPath.split('/').last}');
        continue;
      }
      if (screenIndex != -1 && screenIndex < row.length) {
        screens[key] = row[screenIndex];
      }
      final value = onhanIndex < row.length ? row[onhanIndex] : '';
      if (value.trim().isNotEmpty) filled[key] = value;
    }
  }

  for (final entry in filled.entries) {
    final english = template[entry.key] as String;
    try {
      final expected = icuArguments(english);
      final actual = icuArguments(entry.value);
      if (expected.join('|') != actual.join('|')) {
        errors.add('${entry.key}: placeholders differ, expected '
            '[${expected.join(', ')}] but found [${actual.join(', ')}]');
      }
    } on FormatException catch (e) {
      errors.add('${entry.key}: invalid ICU syntax (${e.message})');
    }
  }

  if (errors.isNotEmpty) {
    return OnhanImportResult(
      arbText: null,
      errors: errors,
      translatedByScreen: translatedByScreen,
      pendingByScreen: pendingByScreen,
    );
  }

  final output = <String, dynamic>{'@@locale': onhanLocale};
  for (final key in keys) {
    output[key] = filled[key] ?? template[key];
    if (template.containsKey('@$key')) output['@$key'] = template['@$key'];
    final screen = screens[key] ?? 'Unknown';
    final bucket =
        filled.containsKey(key) ? translatedByScreen : pendingByScreen;
    bucket[screen] = (bucket[screen] ?? 0) + 1;
  }
  return OnhanImportResult(
    arbText: '${const JsonEncoder.withIndent('  ').convert(output)}\n',
    errors: errors,
    translatedByScreen: translatedByScreen,
    pendingByScreen: pendingByScreen,
  );
}

void main(List<String> args) {
  final sheetPath = args.isNotEmpty ? args.first : defaultSheetPath;
  final sheet = File(sheetPath);
  if (!sheet.existsSync()) {
    stderr.writeln('Sheet not found: $sheetPath');
    exit(2);
  }
  if (!sheetPath.toLowerCase().endsWith('.csv')) {
    stderr.writeln('Only the CSV sheet from export_onhan_sheet.dart is '
        'supported (save the filled sheet as UTF-8 CSV).');
    exit(2);
  }

  final result = buildOnhanArb(
    readArb(templateArbPath),
    decodeCsv(utf8.decode(sheet.readAsBytesSync())),
  );
  if (result.errors.isNotEmpty) {
    for (final error in result.errors) {
      stderr.writeln(error);
    }
    stderr.writeln('No file written ($onhanArbPath is unchanged).');
    exit(1);
  }

  File(onhanArbPath).writeAsStringSync(result.arbText!);
  stdout.writeln('Wrote $onhanArbPath');
  stdout
      .writeln('Translated: ${result.translated}, pending: ${result.pending}');
  final screens = {
    ...result.translatedByScreen.keys,
    ...result.pendingByScreen.keys,
  };
  for (final screen in screens) {
    stdout.writeln('  $screen: ${result.translatedByScreen[screen] ?? 0} '
        'translated, ${result.pendingByScreen[screen] ?? 0} pending');
  }

  // gen-l10n is not run automatically by this project, so regenerate here.
  final gen = Process.runSync('flutter', ['gen-l10n'], runInShell: true);
  stdout.write(gen.stdout);
  stderr.write(gen.stderr);
  if (gen.exitCode != 0) exit(gen.exitCode);
}
