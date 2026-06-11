import 'package:flutter/material.dart';

abstract final class AppColors {
  // Brand — base palette
  static const Color espresso = Color(0xFF1A0F0A);
  static const Color espressoLight = Color(0xFF2C1A12);
  static const Color caramel = Color(0xFFC68642);
  static const Color caramelLight = Color(0xFFD4975A);
  static const Color cream = Color(0xFFF5EFE6);
  static const Color parchment = Color(0xFFEDE3D4);

  // AI — EXCLUSIVELY for AI-generated content
  static const Color aiBlue = Color(0xFF2D7DD2);
  static const Color aiBlueLight = Color(0xFF5B9FE1);
  static const Color aiBlueContainer = Color(0xFFE8F1FC);

  // Role accent colors
  static const Color roleFarmer       = Color(0xFF4CAF50);
  static const Color roleProcessor    = Color(0xFFC68642);
  static const Color roleBarista      = Color(0xFF1565C0);
  static const Color roleEntrepreneur = Color(0xFF7B1FA2);
  static const Color roleAdmin        = Color(0xFF37474F);

  // Semantic
  static const Color success = Color(0xFF2E7D32);
  static const Color successContainer = Color(0xFFE8F5E9);
  static const Color warning = Color(0xFFF57F17);
  static const Color warningContainer = Color(0xFFFFFDE7);
  static const Color error = Color(0xFFC62828);
  static const Color errorContainer = Color(0xFFFFEBEE);
  static const Color info = Color(0xFF01579B);
  static const Color infoContainer = Color(0xFFE1F5FE);

  // Alert levels (mirrors AI alert_level field)
  static const Color alertNone = Colors.transparent;
  static const Color alertInfo = Color(0xFF2D7DD2);
  static const Color alertWarning = Color(0xFFF57F17);
  static const Color alertCritical = Color(0xFFC62828);

  // Neutral
  static const Color surface = Color(0xFFFAF7F4);
  static const Color surfaceVariant = Color(0xFFF0EBE3);
  static const Color outline = Color(0xFFB5A99A);
  static const Color outlineVariant = Color(0xFFD6CCC0);
  static const Color onSurface = Color(0xFF1A0F0A);
  static const Color onSurfaceVariant = Color(0xFF5C4A3A);
  static const Color disabled = Color(0xFF9E9E9E);
  static const Color divider  = Color(0xFFEDE3D4);

  // Learning / AI card
  static const Color learningBg     = Color(0xFFE8F1FC);
  static const Color learningBorder = Color(0xFF5B9FE1);
  static const Color learningIcon   = Color(0xFF2D7DD2);
}
