import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/constants/app_config.dart';
import '../../core/localization/isla_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../../core/utils/text_editing_ops.dart';
import 'keyboard_layouts.dart';

/// A compact, accessible keyboard that edits the shared message controller.
class OnScreenKeyboard extends StatefulWidget {
  const OnScreenKeyboard({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    super.key,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;

  @override
  State<OnScreenKeyboard> createState() => _OnScreenKeyboardState();
}

class _OnScreenKeyboardState extends State<OnScreenKeyboard> {
  bool _symbols = false;
  bool _shifted = true;
  bool _capsLock = false;
  DateTime? _lastShiftTap;
  Timer? _deleteTimer;

  @override
  void didUpdateWidget(covariant OnScreenKeyboard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller.text != widget.controller.text) {
      _autoShift();
    }
  }

  @override
  void dispose() {
    _deleteTimer?.cancel();
    super.dispose();
  }

  void _autoShift() {
    final text = widget.controller.text;
    _shifted = _capsLock ||
        text.isEmpty ||
        RegExp(r'[.!?]\s$').hasMatch(text);
  }

  void _insert(String text, {bool isLetter = false}) {
    final value = applyInsert(widget.controller.value, text, kMaxChars);
    if (value == widget.controller.value) return;
    widget.controller.value = value;
    widget.onChanged(value.text);
    if (isLetter && _shifted && !_capsLock) {
      setState(() => _shifted = false);
    }
    if (text == ' ' || text == '\n') {
      setState(_autoShift);
    }
  }

  void _backspace() {
    final value = applyBackspace(widget.controller.value);
    if (value == widget.controller.value) return;
    widget.controller.value = value;
    widget.onChanged(value.text);
    setState(_autoShift);
  }

  void _shift() {
    final now = DateTime.now();
    final isDoubleTap =
        _lastShiftTap != null && now.difference(_lastShiftTap!) <=
            const Duration(milliseconds: 400);
    setState(() {
      if (isDoubleTap) {
        _capsLock = !_capsLock;
        _shifted = _capsLock;
      } else {
        _shifted = !_shifted;
        _capsLock = false;
      }
      _lastShiftTap = _capsLock ? null : now;
    });
  }

  Future<void> _showAlternates(
    BuildContext context,
    KeyboardKeyData key,
  ) async {
    if (key.alternates.isEmpty) return;
    final renderBox = context.findRenderObject()! as RenderBox;
    final topLeft = renderBox.localToGlobal(Offset.zero);
    final selected = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        topLeft.dx,
        topLeft.dy,
        topLeft.dx + renderBox.size.width,
        topLeft.dy + renderBox.size.height,
      ),
      items: [
        for (final alternate in key.alternates)
          PopupMenuItem(value: alternate, child: Text(alternate)),
      ],
    );
    if (selected != null) _insert(selected);
  }

  String _accessibleLabel(BuildContext context, KeyboardKeyData key) {
    return switch (key.kind) {
      KeyboardKeyKind.shift => context.t(L10nKeys.keyboardShift),
      KeyboardKeyKind.backspace => context.t(L10nKeys.keyboardBackspace),
      KeyboardKeyKind.space => context.t(L10nKeys.keyboardSpace),
      KeyboardKeyKind.enter => context.t(L10nKeys.keyboardEnter),
      KeyboardKeyKind.layer => _symbols
          ? context.t(L10nKeys.keyboardLetters)
          : context.t(L10nKeys.keyboardSymbols),
      KeyboardKeyKind.character => key.label,
      KeyboardKeyKind.disabled => '',
    };
  }

  @override
  Widget build(BuildContext context) {
    final rows = _symbols ? symbolKeyboardRows : letterKeyboardRows;
    return Container(
      padding: EdgeInsets.all(Responsive.space(context, 12)),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(Responsive.space(context, 24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            context.t(L10nKeys.keyboardLabel),
            style: TextStyle(
              color: AppColors.espresso,
              fontSize: Responsive.sp(context, 14),
              fontWeight: FontWeight.w700,
              letterSpacing: Responsive.space(context, 1.5),
            ),
          ),
          SizedBox(height: Responsive.space(context, 8)),
          for (var rowIndex = 0; rowIndex < rows.length; rowIndex++) ...[
            if (rowIndex > 0)
              SizedBox(height: Responsive.space(context, 6)),
            Row(
              children: [
                if (rowIndex == 1) const Spacer(flex: 1),
                for (var index = 0; index < rows[rowIndex].length; index++) ...[
                  if (index > 0)
                    SizedBox(width: Responsive.space(context, 6)),
                  Expanded(
                    flex: rows[rowIndex][index].flex,
                    child: _keyButton(context, rows[rowIndex][index]),
                  ),
                ],
                if (rowIndex == 1) const Spacer(flex: 1),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _keyButton(BuildContext context, KeyboardKeyData key) {
    if (key.kind == KeyboardKeyKind.disabled) {
      return SizedBox(height: Responsive.space(context, 44));
    }
    final selectedShift = key.kind == KeyboardKeyKind.shift && _shifted;
    final fill = switch (key.kind) {
      KeyboardKeyKind.shift || KeyboardKeyKind.enter => AppColors.chambray,
      KeyboardKeyKind.backspace => AppColors.clay,
      KeyboardKeyKind.layer => AppColors.bisque,
      _ => AppColors.canvas,
    };
    final labelColor =
        selectedShift ? AppColors.glacier : AppColors.espresso;
    final label = key.isLetter
        ? (_shifted ? key.label.toUpperCase() : key.label.toLowerCase())
        : key.label;
    final icon = switch (key.kind) {
      KeyboardKeyKind.shift when _capsLock => Icons.lock,
      KeyboardKeyKind.backspace => Icons.backspace_outlined,
      KeyboardKeyKind.enter => Icons.keyboard_return,
      _ => null,
    };

    return ExcludeFocus(
      child: Semantics(
        button: true,
        label: _accessibleLabel(context, key),
        child: GestureDetector(
          key: switch (key.kind) {
            KeyboardKeyKind.shift => const ValueKey('keyboard-shift'),
            KeyboardKeyKind.layer => const ValueKey('keyboard-layer'),
            KeyboardKeyKind.enter => const ValueKey('keyboard-enter'),
            KeyboardKeyKind.backspace =>
              const ValueKey('keyboard-backspace'),
            _ => null,
          },
          onTap: () => switch (key.kind) {
            KeyboardKeyKind.shift => _shift(),
            KeyboardKeyKind.backspace => _backspace(),
            KeyboardKeyKind.layer => setState(() => _symbols = !_symbols),
            KeyboardKeyKind.enter => _insert('\n'),
            KeyboardKeyKind.space => _insert(' '),
            KeyboardKeyKind.character => _insert(
                _shifted ? key.label.toUpperCase() : key.label.toLowerCase(),
                isLetter: key.isLetter,
              ),
            KeyboardKeyKind.disabled => null,
          },
          onLongPress: key.kind == KeyboardKeyKind.character
              ? () => _showAlternates(context, key)
              : null,
          onLongPressStart: key.kind == KeyboardKeyKind.backspace
              ? (_) {
                  _deleteTimer?.cancel();
                  _deleteTimer = Timer.periodic(
                    const Duration(milliseconds: 50),
                    (_) => _backspace(),
                  );
                }
              : null,
          onLongPressEnd: key.kind == KeyboardKeyKind.backspace
              ? (_) => _deleteTimer?.cancel()
              : null,
          child: Material(
            color: selectedShift ? AppColors.espresso : fill,
            borderRadius: BorderRadius.circular(Responsive.space(context, 12)),
            child: SizedBox(
              height: Responsive.space(context, 44),
              child: Center(
                child: icon == null
                    ? Text(
                        key.kind == KeyboardKeyKind.shift && _capsLock
                            ? 'Shift'
                            : label,
                        style: TextStyle(
                          color: labelColor,
                          fontSize: key.kind == KeyboardKeyKind.space
                              ? Responsive.sp(context, 15)
                              : Responsive.sp(context, 18),
                          fontWeight: FontWeight.w600,
                        ),
                      )
                    : Icon(
                        icon,
                        size: Responsive.sp(context, 22),
                        color: key.kind == KeyboardKeyKind.backspace
                            ? AppColors.glacier
                            : AppColors.espresso,
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
