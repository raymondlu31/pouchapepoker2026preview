
import 'package:flutter/material.dart';
import '../../helper/timer_helper.dart';
import '../styles/game_colors.dart';

class CountdownTimerWidget extends StatelessWidget {
  final TimerState timerState;
  final bool showCountdown;

  const CountdownTimerWidget({
    super.key,
    required this.timerState,
    required this.showCountdown,
  });

  @override
  Widget build(BuildContext context) {
    if (!showCountdown) return const SizedBox.shrink();

    final colors = timerState.colors;
    final backgroundColor = Color(int.parse('0xFF${colors.backgroundColor}'));
    final textColor = Color(int.parse('0xFF${colors.textColor}'));

    return Container(
      width: 120,
      height: 50,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: GameColors.textBlack, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          timerState.displayTime,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
      ),
    );
  }
}

