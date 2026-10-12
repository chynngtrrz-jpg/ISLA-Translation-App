import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isla_app/core/constants/languages.dart';
import 'package:isla_app/core/utils/phrase_normalizer.dart';
import 'package:isla_app/core/utils/text_similarity.dart';
import 'package:isla_app/data/models/language.dart';
import 'package:isla_app/data/models/translation_result.dart';
import 'package:isla_app/data/phrasebook/phrasebook.dart';
import 'package:isla_app/data/services/phrasebook_translator_service.dart';
import 'package:isla_app/data/services/translator_service.dart';
import 'package:isla_app/l10n/app_localizations.dart';
import 'package:isla_app/providers/session_provider.dart';
import 'package:isla_app/ui/screens/input_translate_screen.dart';
import 'package:isla_app/ui/screens/view_result_screen.dart';
import 'package:provider/provider.dart';

class _FakeFallback implements TranslatorService {
  int calls = 0;

  @override
  bool get isReady => true;

  @override
  Future<TranslationResult> translate({
    required String text,
    required Language source,
    required Language target,
  }) async {
    calls++;
    return const TranslationResult(
      text: 'from model',
      confidence: 0.5,
      latencyMs: 1,
    );
  }
}

Language _lang(String id) => languages.firstWhere((l) => l.id == id);

Phrasebook _realPhrasebook() => Phrasebook()
  ..loadFromJson(File('assets/phrasebook/phrasebook.json').readAsStringSync());

PhrasebookTranslatorService _service({
  Phrasebook? phrasebook,
  TranslatorService? fallback,
  bool enabled = true,
  bool fallbackToModel = true,
  double fuzzyThreshold = 0.85,
}) =>
    PhrasebookTranslatorService(
      phrasebook: phrasebook ?? _realPhrasebook(),
      fallback: fallback,
      enabled: enabled,
      fallbackToModel: fallbackToModel,
      fuzzyThreshold: fuzzyThreshold,
    );

