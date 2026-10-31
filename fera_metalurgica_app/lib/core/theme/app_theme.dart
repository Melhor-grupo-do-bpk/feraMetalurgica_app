import 'package:fera_metalurgica_app/core/theme/app_colors.dart';
import 'package:fera_metalurgica_app/core/theme/app_spacing.dart';
import 'package:fera_metalurgica_app/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';

/// Centralized theme configuration for the FERA app.
class AppTheme {
  const AppTheme._();

  /// Tema claro.
  static ThemeData get light => _build(AppColors.light, Brightness.light);

  /// Tema escuro.
  static ThemeData get dark => _build(AppColors.dark, Brightness.dark);

  static ThemeData _build(AppColors c, Brightness brightness) {
    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: c.primary,
      onPrimary: c.onPrimary,
      secondary: c.brand,
      onSecondary: c.onPrimary,
      tertiary: c.accent,
      onTertiary: c.onPrimary,
      error: c.error,
      onError: c.onPrimary,
      surface: c.background,
      onSurface: c.textPrimary,
      onSurfaceVariant: c.textSecondary,
      surfaceContainerLowest: c.surface,
      surfaceContainerLow: c.surfaceMuted,
      surfaceContainer: c.surfaceVariant,
      outline: c.border,
      outlineVariant: c.borderSubtle,
    );

    final textTheme = const TextTheme(
      displaySmall: AppTextStyles.display,
      headlineSmall: AppTextStyles.headline,
      titleLarge: AppTextStyles.title,
      titleMedium: AppTextStyles.bodyStrong,
      bodyLarge: AppTextStyles.body,
      bodyMedium: AppTextStyles.label,
      bodySmall: AppTextStyles.caption,
      labelLarge: AppTextStyles.labelMedium,
      labelMedium: AppTextStyles.label,
      labelSmall: AppTextStyles.tag,
    ).apply(bodyColor: c.textPrimary, displayColor: c.textPrimary);

    final buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
    );
    const buttonPadding = EdgeInsets.symmetric(
      horizontal: AppSpacing.lg,
      vertical: AppSpacing.sm,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: c.background,
      textTheme: textTheme,
      extensions: [c],
      dividerTheme: DividerThemeData(
        color: c.borderSubtle,
        thickness: 1,
        space: 1,
      ),
      // O fundo padrão do diálogo (`surfaceContainerHigh`) cai em
      // `background`, onde o `TextButton` em `primary` dava 4,41:1 no claro.
      // Em `surface` dá 4,64:1 (D-25), sem cor própria nos botões.
      dialogTheme: DialogThemeData(backgroundColor: c.surface),
      cardTheme: CardThemeData(
        color: c.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          side: BorderSide(color: c.border),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: c.primary,
          foregroundColor: c.onPrimary,
          textStyle: AppTextStyles.labelMedium,
          padding: buttonPadding,
          shape: buttonShape,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: c.textPrimary,
          textStyle: AppTextStyles.label,
          side: BorderSide(color: c.textMuted),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          shape: buttonShape,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surfaceMuted,
        hintStyle: AppTextStyles.body.copyWith(color: c.textMuted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          borderSide: BorderSide(color: c.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          borderSide: BorderSide(color: c.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          borderSide: BorderSide(color: c.primary, width: 2),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: c.accent,
        foregroundColor: c.onPrimary,
        shape: const CircleBorder(),
      ),
    );
  }
}
