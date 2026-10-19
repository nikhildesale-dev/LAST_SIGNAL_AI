import 'package:flutter/material.dart';

/// Centralized color palette for LAST SIGNAL AI
/// Inspired by deep oceans, Earth observation, disaster preparedness,
/// and emergency-response technology.
class AppColors {
  AppColors._();

  // Core Ocean Palette
  static const Color deepOceanNavy = Color(0xFF0B2538); // Primary dark background
  static const Color darkOceanBlue = Color(0xFF123D53); // Surface cards & dialogs
  static const Color teal = Color(0xFF1D6177);          // Accent primary
  static const Color mutedBlue = Color(0xFF2D7189);     // Secondary accent & borders
  static const Color icyBlue = Color(0xFFBDE7F2);       // Highlights & glowing accents
  static const Color white = Color(0xFFF7FAFC);         // Pure light text & surfaces

  // Neutral Backgrounds & Text
  static const Color lightBackground = Color(0xFFEDF3F5); // Light mode background
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color mutedText = Color(0xFF6B8290);       // Subtitles, metadata
  static const Color lightMutedText = Color(0xFF8FA3B0);
  static const Color borderNavy = Color(0xFF1A455E);       // Subtle borders in dark mode
  static const Color surfaceCardDark = Color(0xFF0F3247);  // Elevated card background

  // Emergency & Status Colors
  static const Color emergencyRed = Color(0xFFD95757);    // Critical risk & Emergency Mode
  static const Color warningAmber = Color(0xFFE5A84B);    // Moderate/High risk
  static const Color successGreen = Color(0xFF398B77);    // Verified, Synced, Safe
  static const Color infoBlue = Color(0xFF4A90E2);        // Informational notices

  // Gradients
  static const LinearGradient oceanGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [deepOceanNavy, Color(0xFF071926)],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [darkOceanBlue, Color(0xFF0D2E40)],
  );

  static const LinearGradient emergencyGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF8B2323), Color(0xFF4A1010)],
  );

  static const LinearGradient tealAccentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF287994), Color(0xFF134859)],
  );
}
