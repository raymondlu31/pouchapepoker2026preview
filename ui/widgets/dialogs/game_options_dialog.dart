
import 'package:flutter/material.dart';
import '../../../core/models/flag_options.dart';
import '../../styles/game_colors.dart';

class GameOptionsDialog extends StatefulWidget {
  final FlagOptions initialOptions;
  final Function(FlagOptions) onOptionsChanged;

  const GameOptionsDialog({
    super.key,
    required this.initialOptions,
    required this.onOptionsChanged,
  });

  @override
  State<GameOptionsDialog> createState() => _GameOptionsDialogState();
}

class _GameOptionsDialogState extends State<GameOptionsDialog> {
  late FlagOptions _currentOptions;

  @override
  void initState() {
    super.initState();
    _currentOptions = widget.initialOptions;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: GameColors.dialogBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: GameColors.textBlack, width: 3),
      ),
      child: Container(
        width: 500,
        height: 600,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            const Text(
              'Game Options',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: GameColors.primaryPurple,
              ),
            ),
            const SizedBox(height: 20),
            const Divider(color: GameColors.textBlack, thickness: 1),

            // Content - Scrollable
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    _buildSectionTitle('Game Speed'),
                    _buildGameSpeedOptions(),
                    
                    const SizedBox(height: 30),
                    _buildSectionTitle('Display Options'),
                    _buildToggleOption(
                      'Show Stage Dialogs',
                      _currentOptions.showStageDialog,
                      (value) => _updateOptions(showStageDialog: value),
                    ),
                    _buildToggleOption(
                      'Show Countdown Timer',
                      _currentOptions.showCountDown,
                      (value) => _updateOptions(showCountDown: value),
                    ),
                    _buildToggleOption(
                      'Show Warnings',
                      _currentOptions.showWarnings,
                      (value) => _updateOptions(showWarnings: value),
                    ),
                    
                    const SizedBox(height: 30),
                    _buildSectionTitle('Verbose Log Options'),
                    _buildToggleOption(
                      'Verbose Log Mode',
                      _currentOptions.verboseLogMode,
                      (value) => _updateOptions(verboseLogMode: value),
                    ),
                    
                    const SizedBox(height: 30),
                    _buildSectionTitle('Auto-close Duration'),
                    Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: Text(
                        '${_currentOptions.autoCloseDuration}ms '
                        '(${_getSpeedDescription(_currentOptions.gameSpeed)})',
                        style: const TextStyle(
                          fontSize: 16,
                          color: GameColors.textBlack,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Buttons
            const Divider(color: GameColors.textBlack, thickness: 1),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      fontSize: 16,
                      color: GameColors.textBlack,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () {
                    widget.onOptionsChanged(_currentOptions);
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GameColors.primaryGreen,
                    foregroundColor: GameColors.textWhite,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Save & Start Game',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: GameColors.primaryPurple,
        ),
      ),
    );
  }

  Widget _buildToggleOption(String label, bool value, Function(bool) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                color: GameColors.textBlack,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: GameColors.primaryGreen,
          ),
        ],
      ),
    );
  }

  Widget _buildGameSpeedOptions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildSpeedOption(1, 'Fast (1s)', Icons.fast_forward),
          _buildSpeedOption(2, 'Medium (3s)', Icons.play_arrow),
          _buildSpeedOption(3, 'Slow (10s)', Icons.slow_motion_video),
        ],
      ),
    );
  }

  Widget _buildSpeedOption(int speed, String label, IconData icon) {
    final isSelected = _currentOptions.gameSpeed == speed;
    return GestureDetector(
      onTap: () => _updateOptions(gameSpeed: speed),
      child: Container(
        width: 120,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? GameColors.accentGold : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? GameColors.primaryPurple : Colors.grey,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? GameColors.textBlack : Colors.grey),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isSelected ? GameColors.textBlack : Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _updateOptions({
    bool? verboseLogMode,
    bool? showStageDialog,
    bool? showCountDown,
    bool? showWarnings,
    int? gameSpeed,
  }) {
    setState(() {
      _currentOptions = _currentOptions.copyWith(
        verboseLogMode: verboseLogMode,
        showStageDialog: showStageDialog,
        showCountDown: showCountDown,
        showWarnings: showWarnings,
        gameSpeed: gameSpeed,
      );
    });
  }

  String _getSpeedDescription(int speed) {
    switch (speed) {
      case 1: return 'Fast';
      case 2: return 'Medium';
      case 3: return 'Slow';
      default: return 'Custom';
    }
  }
}

