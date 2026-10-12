import 'package:flutter_test/flutter_test.dart';
import 'package:isla_app/core/utils/phrase_normalizer.dart';
import 'package:isla_app/core/utils/text_similarity.dart';

void main() {
  group('normalize', () {
    test('lowercases and trims', () {
      expect(normalize('  How To Go  '), 'how to go');
    });

    test('removes punctuation', () {
      expect(normalize('Where are you going?'), 'where are you going');
      expect(normalize('Hello, world! (ok)'), 'hello world ok');
    });

    test('converts curly quotes and apostrophes to straight ones', () {
      expect(normalize('It\u2019s \u201Cfine\u201D'), "it's fine");
      expect(normalize('\u2018tis'), "'tis");
    });

    test('keeps ñ and accented letters, digits, apostrophes and hyphens', () {
      expect(normalize('Año Café 2-go'), 'año café 2-go');
    });

    test('collapses repeated whitespace including newlines and tabs', () {
      expect(normalize('how   to\n\tgo'), 'how to go');
    });

    test('noisy and unpunctuated input normalizes to the same key', () {
      final expected = normalize('How to go to Bonbon Beach?');
      expect(normalize('How to go to Bonbon Beach ?'), expected);
      expect(normalize('how to go to bonbon beach'), expected);
      expect(expected, 'how to go to bonbon beach');
    });
  });

  group('splitSentences', () {
    test('splits on . ? ! followed by whitespace', () {
      expect(
        splitSentences('Where are you going? How much is it. Go now!'),
        ['Where are you going?', 'How much is it.', 'Go now!'],
      );
    });

    test('keeps a single sentence and ignores empty segments', () {
      expect(splitSentences('  Hello?  '), ['Hello?']);
      expect(splitSentences('   '), isEmpty);
    });
  });

  group('similarity', () {
    test('is 1.0 for equal strings and 0.0 for fully different ones', () {
      expect(similarity('abc', 'abc'), 1.0);
      expect(similarity('', ''), 1.0);
      expect(similarity('abc', 'xyz'), 0.0);
    });

    test('is 1 - distance / longest length', () {
      expect(similarity('abcd', 'abce'), closeTo(0.75, 1e-9));
      expect(levenshtein('kitten', 'sitting'), 3);
    });
  });
}
