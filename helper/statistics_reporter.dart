import '../core/models/card_model.dart';
import '../core/models/stage_model.dart';
import '../core/models/user_guess.dart';
import '../core/models/score_entry.dart';
import '../core/data/64gua_data.dart';
import 'round_probability_data.dart';
import 'score_calculator.dart';
import 'shuffle_analyzer.dart';

/// Types of reports that can be generated
enum ReportType {
  roundSummary,          // Summary of each round
  stageSummary,          // Stage-by-stage analysis
  stackSummary,          // Stack hexagram analysis
  obviousMistakes,       // Obvious mistakes summary
  bonusSummary,          // Bonus score breakdown
  consecutiveWins,       // Consecutive wins analysis
  guaSummary,            // 8Gua and 64Gua summary
  hexagramExplanation,   // 64Gua explanations
  finalScores,           // Final scores and baseline
  shuffleLuck,           // Shuffle luck analysis
}

/// Data for a single round in reports
class RoundReportData {
  final int roundNumber;
  final String computerCard;
  final String userCard;
  final UserGuess? userGuess;
  final UserGuess? correctAnswer;
  final bool isCorrect;
  final String roundCategory;
  final bool isCounterIntuitive;
  final bool isObviousMistake;
  final int baseScore;
  final Map<String, int> bonuses;
  final int totalScore;
  final Map<String, String> probabilities;

  RoundReportData({
    required this.roundNumber,
    required this.computerCard,
    required this.userCard,
    required this.userGuess,
    required this.correctAnswer,
    required this.isCorrect,
    required this.roundCategory,
    required this.isCounterIntuitive,
    required this.isObviousMistake,
    required this.baseScore,
    required this.bonuses,
    required this.totalScore,
    required this.probabilities,
  });

  Map<String, dynamic> toJson() {
    return {
      'roundNumber': roundNumber,
      'computerCard': computerCard,
      'userCard': userCard,
      'userGuess': userGuess?.displayName,
      'correctAnswer': correctAnswer?.displayName,
      'isCorrect': isCorrect,
      'accuracy': isCorrect ? '✓' : '✗',
      'roundCategory': roundCategory,
      'isCounterIntuitive': isCounterIntuitive,
      'isObviousMistake': isObviousMistake,
      'baseScore': baseScore,
      'bonuses': bonuses,
      'totalScore': totalScore,
      'probabilities': probabilities,
    };
  }
}

/// Data for obvious mistake analysis
class ObviousMistakeData {
  final int roundNumber;
  final String mistakeType; // 'missedObviousWin', 'impossibleOption', 'forgetRevealedCards', 'consecutiveMissedHighProb'
  final String description;
  final UserGuess? userGuess;
  final UserGuess? correctAnswer;
  final String computerCard;
  final String userCard;
  final double? userGuessProbability;
  final double? correctAnswerProbability;

  ObviousMistakeData({
    required this.roundNumber,
    required this.mistakeType,
    required this.description,
    required this.userGuess,
    required this.correctAnswer,
    required this.computerCard,
    required this.userCard,
    this.userGuessProbability,
    this.correctAnswerProbability,
  });

  Map<String, dynamic> toJson() {
    return {
      'roundNumber': roundNumber,
      'mistakeType': mistakeType,
      'description': description,
      'userGuess': userGuess?.displayName,
      'correctAnswer': correctAnswer?.displayName,
      'computerCard': computerCard,
      'userCard': userCard,
      'userGuessProbability': userGuessProbability,
      'correctAnswerProbability': correctAnswerProbability,
    };
  }
}

/// Data for bonus analysis
class BonusReportData {
  final String bonusType;
  final String description;
  final int points;
  final List<int> rounds; // Rounds where this bonus was awarded
  final int count;

  BonusReportData({
    required this.bonusType,
    required this.description,
    required this.points,
    required this.rounds,
  }) : count = rounds.length;

  int get totalPoints => points * count;

  Map<String, dynamic> toJson() {
    return {
      'bonusType': bonusType,
      'description': description,
      'pointsPerRound': points,
      'rounds': rounds,
      'count': count,
      'totalPoints': totalPoints,
    };
  }
}

