// ============================================================
// lib/theme/app_theme.dart — S2 Midnight
// ------------------------------------------------------------
// 保证：
//   - 所有 public 字段名与原版一致（不会触发任何调用点编译错误）
//   - lightTheme 这个 getter 名字保留（外部 MaterialApp 不用动）
//   - 几何 token (radius*, padding*) 数值完全不变（无布局位移）
//   - 内部切到 Material 3 Brightness.dark + 自定义午夜色板
// ============================================================

import 'package:flutter/material.dart';

class AppTheme {
  // ── ink (前景) ───────────────────────────────────────────────
  static const Color _ink = Color(0xFFF2E9D8);

  // ── 主行动 / 重大事件：余烬橙 ─────────────────────────────────
  static const Color accent = Color(0xFFE07A3B);
  static const Color accentStrong = Color(0xFFEC8C4F);
  static const Color accentSoft = Color(0x2EE07A3B);     // ~18% alpha
  static const Color accentMuted = Color(0xFFB66332);

  // ── 持续追踪 / 高亮：暖琥珀（取代旧绿色 mint / live 槽位）─────
  static const Color highlight = Color(0xFFF2B544);
  static const Color highlightStrong = Color(0xFFE0A02E);
  static const Color highlightSoft = Color(0x29F2B544);  // ~16% alpha

  // ── 页面 / 卡片 ─────────────────────────────────────────────
  static const Color background = Color(0xFF0E1A2B);
  static const Color followingBackground = Color(0xFF0E1A2B);
  static const Color backgroundRaised = Color(0xFF142238);
  static const Color timelineBackground = Color(0xFF0E1A2B);
  static const Color recommendBackground = Color(0xFF0E1A2B);
  static const Color surface = Color(0xFF142238);
  static const Color surfaceMuted = Color(0xFF1B2E47);

  // ── 历史 mint / success → 同步改琥珀，确保整个 app 无绿 ────────
  static const Color mint = Color(0xFFF2B544);
  static const Color mintDeep = Color(0xFFE0A02E);
  static const Color mintSoft = Color(0x29F2B544);

  // ── 来源 / 信息冷色点缀（替代旧 lavender 紫，紫色在午夜不和谐）─
  static const Color lavender = Color(0xFF7AB6EA);
  static const Color lavenderSoft = Color(0x247AB6EA);   // ~14% alpha

  // ── 纸面/木色装饰槽位 → 重新指向深抬起色，避免米色泄漏 ─────────
  static const Color paperGold = Color(0xFF1B2E47);
  static const Color brown = Color(0x9EF2E9D8);          // 62% ink

  // ── 描边 / 分割线（10% / 18% 象牙白）──────────────────────────
  static const Color border = Color(0x1AF2E9D8);
  static const Color warmHairline = Color(0x1AF2E9D8);
  static const Color borderStrong = Color(0x2EF2E9D8);

  // ── 文本 ────────────────────────────────────────────────────
  static const Color textPrimary = _ink;
  static const Color textSecondary = Color(0x9EF2E9D8);  // 62%
  static const Color textTertiary = Color(0x61F2E9D8);   // 38%

  // ── 语义色 ──────────────────────────────────────────────────
  static const Color success = Color(0xFFF2B544);        // 不再用绿色
  static const Color danger = Color(0xFFE0796E);
  static const Color unread = Color(0x2EE07A3B);
  static const Color unreadBorder = Color(0xFFE07A3B);

  // ── 阴影：dark mode 加深 ─────────────────────────────────────
  static const Color shadow = Color(0x66000000);

  // ── 几何 token（保持原值，避免布局位移）────────────────────────
  static const double pageHorizontalPadding = 18;
  static const double cardVerticalGap = 12;
  static const double radiusCard = 18;
  static const double radiusControl = 14;
  static const double radiusSheet = 22;
  static const double radiusPill = 999;

