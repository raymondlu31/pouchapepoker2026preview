import 'dart:async';
import 'package:flutter/material.dart';
import '../core/models/flag_options.dart';
import '../core/models/stage_model.dart';
import '../core/models/score_entry.dart';
import '../ui/widgets/dialogs/message_dialogs.dart';
import '../ui/widgets/dialogs/game_options_dialog.dart';
import '../ui/widgets/dialogs/report_dialogs.dart';


/// Configuration for a dialog in the sequence
class DialogConfig {
  final WidgetBuilder builder;
  final int autoCloseDuration; // 0 = manual close, >0 = auto-close after ms
  final bool dismissible;
  final String type; // For logging purposes

  const DialogConfig({
    required this.builder,
    this.autoCloseDuration = 0,
    this.dismissible = false,
    this.type = 'unknown',
  });
}

/// Manages the sequential display of game dialogs
class DialogSequencer {
  final BuildContext context;
  final FlagOptions options;
  final Future<void> Function() onSequenceComplete;
  
  bool _isRunning = false;
  bool _isDialogShowing = false;
  
  DialogSequencer({
    required this.context,
    required this.options,
    required this.onSequenceComplete,
  });
  
  bool get isRunning => _isRunning;
  
  /// Start a dialog sequence
  Future<void> startSequence(List<DialogConfig> configs) async {
    if (_isRunning) return;
    
    _isRunning = true;
    
    for (int i = 0; i < configs.length; i++) {
      final config = configs[i];
      
      _isDialogShowing = true;
      
      await showDialog(
        context: context,
        barrierDismissible: config.dismissible,
        builder: config.builder,
      );
      
      _isDialogShowing = false;
      
      if (!_isRunning) break;
    }
    
    _isRunning = false;
    await onSequenceComplete();
  }
  
  /// Stop any running sequence
  void stop() {
    _isRunning = false;
    if (_isDialogShowing && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      _isDialogShowing = false;
    }
  }
}

/// Factory for creating dialog sequences based on game state
class DialogSequenceFactory {
  static List<DialogConfig> createInitialSequence(
    FlagOptions options,
    FlagOptions initialOptions,
    Function(FlagOptions) onOptionsChanged,
  ) {
    return [
      DialogConfig(
        builder: (context) => InstructionDialog(
          autoCloseDuration: options.autoCloseDuration,
        ),

        autoCloseDuration: options.autoCloseDuration,
        type: 'instruction',
      ),
      DialogConfig(
        builder: (context) => GameOptionsDialog(
          initialOptions: initialOptions,
          onOptionsChanged: onOptionsChanged,
        ),
        autoCloseDuration: 0, // Manual close
        type: 'options',
      ),
    ];
  }
  
  static List<DialogConfig> createRoundCompleteSequence({
    required ScoreEntry scoreEntry,
    required FlagOptions options,
    StageModel? stage,
    StackModel? stack,
    StageStackManager? stageStackManager,
    bool showWarning = false,
    String? warningMessage,
    String? warningTitle,
  }) {
    final List<DialogConfig> configs = [];
    
    // Always show score dialog
    configs.add(DialogConfig(
      builder: (context) => ScoreDialog(
        scoreEntry: scoreEntry,
        autoCloseDuration: options.autoCloseDuration,
      ),
      autoCloseDuration: options.autoCloseDuration,
      type: 'score',
    ));
    
    // Show bonus dialog if there are bonuses
    if (scoreEntry.bonusPoints > 0) {
      configs.add(DialogConfig(
        builder: (context) => ScoreDialog(
          scoreEntry: scoreEntry,
          autoCloseDuration: options.autoCloseDuration,
          showOnlyBonuses: true,
        ),
        autoCloseDuration: options.autoCloseDuration,
        type: 'bonus',
      ));
    }
    
    // Show warning if needed
    if (showWarning && options.showWarnings) {
      configs.add(DialogConfig(
        builder: (context) => WarningDialog(
          title: warningTitle ?? 'Obvious Mistake!',
          message: warningMessage ?? 'Obvious mistake detected!',
          autoCloseDuration: options.autoCloseDuration,
        ),
        autoCloseDuration: options.autoCloseDuration,
        type: 'warning',
      ));
    }
    
    // Show stage result if stage is complete
    if (stage != null && stage.isComplete && options.showStageDialog && stageStackManager != null) {
      configs.add(DialogConfig(
        builder: (context) => StageResultDialog(
          stage: stage,
          stageStackManager: stageStackManager,
          autoCloseDuration: options.autoCloseDuration,
        ),
        autoCloseDuration: options.autoCloseDuration,
        type: 'stageResult',
      ));
    }
    
    // Show stack result if stack is complete
    if (stack != null && stack.isComplete && options.showStageDialog && stageStackManager != null) {
      configs.add(DialogConfig(
        builder: (context) => StackResultDialog(
          stack: stack,
          stageStackManager: stageStackManager,
          autoCloseDuration: options.autoCloseDuration,
        ),
        autoCloseDuration: options.autoCloseDuration,
        type: 'stackResult',
      ));
    }
    
    return configs;
  }
  
  static List<DialogConfig> createGameCompleteSequence({
    required Map<String, dynamic> reports,
    required int totalScore,
    required int baseline,
    required FlagOptions options,
    // required VoidCallback onPlayAgain,
    required VoidCallback onExit,
  }) {
    // Changed order: Reports first, then FinalScoresDialog at the end
    return [
      DialogConfig(
        builder: (context) => Report1_StageStackSummary(
          reports: reports,
          onNext: () => Navigator.of(context).pop(),
        ),
        autoCloseDuration: 0,
        type: 'report1',
      ),
      DialogConfig(
        builder: (context) => Report2_4Stack_64Gua_Explanation(
          reports: reports,
          onNext: () => Navigator.of(context).pop(),
        ),
        autoCloseDuration: 0,
        type: 'report2',
      ),
      DialogConfig(
        builder: (context) => Report3a_RoundStatistics(
          reports: reports,
          onNext: () => Navigator.of(context).pop(),
        ),
        autoCloseDuration: 0,
        type: 'report3a',
      ),
      DialogConfig(
        builder: (context) => Report3_GuessAccuracy(
          reports: reports,
          onNext: () => Navigator.of(context).pop(),
        ),
        autoCloseDuration: 0,
        type: 'report3',
      ),
      DialogConfig(
        builder: (context) => Report4_MistakeSummary(
          reports: reports,
          onNext: () => Navigator.of(context).pop(),
        ),
        autoCloseDuration: 0,
        type: 'report4',
      ),
      DialogConfig(
        builder: (context) => Report5_RadarChart(
          reports: reports,
          onNext: () => Navigator.of(context).pop(),
        ),
        autoCloseDuration: 0,
        type: 'report5',
      ),
      DialogConfig(
        builder: (context) => FinalScoresDialog(
          totalScore: totalScore,
          baseline: baseline,
          autoCloseDuration: 0, // Manual close for final scores
          // onPlayAgain: onPlayAgain,
          onExit: onExit,
        ),
        autoCloseDuration: 0,
        type: 'finalScores',
      ),
    ];
  }
}