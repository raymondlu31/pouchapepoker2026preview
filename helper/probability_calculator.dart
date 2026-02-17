

import '../core/models/card_model.dart';
import '../core/models/user_guess.dart';
import 'round_probability_data.dart';

/// Categories for round types based on probability distribution
enum RoundType {
  obviousWin,      // Has an option with 100% probability
  obviousFail,     // Has an option with 0% probability (but no 100% option)
  common,          // No 0% or 100% options
}

/// Categories for win option probabilities
enum WinOptionType {
  highProbability,     // >= 50%
  lowProbability,      // < 50% and >= 10%
  superLowProbability, // < 10%
  obviousWin,          // = 100%
  obviousFail,         // = 0%
}

/// Represents the three probability options in a round
class ProbabilityOptions {
  final double higher;
  final double tie;
  final double lower;
  final double totalCards;

  ProbabilityOptions({
    required this.higher,
    required this.tie,
    required this.lower,
    required this.totalCards,
  });

  /// Get the probability for a specific guess
  double getProbability(UserGuess guess) {
    switch (guess) {
      case UserGuess.higher:
        return higher;
      case UserGuess.tie:
        return tie;
      case UserGuess.lower:
        return lower;
    }
  }

  /// Get the correct guess based on computer and user cards
  UserGuess getCorrectGuess(CardModel computerCard, CardModel userCard) {
    if (computerCard.canTieWith(userCard) && computerCard.isEqualTo(userCard)) {
      return UserGuess.tie;
    } else if (userCard.isHigherThan(computerCard)) {
      return UserGuess.higher;
    } else {
      return UserGuess.lower;
    }
  }

  /// Get the probability of the correct guess
  double getCorrectProbability(CardModel computerCard, CardModel userCard) {
    final correctGuess = getCorrectGuess(computerCard, userCard);
    return getProbability(correctGuess);
  }

  /// Get the win option type for the correct answer
  WinOptionType getWinOptionType(CardModel computerCard, CardModel userCard) {
    final probability = getCorrectProbability(computerCard, userCard);
    
    if (probability == 1.0) return WinOptionType.obviousWin;
    if (probability == 0.0) return WinOptionType.obviousFail;
    if (probability >= 0.5) return WinOptionType.highProbability;
    if (probability >= 0.1) return WinOptionType.lowProbability;
    return WinOptionType.superLowProbability;
  }

  /// Determine the round type
  RoundType getRoundType() {
    final hasObviousWin = higher == 1.0 || tie == 1.0 || lower == 1.0;
    final hasObviousFail = higher == 0.0 || tie == 0.0 || lower == 0.0;
    
    if (hasObviousWin) return RoundType.obviousWin;
    if (hasObviousFail) return RoundType.obviousFail;
    return RoundType.common;
  }

  /// Check if this is a counter-intuitive high-probability round
  bool isCounterIntuitiveHighProbRound(CardModel computerCard, CardModel userCard) {
    final correctGuess = getCorrectGuess(computerCard, userCard);
    final correctProb = getCorrectProbability(computerCard, userCard);
    
    // Must be high probability (>= 50%)
    if (correctProb < 0.5) return false;
    
    final computerIntuitiveSize = computerCard.name.intuitiveSize;
    final userIntuitiveSize = userCard.name.intuitiveSize;
    
    // Case 1: Computer Small card (2-6) and correct answer is Lower
    if (computerIntuitiveSize == 'Small' && 
        correctGuess == UserGuess.lower &&
        userIntuitiveSize == 'Small') {
      return true;
    }
    
    // Case 2: Computer Big card (10+) and correct answer is Higher
    if (computerIntuitiveSize == 'Big' && 
        correctGuess == UserGuess.higher &&
        userIntuitiveSize == 'Big') {
      return true;
    }
    
    return false;
  }

  @override
  String toString() {
    return 'ProbabilityOptions(H: ${(higher * 100).toStringAsFixed(1)}%, '
           'T: ${(tie * 100).toStringAsFixed(1)}%, '
           'L: ${(lower * 100).toStringAsFixed(1)}%)';
  }
}