Future<TranslationResult> _translate(
  TranslatorService service,
  String text,
  String source,
  String target,
) =>
    service.translate(text: text, source: _lang(source), target: _lang(target));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('exact match', () {
    test('returns the target phrase with confidence 1.0', () async {
      final result = await _translate(
          _service(), 'How to go to Bonbon Beach?', 'en', 'ini');
      expect(result.text, 'Paano magkadto sa Bonbon Beach?');
      expect(result.confidence, 1.0);
      expect(result.origin, TranslationOrigin.phrasebook);
    });

    test('works for every language pair', () async {
      final book = _realPhrasebook();
      final service = _service(phrasebook: book);
      for (final source in languages) {
        for (final target in languages) {
          if (source.id == target.id) continue;
          for (final entry in book.entries) {
            final result = await service.translate(
              text: entry.textFor(source.id)!,
              source: source,
              target: target,
            );
            expect(result.text, entry.textFor(target.id));
            expect(result.confidence, 1.0);
          }
        }
      }
    });

    test('non-English pairs match directly', () async {
      expect(
        (await _translate(_service(), 'Diin ka pakadto?', 'ini', 'onh')).text,
        'Diin ikaw paayan?',
      );
      expect(
        (await _translate(_service(), 'Saan ka papunta?', 'fil', 'asi')).text,
        'Riin ka mapagto?',
      );
    });

    test('ignores case and missing punctuation (voice transcript)', () async {
      final result = await _translate(
          _service(), 'how to go to bonbon beach', 'en', 'fil');
      expect(result.text, 'Paano pumunta sa Bonbon Beach?');
      expect(result.confidence, 1.0);
    });
  });

  group('fuzzy match', () {
    test('matches a near miss below 1.0 and above the threshold', () async {
      final result = await _translate(
        _service(),
        'How to go to Bonbon Beech?',
        'en',
        'fil',
      );
      expect(result.text, 'Paano pumunta sa Bonbon Beach?');
      expect(result.confidence, lessThan(1.0));
      expect(result.confidence, greaterThan(0.85));
      expect(result.origin, TranslationOrigin.phrasebook);
    });

    test('does not match an unrelated phrase', () async {
      await expectLater(
        _translate(_service(fallbackToModel: false), 'Where is the airport?',
            'en', 'fil'),
        throwsA(isA<PhraseNotFoundException>()),
      );
    });

    test('inputs shorter than the minimum length match only exactly', () async {
      final book = Phrasebook()
        ..loadFromJson(
          '{"entries":[{"id":"p1","en":"abc","fil":"xyz"},'
          '{"id":"p2","en":"mnop","fil":"wxyz"}]}',
        );
      final service = _service(
        phrasebook: book,
        fallbackToModel: false,
        fuzzyThreshold: 0.5,
      );
      expect((await _translate(service, 'abc', 'en', 'fil')).text, 'xyz');
      await expectLater(
        _translate(service, 'mno', 'en', 'fil'),
        throwsA(isA<PhraseNotFoundException>()),
      );
      expect((await _translate(service, 'mnoq', 'en', 'fil')).text, 'wxyz');
    });
  });

  group('multiple sentences', () {
    test('joins the matched target sentences with one space', () async {
      final result = await _translate(
        _service(),
        'Where are you going? How much is the fare to go there?',
        'en',
        'fil',
      );
      expect(
        result.text,
        'Saan ka papunta? Magkano ang pamasahe papunta doon?',
      );
      expect(result.confidence, 1.0);
      expect(result.origin, TranslationOrigin.phrasebook);
    });

    test('uses the lowest segment confidence', () async {
      final result = await _translate(
        _service(),
        'Where are you going? How much is the fare to go thre?',
        'en',
        'fil',
      );
      expect(result.confidence, lessThan(1.0));
      expect(result.origin, TranslationOrigin.phrasebook);
    });

    test('one unmatched sentence triggers the fallback', () async {
      final fallback = _FakeFallback();
      final result = await _translate(
        _service(fallback: fallback),
        'Where are you going? Where is the airport?',
        'en',
        'fil',
      );
      expect(result.text, 'from model');
      expect(result.origin, TranslationOrigin.model);
      expect(fallback.calls, 1);
    });

    test('one unmatched sentence throws when the fallback is off', () async {
      await expectLater(
        _translate(
          _service(fallback: _FakeFallback(), fallbackToModel: false),
          'Where are you going? Where is the airport?',
          'en',
          'fil',
        ),
        throwsA(isA<PhraseNotFoundException>()),
      );
    });
  });

  group('not found', () {
    test('suggestions are ordered by similarity and need the target language',
        () async {
      final book = Phrasebook()
        ..loadFromJson(
          '{"entries":['
          '{"id":"a","en":"Where is the market","fil":"Nasaan ang palengke"},'
          '{"id":"b","en":"Where is the airport now"},'
          '{"id":"c","en":"Where is the bus","fil":"Nasaan ang bus"},'
          '{"id":"d","en":"Good night","fil":"Magandang gabi"}]}',
        );
      try {
        await _translate(
          _service(phrasebook: book, fallbackToModel: false),
          'Where is the airport?',
          'en',
          'fil',
        );
        fail('expected PhraseNotFoundException');
      } on PhraseNotFoundException catch (error) {
        expect(error.suggestions, isNot(contains('Where is the airport now')));
        expect(error.suggestions.length, 3);
        final scores = [
          for (final s in error.suggestions)
            similarity(normalize('Where is the airport'), normalize(s)),
        ];
        expect([...scores]..sort((a, b) => b.compareTo(a)), scores);
      }
    });

    test('throws with an empty list when the source has no phrases', () async {
      final book = Phrasebook()..loadFromJson('{"entries":[]}');
      try {
        await _translate(
          _service(phrasebook: book, fallbackToModel: false),
          'anything goes',
          'en',
          'fil',
        );
        fail('expected PhraseNotFoundException');
      } on PhraseNotFoundException catch (error) {
        expect(error.suggestions, isEmpty);
      }
    });
  });

  group('fallback', () {
    test('is not called when a phrasebook tier matched', () async {
      final fallback = _FakeFallback();
      await _translate(
        _service(fallback: fallback),
        'Where are you going?',
        'en',
        'fil',
      );
      await _translate(
        _service(fallback: fallback),
        'Where are you goin?',
        'en',
        'fil',
      );
      expect(fallback.calls, 0);
    });

    test('is called only when nothing matched and it is allowed', () async {
      final fallback = _FakeFallback();
      final result = await _translate(
        _service(fallback: fallback),
        'Where is the airport?',
        'en',
        'fil',
      );
      expect(result.origin, TranslationOrigin.model);
      expect(fallback.calls, 1);

      await expectLater(
        _translate(
          _service(fallback: fallback, fallbackToModel: false),
          'Where is the airport?',
          'en',
          'fil',
        ),
        throwsA(isA<PhraseNotFoundException>()),
      );
      expect(fallback.calls, 1);
    });

    test('a disabled phrasebook is skipped', () async {
      final fallback = _FakeFallback();
      final result = await _translate(
        _service(fallback: fallback, enabled: false),
        'Where are you going?',
        'en',
        'fil',
      );
      expect(result.text, 'from model');
      expect(fallback.calls, 1);
    });

    test('isReady follows the phrasebook and the fallback', () {
      expect(_service().isReady, isTrue);
      expect(_service(phrasebook: Phrasebook()).isReady, isFalse);
      expect(_service(fallback: _FakeFallback()).isReady, isTrue);
    });
  });

  group('not-found UI', () {
    late SessionProvider session;

    Future<void> pumpScreen(WidgetTester tester) async {
      session = SessionProvider(
        translator: _service(fallbackToModel: false),
      )..setTarget('fil');
      await tester.pumpWidget(
        ChangeNotifierProvider<SessionProvider>.value(
          value: session,
          child: MaterialApp(
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: const InputTranslateScreen(),
          ),
        ),
      );
    }

    Future<void> translateUnknown(WidgetTester tester) async {
      await tester.enterText(find.byType(TextField), 'Where is the airport?');
      await tester.pump();
      await tester.ensureVisible(find.text('Translate'));
      await tester.tap(find.text('Translate'));
      await tester.pumpAndSettle();
    }

    String fieldText(WidgetTester tester) =>
        tester.widget<TextField>(find.byType(TextField)).controller!.text;

    testWidgets('shows the message and chips without navigating',
        (tester) async {
      await pumpScreen(tester);
      await translateUnknown(tester);

      expect(
          find.text('No translation found for this phrase.'), findsOneWidget);
      expect(find.text('Try one of these:'), findsOneWidget);
      expect(session.suggestions, isNotEmpty);
      for (final phrase in session.suggestions) {
        expect(find.text(phrase), findsOneWidget);
      }
      expect(find.byType(ViewResultScreen), findsNothing);
      expect(session.result, isNull);
      expect(session.isTranslating, isFalse);
    });

    testWidgets('tapping a chip fills the field without translating',
        (tester) async {
      await pumpScreen(tester);
      await translateUnknown(tester);

      final phrase = session.suggestions.first;
      await tester.ensureVisible(find.text(phrase));
      await tester.tap(find.text(phrase));
      await tester.pumpAndSettle();

      expect(fieldText(tester), phrase);
      expect(session.inputText, phrase);
      expect(session.result, isNull);
      expect(find.byType(ViewResultScreen), findsNothing);
    });

    testWidgets('the message clears when the text is edited', (tester) async {
      await pumpScreen(tester);
      await translateUnknown(tester);
      expect(
          find.text('No translation found for this phrase.'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'Where is the airpor');
      await tester.pump();

      expect(find.text('No translation found for this phrase.'), findsNothing);
      expect(find.text('Try one of these:'), findsNothing);
    });

    testWidgets('the message clears when the language pair changes',
        (tester) async {
      await pumpScreen(tester);
      await translateUnknown(tester);

      session.setTarget('asi');
      await tester.pump();

      expect(find.text('No translation found for this phrase.'), findsNothing);
    });

    testWidgets('the message clears on Clear & Start Over', (tester) async {
      await pumpScreen(tester);
      await translateUnknown(tester);

      await tester.ensureVisible(find.text('Clear & Start Over'));
      await tester.tap(find.text('Clear & Start Over'));
      await tester.pumpAndSettle();

      expect(find.text('No translation found for this phrase.'), findsNothing);
      expect(fieldText(tester), isEmpty);
    });
  });
}
