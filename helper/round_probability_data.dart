// lib/helper/round_probability_data.dart


import '../core/models/card_model.dart';
import '../core/models/user_guess.dart';

/// Types of obvious mistakes
enum ObviousMistakeType {
  missedObviousWin,      // Type 1: Missed 100% probability option
  impossibleOption,      // Type 2: Structural impossibility
  forgetRevealedCards,   // Type 3: Contextual impossibility
}

/// Data class representing the probability analysis for a single round
class RoundProbabilityData {
  final int roundNumber;
  final double higherProbability;  // 0.0 to 1.0
  final double tieProbability;     // 0.0 to 1.0
  final double lowerProbability;   // 0.0 to 1.0
  final String roundType;          // "ObviousWin", "ObviousFail", "Common"
  final String winOptionType;      // "High", "Low", "SuperLow", "ObviousWin", "ObviousFail"
  final String roundCategory;      // Human-readable category
  final bool isCounterIntuitive;
  final double maxProbability;
  final double minProbability;
  final double middleProbability;
  
  // New fields for correct answer and cards
  final UserGuess? correctAnswer;           // The correct guess for this round
  final double correctAnswerProbability;    // Probability of the correct answer
  final CardModel? computerCard;            // Computer's revealed card
  final CardModel? userCard;                // User's face-down card

  RoundProbabilityData({
    required this.roundNumber,
    required this.higherProbability,
    required this.tieProbability,
    required this.lowerProbability,
    required this.roundType,
    required this.winOptionType,
    required this.roundCategory,
    required this.isCounterIntuitive,
    required this.maxProbability,
    required this.minProbability,
    required this.middleProbability,
    this.correctAnswer,
    required this.correctAnswerProbability,
    this.computerCard,
    this.userCard,
  });

  /// Factory constructor for creating from basic probability data
  factory RoundProbabilityData.create({
    required int roundNumber,
    required double higherProbability,
    required double tieProbability,
    required double lowerProbability,
    required String roundType,
    required String winOptionType,
    required bool isCounterIntuitive,
    required CardModel computerCard,
    required CardModel userCard,
  }) {
    // Calculate additional probability metrics
    final probabilities = [higherProbability, tieProbability, lowerProbability];
    probabilities.sort((a, b) => b.compareTo(a)); // Descending
    
    final maxProbability = probabilities[0];
    final minProbability = probabilities[2];
    final middleProbability = probabilities[1];
    
    // Determine correct answer based on cards
    final correctAnswer = _determineCorrectAnswer(computerCard, userCard);
    final correctAnswerProbability = _getCorrectAnswerProbability(
      correctAnswer: correctAnswer,
      higherProbability: higherProbability,
      tieProbability: tieProbability,
      lowerProbability: lowerProbability,
    );
    
    // Determine human-readable category
    final roundCategory = _determineRoundCategory(
      roundType: roundType,
      winOptionType: winOptionType,
      maxProbability: maxProbability,
    );
    
    return RoundProbabilityData(
      roundNumber: roundNumber,
      higherProbability: higherProbability,
      tieProbability: tieProbability,
      lowerProbability: lowerProbability,
      roundType: roundType,
      winOptionType: winOptionType,
      roundCategory: roundCategory,
      isCounterIntuitive: isCounterIntuitive,
      maxProbability: maxProbability,
      minProbability: minProbability,
      middleProbability: middleProbability,
      correctAnswer: correctAnswer,
      correctAnswerProbability: correctAnswerProbability,
      computerCard: computerCard,
      userCard: userCard,
    );
  }

  /// Get the probability for a specific user guess
  double getProbabilityForGuess(UserGuess guess) {
    switch (guess) {
      case UserGuess.higher:
        return higherProbability;
      case UserGuess.tie:
        return tieProbability;
      case UserGuess.lower:
        return lowerProbability;
    }
  }

  /// Check if user's guess is correct
  bool isGuessCorrect(UserGuess userGuess) {
    return correctAnswer != null && userGuess == correctAnswer;
  }

  /// Check if user made an obvious mistake
  bool isObviousMistake(UserGuess userGuess) {
    if (correctAnswer == null) return false;
    
    // Case 1: Missed Obvious Win Option (correct has 100%, user didn't select it)
    if (correctAnswerProbability == 1.0 && userGuess != correctAnswer) {
      return true;
    }
    
    // Case 2: Selected Obvious Fail Option (user selected 0% option)
    final userGuessProbability = getProbabilityForGuess(userGuess);
    if (userGuessProbability == 0.0) {
      return true;
    }
    
    return false;
  }

  /// Get the type of obvious mistake (if any)
  ObviousMistakeType? getObviousMistakeType(UserGuess userGuess) {
    if (correctAnswer == null || computerCard == null) return null;
    
    final userGuessProbability = getProbabilityForGuess(userGuess);
    
    // Type 1: Missed Obvious Win (correct has 100%, user didn't select it)
    if (correctAnswerProbability == 1.0 && userGuess != correctAnswer) {
      return ObviousMistakeType.missedObviousWin;
    }
    
    // Type 2 & 3: Selected 0% option
    if (userGuessProbability == 0.0) {
      if (_isStructuralImpossibility(userGuess)) {
        return ObviousMistakeType.impossibleOption;
      } else {
        return ObviousMistakeType.forgetRevealedCards;
      }
    }
    
    return null;
  }