/// Main calculator for round probabilities
class ProbabilityCalculator {
  /// Calculate probabilities for a round given current game state
  RoundProbabilityData calculateRoundProbabilities({
    required List<CardModel> allCards,
    required CardModel computerCard,
    required CardModel userCard,
    required int roundNumber,
  }) {
    // Get unrevealed cards (deck + user's face-down card)
    final unrevealedCards = _getUnrevealedCards(allCards, userCard);
    final totalUnrevealed = unrevealedCards.length.toDouble();
    
    // Calculate probabilities
    final probabilities = _calculateProbabilities(
      computerCard: computerCard,
      allCards: allCards,
      unrevealedCards: unrevealedCards,
      totalCards: totalUnrevealed,
    );
    
    // Determine round type and win option type
    final roundType = probabilities.getRoundType();
    final winOptionType = probabilities.getWinOptionType(computerCard, userCard);
    final isCounterIntuitive = probabilities.isCounterIntuitiveHighProbRound(computerCard, userCard);
    
    // Convert enums to strings for RoundProbabilityData
    final roundTypeString = _roundTypeToString(roundType);
    final winOptionTypeString = _winOptionTypeToString(winOptionType);
    
    // Create enhanced RoundProbabilityData with correct answer info
    return RoundProbabilityData.create(
      roundNumber: roundNumber,
      higherProbability: probabilities.higher,
      tieProbability: probabilities.tie,
      lowerProbability: probabilities.lower,
      roundType: roundTypeString,
      winOptionType: winOptionTypeString,
      isCounterIntuitive: isCounterIntuitive,
      computerCard: computerCard,
      userCard: userCard,
    );
  }

  /// Get all unrevealed cards (deck + user's face-down card)
  List<CardModel> _getUnrevealedCards(
    List<CardModel> allCards,
    CardModel userCard,
  ) {
    return allCards.where((card) {
      // Include cards in deck
      if (card.status == CardStatus.inDeck) return true;
      // Include user's face-down card
      if (card.cardId == userCard.cardId && card.status == CardStatus.dealed) {
        return true;
      }
      return false;
    }).toList();
  }

  /// Calculate probabilities for Higher/Tie/Lower
  ProbabilityOptions _calculateProbabilities({
    required CardModel computerCard,
    required List<CardModel> allCards,
    required List<CardModel> unrevealedCards,
    required double totalCards,
  }) {
    // Special handling for jokers
    if (computerCard.name.isJoker) {
      return _calculateJokerProbabilities(
        computerCard: computerCard,
        allCards: allCards,
        unrevealedCards: unrevealedCards,
        totalCards: totalCards,
      );
    }
    
    // Regular card probability calculation
    return _calculateRegularCardProbabilities(
      computerCard: computerCard,
      unrevealedCards: unrevealedCards,
      totalCards: totalCards,
    );
  }

  /// Calculate probabilities when computer reveals a regular card
  ProbabilityOptions _calculateRegularCardProbabilities({
    required CardModel computerCard,
    required List<CardModel> unrevealedCards,
    required double totalCards,
  }) {
    int higherCount = 0;
    int tieCount = 0;
    int lowerCount = 0;
    
    for (final card in unrevealedCards) {
      if (card.value > computerCard.value) {
        higherCount++;
      } else if (card.value == computerCard.value) {
        // Check if cards can tie (non-jokers with same value)
        if (card.canTieWith(computerCard)) {
          tieCount++;
        } else {
          // If can't tie (e.g., joker with same value as regular card)
          if (card.value > computerCard.value) {
            higherCount++;
          } else {
            lowerCount++;
          }
        }
      } else {
        lowerCount++;
      }
    }
    
    return ProbabilityOptions(
      higher: higherCount / totalCards,
      tie: tieCount / totalCards,
      lower: lowerCount / totalCards,
      totalCards: totalCards,
    );
  }

  /// Calculate probabilities when computer reveals a joker
  ProbabilityOptions _calculateJokerProbabilities({
    required CardModel computerCard,
    required List<CardModel> allCards,
    required List<CardModel> unrevealedCards,
    required double totalCards,
  }) {
    final isBigJoker = computerCard.name == CardName.bigJoker;
    
    if (isBigJoker) {
      // Big Joker: User card is always Lower (100%)
      return ProbabilityOptions(
        higher: 0.0,
        tie: 0.0,
        lower: 1.0,
        totalCards: totalCards,
      );
    } else {
      // Little Joker
      // Check if Big Joker is already revealed (in allCards, not just unrevealedCards)
      final bigJokerRevealed = allCards.any((card) =>
          card.name == CardName.bigJoker && card.status == CardStatus.revealed);
      
      if (bigJokerRevealed) {
        // Big Joker already revealed: User card is Lower (100%)
        return ProbabilityOptions(
          higher: 0.0,
          tie: 0.0,
          lower: 1.0,
          totalCards: totalCards,
        );
      } else {
        // Big Joker not revealed yet
        // High probability = 1/N (user has Big Joker)
        // Low probability = (N-1)/N (user doesn't have Big Joker)
        
        if (totalCards > 1) {
          return ProbabilityOptions(
            higher: (1.0 / totalCards),
            tie: 0.0, // Jokers can't tie
            lower: (totalCards - 1.0) / totalCards,
            totalCards: totalCards,
          );
        } else {
          // Only one card left (the user must have Big Joker)
          return ProbabilityOptions(
            higher: 1.0,
            tie: 0.0,
            lower: 0.0,
            totalCards: totalCards,
          );
        }
      }

    }
  }