/// Main reporter for generating game statistics and reports
class StatisticsReporter {
  final List<RoundReportData> roundReports = [];
  final List<ObviousMistakeData> obviousMistakes = [];
  final List<BonusReportData> bonusReports = [];
  final List<StageModel> completedStages = [];
  final List<StackModel> completedStacks = [];
  final List<ShuffleAnalysis> shuffleAnalyses = [];

  int totalRounds = 0;
  int correctRounds = 0;
  int totalScore = 0;
  int baselineScore = 0;
  int totalShuffles = 0;
  int luckyShuffles = 0;
  int unfortunatelyShuffles = 0;
  int equivalentShuffles = 0;
  int warningDialogCount = 0;
  
  /// Add round data to reports
  void addRoundData({
    required int roundNumber,
    required CardModel computerCard,
    required CardModel userCard,
    required UserGuess? userGuess,
    required RoundProbabilityData probabilityData,
    required ScoreEntry scoreEntry,
  }) {
    totalRounds++;
    if (scoreEntry.isCorrect) correctRounds++;
    totalScore += scoreEntry.totalScore;
    
    // Create round report
    final roundReport = RoundReportData(
      roundNumber: roundNumber,
      computerCard: computerCard.displayNameWithSuit,
      userCard: userCard.displayNameWithSuit,
      userGuess: userGuess,
      correctAnswer: probabilityData.correctAnswer,
      isCorrect: scoreEntry.isCorrect,
      roundCategory: probabilityData.roundCategory,
      isCounterIntuitive: probabilityData.isCounterIntuitive,
      isObviousMistake: scoreEntry.isObviousMistake,
      baseScore: scoreEntry.baseScore,
      bonuses: scoreEntry.bonuses,
      totalScore: scoreEntry.totalScore,
      probabilities: probabilityData.formattedProbabilities,
    );
    
    roundReports.add(roundReport);
    
    // Check for obvious mistakes
    if (scoreEntry.isObviousMistake) {
      _addObviousMistake(
        roundNumber: roundNumber,
        probabilityData: probabilityData,
        userGuess: userGuess,
        computerCard: computerCard,
        userCard: userCard,
      );
    }
    
    // Update bonus reports
    _updateBonusReports(roundNumber, scoreEntry);
  }
  
  /// Add stage data
  void addStageData(StageModel stage) {
    if (stage.isComplete) {
      completedStages.add(stage);
    }
  }
  
  /// Add stack data
  void addStackData(StackModel stack) {
    if (stack.isComplete) {
      completedStacks.add(stack);
    }
  }

  /// Add shuffle analysis
  void addShuffleAnalysis(ShuffleAnalysis analysis) {
    shuffleAnalyses.add(analysis);
    totalShuffles++;

    switch (analysis.luck) {
      case ShuffleLuck.lucky:
        luckyShuffles++;
        break;
      case ShuffleLuck.unfortunately:
        unfortunatelyShuffles++;
        break;
      case ShuffleLuck.equivalent:
        equivalentShuffles++;
        break;
    }
  }

  /// Set baseline score for comparison
  void setBaselineScore(int baseline) {
    baselineScore = baseline;
  }
  
  /// Set warning dialog count
  void setWarningDialogCount(int count) {
    warningDialogCount = count;
  }
  
  /// Generate a specific report
  Map<String, dynamic> generateReport(ReportType reportType) {
    switch (reportType) {
      case ReportType.roundSummary:
        return _generateRoundSummary();
      case ReportType.stageSummary:
        return _generateStageSummary();
      case ReportType.stackSummary:
        return _generateStackSummary();
      case ReportType.obviousMistakes:
        return _generateObviousMistakesSummary();
      case ReportType.bonusSummary:
        return _generateBonusSummary();
      case ReportType.consecutiveWins:
        return _generateConsecutiveWinsSummary();
      case ReportType.guaSummary:
        return _generateGuaSummary();
      case ReportType.hexagramExplanation:
        return _generateHexagramExplanation();
      case ReportType.finalScores:
        return _generateFinalScores();
      case ReportType.shuffleLuck:
        return _generateShuffleLuckReport();
    }
  }
  
