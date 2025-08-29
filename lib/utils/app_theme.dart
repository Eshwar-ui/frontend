import 'package:flutter/material.dart';

class AppTheme {
  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: Color(0xFF1976D2),
    colorScheme: ColorScheme.light(
      primary: Color(0xFF1976D2),
      secondary: Colors.amber,
    ),
    scaffoldBackgroundColor: Colors.grey[200],
    cardColor: Colors.white,
    textTheme: ThemeData.light().textTheme.apply(
      fontFamily: 'Poppins',
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Color(0xFF1976D2),
      elevation: 0,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Color(0xFF1976D2),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: Color(0xFF2196F3),
    colorScheme: ColorScheme.dark(
      primary: Color(0xFF2196F3),
      secondary: Colors.amber,
    ),
    scaffoldBackgroundColor: Colors.grey[900],
    cardColor: Colors.grey[800],
    textTheme: ThemeData.dark().textTheme.apply(
      fontFamily: 'Poppins',
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.grey[850],
      elevation: 0,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Color(0xFF2196F3),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
  );
}