  /// Categorize a round based on its probabilities
  String categorizeRound(ProbabilityOptions probabilities) {
    final roundType = probabilities.getRoundType();
    
    switch (roundType) {
      case RoundType.obviousWin:
        return 'Obvious Win Option Round';
      case RoundType.obviousFail:
        return 'Obvious Fail Option Round';
      case RoundType.common:
        // For common rounds, further categorize by probability distribution
        final probs = [probabilities.higher, probabilities.tie, probabilities.lower];
        probs.sort((a, b) => b.compareTo(a)); // Descending
        
        if (probs[0] >= 0.5) {
          return 'High Probability Win-Option Round';
        } else if (probs[0] >= 0.1) {
          return 'Low Probability Win-Option Round';
        } else {
          return 'Super Low Probability Win-Option Round';
        }
    }
  }

  /// Get the maximum probability among the three options
  double getMaxProbability(ProbabilityOptions probabilities) {
    return [probabilities.higher, probabilities.tie, probabilities.lower]
        .reduce((a, b) => a > b ? a : b);
  }

  /// Get the minimum probability among the three options
  double getMinProbability(ProbabilityOptions probabilities) {
    return [probabilities.higher, probabilities.tie, probabilities.lower]
        .reduce((a, b) => a < b ? a : b);
  }

  /// Get the middle probability among the three options
  double getMiddleProbability(ProbabilityOptions probabilities) {
    final probs = [probabilities.higher, probabilities.tie, probabilities.lower];
    probs.sort();
    return probs[1]; // Middle value
  }

  /// Check if user made an obvious mistake
  bool isObviousMistake({
    required ProbabilityOptions probabilities,
    required UserGuess userGuess,
    required CardModel computerCard,
    required CardModel userCard,
  }) {
    final correctGuess = probabilities.getCorrectGuess(computerCard, userCard);
    final correctProb = probabilities.getCorrectProbability(computerCard, userCard);
    final userProb = probabilities.getProbability(userGuess);
    
    // Case 1: Missed Obvious Win Option (correct has 100%, user didn't select it)
    if (correctProb == 1.0 && userGuess != correctGuess) {
      return true;
    }
    
    // Case 2: Selected Obvious Fail Option (user selected 0% option)
    if (userProb == 0.0) {
      return true;
    }
    
    return false;
  }

  /// Helper method to convert round type to string
  String _roundTypeToString(RoundType roundType) {
    switch (roundType) {
      case RoundType.obviousWin:
        return 'ObviousWin';
      case RoundType.obviousFail:
        return 'ObviousFail';
      case RoundType.common:
        return 'Common';
    }
  }

  /// Helper method to convert win option type to string
  String _winOptionTypeToString(WinOptionType winOptionType) {
    switch (winOptionType) {
      case WinOptionType.highProbability:
        return 'High';
      case WinOptionType.lowProbability:
        return 'Low';
      case WinOptionType.superLowProbability:
        return 'SuperLow';
      case WinOptionType.obviousWin:
        return 'ObviousWin';
      case WinOptionType.obviousFail:
        return 'ObviousFail';
    }
  }

  /// Analyze the deck to predict future round types after shuffle
  Map<String, int> analyzeDeckComposition(List<CardModel> deck) {
    final counts = DeckManager.getValueCounts(deck);
    
    // Analyze for different computer card values
    int obviousWinRounds = 0;
    int obviousFailRounds = 0;
    int highProbRounds = 0;
    int lowProbRounds = 0;
    int superLowProbRounds = 0;
    
    // For each possible computer card value (2-16)
    for (int computerValue = 2; computerValue <= 16; computerValue++) {
      // Simulate if this value was revealed
      int higherCount = 0;
      int tieCount = 0;
      int lowerCount = 0;
      
      for (final entry in counts.entries) {
        final cardValue = entry.key;
        final cardCount = entry.value;
        
        if (cardValue > computerValue) {
          higherCount += cardCount;
        } else if (cardValue == computerValue) {
          tieCount += cardCount;
        } else {
          lowerCount += cardCount;
        }
      }
      
      final totalCards = deck.length.toDouble();
      final higherProb = higherCount / totalCards;
      final tieProb = tieCount / totalCards;
      final lowerProb = lowerCount / totalCards;
      
      // Check for obvious win/fail
      if (higherProb == 1.0 || tieProb == 1.0 || lowerProb == 1.0) {
        obviousWinRounds++;
      } else if (higherProb == 0.0 || tieProb == 0.0 || lowerProb == 0.0) {
        obviousFailRounds++;
      } else {
        // Check max probability for categorization
        final maxProb = [higherProb, tieProb, lowerProb].reduce((a, b) => a > b ? a : b);
        if (maxProb >= 0.5) {
          highProbRounds++;
        } else if (maxProb >= 0.1) {
          lowProbRounds++;
        } else {
          superLowProbRounds++;
        }
      }
    }
    
    return {
      'obviousWinRounds': obviousWinRounds,
      'obviousFailRounds': obviousFailRounds,
      'highProbRounds': highProbRounds,
      'lowProbRounds': lowProbRounds,
      'superLowProbRounds': superLowProbRounds,
    };
  }

