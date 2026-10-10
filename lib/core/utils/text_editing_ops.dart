import 'package:characters/characters.dart';
import 'package:flutter/services.dart';

TextEditingValue applyInsert(
  TextEditingValue value,
  String insertion,
  int maxChars,
) {
  final text = value.text;
  final rawStart = value.selection.start;
  final rawEnd = value.selection.end;
  final start =
      rawStart < 0 ? text.length : rawStart.clamp(0, text.length).toInt();
  final end = rawEnd < 0
      ? text.length
      : rawEnd.clamp(start, text.length).toInt();
  final removedCount = text.substring(start, end).characters.length;
  final available = maxChars - (text.characters.length - removedCount);
  if (available <= 0) return value;

  final inserted = insertion.characters.take(available).toString();
  if (inserted.isEmpty) return value;
  final updated = text.replaceRange(start, end, inserted);
  final caret = start + inserted.length;
  return TextEditingValue(
    text: updated,
    selection: TextSelection.collapsed(offset: caret),
  );
}

TextEditingValue applyBackspace(TextEditingValue value) {
  final text = value.text;
  final rawStart = value.selection.start;
  final rawEnd = value.selection.end;
  final start =
      rawStart < 0 ? text.length : rawStart.clamp(0, text.length).toInt();
  final end = rawEnd < 0
      ? text.length
      : rawEnd.clamp(start, text.length).toInt();

  if (start != end) {
    final updated = text.replaceRange(start, end, '');
    return TextEditingValue(
      text: updated,
      selection: TextSelection.collapsed(offset: start),
    );
  }
  if (start == 0) return value;

  final previousGrapheme = text.substring(0, start).characters.last;
  final graphemeStart = start - previousGrapheme.length;
  final updated = text.replaceRange(graphemeStart, start, '');
  return TextEditingValue(
    text: updated,
    selection: TextSelection.collapsed(offset: graphemeStart),
  );
}