  /// Generate all reports (for end of game)
  Map<String, dynamic> generateAllReports() {
    return {
      'roundSummary': _generateRoundSummary(),
      'stageSummary': _generateStageSummary(),
      'stackSummary': _generateStackSummary(),
      'obviousMistakes': _generateObviousMistakesSummary(),
      'bonusSummary': _generateBonusSummary(),
      'consecutiveWins': _generateConsecutiveWinsSummary(),
      'guaSummary': _generateGuaSummary(),
      'hexagramExplanation': _generateHexagramExplanation(),
      'shuffleLuck': _generateShuffleLuckReport(),
      'finalScores': _generateFinalScores(),
      'metadata': _generateMetadata(),
      'warningDialogCount': warningDialogCount,
    };
  }
  
  /// Generate round summary report (4.6.6.1)
  Map<String, dynamic> _generateRoundSummary() {
    final accuracy = totalRounds > 0 ? (correctRounds / totalRounds * 100) : 0.0;
    
    // Categorize rounds
    final roundCategories = <String, int>{};
    final roundTypes = <String, int>{};
    
    for (final report in roundReports) {
      roundCategories[report.roundCategory] = 
          (roundCategories[report.roundCategory] ?? 0) + 1;
      
      final type = report.isCorrect ? 'Win' : 'Missed';
      roundTypes[type] = (roundTypes[type] ?? 0) + 1;
    }
    
    return {
      'title': 'Round Summary',
      'totalRounds': totalRounds,
      'correctRounds': correctRounds,
      'missedRounds': totalRounds - correctRounds,
      'accuracy': accuracy,
      'accuracyFormatted': '${accuracy.toStringAsFixed(1)}%',
      'roundCategories': roundCategories,
      'winMissedBreakdown': roundTypes,
      'roundDetails': roundReports.map((r) => r.toJson()).toList(),
    };
  }
  
  /// Generate stage summary report (4.6.6.1)
  Map<String, dynamic> _generateStageSummary() {
    final stageAccuracies = <String, double>{};
    final stageBinaries = <String, String>{};
    final stageDurations = <String, String>{};
    
    for (final stage in completedStages) {
      stageAccuracies[stage.stageId] = stage.accuracy;
      stageBinaries[stage.stageId] = stage.binaryResult ?? 'Incomplete';
      stageDurations[stage.stageId] = stage.formattedDuration;
    }
    
    return {
      'title': 'Stage Summary',
      'totalStagesCompleted': completedStages.length,
      'stageAccuracies': stageAccuracies,
      'stageBinaries': stageBinaries,
      'stageDurations': stageDurations,
      'averageStageAccuracy': completedStages.isNotEmpty 
          ? completedStages.map((s) => s.accuracy).reduce((a, b) => a + b) / completedStages.length
          : 0.0,
      'stageDetails': completedStages.map((s) => _stageToJson(s)).toList(),
    };
  }
  
  /// Generate stack summary report
  Map<String, dynamic> _generateStackSummary() {
    final stackAccuracies = <String, double>{};
    final stackBinaries = <String, String>{};
    final stackDurations = <String, String>{};
    
    for (final stack in completedStacks) {
      stackAccuracies['Stack ${stack.stackNumber}'] = stack.accuracy;
      stackBinaries['Stack ${stack.stackNumber}'] = stack.binaryResult ?? 'Incomplete';
      stackDurations['Stack ${stack.stackNumber}'] = stack.formattedDuration;
    }
    
    return {
      'title': 'Stack Summary',
      'totalStacksCompleted': completedStacks.length,
      'stackAccuracies': stackAccuracies,
      'stackBinaries': stackBinaries,
      'stackDurations': stackDurations,
      'stackDetails': completedStacks.map((s) => _stackToJson(s)).toList(),
    };
  }
  
  /// Generate obvious mistakes summary (4.6.6.2)
  Map<String, dynamic> _generateObviousMistakesSummary() {
    final mistakeCounts = <String, int>{};
    
    for (final mistake in obviousMistakes) {
      mistakeCounts[mistake.mistakeType] = 
          (mistakeCounts[mistake.mistakeType] ?? 0) + 1;
    }
    
    return {
      'title': 'Obvious Mistakes Summary',
      'totalMistakes': obviousMistakes.length,
      'mistakeCounts': mistakeCounts,
      'mistakeDetails': obviousMistakes.map((m) => m.toJson()).toList(),
      'summary': 'You made ${obviousMistakes.length} obvious mistake(s) during the game.',
    };
  }
  