  /// Check if 0% probability is due to structural impossibility (Type 2)
  bool _isStructuralImpossibility(UserGuess userGuess) {
    if (computerCard == null) return false;
    
    // Type 2: No card lower than "2"
    if (userGuess == UserGuess.lower && computerCard!.name == CardName.two) {
      return true;
    }
    
    // Type 2: No tie card for jokers
    if (userGuess == UserGuess.tie && computerCard!.name.isJoker) {
      return true;
    }
    
    // Type 2: No card higher than "Big Joker"
    if (userGuess == UserGuess.higher && computerCard!.name == CardName.bigJoker) {
      return true;
    }
    
    return false; // Otherwise it's Type 3 (contextual)
  }

  /// Get which guess has the highest probability
  UserGuess get guessWithMaxProbability {
    if (higherProbability >= tieProbability && higherProbability >= lowerProbability) {
      return UserGuess.higher;
    } else if (tieProbability >= higherProbability && tieProbability >= lowerProbability) {
      return UserGuess.tie;
    } else {
      return UserGuess.lower;
    }
  }

  /// Get which guess has the lowest probability
  UserGuess get guessWithMinProbability {
    if (higherProbability <= tieProbability && higherProbability <= lowerProbability) {
      return UserGuess.higher;
    } else if (tieProbability <= higherProbability && tieProbability <= lowerProbability) {
      return UserGuess.tie;
    } else {
      return UserGuess.lower;
    }
  }

  /// Get which guess has the middle probability
  UserGuess get guessWithMiddleProbability {
    final guesses = [
      _ProbabilityGuess(UserGuess.higher, higherProbability),
      _ProbabilityGuess(UserGuess.tie, tieProbability),
      _ProbabilityGuess(UserGuess.lower, lowerProbability),
    ];
    
    guesses.sort((a, b) => a.probability.compareTo(b.probability));
    return guesses[1].guess;
  }

  /// Check if this round has an obvious win option (100% probability)
  bool get hasObviousWinOption => 
      higherProbability == 1.0 || tieProbability == 1.0 || lowerProbability == 1.0;

  /// Check if this round has an obvious fail option (0% probability)
  bool get hasObviousFailOption => 
      higherProbability == 0.0 || tieProbability == 0.0 || lowerProbability == 0.0;

  /// Get the obvious win guess if it exists (null if none)
  UserGuess? get obviousWinGuess {
    if (higherProbability == 1.0) return UserGuess.higher;
    if (tieProbability == 1.0) return UserGuess.tie;
    if (lowerProbability == 1.0) return UserGuess.lower;
    return null;
  }

  /// Get all obvious fail guesses
  List<UserGuess> get obviousFailGuesses {
    final List<UserGuess> fails = [];
    if (higherProbability == 0.0) fails.add(UserGuess.higher);
    if (tieProbability == 0.0) fails.add(UserGuess.tie);
    if (lowerProbability == 0.0) fails.add(UserGuess.lower);
    return fails;
  }

  /// Check if a specific guess is an obvious fail
  bool isObviousFailGuess(UserGuess guess) {
    return getProbabilityForGuess(guess) == 0.0;
  }

  /// Get the score category for bonus scoring
  String get scoreCategory {
    if (correctAnswerProbability == 1.0) return "ObviousWin";
    if (correctAnswerProbability >= 0.5) return "High";
    if (correctAnswerProbability >= 0.1) return "Low";
    return "SuperLow";
  }

  /// Get formatted probability percentages as strings
  Map<String, String> get formattedProbabilities {
    return {
      'higher': '${(higherProbability * 100).toStringAsFixed(1)}%',
      'tie': '${(tieProbability * 100).toStringAsFixed(1)}%',
      'lower': '${(lowerProbability * 100).toStringAsFixed(1)}%',
      'correct': '${(correctAnswerProbability * 100).toStringAsFixed(1)}%',
    };
  }

  /// Convert to JSON for logging
  Map<String, dynamic> toJson() {
    return {
      'roundNumber': roundNumber,
      'higherProbability': higherProbability,
      'tieProbability': tieProbability,
      'lowerProbability': lowerProbability,
      'roundType': roundType,
      'winOptionType': winOptionType,
      'roundCategory': roundCategory,
      'isCounterIntuitive': isCounterIntuitive,
      'maxProbability': maxProbability,
      'minProbability': minProbability,
      'middleProbability': middleProbability,
      'correctAnswer': correctAnswer?.displayName,
      'correctAnswerProbability': correctAnswerProbability,
      'computerCard': computerCard?.displayNameWithSuit,
      'userCard': userCard?.displayNameWithSuit,
      'formattedProbabilities': formattedProbabilities,
      'hasObviousWinOption': hasObviousWinOption,
      'hasObviousFailOption': hasObviousFailOption,
      'obviousWinGuess': obviousWinGuess?.displayName,
      'obviousFailGuesses': obviousFailGuesses.map((g) => g.displayName).toList(),
      'scoreCategory': scoreCategory,
    };
  }