  /// Calculate hint information for display
  Map<String, dynamic> calculateHintInfo({
    required List<CardModel> allCards,
    required CardModel computerCard,
    required CardModel userCard,
    required int roundNumber,
    required String hintType, // 'basic', 'revealed', 'history', 'remain'
  }) {
    final unrevealedCards = _getUnrevealedCards(allCards, userCard);
    final revealedCards = allCards.where((card) => card.status == CardStatus.revealed).toList();
    final deckCards = allCards.where((card) => card.status == CardStatus.inDeck).toList();
    
    switch (hintType) {
      case 'basic':
        final probabilities = calculateRoundProbabilities(
          allCards: allCards,
          computerCard: computerCard,
          userCard: userCard,
          roundNumber: roundNumber,
        );
        
        // Calculate card counts for intermediate steps
        int higherCount = 0;
        int tieCount = 0;
        int lowerCount = 0;
        final totalUnrevealed = unrevealedCards.length;
        
        for (final card in unrevealedCards) {
          if (computerCard.name.isJoker) {
            // Special handling for jokers
            final isBigJoker = computerCard.name == CardName.bigJoker;
            if (isBigJoker) {
              // Big Joker: User card is always Lower
              lowerCount++;
            } else {
              // Little Joker
              final bigJokerRevealed = allCards.any((c) => 
                  c.name == CardName.bigJoker && c.status == CardStatus.revealed);
              if (bigJokerRevealed) {
                lowerCount++;
              } else {
                // Check if this card is Big Joker
                if (card.name == CardName.bigJoker) {
                  higherCount++;
                } else {
                  lowerCount++;
                }
              }
            }
          } else {
            // Regular card probability calculation
            if (card.value > computerCard.value) {
              higherCount++;
            } else if (card.value == computerCard.value) {
              // Check if cards can tie (non-jokers with same value)
              if (card.canTieWith(computerCard)) {
                tieCount++;
              } else {
                // If can't tie (e.g., joker with same value as regular card)
                if (card.value > computerCard.value) {
                  higherCount++;
                } else {
                  lowerCount++;
                }
              }
            } else {
              lowerCount++;
            }
          }
        }
        
        return {
          'type': 'basic',
          'probabilities': probabilities.formattedProbabilities,
          'roundCategory': probabilities.roundCategory,
          'correctAnswer': probabilities.correctAnswer?.displayName,
          'correctProbability': probabilities.formattedProbabilities['correct'],
          'higherCount': higherCount,
          'tieCount': tieCount,
          'lowerCount': lowerCount,
          'totalUnrevealed': totalUnrevealed,
        };
        
      case 'revealed':
        // Group revealed cards by suit
        final bySuit = <String, List<String>>{};
        for (final card in revealedCards) {
          if (card.suit != null) {
            final suitName = card.suit!.displayName;
            bySuit.putIfAbsent(suitName, () => []);
            bySuit[suitName]!.add(card.displayNameWithSuit);
          } else {
            // Jokers
            bySuit.putIfAbsent('Jokers', () => []);
            bySuit['Jokers']!.add(card.displayNameWithSuit);
          }
        }
        return {
          'type': 'revealed',
          'totalRevealed': revealedCards.length,
          'bySuit': bySuit,
          'computerCard': computerCard.displayNameWithSuit,
        };
        
      case 'remain':
        // Group remaining cards by suit
        final bySuit = <String, List<String>>{};
        for (final card in deckCards) {
          if (card.suit != null) {
            final suitName = card.suit!.displayName;
            bySuit.putIfAbsent(suitName, () => []);
            bySuit[suitName]!.add(card.displayNameWithSuit);
          } else {
            // Jokers
            bySuit.putIfAbsent('Jokers', () => []);
            bySuit['Jokers']!.add(card.displayNameWithSuit);
          }
        }
        return {
          'type': 'remain',
          'totalRemaining': deckCards.length,
          'bySuit': bySuit,
          'userCardHidden': 'Face-down card not shown',
        };
        
      case 'history':
        // This would be populated by GameManager with previous round history
        return {
          'type': 'history',
          'message': 'Round history would be shown here',
          'currentRound': roundNumber,
        };
        
      default:
        return {'type': 'unknown', 'error': 'Unknown hint type'};
    }
  }
}


