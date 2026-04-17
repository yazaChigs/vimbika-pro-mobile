import 'package:flutter/material.dart';
import 'package:vimbika_pos_app/src/theme/appbar_theme.dart';
import 'package:vimbika_pos_app/src/constants/colors.dart';
import 'package:vimbika_pos_app/src/constants/sizes.dart';
import 'package:vimbika_pos_app/src/theme/elevated_button_theme.dart';
import 'package:vimbika_pos_app/src/theme/outlined_button_theme.dart';
import 'package:vimbika_pos_app/src/theme/text_field_theme.dart';
import 'package:vimbika_pos_app/src/theme/text_theme.dart';

class TAppTheme {
  TAppTheme._();

  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: tPrimaryColor,
    colorScheme: const ColorScheme.light(
      primary: tPrimaryColor,
      secondary: tSecondaryColor,
      onPrimary: tWhiteColor,
    ),
    textTheme: TTextTheme.lightTextTheme,
    appBarTheme: TAppBarTheme.lightAppBarTheme,
    elevatedButtonTheme: TElevatedButtonTheme.lightElevatedButtonTheme,
    outlinedButtonTheme: TOutlinedButtonTheme.lightOutlinedButtonTheme,
    inputDecorationTheme: TTextFormFieldTheme.lightInputDecorationTheme,
  );

  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: tPrimaryColor,
    colorScheme: const ColorScheme.dark(
      primary: tPrimaryColor,
      secondary: tSecondaryColor,
      onPrimary: tDarkColor,
    ),
    textTheme: TTextTheme.darkTextTheme,
    appBarTheme: TAppBarTheme.darkAppBarTheme,
    elevatedButtonTheme: TElevatedButtonTheme.darkElevatedButtonTheme,
    outlinedButtonTheme: TOutlinedButtonTheme.darkOutlinedButtonTheme,
    inputDecorationTheme: TTextFormFieldTheme.darkInputDecorationTheme,
  );
}
