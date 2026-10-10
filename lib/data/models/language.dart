import 'package:flutter/material.dart';

/// Immutable presentation and identity data for an app interface language.
class Language {
  const Language({
    required this.id,
    required this.name,
    required this.fieldLabel,
    required this.greeting,
    required this.fillColor,
    required this.textColor,
    this.borderColor,
    this.sttLocale,
    this.ttsLocale,
    this.ttsApproximate = false,
    this.isExperimental = false,
  });

  final String id;
  final String name;
  final String fieldLabel;
  final String greeting;
  final Color fillColor;
  final Color textColor;
  final Color? borderColor;
  final String? sttLocale;
  final String? ttsLocale;
  final bool ttsApproximate;

  /// True when translation quality for this language is still being tested.
  final bool isExperimental;
}