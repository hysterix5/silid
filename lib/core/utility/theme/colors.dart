import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Light Theme Colors
  static const Color lightPrimary = Color(0xFF000000); // Black
  static const Color lightSecondary = Color(0xFF14213D); // Dark Blue
  static const Color lightTertiary = Color(0xFFFCA311); // Orange
  static const Color lightBackground = Color(0xFFFFFFFF); // White
  static const Color lightSurface = Color(0xFFF5F5F5); // Light Gray
  static const Color lightError = Colors.red;
  static const Color lightTextColor = Colors.black; // Ensures text is readable

  // Dark Theme Colors
  static const Color darkPrimary = Color.fromARGB(255, 255, 255, 255); // Orange
  static const Color darkSecondary = Color(0xFF14213D); // Dark Blue
  static const Color darkTertiary = Color(0xFF000000); // Black
  static const Color darkBackground = Color(0xFF121212); // Dark Gray
  static const Color darkSurface = Color(0xFF1E1E1E); // Darker Gray
  static const Color darkError = Colors.redAccent;
  static const Color darkTextColor = Colors.white; // Ensures text is readable

  // Light Theme Data
  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      primary: lightPrimary,
      onPrimary: lightBackground,
      secondary: lightSecondary,
      onSecondary: lightBackground,
      tertiary: lightTertiary,
      onTertiary: lightBackground,
      surface: lightSurface,
      onSurface: lightPrimary,
      error: lightError,
      onError: lightBackground,
    ),
    primaryColor: lightPrimary,
    scaffoldBackgroundColor: lightBackground,
    appBarTheme: const AppBarTheme(
        backgroundColor: lightPrimary, foregroundColor: darkPrimary),
    textTheme: GoogleFonts.openSansTextTheme().apply(
      bodyColor: lightTextColor, // Sets default text color
      displayColor: lightTextColor,
    ),
  );

  // Dark Theme Data
  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: darkPrimary,
      onPrimary: darkBackground,
      secondary: darkSecondary,
      onSecondary: darkBackground,
      tertiary: darkTertiary,
      onTertiary: darkBackground,
      surface: darkSurface,
      onSurface: darkPrimary,
      error: darkError,
      onError: darkBackground,
    ),
    primaryColor: darkPrimary,
    scaffoldBackgroundColor: darkBackground,
    appBarTheme: const AppBarTheme(
        backgroundColor: darkPrimary, foregroundColor: lightPrimary),
    textTheme: GoogleFonts.openSansTextTheme().apply(
      bodyColor: darkTextColor, // Ensures dark mode text is visible
      displayColor: darkTextColor,
    ),
  );
}
