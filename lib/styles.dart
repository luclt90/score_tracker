import 'package:flutter/material.dart';

const Color backgroundColor = const Color(0xff1a1919); //Color: Onyx
const Color backgroundHeaderColor = const Color(0xff222326); //Color: Charcoal
const Color foregroundButtonColor = const Color(0xfffafafa); //Color: Alabaster
const Color foregroundHintColor = const Color(0xff807f7f); //Color: Smoke
const Color backgroundButtonColorAlabaster = const Color(
  0xfffafafa,
); //Color: Alabaster
const Color backgroundButtonColorBlue = const Color(0xff4280a8); // Color: Blue
const Color foregroundColor = const Color(0xffcccccc); //Color: Silver
const Color roomSecondaryTextColor = Color(0xffb7c2c5);
const Color negativeScoreColor = const Color(0xffff8a80);
const Color negativeScoreBackgroundColor = const Color(0xff633a3d);

const String fontFamily = 'SF Pro Display';
const String fontFamilySFProText = 'SF Pro Text';

TextStyle rowTextStyle = TextStyle(
  color: foregroundColor,
  fontFamily: fontFamilySFProText,
  fontSize: 18.0,
  fontStyle: FontStyle.normal,
);

ThemeData roomExperienceTheme(BuildContext context) {
  final baseTheme = Theme.of(context);
  final colorScheme = baseTheme.colorScheme.copyWith(
    brightness: Brightness.dark,
    primary: backgroundButtonColorBlue,
    onPrimary: foregroundButtonColor,
    surface: backgroundHeaderColor,
    onSurface: foregroundButtonColor,
    outline: roomSecondaryTextColor,
    error: negativeScoreColor,
    onError: backgroundColor,
  );

  return baseTheme.copyWith(
    brightness: Brightness.dark,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: backgroundColor,
    dividerColor: foregroundHintColor.withValues(alpha: 0.28),
    textTheme: baseTheme.textTheme.apply(
      bodyColor: foregroundColor,
      displayColor: foregroundButtonColor,
      fontFamily: fontFamilySFProText,
    ),
    appBarTheme: baseTheme.appBarTheme.copyWith(
      backgroundColor: backgroundColor,
      foregroundColor: foregroundButtonColor,
      titleTextStyle: const TextStyle(
        color: foregroundButtonColor,
        fontFamily: fontFamilySFProText,
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
      iconTheme: const IconThemeData(color: foregroundButtonColor),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: backgroundHeaderColor,
      labelStyle: const TextStyle(color: foregroundColor),
      floatingLabelStyle: const TextStyle(color: foregroundButtonColor),
      hintStyle: const TextStyle(color: roomSecondaryTextColor),
      prefixIconColor: foregroundColor,
      suffixIconColor: foregroundColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: roomSecondaryTextColor.withValues(alpha: 0.65),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: roomSecondaryTextColor.withValues(alpha: 0.65),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: backgroundButtonColorBlue,
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: negativeScoreColor),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: negativeScoreColor, width: 2),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        backgroundColor: backgroundButtonColorBlue,
        foregroundColor: foregroundButtonColor,
        textStyle: const TextStyle(
          fontFamily: fontFamilySFProText,
          fontWeight: FontWeight.w700,
          fontSize: 15,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(50),
        foregroundColor: foregroundButtonColor,
        side: BorderSide(color: roomSecondaryTextColor.withValues(alpha: 0.8)),
        textStyle: const TextStyle(
          fontFamily: fontFamilySFProText,
          fontWeight: FontWeight.w700,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
  );
}
