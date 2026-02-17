import 'package:flutter/material.dart';

class GameColors {
  // Card suits
  static const Color spade = Colors.black;
  static const Color heart = Colors.red;
  static const Color diamond = Colors.red;
  static const Color club = Colors.black;
  
  // Game UI
  static const Color primaryGreen = Color(0xFF327850);
  static const Color cardBackBlue = Color(0xFF1E3C78);
  static const Color accentGold = Color(0xFFFFD700);
  static const Color background = Color(0xFF2D3047);
  static const Color primaryPurple = Color(0xFF6A6D9E);
  static const Color secondaryYellow = Color(0xFFF9A826);
  static const Color accentBlue = Color(0xFF00B4D8);
  static const Color cardBackDarkGreen = Color(0xFF1B4332);

  // buttons
  static const Color buttonGrey = Color(0xFFE0E0E0);
  static const Color buttonTextDark = Colors.black;
  
  // results
  static const Color correctGreen = Color(0xFF009600);
  static const Color wrongRed = Colors.red;
  static const Color bonusGreen = Colors.green;
  
  // dialogs and overlays
  static const Color dialogBackground = Color(0xFFF5F5F5);
  static const Color overlayDark = Color(0x88000000);
  
  // fonts
  static const Color textWhite = Colors.white;
  static const Color textBlack = Colors.black;
  static const Color textBrightGold = Color(0xFFFFD700);
  static const Color textBrightWhite = Color(0xFFF5F5F5);
  static const Color textBrightGrey = Color(0xFFB0B0B0);
  static const Color textBrightGreyDark = Color(0xFF808080);
  
  // Timer phases
  static const Color timerPhase1 = Colors.green;
  static const Color timerPhase2 = Colors.blue;
  static const Color timerPhase3 = Colors.yellow;
  static const Color timerCountUp = Colors.green;
  
  // Score
  static const Color positiveScore = Colors.green;
  static const Color negativeScore = Colors.red;
  static const Color bonusScore = Colors.amber;

  // Probability-specific colors
  static const Color probObviousWin = Color(0xFF00C853); // Bright green for 100% probability
  static const Color probHigh = Color(0xFF4CAF50); // Green for 50-100% probability
  static const Color probLow = Color(0xFFFF9800); // Orange for 10-50% probability
  static const Color probSuperLow = Color(0xFFF44336); // Red for 0-10% probability
  static const Color probObviousFail = Color(0xFFB71C1C); // Dark red for 0% probability

}