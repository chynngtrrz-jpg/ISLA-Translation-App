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
    this.sttFallbackLocale,
    this.ttsLocale,
    this.ttsApproximate = false,
  });

  final String id;
  final String name;
  final String fieldLabel;
  final String greeting;
  final Color fillColor;
  final Color textColor;
  final Color? borderColor;
  final String? sttLocale;
  final String? sttFallbackLocale;
  final String? ttsLocale;
  final bool ttsApproximate;

  /// Recognizer locale used for voice input, or null if voice is unsupported.
  String? get effectiveSttLocale => sttLocale ?? sttFallbackLocale;
}