  /// Create a summary string for display
  String get summary {
    final probs = formattedProbabilities;
    final correct = correctAnswer?.displayName ?? 'Unknown';
    return 'Round $roundNumber: H=${probs['higher']}, T=${probs['tie']}, L=${probs['lower']} '
           '| Correct: $correct (${probs['correct']}) - $roundCategory';
  }

  @override
  String toString() {
    final correct = correctAnswer?.displayName ?? 'Unknown';
    return 'RoundProbabilityData(round: $roundNumber, '
           'H: ${(higherProbability * 100).toStringAsFixed(1)}%, '
           'T: ${(tieProbability * 100).toStringAsFixed(1)}%, '
           'L: ${(lowerProbability * 100).toStringAsFixed(1)}%, '
           'Correct: $correct (${(correctAnswerProbability * 100).toStringAsFixed(1)}%), '
           'type: $roundType, winType: $winOptionType)';
  }

  // Helper method to determine correct answer based on cards
  static UserGuess? _determineCorrectAnswer(CardModel computerCard, CardModel userCard) {
    if (computerCard.canTieWith(userCard) && computerCard.isEqualTo(userCard)) {
      return UserGuess.tie;
    } else if (userCard.isHigherThan(computerCard)) {
      return UserGuess.higher;
    } else if (userCard.isLowerThan(computerCard)) {
      return UserGuess.lower;
    }
    return null;
  }

  // Helper method to get correct answer probability
  static double _getCorrectAnswerProbability({
    required UserGuess? correctAnswer,
    required double higherProbability,
    required double tieProbability,
    required double lowerProbability,
  }) {
    if (correctAnswer == null) return 0.0;
    
    switch (correctAnswer) {
      case UserGuess.higher:
        return higherProbability;
      case UserGuess.tie:
        return tieProbability;
      case UserGuess.lower:
        return lowerProbability;
    }
  }

  // Helper method to determine human-readable category
  static String _determineRoundCategory({
    required String roundType,
    required String winOptionType,
    required double maxProbability,
  }) {
    if (roundType == 'ObviousWin') {
      return 'Obvious Win Option Round';
    } else if (roundType == 'ObviousFail') {
      return 'Obvious Fail Option Round';
    } else {
      // Common round
      if (maxProbability >= 0.5) {
        return 'High Probability Win-Option Round';
      } else if (maxProbability >= 0.1) {
        return 'Low Probability Win-Option Round';
      } else {
        return 'Super Low Probability Win-Option Round';
      }
    }
  }
}

/// Helper class for sorting guesses by probability
class _ProbabilityGuess {
  final UserGuess guess;
  final double probability;
  
  _ProbabilityGuess(this.guess, this.probability);
}

/// Extension for list of RoundProbabilityData
extension RoundProbabilityDataListExtension on List<RoundProbabilityData> {
  /// Get statistics from a list of round probability data
  Map<String, dynamic> get statistics {
    if (isEmpty) return {};
    
    int obviousWinRounds = 0;
    int obviousFailRounds = 0;
    int highProbRounds = 0;
    int lowProbRounds = 0;
    int superLowProbRounds = 0;
    int counterIntuitiveRounds = 0;
    
    for (final data in this) {
      switch (data.roundType) {
        case 'ObviousWin':
          obviousWinRounds++;
          break;
        case 'ObviousFail':
          obviousFailRounds++;
          break;
        case 'Common':
          switch (data.winOptionType) {
            case 'High':
              highProbRounds++;
              break;
            case 'Low':
              lowProbRounds++;
              break;
            case 'SuperLow':
              superLowProbRounds++;
              break;
          }
          break;
      }
      
      if (data.isCounterIntuitive) {
        counterIntuitiveRounds++;
      }
    }
    
    return {
      'totalRounds': length,
      'obviousWinRounds': obviousWinRounds,
      'obviousFailRounds': obviousFailRounds,
      'highProbRounds': highProbRounds,
      'lowProbRounds': lowProbRounds,
      'superLowProbRounds': superLowProbRounds,
      'counterIntuitiveRounds': counterIntuitiveRounds,
      'obviousWinPercentage': (obviousWinRounds / length) * 100,
      'highProbPercentage': (highProbRounds / length) * 100,
    };
  }
  
  /// Filter rounds by win option type
  List<RoundProbabilityData> filterByWinOptionType(String winOptionType) {
    return where((data) => data.winOptionType == winOptionType).toList();
  }
  
  /// Filter rounds by round type
  List<RoundProbabilityData> filterByRoundType(String roundType) {
    return where((data) => data.roundType == roundType).toList();
  }
  
  /// Get average maximum probability across all rounds
  double get averageMaxProbability {
    if (isEmpty) return 0.0;
    final total = fold(0.0, (sum, data) => sum + data.maxProbability);
    return total / length;
  }
  
  /// Get average correct answer probability
  double get averageCorrectProbability {
    if (isEmpty) return 0.0;
    final total = fold(0.0, (sum, data) => sum + data.correctAnswerProbability);
    return total / length;
  }
}


