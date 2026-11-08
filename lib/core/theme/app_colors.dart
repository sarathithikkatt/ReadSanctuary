import 'package:flutter/material.dart';

/// Centralized color palette and brand tokens for ShelfCraft.
abstract final class AppColors {
  // Brand Warm Oak & Amber
  static const Color primaryOak = Color(0xFFC79C5E);
  static const Color oakDark = Color(0xFFA87E42);
  static const Color oakFascia = Color(0xFF986F35);
  static const Color oakHighlight = Color(0xFFDEBA82);
  static const Color oakShadow = Color(0xFF6B4C20);

  // Backgrounds & Surfaces
  static const Color scaffoldBackground = Color(0xFFF7F2EC);
  static const Color cardSurface = Colors.white;
  static const Color darkAcademiaBackground = Color(0xFF1E2822);
  static const Color botanicalBackground = Color(0xFFD3DDD0);
  static const Color classicWhiteBackground = Color(0xFFFAFAFA);

  // Accents & Materials
  static const Color goldAccent = Color(0xFFD4AF37);
  static const Color goldLight = Color(0xFFFFF4D0);

  // Status Colors
  static const Color statusTbr = Colors.blueGrey;
  static const Color statusReading = Colors.amber;
  static const Color statusFinished = Colors.green;
  static const Color statusDnf = Colors.deepOrange;
  static const Color statusLent = Colors.purple;
}
