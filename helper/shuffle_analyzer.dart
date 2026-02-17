import '../core/models/card_model.dart';
import '../core/models/user_guess.dart';
import 'probability_calculator.dart';
import 'round_probability_data.dart';

/// Probability category for a round
enum ProbabilityCategory {
  highest,   // Correct answer is highest probability
  second,     // Correct answer is 2nd highest probability
  lowest,     // Correct answer is lowest probability
  draw,       // Tied probabilities
  obvious,    // 100% probability (obvious win)
}

/// Luck category for shuffling
enum ShuffleLuck {
  lucky,        // Number of highest-probability rounds increased
  equivalent,   // Number stayed the same
  unfortunately,// Number decreased
}

/// Prediction for a single round
class RoundPrediction {
  final int roundNumber;
  final CardModel computerCard;
  final CardModel userCard;
  final double higherProb;
  final double tieProb;
  final double lowerProb;
  final UserGuess correctAnswer;
  final double correctAnswerProb;
  final ProbabilityCategory category;

  RoundPrediction({
    required this.roundNumber,
    required this.computerCard,
    required this.userCard,
    required this.higherProb,
    required this.tieProb,
    required this.lowerProb,
    required this.correctAnswer,
    required this.correctAnswerProb,
    required this.category,
  });

  Map<String, dynamic> toJson() {
    return {
      'roundNumber': roundNumber,
      'computerCard': computerCard.displayNameWithSuit,
      'userCard': userCard.displayNameWithSuit,
      'higherProb': higherProb,
      'tieProb': tieProb,
      'lowerProb': lowerProb,
      'correctAnswer': correctAnswer.displayName,
      'correctAnswerProb': correctAnswerProb,
      'category': category.name,
    };
  }
}

/// Analysis result for a shuffle
class ShuffleAnalysis {
  final int shuffleNumber;
  final int roundNumber;
  final bool isInitialShuffle;
  final DateTime shuffleTime;
  final int highestProbRoundsBefore;
  final int highestProbRoundsAfter;
  final int difference;
  final ShuffleLuck luck;
  final List<RoundPrediction> predictions;
  final int remainingRounds;

  ShuffleAnalysis({
    required this.shuffleNumber,
    required this.roundNumber,
    required this.isInitialShuffle,
    required this.shuffleTime,
    required this.highestProbRoundsBefore,
    required this.highestProbRoundsAfter,
    required this.difference,
    required this.luck,
    required this.predictions,
    required this.remainingRounds,
  });

  Map<String, dynamic> toJson() {
    return {
      'shuffleNumber': shuffleNumber,
      'roundNumber': roundNumber,
      'isInitialShuffle': isInitialShuffle,
      'shuffleTime': shuffleTime.toIso8601String(),
      'highestProbRoundsBefore': highestProbRoundsBefore,
      'highestProbRoundsAfter': highestProbRoundsAfter,
      'difference': difference,
      'luck': luck.name,
      'remainingRounds': remainingRounds,
      'predictions': predictions.map((p) => p.toJson()).toList(),
    };
  }

  @override
  String toString() {
    return 'ShuffleAnalysis(#$shuffleNumber at round $roundNumber: '
           'Before=$highestProbRoundsBefore, After=$highestProbRoundsAfter, '
           'Diff=$difference, Luck=$luck)';
  }
}

/// Analyzer for evaluating shuffle luck
class ShuffleAnalyzer {
  final ProbabilityCalculator _probabilityCalculator;

  ShuffleAnalyzer(this._probabilityCalculator);

  /// Analyze a shuffle by comparing before/after predictions
  ShuffleAnalysis analyzeShuffle({
    required List<CardModel> allCards,
    required int currentRound,
    required int shuffleNumber,
    required bool isInitialShuffle,
  }) {
    // 1. Get predictions BEFORE shuffle (if not initial)
    int highestBefore = 0;
    if (!isInitialShuffle) {
      highestBefore = _countHighestProbRounds(allCards, currentRound);
    }

    // 2. Get predictions AFTER shuffle
    final predictions = _generatePredictions(allCards, currentRound);
    final highestAfter = predictions
        .where((p) => p.category == ProbabilityCategory.highest)
        .length;

    // 3. Calculate difference and luck
    final difference = highestAfter - highestBefore;
    final luck = _determineLuck(difference, isInitialShuffle);

    return ShuffleAnalysis(
      shuffleNumber: shuffleNumber,
      roundNumber: currentRound,
      isInitialShuffle: isInitialShuffle,
      shuffleTime: DateTime.now(),
      highestProbRoundsBefore: highestBefore,
      highestProbRoundsAfter: highestAfter,
      difference: difference,
      luck: luck,
      predictions: predictions,
      remainingRounds: predictions.length,
    );
  }

  /// Count rounds where correct answer is highest probability
  int _countHighestProbRounds(List<CardModel> allCards, int currentRound) {
    final predictions = _generatePredictions(allCards, currentRound);
    return predictions
        .where((p) => p.category == ProbabilityCategory.highest)
        .length;
  }

  /// Generate predictions for all remaining rounds
  List<RoundPrediction> _generatePredictions(
    List<CardModel> allCards,
    int currentRound,
  ) {
    final predictions = <RoundPrediction>[];
    final deckCards = allCards
        .where((card) => card.status == CardStatus.inDeck)
        .toList();

    // Simulate dealing pairs from deck
    for (int i = 0; i < deckCards.length - 1; i += 2) {
      final computerCard = deckCards[i];
      final userCard = deckCards[i + 1];

      // Calculate probabilities
      final probData = _probabilityCalculator.calculateRoundProbabilities(
        allCards: allCards,
        computerCard: computerCard,
        userCard: userCard,
        roundNumber: currentRound + (i ~/ 2) + 1,
      );

      // Skip if no correct answer (should not happen)
      if (probData.correctAnswer == null) {
        continue;
      }

      // Determine category
      final category = _determineCategory(probData);

      predictions.add(RoundPrediction(
        roundNumber: currentRound + (i ~/ 2) + 1,
        computerCard: computerCard,
        userCard: userCard,
        higherProb: probData.higherProbability,
        tieProb: probData.tieProbability,
        lowerProb: probData.lowerProbability,
        correctAnswer: probData.correctAnswer!,
        correctAnswerProb: probData.correctAnswerProbability,
        category: category,
      ));
    }

    return predictions;
  }

  /// Determine probability category for a round
  ProbabilityCategory _determineCategory(RoundProbabilityData probData) {
    // Skip 100% obvious wins
    if (probData.correctAnswerProbability == 1.0) {
      return ProbabilityCategory.obvious;
    }

    final probs = [
      probData.higherProbability,
      probData.tieProbability,
      probData.lowerProbability,
    ];
    probs.sort((a, b) => b.compareTo(a));

    // Check for ties
    final correctProb = probData.correctAnswerProbability;
    final countOfCorrect = probs.where((p) => p == correctProb).length;
    if (countOfCorrect > 1) {
      return ProbabilityCategory.draw;
    }

    // Determine rank
    if (correctProb == probs[0]) {
      return ProbabilityCategory.highest;
    } else if (correctProb == probs[1]) {
      return ProbabilityCategory.second;
    } else {
      return ProbabilityCategory.lowest;
    }
  }

  /// Determine luck category
  ShuffleLuck _determineLuck(int difference, bool isInitialShuffle) {
    if (isInitialShuffle) {
      return ShuffleLuck.equivalent; // No comparison for initial shuffle
    }
    if (difference > 0) return ShuffleLuck.lucky;
    if (difference < 0) return ShuffleLuck.unfortunately;
    return ShuffleLuck.equivalent;
  }
}