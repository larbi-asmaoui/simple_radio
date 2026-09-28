import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/settings/app_settings.dart';
import 'app_colors.dart';

/// Material 3 [ThemeData] for the "Reelhouse" design system.
abstract final class AppTheme {
  static ThemeData build(AppFont font) {
    const scheme = ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.primary,
      onPrimary: AppColors.primaryForeground,
      primaryContainer: AppColors.accent,
      onPrimaryContainer: AppColors.foreground,
      secondary: AppColors.secondary,
      onSecondary: AppColors.foreground,
      // Tonal buttons and selected segments, like shadcn's `secondary`.
      secondaryContainer: AppColors.accent,
      onSecondaryContainer: AppColors.foreground,
      error: AppColors.destructive,
      onError: AppColors.background,
      surface: AppColors.card,
      onSurface: AppColors.foreground,
      onSurfaceVariant: AppColors.mutedForeground,
      surfaceContainerLowest: AppColors.background,
      surfaceContainerLow: AppColors.sidebar,
      surfaceContainer: AppColors.card,
      surfaceContainerHigh: AppColors.secondary,
      surfaceContainerHighest: AppColors.accent,
      outline: AppColors.input,
      outlineVariant: AppColors.border,
      surfaceTint: Colors.transparent,
    );

    final textTheme = _textTheme(font);
    final radius = BorderRadius.circular(AppColors.radius);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: AppColors.background,
      canvasColor: AppColors.background,
      dividerColor: AppColors.border,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.foreground,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.headlineMedium,
      ),
      cardTheme: CardThemeData(
        color: AppColors.card,
        elevation: 0,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.sidebar,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.mutedForeground,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        showUnselectedLabels: true,
        selectedLabelStyle: textTheme.labelSmall?.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: textTheme.labelSmall?.copyWith(fontSize: 12),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.secondary,
        selectedColor: AppColors.primary,
        side: const BorderSide(color: AppColors.border),
        shape: const StadiumBorder(),
        labelStyle: textTheme.labelLarge,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: radius),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.popover,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppColors.radius * 1.4),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.popover,
        dragHandleColor: AppColors.accent,
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: AppColors.mutedForeground,
        textColor: AppColors.foreground,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),
      iconTheme: const IconThemeData(color: AppColors.foreground),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: Colors.transparent,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.popover,
        contentTextStyle: textTheme.bodyMedium,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: InputBorder.none,
        hintStyle: TextStyle(color: AppColors.mutedForeground),
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AppColors.primary,
      ),
    );
  }

  /// Body text in the chosen sans; big headings in the display face,
  /// extra-bold with a touch of tracking (the site's
  /// `font-display font-extrabold tracking-wide`).
  static TextTheme _textTheme(AppFont font) {
    final base = Typography.material2021().white.apply(
      bodyColor: AppColors.foreground,
      displayColor: AppColors.foreground,
    );

    // Google Fonts are fetched on first use and cached on device.
    TextStyle? body(TextStyle? s) => font.bodyFamily == null
        ? s
        : GoogleFonts.getFont(font.bodyFamily!, textStyle: s);

    TextStyle? display(TextStyle? s, double size) {
      final styled = s?.copyWith(
        fontSize: size,
        fontWeight: FontWeight.w800,
        letterSpacing: size * 0.025,
        height: 1.05,
      );
      return font.displayFamily == null
          ? styled
          : GoogleFonts.getFont(font.displayFamily!, textStyle: styled);
    }

    return TextTheme(
      displayLarge: display(base.displayLarge, 64),
      displayMedium: display(base.displayMedium, 52),
      displaySmall: display(base.displaySmall, 44),
      headlineLarge: display(base.headlineLarge, 40),
      headlineMedium: display(base.headlineMedium, 32),
      headlineSmall: display(base.headlineSmall, 28),
      titleLarge: display(base.titleLarge, 24),
      titleMedium: body(
        base.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
      titleSmall: body(base.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
      bodyLarge: body(base.bodyLarge),
      bodyMedium: body(base.bodyMedium),
      bodySmall: body(
        base.bodySmall?.copyWith(color: AppColors.mutedForeground),
      ),
      labelLarge: body(base.labelLarge?.copyWith(fontWeight: FontWeight.w500)),
      labelMedium: body(base.labelMedium),
      labelSmall: body(
        base.labelSmall?.copyWith(color: AppColors.mutedForeground),
      ),
    );
  }
}
