import 'package:fluent_ui/fluent_ui.dart';

/// NAI Prompt Managerのテーマ定義
/// Tailwind CSSのカラーをFluentUIテーマに変換
class NaiTheme {
  // カラー定数（Tailwind Zinc系）
  static const Color bg0 = Color(0xFF18181B);  // zinc-900
  static const Color bg1 = Color(0xFF27272A);  // zinc-800
  static const Color bg2 = Color(0xFF3F3F46);  // zinc-700
  static const Color bg3 = Color(0xFF52525B);  // zinc-600
  static const Color text0 = Color(0xFFFAFAFA); // zinc-50
  static const Color text1 = Color(0xFFA1A1AA); // zinc-400
  static const Color text2 = Color(0xFF71717A); // zinc-500
  static const Color accent = Color(0xFFA78BFA); // violet-400
  static const Color accentLight = Color(0xFFC4B5FD); // violet-300
  static const Color accentDark = Color(0xFF8B5CF6); // violet-500
  static const Color success = Color(0xFF4ADE80); // green-400
  static const Color warning = Color(0xFFFBBF24); // amber-400
  static const Color error = Color(0xFFF87171); // red-400

  /// ダークテーマ
  static FluentThemeData get dark {
    return FluentThemeData(
      brightness: Brightness.dark,
      accentColor: AccentColor.swatch({
        'darkest': accentDark,
        'darker': accentDark,
        'dark': accent,
        'normal': accent,
        'light': accentLight,
        'lighter': accentLight,
        'lightest': accentLight,
      }),
      scaffoldBackgroundColor: bg0,
      menuColor: bg1,
      cardColor: bg1,
      micaBackgroundColor: bg0,
      acrylicBackgroundColor: bg1.withAlpha(200),
      typography: Typography.raw(
        caption: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.normal,
          color: text2,
        ),
        body: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: text0,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: text0,
        ),
        bodyStrong: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: text0,
        ),
        subtitle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: text0,
        ),
        title: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: text0,
        ),
        titleLarge: TextStyle(
          fontSize: 40,
          fontWeight: FontWeight.w600,
          color: text0,
        ),
        display: TextStyle(
          fontSize: 68,
          fontWeight: FontWeight.w600,
          color: text0,
        ),
      ),
      navigationPaneTheme: NavigationPaneThemeData(
        backgroundColor: bg1,
        highlightColor: accent,
        selectedIconColor: WidgetStateProperty.all(text0),
        unselectedIconColor: WidgetStateProperty.all(text1),
        selectedTextStyle: WidgetStateProperty.all(
          const TextStyle(color: text0, fontWeight: FontWeight.w500),
        ),
        unselectedTextStyle: WidgetStateProperty.all(
          const TextStyle(color: text1),
        ),
      ),
      buttonTheme: ButtonThemeData(
        defaultButtonStyle: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) {
              return bg3;
            }
            if (states.contains(WidgetState.hovered)) {
              return bg2;
            }
            return bg1;
          }),
          foregroundColor: WidgetStateProperty.all(text0),
        ),
        filledButtonStyle: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) {
              return accentDark;
            }
            if (states.contains(WidgetState.hovered)) {
              return accentLight;
            }
            return accent;
          }),
          foregroundColor: WidgetStateProperty.all(bg0),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: bg2,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }

  /// ライトテーマ（将来対応）
  static FluentThemeData get light {
    // 暫定的にダークテーマを返す
    return dark;
  }
}
