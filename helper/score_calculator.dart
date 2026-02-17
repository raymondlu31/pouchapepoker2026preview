
import 'round_probability_data.dart';
import '../core/models/user_guess.dart';
import '../core/models/score_entry.dart'; // Import from score_entry.dart
import 'ui_debug_logger.dart';

/// Represents a single score entry with breakdown
// REMOVE the duplicate ScoreEntry class from here
// class ScoreEntry { ... } // DELETE THIS


/// Manages consecutive win tracking
class ConsecutiveWinTracker {
  int _currentStreak = 0;
  int _longestStreak = 0;
  
  /// Update streak based on round result
  void update(bool wonRound) {
    if (wonRound) {
      _currentStreak++;
      if (_currentStreak > _longestStreak) {
        _longestStreak = _currentStreak;
      }
    } else {
      _currentStreak = 0;
    }
  }
  
  /// Get current streak length
  int get currentStreak => _currentStreak;
  
  /// Get longest streak in this game
  int get longestStreak => _longestStreak;
  
  /// Check if we should award consecutive win bonus
  Map<String, int> checkConsecutiveBonuses() {
    final bonuses = <String, int>{};
    
    if (_currentStreak >= 3 && _currentStreak % 3 == 0) {
      // Award for every 3 consecutive wins
      if (_currentStreak == 3) {
        bonuses['consecutive3'] = 30;
      } else if (_currentStreak == 5) {
        bonuses['consecutive5'] = 50;
      } else if (_currentStreak > 5 && _currentStreak % 5 == 0) {
        bonuses['consecutiveMore'] = 80;
      }
    }
    
    return bonuses;
  }
  
  /// Reset for new game
  void reset() {
    _currentStreak = 0;
    _longestStreak = 0;
  }
}

/// Manages consecutive missed high probability tracking
class ConsecutiveMissedHighProbTracker {
  int _currentCount = 0;
  final List<bool> _last3Rounds = [false, false, false];
  
  /// Update tracking based on round result
  /// Conditions:
  /// 1. Round win: reset
  /// 2. Round missed, but win option is 2nd or 3rd probability: reset
  /// 3. Consecutive 3 rounds missed, and win options in all 3 rounds are highest probability: show warning
  void update({
    required bool isCorrect,
    required RoundProbabilityData? probabilityData,
    required UserGuess? userGuess,
  }) {
    // Shift the tracking array
    for (int i = 2; i > 0; i--) {
      _last3Rounds[i] = _last3Rounds[i - 1];
    }
    
    // Check if this round was a missed high probability opportunity
    final wasHighProbMissed = _checkIfHighProbMissedThisRound(
      isCorrect: isCorrect,
      probabilityData: probabilityData,
      userGuess: userGuess,
    );
    
    _last3Rounds[0] = wasHighProbMissed;

    // DEBUG: Log the tracking state
    UIDebugLogger.logDialog('ConsecutiveMissedHighProbTracker.update', 
      'isCorrect=$isCorrect, wasHighProbMissed=$wasHighProbMissed, '
      '_last3Rounds=$_last3Rounds, _currentCount before=$_currentCount');
    
    // Apply conditions
    if (isCorrect) {
      // Condition 1: Round win - reset
      UIDebugLogger.logDialog('ConsecutiveMissedHighProbTracker.update', 
        'Condition 1: Round win - resetting counter');
      // Condition 1: Round win - reset
      _currentCount = 0;
    } else if (!wasHighProbMissed) {
      // Condition 2: Round missed, but win option is 2nd or 3rd probability - reset
      UIDebugLogger.logDialog('ConsecutiveMissedHighProbTracker.update', 
        'Condition 2: Missed but not high prob - resetting counter');
      // Condition 2: Round missed, but win option is 2nd or 3rd probability - reset
      _currentCount = 0;
    } else if (wasHighProbMissed) {
      // High probability was missed
      UIDebugLogger.logDialog('ConsecutiveMissedHighProbTracker.update', 
        'Condition 3: High probability missed - incrementing counter');
      // High probability was missed
      _currentCount++;
    }
    // DEBUG: Log final state
    UIDebugLogger.logDialog('ConsecutiveMissedHighProbTracker.update', 
      '_currentCount after=$_currentCount, shouldShowWarning=${shouldShowWarning()}');
  }
  
