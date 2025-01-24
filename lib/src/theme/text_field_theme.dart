import 'package:flutter/material.dart';
import 'package:vimbika_pos_app/src/constants/colors.dart';

class TTextFormFieldTheme {
  TTextFormFieldTheme._();

  static InputDecorationTheme lightInputDecorationTheme = const InputDecorationTheme(
    //If you want circular border -- Use this
    // border: OutlineInputBorder(borderRadius: BorderRadius.circular(100)),
      border: OutlineInputBorder(),
      prefixIconColor: tSecondaryColor,
      floatingLabelStyle: TextStyle(color: tSecondaryColor),
      focusedBorder: OutlineInputBorder(
        // for circular focused Border
        //borderRadius: BorderRadius.circular(100),
        borderSide: BorderSide(width: 2, color: tSecondaryColor),
      ));

  static InputDecorationTheme darkInputDecorationTheme = const InputDecorationTheme(
    //If you want circular border -- Use this
      // border: OutlineInputBorder(borderRadius: BorderRadius.circular(100)),
      border: OutlineInputBorder(),
      prefixIconColor: tPrimaryColor,
      floatingLabelStyle: TextStyle(color: tPrimaryColor),
      focusedBorder: OutlineInputBorder(
        // for circular focused Border
        //borderRadius: BorderRadius.circular(100),
        borderSide: BorderSide(width: 2, color: tPrimaryColor),
      ));
}