  /// Generate bonus score summary (4.6.6.3)
  Map<String, dynamic> _generateBonusSummary() {
    // Group bonuses by type
    final bonusGroups = <String, BonusReportData>{};
    
    for (final bonus in bonusReports) {
      if (!bonusGroups.containsKey(bonus.bonusType)) {
        bonusGroups[bonus.bonusType] = bonus;
      } else {
        // Merge rounds
        final existing = bonusGroups[bonus.bonusType]!;
        final mergedRounds = [...existing.rounds, ...bonus.rounds];
        bonusGroups[bonus.bonusType] = BonusReportData(
          bonusType: existing.bonusType,
          description: existing.description,
          points: existing.points,
          rounds: mergedRounds,
        );
      }
    }
    
    final totalBonusPoints = bonusGroups.values
        .fold(0, (sum, bonus) => sum + bonus.totalPoints);
    
    return {
      'title': 'Bonus Score Summary',
      'totalBonusPoints': totalBonusPoints,
      'bonusCount': bonusReports.length,
      'bonusTypes': bonusGroups.values.map((b) => b.toJson()).toList(),
      'summary': 'You earned $totalBonusPoints bonus points from ${bonusGroups.length} different bonus types.',
    };
  }
  
  /// Generate consecutive wins summary (4.6.6.4)
  Map<String, dynamic> _generateConsecutiveWinsSummary() {
    // Calculate consecutive wins and losses from round history
    int currentWinStreak = 0;
    int longestWinStreak = 0;
    
    int currentLoseStreak = 0;
    int longestLoseStreak = 0;
    
    for (final report in roundReports) {
      if (report.isCorrect) {
        // Win: increment win streak, reset lose streak
        currentWinStreak++;
        if (currentWinStreak > longestWinStreak) {
          longestWinStreak = currentWinStreak;
        }
        currentLoseStreak = 0;
      } else {
        // Lose: increment lose streak, reset win streak
        currentLoseStreak++;
        if (currentLoseStreak > longestLoseStreak) {
          longestLoseStreak = currentLoseStreak;
        }
        currentWinStreak = 0;
      }
    }
    
    return {
      'title': 'Consecutive Performance Summary',
      'longestWinStreak': longestWinStreak,
      'longestLoseStreak': longestLoseStreak,
      'summary': 'Longest win streak: $longestWinStreak, Longest lose streak: $longestLoseStreak',
    };
  }

  /// Generate shuffle luck report (4a)
  Map<String, dynamic> _generateShuffleLuckReport() {
    return {
      'title': 'Shuffle Luck Analysis',
      'totalShuffles': totalShuffles,
      'luckyShuffles': luckyShuffles,
      'unfortunatelyShuffles': unfortunatelyShuffles,
      'equivalentShuffles': equivalentShuffles,
      'shuffleDetails': shuffleAnalyses.map((s) => s.toJson()).toList(),
      'summary': _generateShuffleLuckSummary(),
    };
  }

  /// Generate shuffle luck summary text
  String _generateShuffleLuckSummary() {
    if (totalShuffles == 0) {
      return 'No shuffles performed during the game.';
    }

    final buffer = StringBuffer();
    buffer.writeln('Total shuffles: $totalShuffles');
    buffer.writeln('Lucky shuffles: $luckyShuffles');
    buffer.writeln('Equivalent shuffles: $equivalentShuffles');
    buffer.writeln('Unfortunately shuffles: $unfortunatelyShuffles');

    if (luckyShuffles > unfortunatelyShuffles) {
      buffer.writeln('\nOverall: You had lucky shuffles!');
    } else if (unfortunatelyShuffles > luckyShuffles) {
      buffer.writeln('\nOverall: You had unfortunately shuffles.');
    } else {
      buffer.writeln('\nOverall: Your shuffles were balanced.');
    }

    return buffer.toString();
  }