  /// Check if high probability was missed this round
  bool _checkIfHighProbMissedThisRound({
    required bool isCorrect,
    required RoundProbabilityData? probabilityData,
    required UserGuess? userGuess,
  }) {
    if (probabilityData == null || userGuess == null) {
      UIDebugLogger.logDialog('ConsecutiveMissedHighProbTracker._checkIfHighProbMissedThisRound', 
        'ERROR: probabilityData or userGuess is null');
      return false;
    }
    
    // Check if correct answer had high probability (>= 50%)
    final correctProb = probabilityData.correctAnswerProbability;
    UIDebugLogger.logDialog('ConsecutiveMissedHighProbTracker._checkIfHighProbMissedThisRound', 
      'correctProb=$correctProb, threshold=0.5, correctProb >= 0.5 = ${correctProb >= 0.5}');

    if (correctProb < 0.5) {

      UIDebugLogger.logDialog('ConsecutiveMissedHighProbTracker._checkIfHighProbMissedThisRound', 
        'Correct probability < 0.5, not a high prob round');


      return false;

    } 
    
    // Check if user didn't select the correct answer
    final isCorrectGuess = probabilityData.isGuessCorrect(userGuess);

    UIDebugLogger.logDialog('ConsecutiveMissedHighProbTracker._checkIfHighProbMissedThisRound', 
      'isCorrectGuess=$isCorrectGuess, returning ${!isCorrectGuess}');


    return !isCorrectGuess;
  }
  
  /// Check for 3 consecutive missed high probability rounds
  bool shouldShowWarning() {
    // Check if we have 3 consecutive missed high probability rounds
    return _currentCount >= 3 && _last3Rounds.every((missed) => missed);
  }
  
  /// Get warning message
  String getWarningMessage() {
    if (shouldShowWarning()) {
      return 'You have missed high-probability answers for 3 or more times, please check hint, if you need.';
    }
    return '';
  }

  /// Get current count
  int get currentCount => _currentCount;
  
  /// Reset for new game
  void reset() {
    _currentCount = 0;
    _last3Rounds.fillRange(0, 3, false);
  }
}


/*
/// Manages consecutive loss tracking
class ConsecutiveLossTracker {
  int _currentLossStreak2 = 0;
  int _longestLossStreak2 = 0;
  
  /// Update streak based on round result, not won
  void update(bool wonRound) {
    if (!wonRound) {
      _currentLossStreak2++;
      if (_currentLossStreak2 > _longestLossStreak2) {
        _longestLossStreak2 = _currentLossStreak2;
      }
    } else {
      _currentLossStreak2 = 0;
    }
  }
  
  /// Get current streak length
  int get currentLossStreak2 => _currentLossStreak2;
  
  /// Get longest streak in this game
  int get longestLossStreak2 => _longestLossStreak2;
  
  /// Check if we should award consecutive win bonus
  Map<String, int> checkConsecutiveBonuses() {
    final consecutiveLossWarnings = <String, int>{};
    
    if (_currentLossStreak2 >= 3 && _currentLossStreak2 % 3 == 0) {
      // Award for every 3 consecutive wins
      if (_currentLossStreak2 == 3) {
        // alert for 3 consecutive missed
        // bonuses['consecutive23'] = 30;
      
      }
    }
    
    return consecutiveLossWarnings;
  }
  
  /// Reset for new game
  void resetConsecutiveLossTracker() {
    _currentLossStreak2 = 0;
    _longestLossStreak2 = 0;
  }
}
*/

/// Main calculator for game scoring
class ScoreCalculator {
  final ConsecutiveWinTracker winTracker = ConsecutiveWinTracker();
  final ConsecutiveMissedHighProbTracker missedHighProbTracker = ConsecutiveMissedHighProbTracker();
  final List<ScoreEntry> scoreHistory = []; // Now using the imported ScoreEntry
  
  // Warning dialog counter
  int _warningDialogShownCount = 0;
  int get warningDialogShownCount => _warningDialogShownCount;
  
  // Bonus amounts as specified
  static const int counterIntuitiveBonus = 10;
  static const int lowProbBonus = 200;
  static const int superLowProbBonus = 900;
  static const int middleProbBonus = 10;
  static const int minProbBonus = 20;
  
  // Base scores by probability category
  static const Map<String, int> baseScores = {
    'High': 100,        // >= 50%
    'Low': 300,         // < 50% and >= 10%
    'SuperLow': 1000,   // < 10%
    'ObviousWin': 100,  // = 100% (treated as High for base)
  };

