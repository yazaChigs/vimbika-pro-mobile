import 'package:flutter/material.dart';
import 'package:vimbika_pos_app/src/constants/colors.dart';
/* -- Light & Dark Text Themes -- */
class TTextTheme {
  TTextTheme._(); //To avoid creating instances

/* -- Light Text Theme -- */
  static TextTheme lightTextTheme = TextTheme(
    displayLarge: const TextStyle(fontFamily: 'Poppins', fontSize: 28.0, fontWeight: FontWeight.bold, color: tDarkColor),
    displayMedium: const TextStyle(fontFamily: 'Poppins', fontSize: 24.0, fontWeight: FontWeight.w700, color: tDarkColor),
    displaySmall: const TextStyle(fontFamily: 'Poppins', fontSize: 24.0, fontWeight: FontWeight.normal, color: tDarkColor),
    headlineMedium: const TextStyle(fontFamily: 'Poppins', fontSize: 18.0, fontWeight: FontWeight.w600, color: tDarkColor),
    headlineSmall: const TextStyle(fontFamily: 'Poppins', fontSize: 18.0, fontWeight: FontWeight.normal, color: tDarkColor),
    titleLarge: const TextStyle(fontFamily: 'Poppins', fontSize: 14.0, fontWeight: FontWeight.w600, color: tDarkColor),
    bodyLarge: const TextStyle(fontFamily: 'Poppins', fontSize: 14.0, color: tDarkColor),
    bodyMedium: TextStyle(fontFamily: 'Poppins', fontSize: 14.0, color: tDarkColor.withOpacity(0.8)),
  );

  /* -- Dark Text Theme -- */
  static TextTheme darkTextTheme = TextTheme(
    displayLarge: const TextStyle(fontFamily: 'Poppins', fontSize: 28.0, fontWeight: FontWeight.bold, color: tWhiteColor),
    displayMedium: const TextStyle(fontFamily: 'Poppins', fontSize: 24.0, fontWeight: FontWeight.w700, color: tWhiteColor),
    displaySmall: const TextStyle(fontFamily: 'Poppins', fontSize: 24.0, fontWeight: FontWeight.normal, color: tWhiteColor),
    headlineMedium: const TextStyle(fontFamily: 'Poppins', fontSize: 18.0, fontWeight: FontWeight.w600, color: tWhiteColor),
    headlineSmall: const TextStyle(fontFamily: 'Poppins', fontSize: 18.0, fontWeight: FontWeight.normal, color: tWhiteColor),
    titleLarge: const TextStyle(fontFamily: 'Poppins', fontSize: 14.0, fontWeight: FontWeight.w600, color: tWhiteColor),
    bodyLarge: const TextStyle(fontFamily: 'Poppins', fontSize: 14.0, color: tWhiteColor),
    bodyMedium: TextStyle(fontFamily: 'Poppins', fontSize: 14.0, color: tWhiteColor.withOpacity(0.8)),
  );
}
