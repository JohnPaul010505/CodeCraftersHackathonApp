// lib/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Brand palette — single source of truth
// ─────────────────────────────────────────────────────────────────────────────
class AppColors {
  // Brand reds
  static const Color red       = Color(0xFFCC0000);
  static const Color redDark   = Color(0xFF990000);
  static const Color redLight  = Color(0xFFFF3333);

  // Neutrals
  static const Color darkGray   = Color(0xFF1E1E1E);
  static const Color midGray    = Color(0xFF4A4A4A);
  static const Color lightGray  = Color(0xFF8A8A8A);
  static const Color borderGray = Color(0xFFE4E4E4);
  static const Color bgGray     = Color(0xFFF5F5F5);
  static const Color white      = Color(0xFFFFFFFF);
  static const Color surface    = Color(0xFFFAFAFA);

  // Semantic
  static const Color available = Color(0xFF2E7D32);  // green
  static const Color warning   = Color(0xFFF57F17);  // amber
  static const Color moderate  = Color(0xFFE65100);  // orange
  static const Color conflict  = Color(0xFFC62828);  // error red

  /// Returns a colour based on occupancy 0–1
  static Color dashBgColor(double occ) {
    if (occ < 0.3)  return const Color(0xFFE8F5E9);
    if (occ < 0.6)  return const Color(0xFFFFF8E1);
    if (occ < 0.85) return const Color(0xFFFBE9E7);
    return const Color(0xFFFFEBEE);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AppTheme — Material3 light theme
// ─────────────────────────────────────────────────────────────────────────────
class AppTheme {
  // Legacy aliases (keeps older screens compiling without changes)
  static const Color primaryBlue        = AppColors.red;
  static const Color primaryBlueDark    = AppColors.redDark;
  static const Color primaryBlueLight   = AppColors.redLight;
  static const Color accentBlue         = AppColors.red;
  static const Color availableGreen     = AppColors.available;
  static const Color availableGreenLight= AppColors.available;
  static const Color warningYellow      = AppColors.warning;
  static const Color warningOrange      = AppColors.moderate;
  static const Color conflictRed        = AppColors.conflict;
  static const Color conflictRedLight   = AppColors.redLight;
  static const Color backgroundLight    = AppColors.bgGray;
  static const Color cardWhite          = AppColors.white;
  static const Color textPrimary        = AppColors.darkGray;
  static const Color textSecondary      = AppColors.lightGray;
  static const Color dividerColor       = AppColors.borderGray;
  static const Color surfaceGrey        = AppColors.bgGray;

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.red,
        brightness: Brightness.light,
        primary: AppColors.red,
        secondary: AppColors.darkGray,
        error: AppColors.conflict,
        surface: AppColors.white,
      ),
      textTheme: GoogleFonts.interTextTheme().copyWith(
        displayLarge:  GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.w700, color: AppColors.darkGray),
        displayMedium: GoogleFonts.inter(fontSize: 26, fontWeight: FontWeight.w600, color: AppColors.darkGray),
        headlineLarge: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w600, color: AppColors.darkGray),
        headlineMedium:GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.darkGray),
        headlineSmall: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.darkGray),
        bodyLarge:     GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.darkGray),
        bodyMedium:    GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w400, color: AppColors.lightGray),
        labelLarge:    GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.2),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.darkGray,
        foregroundColor: AppColors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.white,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.borderGray),
        ),
        color: AppColors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.red,
          foregroundColor: AppColors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.darkGray,
          side: const BorderSide(color: AppColors.borderGray),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.borderGray),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.borderGray),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.red, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.conflict),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.conflict, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        labelStyle: GoogleFonts.inter(color: AppColors.lightGray, fontSize: 13),
        hintStyle: GoogleFonts.inter(color: AppColors.lightGray, fontSize: 13),
      ),
      scaffoldBackgroundColor: AppColors.bgGray,
      dividerTheme: const DividerThemeData(color: AppColors.borderGray, thickness: 1),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.red,
        foregroundColor: AppColors.white,
        elevation: 2,
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reusable design tokens
// ─────────────────────────────────────────────────────────────────────────────
const kCardRadius = 12.0;
const kPagePadding = EdgeInsets.all(16.0);
const kSectionGap = SizedBox(height: 20);
const kItemGap    = SizedBox(height: 12);

BoxDecoration kCardDecoration({
  Color? color,
  Color? borderColor,
  double radius = kCardRadius,
}) =>
    BoxDecoration(
      color: color ?? AppColors.white,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: borderColor ?? AppColors.borderGray),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );

/// A consistent page header with optional action
class PageHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? action;
  final Color backgroundColor;
  final Color foregroundColor;

  const PageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
    this.backgroundColor = AppColors.darkGray,
    this.foregroundColor = AppColors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        left: 20,
        right: 16,
        bottom: 14,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: foregroundColor,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: foregroundColor.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (action != null) action!,
        ],
      ),
    );
  }
}

/// Consistent section label
class SectionLabel extends StatelessWidget {
  final String text;
  final Color? color;
  final EdgeInsetsGeometry padding;

  const SectionLabel(
      this.text, {
        super.key,
        this.color,
        this.padding = const EdgeInsets.only(bottom: 10),
      });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color ?? AppColors.lightGray,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

/// Status badge pill
class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final double fontSize;

  const StatusBadge(
      this.label, {
        super.key,
        required this.color,
        this.fontSize = 10,
      });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}