  /// Calculate score for a round
  ScoreEntry calculateRoundScore({
    required int roundNumber,
    required RoundProbabilityData probabilityData,
    required UserGuess userGuess,
  }) {
    // Determine if guess is correct
    final isCorrect = probabilityData.isGuessCorrect(userGuess);
    final isObviousMistake = probabilityData.isObviousMistake(userGuess);

    // DEBUG: Log before updating missedHighProbTracker
    UIDebugLogger.logDialog('ScoreCalculator.calculateRoundScore', 
      'Round $roundNumber: isCorrect=$isCorrect, isObviousMistake=$isObviousMistake, '
      'userGuess=${userGuess.displayName}, correctAnswer=${probabilityData.correctAnswer?.displayName}, '
      'correctProb=${probabilityData.correctAnswerProbability}');
    
    // Update win tracker (only if user selected an answer, not timer expiration)
    winTracker.update(isCorrect && !isObviousMistake);

    // DEBUG: Update missed high probability tracker with more info
    UIDebugLogger.logDialog('ScoreCalculator.updateMissedHighProbTracker', 
      'Before update: count=${missedHighProbTracker.currentCount}');

    missedHighProbTracker.update(
      isCorrect: isCorrect,
      probabilityData: probabilityData,
      userGuess: userGuess,
    );

    // DEBUG: Log after update
    UIDebugLogger.logDialog('ScoreCalculator.updateMissedHighProbTracker', 
      'After update: count=${missedHighProbTracker.currentCount}, '
      'shouldShowWarning=${missedHighProbTracker.shouldShowWarning()}');
    
    // Calculate base score (0 if wrong or obvious mistake)
    int baseScore = 0;
    if (isCorrect && !isObviousMistake) {
      baseScore = _calculateBaseScore(probabilityData);
    }
    
    // Calculate bonuses
    final bonuses = _calculateBonuses(
      probabilityData: probabilityData,
      userGuess: userGuess,
      isCorrect: isCorrect,
      isObviousMistake: isObviousMistake,
    );
    
    // Add consecutive win bonuses
    if (isCorrect && !isObviousMistake) {
      final consecutiveBonuses = winTracker.checkConsecutiveBonuses();
      bonuses.addAll(consecutiveBonuses);
    }
    
    // Calculate total score
    final totalScore = baseScore + _sumBonuses(bonuses);
    
    // Create score entry USING THE IMPORTED ScoreEntry
    final entry = ScoreEntry(
      roundNumber: roundNumber,
      baseScore: baseScore,
      bonuses: bonuses,
      totalScore: totalScore,
      scoreCategory: probabilityData.scoreCategory,
      roundCategory: probabilityData.roundCategory,
      isCounterIntuitive: probabilityData.isCounterIntuitive,
      isObviousMistake: isObviousMistake,
      userGuess: userGuess,
      correctAnswer: probabilityData.correctAnswer,
      isCorrect: isCorrect,
      userGuessProbability: probabilityData.getProbabilityForGuess(userGuess),
      correctAnswerProbability: probabilityData.correctAnswerProbability,
      computerCard: probabilityData.computerCard,
      userCard: probabilityData.userCard,
      computerCardStr: probabilityData.computerCard?.displayNameWithSuit,
      userCardStr: probabilityData.userCard?.displayNameWithSuit,
    );
    
    // Add to history
    scoreHistory.add(entry);
    
    return entry;
  }

  /// Calculate base score based on probability category
  int _calculateBaseScore(RoundProbabilityData probabilityData) {
    final category = probabilityData.scoreCategory;
    return baseScores[category] ?? 0;
  }