  /// Generate 8Gua/64Gua summary (4.6.6.5)
  Map<String, dynamic> _generateGuaSummary() {
    final stageGua = <String, Map<String, dynamic>>{};
    final stackGua = <String, Map<String, dynamic>>{};
    
    for (final stage in completedStages) {
      stageGua[stage.stageId] = {
        'binary': stage.binaryResult,
        'symbol': stage.gua8Symbol,
        'name': stage.gua8Name,
        'pinyin': stage.gua8Pinyin,
        'accuracy': stage.accuracy,
      };
    }
    
    for (final stack in completedStacks) {
      stackGua['Stack ${stack.stackNumber}'] = {
        'binary': stack.binaryResult,
        'symbol': stack.gua64Symbol,
        'name': stack.gua64Name,
        'pinyin': stack.gua64Pinyin,
        'description': stack.stackDescription,
        'accuracy': stack.accuracy,
      };
    }
    
    return {
      'title': 'I-Ching Gua Summary',
      'stages': stageGua,
      'stacks': stackGua,
      'totalStages': completedStages.length,
      'totalStacks': completedStacks.length,
      'summary': 'Generated ${completedStages.length} trigrams and ${completedStacks.length} hexagrams.',
    };
  }
  
  /// Generate 64Gua explanations (4.6.6.6)
  Map<String, dynamic> _generateHexagramExplanation() {
    final explanations = <Map<String, dynamic>>[];
    
    for (final stack in completedStacks) {
      explanations.add({
        'stackNumber': stack.stackNumber,
        'binary': stack.binaryResult,
        'symbol': stack.gua64Symbol,
        'nameChinese': stack.gua64Name,
        'namePinyin': stack.gua64Pinyin,
        'description': stack.stackDescription,
        'stages': stack.stageIds,
        'accuracy': stack.accuracy,
        'interpretation': _generateHexagramInterpretation(stack),
      });
    }
    
    return {
      'title': 'Hexagram Explanations',
      'explanations': explanations,
      'totalHexagrams': completedStacks.length,
      'summary': 'Your game generated ${completedStacks.length} hexagram(s) with unique meanings.',
    };
  }
  
  /// Generate final scores report (4.6.6.7)
  Map<String, dynamic> _generateFinalScores() {
    final accuracy = totalRounds > 0 ? (correctRounds / totalRounds * 100) : 0.0;
    final scoreDifference = totalScore - baselineScore;
    final performancePercentage = baselineScore > 0 
        ? (totalScore / baselineScore * 100) 
        : 0.0;
    
    return {
      'title': 'Final Scores',
      'yourScore': totalScore,
      'baselineScore': baselineScore,
      'scoreDifference': scoreDifference,
      'performancePercentage': performancePercentage,
      'performanceFormatted': '${performancePercentage.toStringAsFixed(1)}%',
      'accuracy': accuracy,
      'accuracyFormatted': '${accuracy.toStringAsFixed(1)}%',
      'totalRounds': totalRounds,
      'correctRounds': correctRounds,
      'evaluation': _evaluatePerformance(scoreDifference, performancePercentage),
      'summary': _generateFinalSummary(scoreDifference, performancePercentage),
    };
  }
  
  /// Generate metadata about the game
  Map<String, dynamic> _generateMetadata() {
    return {
      'gameName': 'PouchApePoker2025',
      'reportGenerated': DateTime.now().toIso8601String(),
      'totalReports': ReportType.values.length,
      'roundsAnalyzed': totalRounds,
      'stagesAnalyzed': completedStages.length,
      'stacksAnalyzed': completedStacks.length,
    };
  }
  