  /// 命名保持 `lightTheme` 不变，避免任何 import / 调用点改动。
  /// 实际返回 Material 3 Dark + 自定义午夜色板。
  static ThemeData get lightTheme {
    final base = ThemeData.dark(useMaterial3: true);
    final colorScheme = ColorScheme.fromSeed(
      seedColor: accent,
      brightness: Brightness.dark,
    ).copyWith(
      primary: accent,
      onPrimary: background,
      primaryContainer: accentSoft,
      onPrimaryContainer: accentStrong,
      secondary: highlight,
      onSecondary: background,
      secondaryContainer: highlightSoft,
      onSecondaryContainer: highlight,
      tertiary: accentStrong,
      onTertiary: background,
      surface: surface,
      onSurface: textPrimary,
      surfaceContainerLowest: background,
      surfaceContainerLow: surface,
      surfaceContainer: backgroundRaised,
      surfaceContainerHigh: surfaceMuted,
      surfaceContainerHighest: const Color(0xFF24395A),
      outline: borderStrong,
      outlineVariant: border,
      error: danger,
      onError: background,
    );
    const fallbackFamilies = <String>[
      'PingFang SC',
      'Noto Sans CJK SC',
      'Microsoft YaHei UI',
      'Microsoft YaHei',
    ];
    const serifFallbackFamilies = <String>[
      'Noto Serif SC',
      'Source Han Serif SC',
      'Source Han Serif CN',
      'Noto Serif CJK SC',
      'Songti SC',
      'STSong',
      'SimSun',
      'NSimSun',
      'serif',
      'PingFang SC',
      'Microsoft YaHei',
    ];
    final textTheme = base.textTheme
        .apply(
          bodyColor: textPrimary,
          displayColor: textPrimary,
        )
        .copyWith(
          headlineLarge: const TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
            height: 1.06,
            color: textPrimary,
            fontFamily: 'Noto Serif SC',
            fontFamilyFallback: serifFallbackFamilies,
          ),
          headlineMedium: const TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
            height: 1.08,
            color: textPrimary,
            fontFamily: 'Noto Serif SC',
            fontFamilyFallback: serifFallbackFamilies,
          ),
          headlineSmall: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.1,
            height: 1.14,
            color: textPrimary,
            fontFamily: 'Noto Serif SC',
            fontFamilyFallback: serifFallbackFamilies,
          ),
          titleLarge: const TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
            height: 1.18,
            color: textPrimary,
            fontFamily: 'Noto Serif SC',
            fontFamilyFallback: serifFallbackFamilies,
          ),
          titleMedium: const TextStyle(
            fontSize: 15.5,
            fontWeight: FontWeight.w800,
            height: 1.24,
            color: textPrimary,
            fontFamilyFallback: fallbackFamilies,
          ),
          titleSmall: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            height: 1.24,
            color: textPrimary,
            fontFamilyFallback: fallbackFamilies,
          ),
          bodyLarge: const TextStyle(
            fontSize: 15.5,
            fontWeight: FontWeight.w500,
            height: 1.55,
            color: textPrimary,
            fontFamilyFallback: fallbackFamilies,
          ),
          bodyMedium: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w500,
            height: 1.5,
            color: textPrimary,
            fontFamilyFallback: fallbackFamilies,
          ),
          bodySmall: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            height: 1.45,
            color: textSecondary,
            fontFamilyFallback: fallbackFamilies,
          ),
          labelLarge: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.1,
            color: textPrimary,
            fontFamilyFallback: fallbackFamilies,
          ),
          labelMedium: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.1,
            color: textPrimary,
            fontFamilyFallback: fallbackFamilies,
          ),
          labelSmall: const TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.18,
            color: textSecondary,
            fontFamilyFallback: fallbackFamilies,
          ),
        );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      canvasColor: background,
      dividerColor: border,
      textTheme: textTheme,
      cardTheme: CardThemeData(
        color: surface,
        margin: EdgeInsets.zero,
        elevation: 0,
        shadowColor: shadow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusCard),
          side: const BorderSide(color: border),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        foregroundColor: textPrimary,
        iconTheme: IconThemeData(color: textPrimary),
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
      ),
      iconTheme: const IconThemeData(color: textPrimary),
      primaryIconTheme: const IconThemeData(color: textPrimary),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSheet),
          side: const BorderSide(color: border),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(radiusSheet)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceMuted,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        labelStyle: const TextStyle(
          color: textSecondary,
          fontWeight: FontWeight.w600,
        ),
        hintStyle: const TextStyle(
          color: textTertiary,
        ),
        prefixIconColor: textSecondary,
        suffixIconColor: textSecondary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: accent, width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: danger, width: 1.4),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: background,
          disabledBackgroundColor: surfaceMuted,
          disabledForegroundColor: textTertiary,
          elevation: 0,
          minimumSize: const Size(44, 44),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: textTheme.labelLarge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusControl),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          side: const BorderSide(color: borderStrong),
          backgroundColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusControl),
          ),
          minimumSize: const Size(44, 44),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accent,
          textStyle: textTheme.labelLarge,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: surfaceMuted,
        contentTextStyle: const TextStyle(color: textPrimary),
        actionTextColor: accent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusControl),
          side: const BorderSide(color: border),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: accentSoft,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            color: states.contains(WidgetState.selected)
                ? accentStrong
                : textSecondary,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color:
                states.contains(WidgetState.selected) ? accent : textSecondary,
          ),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: accent,
        linearTrackColor: surfaceMuted,
        circularTrackColor: surfaceMuted,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? accent : textTertiary,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? accentSoft
              : surfaceMuted,
        ),
        trackOutlineColor: WidgetStateProperty.all(border),
      ),
      sliderTheme: const SliderThemeData(
        activeTrackColor: accent,
        inactiveTrackColor: surfaceMuted,
        thumbColor: accent,
        overlayColor: accentSoft,
      ),
      tooltipTheme: const TooltipThemeData(
        decoration: BoxDecoration(
          color: surfaceMuted,
          borderRadius: BorderRadius.all(Radius.circular(8)),
          border: Border.fromBorderSide(BorderSide(color: border)),
        ),
        textStyle: TextStyle(color: textPrimary, fontSize: 12),
      ),
    );
  }
}