  /// Calculate all applicable bonuses
  Map<String, int> _calculateBonuses({
    required RoundProbabilityData probabilityData,
    required UserGuess userGuess,
    required bool isCorrect,
    required bool isObviousMistake,
  }) {
    final bonuses = <String, int>{};
    
    // Only award bonuses for correct guesses without obvious mistakes
    if (!isCorrect || isObviousMistake) {
      return bonuses;
    }
    
    // 1. Counter-Intuitive High-Probability Round bonus
    if (probabilityData.isCounterIntuitive) {
      bonuses['counterIntuitive'] = counterIntuitiveBonus;
    }
    
    // 2. Low Probability Win-Option Round bonus
    if (probabilityData.winOptionType == 'Low') {
      bonuses['lowProb'] = lowProbBonus;
    }
    
    // 3. Super Low Probability Win-Option Round bonus
    if (probabilityData.winOptionType == 'SuperLow') {
      bonuses['superLowProb'] = superLowProbBonus;
    }
    
    // 4. Middle Probability Win-Option bonus
    // (User selected the option with middle probability)
    if (userGuess == probabilityData.guessWithMiddleProbability) {
      bonuses['middleProb'] = middleProbBonus;
    }
    
    // 5. Minimum Probability Win-Option bonus
    // (User selected the option with minimum probability)
    if (userGuess == probabilityData.guessWithMinProbability) {
      bonuses['minProb'] = minProbBonus;
    }
    
    return bonuses;
  }

  /// Sum all bonus values
  int _sumBonuses(Map<String, int> bonuses) {
    return bonuses.values.fold(0, (sum, points) => sum + points);
  }

  /// Get total score so far
  int get totalScore {
    return scoreHistory.fold(0, (sum, entry) => sum + entry.totalScore);
  }

  /// Get total base score (without bonuses)
  int get totalBaseScore {
    return scoreHistory.fold(0, (sum, entry) => sum + entry.baseScore);
  }

  /// Get total bonus score
  int get totalBonusScore {
    return scoreHistory.fold(0, (sum, entry) => sum + entry.bonusPoints);
  }

  /// Get game statistics
  Map<String, dynamic> get statistics {
    if (scoreHistory.isEmpty) return {};
    
    int totalRounds = scoreHistory.length;
    int correctRounds = scoreHistory.where((e) => e.isCorrect).length;
    int obviousMistakes = scoreHistory.where((e) => e.isObviousMistake).length;
    int counterIntuitiveRounds = scoreHistory.where((e) => e.isCounterIntuitive).length;
    
    // Count rounds by score category
    final categoryCounts = <String, int>{};
    final bonusCounts = <String, int>{};
    
    for (final entry in scoreHistory) {
      // Score categories
      categoryCounts[entry.scoreCategory] = 
          (categoryCounts[entry.scoreCategory] ?? 0) + 1;
      
      // Bonuses
      for (final bonus in entry.bonuses.keys) {
        bonusCounts[bonus] = (bonusCounts[bonus] ?? 0) + 1;
      }
    }
    
    return {
      'totalRounds': totalRounds,
      'correctRounds': correctRounds,
      'accuracy': (correctRounds / totalRounds) * 100,
      'obviousMistakes': obviousMistakes,
      'counterIntuitiveRounds': counterIntuitiveRounds,
      'totalScore': totalScore,
      'totalBaseScore': totalBaseScore,
      'totalBonusScore': totalBonusScore,
      'currentWinStreak': winTracker.currentStreak,
      'longestWinStreak': winTracker.longestStreak,
      'scoreByCategory': categoryCounts,
      'bonusDistribution': bonusCounts,
      'averageScorePerRound': totalScore / totalRounds,
      'averageBonusPerRound': totalBonusScore / totalRounds,
    };
  }

  /// Get score breakdown for reporting
  Map<String, dynamic> getScoreBreakdown() {
    final List<Map<String, dynamic>> roundBreakdown = [];
    
    for (final entry in scoreHistory) {
      roundBreakdown.add({
        'round': entry.roundNumber,
        'guess': entry.userGuess?.displayName,
        'correct': entry.correctAnswer?.displayName,
        'result': entry.isCorrect ? 'Win' : 'Missed',
        'baseScore': entry.baseScore,
        'bonuses': entry.bonuses,
        'totalScore': entry.totalScore,
        'category': entry.scoreCategory,
        'isCounterIntuitive': entry.isCounterIntuitive,
        'isObviousMistake': entry.isObviousMistake,
      });
    }
    
    return {
      'roundBreakdown': roundBreakdown,
      'summary': statistics,
      'consecutiveWins': {
        'current': winTracker.currentStreak,
        'longest': winTracker.longestStreak,
      },
    };
  }