  /// Add obvious mistake to tracking
  void _addObviousMistake({
    required int roundNumber,
    required RoundProbabilityData probabilityData,
    required UserGuess? userGuess,
    required CardModel computerCard,
    required CardModel userCard,
  }) {
    if (userGuess == null) return;

    final mistakeType = probabilityData.getObviousMistakeType(userGuess);
    if (mistakeType == null) return;

    String description = '';
    final computerCardStr = computerCard.displayNameWithSuit;
    final correctAnswer = probabilityData.correctAnswer;
    final userGuessStr = userGuess.displayName.toLowerCase();

    switch (mistakeType) {
      case ObviousMistakeType.missedObviousWin:
        // Generate a clearer message based on the correct answer
        if (correctAnswer == UserGuess.higher) {
          description = 'Missed win option. $computerCardStr is not higher than any card.';
        } else if (correctAnswer == UserGuess.lower) {
          description = 'Missed win option. $computerCardStr is not lower than any card.';
        } else if (correctAnswer == UserGuess.tie) {
          description = 'Missed win option. $computerCardStr is not tie any card.';
        } else {
          description = 'Missed win option. $computerCardStr has 100% probability.';
        }
        break;
      case ObviousMistakeType.impossibleOption:
        description = 'There is no card $userGuessStr than $computerCardStr.';
        break;
      case ObviousMistakeType.forgetRevealedCards:
        description = 'There is no left card $userGuessStr than $computerCardStr. The cards had been revealed in previous rounds.';
        break;
    }

    obviousMistakes.add(ObviousMistakeData(
      roundNumber: roundNumber,
      mistakeType: mistakeType.name,
      description: description,
      userGuess: userGuess,
      correctAnswer: probabilityData.correctAnswer,
      computerCard: computerCardStr,
      userCard: userCard.displayNameWithSuit,
      userGuessProbability: probabilityData.getProbabilityForGuess(userGuess),
      correctAnswerProbability: probabilityData.correctAnswerProbability,
    ));
  }
  
  /// Update bonus reports
  void _updateBonusReports(int roundNumber, ScoreEntry scoreEntry) {
    for (final bonus in scoreEntry.bonuses.entries) {
      bonusReports.add(BonusReportData(
        bonusType: bonus.key,
        description: _getBonusDescription(bonus.key),
        points: bonus.value,
        rounds: [roundNumber],
      ));
    }
  }
  
  /// Helper: Convert stage to JSON
  Map<String, dynamic> _stageToJson(StageModel stage) {
    return {
      'stageId': stage.stageId,
      'rounds': stage.roundNumbers,
      'results': stage.roundResults.map((r) => r?.displayName).toList(),
      'binary': stage.binaryResult,
      'symbol': stage.gua8Symbol,
      'name': stage.gua8Name,
      'pinyin': stage.gua8Pinyin,
      'winCount': stage.winCount,
      'missedCount': stage.missedCount,
      'accuracy': stage.accuracy,
      'duration': stage.formattedDuration,
    };
  }
  
  /// Helper: Convert stack to JSON
  Map<String, dynamic> _stackToJson(StackModel stack) {
    // Get full 64gua data if binary result is available
    Map<String, dynamic> gua64Data = {};
    if (stack.binaryResult != null) {
      final gua64Details = Gua64Data.get64Gua(stack.binaryResult!);
      if (gua64Details != null) {
        gua64Data = {
          'name_pinyin_std': gua64Details.name_pinyin_std,
          'name_en_meaning': gua64Details.name_en_meaning,
          'stack_en': gua64Details.stack_en,
          'explanation_zh': gua64Details.explanation_zh,
          'explanation_en': gua64Details.explanation_en,
          'luck_zh': gua64Details.luck_zh,
          'luck_en': gua64Details.luck_en,
          'sign_zh': gua64Details.sign_zh,
          'sign_en': gua64Details.sign_en,
        };
      }
    }
    
    return {
      'stackNumber': stack.stackNumber,
      'stages': stack.stageIds,
      'binary': stack.binaryResult,
      'symbol': stack.gua64Symbol,
      'name': stack.gua64Name,
      'pinyin': stack.gua64Pinyin,
      'description': stack.stackDescription,
      'winCount': stack.winCount,
      'missedCount': stack.missedCount,
      'accuracy': stack.accuracy,
      'duration': stack.formattedDuration,
      ...gua64Data,
    };
  }
  
  /// Helper: Generate hexagram interpretation
  String _generateHexagramInterpretation(StackModel stack) {
    if (stack.binaryResult == null) return 'No hexagram generated';
    
    final accuracy = stack.accuracy;
    final winCount = stack.winCount;
    
    if (accuracy >= 80) {
      return 'Excellent performance! This hexagram suggests strong intuition and good decision-making.';
    } else if (accuracy >= 60) {
      return 'Good performance. The hexagram indicates balanced judgment with room for improvement.';
    } else if (accuracy >= 40) {
      return 'Average performance. The hexagram suggests some intuitive hits mixed with misses.';
    } else {
      return 'Challenging round. The hexagram indicates counter-intuitive choices were prevalent.';
    }
  }
  
