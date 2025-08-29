import 'package:flutter/material.dart';

class AppTextStyles {
  static TextStyle get heading => TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: Colors.black,
    fontFamily: 'Poppins',
  );

  static TextStyle get subheading => TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: Colors.black87,
    fontFamily: 'Poppins',
  );

  static TextStyle get body => TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: Colors.black54,
    fontFamily: 'Poppins',
  );

  static TextStyle get button => TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    color: Colors.white,
    fontFamily: 'Poppins',
  );

  static TextStyle get caption => TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: Colors.black,
    fontFamily: 'Poppins',
  );
}
