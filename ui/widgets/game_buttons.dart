
import 'package:flutter/material.dart';
import '../../core/models/user_guess.dart';
import '../styles/game_colors.dart';

class ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool isEnabled;
  final double? width;

  const ActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.isEnabled = true,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? 180,
      height: 50,
      child: ElevatedButton(
        onPressed: isEnabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: GameColors.buttonGrey,
          foregroundColor: GameColors.buttonTextDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 4,
          shadowColor: Colors.black.withOpacity(0.3),
          padding: const EdgeInsets.symmetric(horizontal: 8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,  // Add ellipsis if text is too long
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GuessButton extends StatelessWidget {
  final UserGuess guess;
  final VoidCallback onPressed;
  final bool isSelected;
  final bool isEnabled;

  const GuessButton({
    super.key,
    required this.guess,
    required this.onPressed,
    this.isSelected = false,
    this.isEnabled = true,
  });

  String _getEmoji() {
    switch (guess) {
      case UserGuess.higher:
        return '🐘';
      case UserGuess.tie:
        return '🈴';
      case UserGuess.lower:
        return '🐜';
    }
  }

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;

    if (!isEnabled) {
      backgroundColor = Colors.grey.shade300;
      textColor = Colors.grey.shade600;
    } else if (isSelected) {
      backgroundColor = GameColors.accentGold;
      textColor = GameColors.textBlack;
    } else {
      backgroundColor = GameColors.buttonGrey;
      textColor = GameColors.buttonTextDark;
    }

    return SizedBox(
      width: 140,
      height: 50,
      child: ElevatedButton(
        onPressed: isEnabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: isSelected ? 8 : 4,
          shadowColor: Colors.black.withOpacity(isSelected ? 0.4 : 0.3),
          padding: const EdgeInsets.symmetric(horizontal: 8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _getEmoji(),
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(width: 6),
            Text(
              guess.displayName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MainButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final Color? textColor;

  const MainButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      height: 50,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? GameColors.primaryGreen,
          foregroundColor: textColor ?? GameColors.textWhite,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 6,
          shadowColor: Colors.black.withOpacity(0.3),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