  /// Helper: Get bonus description
  String _getBonusDescription(String bonusType) {
    switch (bonusType) {
      case 'counterIntuitive':
        return 'Counter-Intuitive High-Probability Round';
      case 'lowProb':
        return 'Low Probability Win-Option Round';
      case 'superLowProb':
        return 'Super Low Probability Win-Option Round';
      case 'middleProb':
        return 'Middle Probability Choice';
      case 'minProb':
        return 'Minimum Probability Choice';
      case 'consecutive3':
        return '3 Consecutive Wins';
      case 'consecutive5':
        return '5 Consecutive Wins';
      case 'consecutiveMore':
        return 'Extended Win Streak';
      default:
        return bonusType;
    }
  }
  
  /// Helper: Evaluate performance
  String _evaluatePerformance(int difference, double percentage) {
    if (percentage >= 150) return 'Exceptional! Far beyond baseline.';
    if (percentage >= 120) return 'Excellent! Well above baseline.';
    if (percentage >= 100) return 'Good! Met or exceeded baseline.';
    if (percentage >= 80) return 'Fair. Close to baseline performance.';
    if (percentage >= 60) return 'Below baseline. Room for improvement.';
    return 'Well below baseline. Practice needed.';
  }
  
  /// Helper: Generate final summary
  String _generateFinalSummary(int difference, double percentage) {
    final accuracy = totalRounds > 0 ? (correctRounds / totalRounds * 100) : 0.0;
    
    final buffer = StringBuffer();
    buffer.writeln('Game Complete!');
    buffer.writeln('• Final Score: ${totalScore.formatted}');
    buffer.writeln('• Baseline Score: ${baselineScore.formatted}');
    buffer.writeln('• Performance: ${percentage.toStringAsFixed(1)}% of baseline');
    
    if (difference > 0) {
      buffer.writeln('• You scored ${difference.formatted} points above baseline!');
    } else if (difference < 0) {
      buffer.writeln('• You scored ${(-difference).formatted} points below baseline.');
    } else {
      buffer.writeln('• You matched the baseline score exactly!');
    }
    
    buffer.writeln('• Accuracy: ${accuracy.toStringAsFixed(1)}% ($correctRounds/$totalRounds)');
    buffer.writeln('• Obvious Mistakes: ${obviousMistakes.length}');
    buffer.writeln('• Bonuses Earned: ${bonusReports.length} different types');
    
    return buffer.toString();
  }

  /// Get game history for hint dialog
  List<Map<String, dynamic>> getGameHistory() {
    return roundReports.map((report) {
      return {
        'roundNumber': report.roundNumber,
        'computerCard': report.computerCard,
        'userCard': report.userCard,
        'result': report.isCorrect ? 'win' : 'missed',
      };
    }).toList();
  }
  
  /// Reset reporter for new game
  void reset() {
    roundReports.clear();
    obviousMistakes.clear();
    bonusReports.clear();
    completedStages.clear();
    completedStacks.clear();
    shuffleAnalyses.clear();

    totalRounds = 0;
    correctRounds = 0;
    totalScore = 0;
    baselineScore = 0;
    totalShuffles = 0;
    luckyShuffles = 0;
    unfortunatelyShuffles = 0;
    equivalentShuffles = 0;
    warningDialogCount = 0;
  }
}

/// Extension for formatting numbers in reports
extension ReportFormatting on double {
  /// Format as percentage
  String get asPercentage => '${toStringAsFixed(1)}%';
  
  /// Format with 2 decimal places
  String get asDecimal => toStringAsFixed(2);
}

/// Extension for score and number formatting
extension ScoreReportFormatting on int {
  /// Format with plus if positive
  String get asScore {
    if (this > 0) return '+${formatted}';
    return formatted;
  }
  
  /// Format with commas for thousands
  String get formatted {
    final numberStr = toString();
    if (numberStr.length <= 3) return numberStr;
    
    final buffer = StringBuffer();
    final length = numberStr.length;
    
    for (int i = 0; i < length; i++) {
      if (i > 0 && (length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(numberStr[i]);
    }
    
    return buffer.toString();
  }
  
  /// Format as percentage (for integers representing percentages)
  String get asPercentage => '$this%';
}
