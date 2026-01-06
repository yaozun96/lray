import 'package:flutter/material.dart';

/// SoraVPN 应用主题配置
/// 完全参考website性冷淡风格 - 极简主义设计
class AppTheme {
  // ===== 配色方案 - 参考 theme_website (Shadcn Slate/Blue) =====

  // 背景色 (Light Mode)
  static const Color background = Color(0xFFFFFFFF); // hsl(0 0% 100%)
  static const Color card = Color(0xFFFFFFFF); // hsl(0 0% 100%)

  // 前景色/文字色 (Light Mode)
  static const Color foreground = Color(0xFF020817); // hsl(222.2 84% 4.9%)
  static const Color mutedForeground = Color(0xFF64748B); // hsl(215.4 16.3% 46.9%)

  // 边框和输入框 (Light Mode)
  static const Color border = Color(0xFFE2E8F0); // hsl(214.3 31.8% 91.4%)
  static const Color input = Color(0xFFE2E8F0); // hsl(214.3 31.8% 91.4%)

  // 次要背景色 (Light Mode)
  static const Color muted = Color(0xFFF1F5F9); // hsl(210 40% 96.1%)
  static const Color secondary = Color(0xFFF1F5F9); // hsl(210 40% 96.1%)
  static const Color accent = Color(0xFFF1F5F9); // hsl(210 40% 96.1%)

  // Primary色 (Light Mode) - Blue 600
  static const Color primary = Color(0xFF2563EB); // hsl(221.2 83.2% 53.3%)
  static const Color primaryForeground = Color(0xFFFFFFFF); // hsl(210 40% 98%)

  // Accent色
  static const Color accentForeground = Color(0xFF0F172A); // hsl(222.2 47.4% 11.2%)

  // 状态颜色
  static const Color destructive = Color(0xFFEF4444); // hsl(0 84.2% 60.2%)
  static const Color destructiveForeground = Color(0xFFFAFAFA); // hsl(210 40% 98%)

  // 成功/警告/错误
  static const Color success = Color(0xFF10B981); // Emerald 500
  static const Color warning = Color(0xFFF59E0B); // Amber 500
  static const Color error = Color(0xFFEF4444); // Red 500

  // Ring颜色
  static const Color ring = Color(0xFF2563EB); // hsl(221.2 83.2% 53.3%)

  /// 主题配置
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primary,

      // 颜色方案
      colorScheme: const ColorScheme.light(
        primary: primary,
        secondary: secondary,
        surface: card,
        background: background,
        error: destructive,
        onPrimary: primaryForeground,
        onSecondary: accentForeground,
        onSurface: foreground,
        onBackground: foreground,
        onError: destructiveForeground,
      ),

      // 脚手架背景
      scaffoldBackgroundColor: background,

      // AppBar 主题
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: foreground,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: foreground),
      ),

      // 卡片主题
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(
            color: border,
            width: 1,
          ),
        ),
        margin: EdgeInsets.zero,
      ),

      // 按钮主题
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: primaryForeground,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      // Outlined按钮
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: foreground,
          side: const BorderSide(color: border, width: 1),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      // Text按钮
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: mutedForeground, // 默认使用次要文字颜色，hover时可能需要加深
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      // 文本主题
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: foreground,
          fontSize: 36,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.02 * 36,
        ),
        displayMedium: TextStyle(
          color: foreground,
          fontSize: 30,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.02 * 30,
        ),
        displaySmall: TextStyle(
          color: foreground,
          fontSize: 24,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.02 * 24,
        ),
        headlineLarge: TextStyle(
          color: foreground,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.02 * 20,
        ),
        headlineMedium: TextStyle(
          color: foreground,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.02 * 18,
        ),
        headlineSmall: TextStyle(
          color: foreground,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: TextStyle(
          color: foreground,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: TextStyle(
          color: foreground,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        titleSmall: TextStyle(
          color: foreground,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: TextStyle(
          color: foreground,
          fontSize: 16,
          fontWeight: FontWeight.w400,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          color: mutedForeground,
          fontSize: 14,
          fontWeight: FontWeight.w400,
          height: 1.5,
        ),
        bodySmall: TextStyle(
          color: mutedForeground,
          fontSize: 12,
          fontWeight: FontWeight.w400,
          height: 1.5,
        ),
        labelLarge: TextStyle(
          color: foreground,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),

      // 输入框主题
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: background, // Shadcn 通常是白底+边框，或者 muted 底
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: ring, width: 2), // Ring 颜色
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: destructive),
        ),
        hintStyle: const TextStyle(color: mutedForeground),
      ),

      // 图标主题
      iconTheme: const IconThemeData(
        color: foreground,
        size: 20,
      ),

      // 分隔线主题
      dividerTheme: const DividerThemeData(
        color: border,
        thickness: 1,
        space: 1,
      ),

      // BottomSheet主题
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
      ),
    );
  }

  // 保留旧的颜色常量以保持兼容性
  static const Color bgLight = background;
  static const Color bgLightSecondary = muted;
  static const Color bgLightCard = card;
  static const Color textLightPrimary = foreground;
  static const Color textLightSecondary = mutedForeground;
  static const Color textLightTertiary = mutedForeground;
  static const Color bgDarkest = primary;
  static const Color bgDarkestLight = Color(0xFF3B82F6); // Blue 500
  static const Color primaryDark = primary;
  static const Color textPrimary = foreground;
  static const Color textSecondary = mutedForeground;
  static const Color bgCard = card;
  static const Color bgDark = Color(0xFF020817); // Slate 950
  static const Color primaryPurple = primary; // Replaced transparently

  static ThemeData get darkTheme => lightTheme; // Forced Light Mode for now to match verified Design
}
