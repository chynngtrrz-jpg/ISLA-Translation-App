import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import '../tool/build_phrasebook.dart';

void main() {
  const header = [
    'English',
    'Tagalog',
    'Ini (Romblomanon)',
    'Onhan',
    'Asi (Bantoanon)'
  ];

  test('maps headers by tokens in canonical order', () {
    final build = buildPhrasebook([
      ['Asi (Bantoanon)', 'Onhan', 'Ini (Romblomanon)', 'Tagalog', 'English'],
      ['asi1', 'onh1', 'ini1', 'fil1', 'en1'],
    ]);
    expect(build.languages, ['en', 'fil', 'ini', 'onh', 'asi']);
    expect(build.entries.single.keys.toList(),
        ['id', 'en', 'fil', 'ini', 'onh', 'asi']);
    expect(build.entries.single['ini'], 'ini1');
  });

  test('stops and lists all headers when one cannot be mapped', () {
    expect(
      () => buildPhrasebook([
        ['English', 'Klingon'],
        ['a', 'b'],
      ]),
      throwsA(
        isA<HeaderMappingException>().having(
          (e) => e.toString(),
          'message',
          allOf(contains('English'), contains('Klingon')),
        ),
      ),
    );
  });

  test('skips empty rows and drops single-language rows', () {
    final build = buildPhrasebook([
      header,
      ['Hello', 'Kumusta', 'Kumusta ba', 'Kamusta', 'Kumusta ka'],
      ['', '', '', '', ''],
      ['Only English', '', '', '', ''],
      ['  ', '  ', '', '', ''],
      ['Thanks', 'Salamat', '', '', ''],
    ]);
    expect(build.entries.map((e) => e['id']), ['p0001', 'p0002']);
    expect(build.entries[1], {'id': 'p0002', 'en': 'Thanks', 'fil': 'Salamat'});
    expect(build.report.rowsRead, 3);
    expect(build.report.entriesWritten, 2);
    expect(build.report.singleLanguageRows, [4]);
    expect(build.report.filledPerLanguage['en'], 3);
    expect(build.report.emptyPerLanguage['ini'], 2);
  });

  test('trims cells and keeps diacritics', () {
    final build = buildPhrasebook([
      ['English', 'Tagalog'],
      ['  Año  ', ' Taón '],
    ]);
    expect(build.entries.single['en'], 'Año');
    expect(build.entries.single['fil'], 'Taón');
  });

  test('reports conflicting duplicates and long cells', () {
    final long = 'x' * 601;
    final build = buildPhrasebook([
      ['English', 'Tagalog'],
      ['Hello?', 'Kumusta'],
      ['hello', 'Magandang araw'],
      ['Same', 'Pareho'],
      ['same!', 'Pareho'],
      [long, 'Mahaba'],
    ]);
    expect(build.report.conflicts, hasLength(1));
    expect(build.report.conflicts.single.language, 'en');
    expect(build.report.conflicts.single.entryIds, ['p0001', 'p0002']);
    expect(build.report.longCells.single.row, 6);
    expect(build.report.longCells.single.language, 'en');
    expect(build.report.toMarkdown(), contains('Conflicting duplicates (1)'));
  });

  test('output is deterministic and valid JSON', () {
    final rows = [
      header,
      [
        'Where are you going?',
        'Saan ka papunta?',
        'Diin ka pakadto?',
        'Diin ikaw paayan?',
        'Riin ka mapagto?'
      ],
    ];
    final first = buildPhrasebook(rows).toJson(generated: '2026-10-10');
    final second = buildPhrasebook(rows).toJson(generated: '2026-10-10');
    expect(first, second);
    final decoded = jsonDecode(first) as Map<String, dynamic>;
    expect(decoded['version'], 1);
    expect(decoded['languages'], ['en', 'fil', 'ini', 'onh', 'asi']);
    expect((decoded['entries'] as List).single['asi'], 'Riin ka mapagto?');
  });

  test('parses CSV with quotes, commas and a BOM', () {
    final rows =
        parseCsv('\uFEFFEnglish,Tagalog\r\n"Hi, you","Kumusta ""po"""\n');
    expect(rows, [
      ['English', 'Tagalog'],
      ['Hi, you', 'Kumusta "po"'],
    ]);
  });
}
