import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Material 3 theme using Nunito and the ISLA palette.
abstract final class AppTheme {
  static final ThemeData light = ThemeData(
    useMaterial3: true,
    fontFamily: 'Nunito',
    scaffoldBackgroundColor: AppColors.canvas,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.chambray,
      surface: AppColors.canvas,
    ).copyWith(
      onSurface: AppColors.espresso,
      onPrimary: AppColors.espresso,
      secondary: AppColors.bisque,
      onSecondary: AppColors.espresso,
    ),
    textTheme: const TextTheme(
      bodyMedium: TextStyle(color: AppColors.espresso),
    ),
  );
}