  /// Calculate reference baseline score
  /// Baseline Score = (number of rounds where the highest probability option is the correct answer) * 100
  int calculateBaselineScore(List<RoundProbabilityData> allRoundProbabilities) {
    UIDebugLogger.logDialog('ScoreCalculator.calculateBaselineScore', 
      'Starting baseline calculation with ${allRoundProbabilities.length} rounds');
    
    int baseline = 0;
    int qualifyingRounds = 0;
    
    for (final probData in allRoundProbabilities) {
      UIDebugLogger.logDialog('ScoreCalculator.calculateBaselineScore', 
        'Round ${probData.roundNumber}: maxProb=${probData.maxProbability}, correctProb=${probData.correctAnswerProbability}, isMatch=${probData.correctAnswerProbability == probData.maxProbability}');
      
      // Check if the highest probability option is the correct answer
      // The highest probability is maxProbability
      // The correct answer probability is correctAnswerProbability
      if (probData.correctAnswerProbability == probData.maxProbability) {
        // Count this round: add base score of 100
        baseline += 100;
        qualifyingRounds++;
        
        UIDebugLogger.logDialog('ScoreCalculator.calculateBaselineScore', 
          'Round ${probData.roundNumber} qualifies! Adding 100. Current baseline: $baseline');
        
        // Add counter-intuitive bonus if applicable
        if (probData.isCounterIntuitive) {
          baseline += counterIntuitiveBonus;
          UIDebugLogger.logDialog('ScoreCalculator.calculateBaselineScore', 
            'Round ${probData.roundNumber} is counter-intuitive! Adding $counterIntuitiveBonus bonus. Current baseline: $baseline');
        }
      }
    }
    
    UIDebugLogger.logDialog('ScoreCalculator.calculateBaselineScore', 
      'Baseline calculation complete: $qualifyingRounds qualifying rounds out of ${allRoundProbabilities.length}, final baseline: $baseline');
    
    return baseline;
  }

  /// Reset calculator for new game
  void reset() {
    scoreHistory.clear();
    winTracker.reset();
    missedHighProbTracker.reset();
    _warningDialogShownCount = 0;
  }

  /// Get score summary for current round
  Map<String, dynamic> getRoundSummary(int roundNumber) {
    final entry = scoreHistory.firstWhere(
      (e) => e.roundNumber == roundNumber,
      orElse: () => ScoreEntry(
        roundNumber: 0,
        baseScore: 0,
        bonuses: {},
        totalScore: 0,
        scoreCategory: '',
        roundCategory: '',
        isCounterIntuitive: false,
        isObviousMistake: false,
        userGuess: null,
        correctAnswer: null,
        isCorrect: false,
        userGuessProbability: 0.0,
        correctAnswerProbability: 0.0,
      ),
    );
    
    return {
      'round': entry.roundNumber,
      'total': entry.totalScore,
      'base': entry.baseScore,
      'bonuses': entry.bonuses,
      'category': entry.scoreCategory,
      'isCounterIntuitive': entry.isCounterIntuitive,
      'isObviousMistake': entry.isObviousMistake,
      'correct': entry.isCorrect,
      'userGuess': entry.userGuess?.displayName,
      'correctAnswer': entry.correctAnswer?.displayName,
    };
  }

  /// Check if we should show a warning for consecutive missed high probability
  bool shouldShowMissedHighProbWarning() {
    return missedHighProbTracker.shouldShowWarning();
  }
  
  /// Increment warning dialog counter (called when warning dialog is shown)
  void incrementWarningDialogCount() {
    _warningDialogShownCount++;
  }
  
  /// Get warning message for consecutive missed high probability
  String getMissedHighProbWarningMessage() {
    return missedHighProbTracker.getWarningMessage();
  }

  /// Get warning message for obvious mistakes
  String getObviousMistakeWarningMessage(RoundProbabilityData probabilityData, UserGuess userGuess) {
    final mistakeType = probabilityData.getObviousMistakeType(userGuess);
    if (mistakeType == null) return '';

    final computerCardStr = probabilityData.computerCard?.displayNameWithSuit ?? '';
    final userCardStr = probabilityData.userCard?.displayNameWithSuit ?? '';
    final correctAnswer = probabilityData.correctAnswer;
    final correctAnswerStr = correctAnswer?.displayName.toLowerCase() ?? '';
    final userGuessStr = userGuess.displayName.toLowerCase();
    final probability = probabilityData.getProbabilityForGuess(userGuess);

    return '''Computer card: $computerCardStr
Your card: $userCardStr
Correct answer: $correctAnswerStr
In the remaining card deck, the probability of $userGuessStr is $probability.''';
  }

}



