import 'package:flutter/material.dart';
import 'package:staapp2025/theme/styles.dart';

ThemeData appThemeData = ThemeData(
  appBarTheme: const AppBarTheme(
    color: Styles.primary,
    elevation: 0.0,
    iconTheme: IconThemeData(color: Styles.secondary),
    toolbarTextStyle: TextStyle(
      fontFamily: Styles.fontFamilyNormal,
      fontSize: 20.0,
      fontWeight: FontWeight.w500,
      color: Styles.secondary,
      letterSpacing: 0.15,
    ),
  ),
  brightness: Brightness.light,
  colorScheme: ColorScheme.fromSwatch()
      .copyWith(primary: Styles.primary, secondary: Styles.secondary),
  elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
          foregroundColor: WidgetStateProperty.all<Color>(Styles.white),
          backgroundColor: WidgetStateProperty.all<Color>(Styles.secondary),
          shape: WidgetStateProperty.all<RoundedRectangleBorder>(
              const RoundedRectangleBorder(
                  borderRadius: Styles.mainBorderRadius,
                  side: BorderSide(color: Styles.secondary))))),
  fontFamily: Styles.fontFamilyNormal,
  hintColor: Styles.grey,
  iconTheme: const IconThemeData(color: Styles.primary),
  inputDecorationTheme: const InputDecorationTheme(
    contentPadding: EdgeInsets.symmetric(
      horizontal: Styles.mainHorizontalPadding,
      vertical: Styles.mainVerticalPadding,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: Styles.mainBorderRadius,
      borderSide: BorderSide(
        color: Styles.secondary,
        width: 1.0,
      ),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: Styles.mainBorderRadius,
      borderSide: BorderSide(
        color: Styles.primary,
        width: 1.0,
      ),
    ),
    labelStyle: TextStyle(
      fontFamily: Styles.fontFamilyNormal,
      fontSize: 14.0,
      fontWeight: FontWeight.w500,
      color: Styles.primary,
    ),
    hintStyle: TextStyle(
      fontFamily: Styles.fontFamilyNormal,
      fontSize: 12.0,
      fontWeight: FontWeight.w500,
      color: Styles.grey,
    ),
  ),
  primaryColor: createMaterialColor(Styles.primary),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: Styles.secondary,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      textStyle: const TextStyle(fontFamily: Styles.fontFamilyNormal),
    ),
  ),
  textSelectionTheme: TextSelectionThemeData(
    cursorColor: Styles.secondary,
    selectionHandleColor: Styles.secondary,
    selectionColor: Styles.secondary.withAlpha(128),
  ),
  textTheme: const TextTheme(
    /*
      NEW theme parameters
headline1	displayLarge
headline2	displayMedium
headline3	displaySmall
headline4	headlineMedium
headline5	headlineSmall
headline6	titleLarge
subtitle1	titleMedium
subtitle2	titleSmall
bodyText1	bodyLarge
bodyText2	bodyMedium
caption	bodySmall
button	labelLarge
overline	labelSmall
    */
    displayLarge: TextStyle(
        fontFamily: Styles.fontFamilyNormal,
        fontSize: 96.0,
        fontWeight: FontWeight.w300,
        color: Styles.primary,
        letterSpacing: -1.5),
    displayMedium: TextStyle(
        fontFamily: Styles.fontFamilyNormal,
        fontSize: 60.0,
        fontWeight: FontWeight.w300,
        color: Styles.primary,
        letterSpacing: -0.5),
    displaySmall: TextStyle(
        fontFamily: Styles.fontFamilyNormal,
        fontSize: 48.0,
        fontWeight: FontWeight.w400,
        color: Styles.primary,
        letterSpacing: 0.0),
    headlineMedium: TextStyle(
        fontFamily: Styles.fontFamilyNormal,
        fontSize: 34.0,
        fontWeight: FontWeight.w400,
        color: Styles.primary,
        letterSpacing: 0.25),
    headlineSmall: TextStyle(
        fontFamily: Styles.fontFamilyNormal,
        fontSize: 24.0,
        fontWeight: FontWeight.w600,
        color: Styles.primary,
        letterSpacing: 0.0),
    titleLarge: TextStyle(
        fontFamily: Styles.fontFamilyTitles,
        fontSize: 18.0,
        fontWeight: FontWeight.bold,
        color: Styles.primary,
        letterSpacing: 0.15),
    titleMedium: TextStyle(
        fontFamily: Styles.fontFamilyNormal,
        fontSize: 16.0,
        fontWeight: FontWeight.w500,
        color: Styles.white,
        letterSpacing: 0.15),
    titleSmall: TextStyle(
        fontFamily: Styles.fontFamilyNormal,
        fontSize: 14.0,
        fontWeight: FontWeight.bold,
        color: Styles.primary,
        letterSpacing: 0.1),
    bodyLarge: TextStyle(
        fontFamily: Styles.fontFamilyNormal,
        fontSize: 16.0,
        fontWeight: FontWeight.w400,
        color: Styles.primary,
        letterSpacing: 0.5),
    bodyMedium: TextStyle(
      fontFamily: Styles.fontFamilyNormal,
      fontSize: 14.0,
      fontWeight: FontWeight.w400,
      color: Styles.primary,
      letterSpacing: 0.25,
    ),
    labelLarge: TextStyle(
        fontFamily: Styles.fontFamilyNormal,
        fontSize: 14.0,
        fontWeight: FontWeight.w500,
        color: Styles.primary,
        letterSpacing: 1.25),
    bodySmall: TextStyle(
        fontFamily: Styles.fontFamilyNormal,
        fontSize: 12.0,
        fontWeight: FontWeight.w400,
        color: Styles.primary,
        letterSpacing: 0.4),
    labelSmall: TextStyle(
        fontFamily: Styles.fontFamilyNormal,
        fontSize: 10.0,
        fontWeight: FontWeight.w400,
        color: Styles.primary,
        letterSpacing: 1.5),
  ),
);

MaterialColor createMaterialColor(Color color) {
  Map<int, Color> swatch = {
    50: Color.alphaBlend(color.withAlpha(26), Colors.white),
    100: Color.alphaBlend(color.withAlpha(51), Colors.white),
    200: Color.alphaBlend(color.withAlpha(77), Colors.white),
    300: Color.alphaBlend(color.withAlpha(102), Colors.white),
    400: Color.alphaBlend(color.withAlpha(128), Colors.white),
    500: Color.alphaBlend(color.withAlpha(153), Colors.white),
    600: Color.alphaBlend(color.withAlpha(179), Colors.white),
    700: Color.alphaBlend(color.withAlpha(204), Colors.white),
    800: Color.alphaBlend(color.withAlpha(230), Colors.white),
    900: color, // No change to the original color
  };

  return MaterialColor(color.hashCode, swatch);
}
