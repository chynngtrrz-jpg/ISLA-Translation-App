// Exports every UI string to a translation sheet for Onhan translators.
//
// Usage: dart run tool/export_onhan_sheet.dart [output.csv]
//
// The `excel` package cannot be resolved alongside this project's `xml`
// dependency, so the sheet is a UTF-8 CSV with BOM (opens in Excel/Sheets).
// Columns: Screen, Key, English, Filipino, [Romblomanon (Ini)], [Asi], Onhan
// (left empty for the translators), Placeholders.
import 'dart:convert';
import 'dart:io';

import 'onhan_common.dart';

/// Screens in app flow order, with the source files that belong to each.
/// A key's screen is the first screen (in this order, then file order)
/// whose files reference it.
const List<(String, List<String>)> _screens = [
  ('Landing', ['lib/app.dart']),
  (
    'Language Selection',
    [
      'lib/ui/screens/language_selection_screen.dart',
      'lib/ui/widgets/language_card.dart',
    ]
  ),
  (
    'Select Languages',
    [
      'lib/ui/screens/select_languages_screen.dart',
      'lib/ui/widgets/language_field.dart',
      'lib/ui/widgets/language_pair_bar.dart',
      'lib/ui/widgets/language_picker_sheet.dart',
      'lib/ui/widgets/swap_button.dart',
    ]
  ),
  (
    'Input and Translate',
    [
      'lib/ui/screens/input_translate_screen.dart',
      'lib/ui/widgets/input_mode_selector.dart',
      'lib/ui/widgets/message_field.dart',
      'lib/ui/widgets/voice_input_panel.dart',
      'lib/ui/widgets/camera_input_panel.dart',
    ]
  ),
  (
    'View Result',
    [
      'lib/ui/screens/view_result_screen.dart',
      'lib/ui/widgets/translation_result_card.dart',
    ]
  ),
  (
    'Shared Widgets',
    [
      'lib/ui/widgets/isla_app_bar.dart',
      'lib/ui/widgets/step_indicator.dart',
      'lib/ui/widgets/welcome_banner.dart',
      'lib/ui/widgets/screen_back_button.dart',
    ]
  ),
];

const String _unusedScreen = 'Unused / Other';

/// Optional comparison languages: header -> ARB path (included if it exists).
const List<(String, String)> _referenceArbs = [
  ('Filipino', 'lib/l10n/app_tl.arb'),
  ('Romblomanon (Ini)', 'lib/l10n/app_rol.arb'),
  ('Asi', 'lib/l10n/app_bno.arb'),
];

String _screenFor(String key, Map<String, String> sources) {
  final usage = RegExp('\\.$key\\b|\\b$key\\b');
  for (final (screen, files) in _screens) {
    for (final file in files) {
      final source = sources[file];
      if (source != null && usage.hasMatch(source)) return screen;
    }
  }
  return _unusedScreen;
}

void main(List<String> args) {
  final outputPath = args.isNotEmpty ? args.first : defaultSheetPath;
  final template = readArb(templateArbPath);
  final keys = messageKeys(template);

  final sources = <String, String>{
    for (final (_, files) in _screens)
      for (final file in files)
        if (File(file).existsSync()) file: File(file).readAsStringSync(),
  };
  final references = <(String, Map<String, dynamic>)>[
    for (final (header, path) in _referenceArbs)
      if (File(path).existsSync()) (header, readArb(path)),
  ];

  final screenOrder = [..._screens.map((s) => s.$1), _unusedScreen];
  final rows = <(int, int, List<String>)>[];
  for (var i = 0; i < keys.length; i++) {
    final key = keys[i];
    final screen = _screenFor(key, sources);
    final placeholders = icuArguments(template[key] as String)
        .map((a) => a.split(':').first)
        .join(', ');
    rows.add((
      screenOrder.indexOf(screen),
      i,
      [
        screen,
        key,
        template[key] as String,
        for (final (_, arb) in references) (arb[key] as String?) ?? '',
        '',
        placeholders,
      ],
    ));
  }
  rows.sort(
      (a, b) => a.$1 != b.$1 ? a.$1.compareTo(b.$1) : a.$2.compareTo(b.$2));

  final header = [
    screenColumn,
    keyColumn,
    englishColumn,
    for (final (name, _) in references) name,
    onhanColumn,
    placeholdersColumn,
  ];
  final file = File(outputPath)..createSync(recursive: true);
  file.writeAsBytesSync([
    0xEF, 0xBB, 0xBF, // UTF-8 BOM so Excel detects the encoding.
    ...utf8.encode(encodeCsv([header, ...rows.map((r) => r.$3)])),
  ]);
  stdout.writeln('Wrote ${rows.length} rows to $outputPath');
}
