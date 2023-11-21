import 'dart:math';

import 'package:flutter/material.dart';

class Styles {
  static const _textSizeLarge = 22.0;
  static const _textSizeDefault = 16.0;
  static const _textSizeSmall = 14.0;
  static const horizontalPaddingDefault = 12.0;
  static final Color _textColorStrong = _hexToColor('000000');
  static final Color _textColorDefault = _hexToColor('000000');
  static final Color _textColorFaint = _hexToColor('999999');
  static final Color textColorBright = _hexToColor('FFFFFF');
  static final Color accentColor = _hexToColor('FF0000');
  static final Color blueColor = _hexToColor('3c556c');
  static final Color textColor = _hexToColor('233115');
  static final Color addButtonColor = _hexToColor('669a33');
  static final Color iconColor = _hexToColor('75a447');
  static final Color shadowColor = _hexToColor('233115');
  static final MaterialColor themeColor = _hexToMaterialColor("669a33");
  static final String _fontNameDefault = 'Roboto'
      '';
  static final navBarTitle = TextStyle(
    fontFamily: _fontNameDefault,
  );
  static final headerLarge = TextStyle(
    fontFamily: _fontNameDefault,
    fontSize: _textSizeLarge,
    color: Colors.white,
  );
  static final fieldDetailTextStyle = TextStyle(
      fontFamily: _fontNameDefault,
      fontSize: _textSizeLarge,
      color: textColor);
  static final textDefault = TextStyle(
    fontFamily: _fontNameDefault,
    fontSize: _textSizeDefault,
    color: _textColorDefault,
    height: 1.2,
  );
  static final textCTAButton = TextStyle(
    fontFamily: _fontNameDefault,
    fontSize: _textSizeLarge,
    color: textColorBright,
  );
  static final locationTileTitleLight = TextStyle(
    fontFamily: _fontNameDefault,
    fontSize: _textSizeLarge,
    color: blueColor,
  );

  static final predictPageTitle = TextStyle(
    fontFamily: _fontNameDefault,
    fontSize: _textSizeDefault,
    color: blueColor,
  );

  static final locationTileTitleDark = TextStyle(
    fontFamily: _fontNameDefault,
    fontSize: _textSizeLarge,
    color: textColorBright,
  );
  static final locationTileSubTitle = TextStyle(
    fontFamily: _fontNameDefault,
    fontSize: _textSizeDefault,
    color: accentColor,
  );
  static final locationTileCaption = TextStyle(
    fontFamily: _fontNameDefault,
    fontSize: _textSizeDefault,
    color: _textColorFaint,
  );

  static final timeTitle = TextStyle(
      fontFamily: _fontNameDefault,
      fontSize: _textSizeDefault,
      color: blueColor);

  static final fieldName = TextStyle(
      fontFamily: _fontNameDefault, fontSize: _textSizeLarge, color: blueColor);

  static final fieldDetailButtonStyle = ButtonStyle(
      padding: MaterialStateProperty.all<EdgeInsets>(EdgeInsets.all(10)),
      backgroundColor: MaterialStateProperty.all<Color>(Colors.white),
      shadowColor: MaterialStateProperty.all<Color>(blueColor),
      shape: MaterialStateProperty.all<RoundedRectangleBorder>(
          RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
      )));

  static final boxDecoration = BoxDecoration(
      borderRadius: new BorderRadius.circular(10),
      //border: Border.all(color: Styles.blueColor),
      color: Colors.white,
      boxShadow: [
        BoxShadow(
            blurRadius: 5.0, offset: Offset(0, 2), color: shadowColor),
      ]);

  static Color _hexToColor(String code) {
    return Color(int.parse(code.substring(0, 6), radix: 16) + 0xFF000000);
  }

  static MaterialColor _hexToMaterialColor(String code) {
    Color color =
        Color(int.parse(code.substring(0, 6), radix: 16) + 0xFF000000);
    return MaterialColorGenerator.from(color);
  }
}

class MaterialColorGenerator{
  static MaterialColor from(Color color) {
    return MaterialColor(color.value, {
      50: tintColor(color, 0.9),
      100: tintColor(color, 0.8),
      200: tintColor(color, 0.6),
      300: tintColor(color, 0.4),
      400: tintColor(color, 0.2),
      500: color,
      600: shadeColor(color, 0.1),
      700: shadeColor(color, 0.2),
      800: shadeColor(color, 0.3),
      900: shadeColor(color, 0.4),
    });
  }

  static int tintValue(int value, double factor) =>
      max(0, min((value + ((255 - value) * factor)).round(), 255));

  static Color tintColor(Color color, double factor) => Color.fromRGBO(
      tintValue(color.red, factor),
      tintValue(color.green, factor),
      tintValue(color.blue, factor),
      1);

  static int shadeValue(int value, double factor) =>
      max(0, min(value - (value * factor).round(), 255));

  static Color shadeColor(Color color, double factor) => Color.fromRGBO(
      shadeValue(color.red, factor),
      shadeValue(color.green, factor),
      shadeValue(color.blue, factor),
      1);
}
