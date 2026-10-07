import 'package:characters/characters.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isla_app/core/utils/text_editing_ops.dart';

void main() {
  group('applyInsert', () {
    test('inserts at the caret', () {
      final value = applyInsert(
        const TextEditingValue(
          text: 'ac',
          selection: TextSelection.collapsed(offset: 1),
        ),
        'b',
        600,
      );

      expect(value.text, 'abc');
      expect(value.selection.baseOffset, 2);
    });

    test('replaces the selected text', () {
      final value = applyInsert(
        const TextEditingValue(
          text: 'hello',
          selection: TextSelection(baseOffset: 1, extentOffset: 4),
        ),
        'i',
        600,
      );

      expect(value.text, 'hio');
      expect(value.selection.baseOffset, 2);
    });

    test('respects the character limit', () {
      final value = applyInsert(
        TextEditingValue(
          text: 'a' * 599,
          selection: TextSelection.collapsed(offset: 599),
        ),
        'bc',
        600,
      );

      expect(value.text.characters.length, 600);
      expect(value.text.endsWith('b'), isTrue);
    });

    test('treats an unset selection as the end of the text', () {
      final value = applyInsert(
        const TextEditingValue(text: 'hello'),
        '!',
        600,
      );

      expect(value.text, 'hello!');
      expect(value.selection.baseOffset, 6);
    });
  });

  group('applyBackspace', () {
    test('deletes one grapheme, including ñ and a joined emoji', () {
      final enye = applyBackspace(
        const TextEditingValue(
          text: 'mañ',
          selection: TextSelection.collapsed(offset: 3),
        ),
      );
      final emoji = applyBackspace(
        const TextEditingValue(
          text: 'hi👩‍👩‍👧‍👦',
          selection: TextSelection.collapsed(offset: 13),
        ),
      );

      expect(enye.text, 'ma');
      expect(emoji.text, 'hi');
    });

    test('deletes the full selection', () {
      final value = applyBackspace(
        const TextEditingValue(
          text: 'hello',
          selection: TextSelection(baseOffset: 1, extentOffset: 4),
        ),
      );

      expect(value.text, 'ho');
      expect(value.selection.baseOffset, 1);
    });

    test('treats an unset selection as the end of the text', () {
      final value = applyBackspace(const TextEditingValue(text: 'hello'));

      expect(value.text, 'hell');
      expect(value.selection.baseOffset, 4);
    });
  });
}
