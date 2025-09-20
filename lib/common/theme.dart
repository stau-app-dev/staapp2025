import 'package:flutter/material.dart';
import 'package:staapp2025/common/styles.dart';

/// Centralized ThemeData wired to the tokens defined in `common/styles.dart`.
final ThemeData appThemeData = ThemeData(
  appBarTheme: AppBarTheme(
    backgroundColor: kMaroon,
    elevation: 0.0,
    iconTheme: IconThemeData(color: kGold),
    toolbarTextStyle: TextStyle(
      fontFamily: fontFamilyNormal,
      fontSize: 20.0,
      fontWeight: FontWeight.w500,
      color: kGold,
      letterSpacing: 0.15,
    ),
  ),
  brightness: Brightness.light,
  colorScheme: ColorScheme.fromSwatch().copyWith(
    primary: kMaroon,
    secondary: kGold,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      foregroundColor: kWhite,
      backgroundColor: kGold,
      shape: RoundedRectangleBorder(
        borderRadius: mainBorderRadius,
        side: BorderSide(color: kGold),
      ),
    ),
  ),
  fontFamily: fontFamilyNormal,
  hintColor: Color(0xFFC4C4C4),
  iconTheme: IconThemeData(color: kMaroon),
  inputDecorationTheme: InputDecorationTheme(
    contentPadding: EdgeInsets.symmetric(
      horizontal: mainHorizontalPadding,
      vertical: mainVerticalPadding,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: mainBorderRadius,
      borderSide: BorderSide(color: kGold, width: 1.0),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: mainBorderRadius,
      borderSide: BorderSide(color: kMaroon, width: 1.0),
    ),
    labelStyle: TextStyle(
      fontFamily: fontFamilyNormal,
      fontSize: 14.0,
      fontWeight: FontWeight.w500,
      color: kMaroon,
    ),
    hintStyle: TextStyle(
      fontFamily: fontFamilyNormal,
      fontSize: 12.0,
      fontWeight: FontWeight.w500,
      color: Color(0xFFC4C4C4),
    ),
  ),
  primaryColor: createMaterialColor(kMaroon),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: kGold,
      padding: kButtonPadding,
      textStyle: const TextStyle(fontFamily: fontFamilyNormal),
    ),
  ),
  textSelectionTheme: TextSelectionThemeData(
    cursorColor: kGold,
    selectionHandleColor: kGold,
    selectionColor: kGold.withAlpha(128),
  ),
  textTheme: TextTheme(
    displayLarge: TextStyle(
      fontFamily: fontFamilyNormal,
      fontSize: 96.0,
      fontWeight: FontWeight.w300,
      color: kMaroon,
      letterSpacing: -1.5,
    ),
    displayMedium: TextStyle(
      fontFamily: fontFamilyNormal,
      fontSize: 60.0,
      fontWeight: FontWeight.w300,
      color: kMaroon,
      letterSpacing: -0.5,
    ),
    displaySmall: TextStyle(
      fontFamily: fontFamilyNormal,
      fontSize: 48.0,
      fontWeight: FontWeight.w400,
      color: kMaroon,
      letterSpacing: 0.0,
    ),
    headlineMedium: TextStyle(
      fontFamily: fontFamilyNormal,
      fontSize: 34.0,
      fontWeight: FontWeight.w400,
      color: kMaroon,
      letterSpacing: 0.25,
    ),
    headlineSmall: TextStyle(
      fontFamily: fontFamilyNormal,
      fontSize: 24.0,
      fontWeight: FontWeight.w600,
      color: kMaroon,
      letterSpacing: 0.0,
    ),
    titleLarge: TextStyle(
      fontFamily: fontFamilyTitles,
      fontSize: 18.0,
      fontWeight: FontWeight.bold,
      color: kMaroon,
      letterSpacing: 0.15,
    ),
    titleMedium: TextStyle(
      fontFamily: fontFamilyNormal,
      fontSize: 16.0,
      fontWeight: FontWeight.w500,
      color: kWhite,
      letterSpacing: 0.15,
    ),
    titleSmall: TextStyle(
      fontFamily: fontFamilyNormal,
      fontSize: 14.0,
      fontWeight: FontWeight.bold,
      color: kMaroon,
      letterSpacing: 0.1,
    ),
    bodyLarge: TextStyle(
      fontFamily: fontFamilyNormal,
      fontSize: 16.0,
      fontWeight: FontWeight.w400,
      color: kMaroon,
      letterSpacing: 0.5,
    ),
    bodyMedium: TextStyle(
      fontFamily: fontFamilyNormal,
      fontSize: 14.0,
      fontWeight: FontWeight.w400,
      color: kMaroon,
      letterSpacing: 0.25,
    ),
    labelLarge: TextStyle(
      fontFamily: fontFamilyNormal,
      fontSize: 14.0,
      fontWeight: FontWeight.w500,
      color: kMaroon,
      letterSpacing: 1.25,
    ),
    bodySmall: TextStyle(
      fontFamily: fontFamilyNormal,
      fontSize: 12.0,
      fontWeight: FontWeight.w400,
      color: kMaroon,
      letterSpacing: 0.4,
    ),
    labelSmall: TextStyle(
      fontFamily: fontFamilyNormal,
      fontSize: 10.0,
      fontWeight: FontWeight.w400,
      color: kMaroon,
      letterSpacing: 1.5,
    ),
  ),
);

// Reuse createMaterialColor helper from styles.dart by importing that file.
MaterialColor createMaterialColor(Color color) {
  // Newer Flutter Color API deprecates .red/.green/.blue/.value.
  // Convert using component accessors to 0-255 ints.
  final int r = (color.r * 255.0).round() & 0xff;
  final int g = (color.g * 255.0).round() & 0xff;
  final int b = (color.b * 255.0).round() & 0xff;
  final int argb = (0xff << 24) | (r << 16) | (g << 8) | b;

  return MaterialColor(argb, <int, Color>{
    50: Color.fromRGBO(r, g, b, .1),
    100: Color.fromRGBO(r, g, b, .2),
    200: Color.fromRGBO(r, g, b, .3),
    300: Color.fromRGBO(r, g, b, .4),
    400: Color.fromRGBO(r, g, b, .5),
    500: Color.fromRGBO(r, g, b, .6),
    600: Color.fromRGBO(r, g, b, .7),
    700: Color.fromRGBO(r, g, b, .8),
    800: Color.fromRGBO(r, g, b, .9),
    900: Color.fromRGBO(r, g, b, 1),
  });
}
