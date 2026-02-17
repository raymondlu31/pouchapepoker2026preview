import 'card_model.dart';
import 'user_guess.dart';

class ScoreEntry {
  final int roundNumber;
  final int baseScore;
  final Map<String, int> bonuses;
  final int totalScore;
  final String scoreCategory;
  final String roundCategory;
  final bool isCounterIntuitive;
  final bool isObviousMistake;
  final UserGuess? userGuess;
  final UserGuess? correctAnswer;
  final bool isCorrect;
  final double userGuessProbability;
  final double correctAnswerProbability;
  final CardModel? computerCard;
  final CardModel? userCard;
  final String? computerCardStr;
  final String? userCardStr;

  ScoreEntry({
    required this.roundNumber,
    required this.baseScore,
    required this.bonuses,
    required this.totalScore,
    required this.scoreCategory,
    required this.roundCategory,
    required this.isCounterIntuitive,
    required this.isObviousMistake,
    required this.userGuess,
    required this.correctAnswer,
    required this.isCorrect,
    required this.userGuessProbability,
    required this.correctAnswerProbability,
    this.computerCard,
    this.userCard,
    this.computerCardStr,
    this.userCardStr,
  });

  int get bonusPoints => bonuses.values.fold(0, (sum, points) => sum + points);

  List<String> get bonusDescriptions {
    return bonuses.entries.map((entry) {
      final type = entry.key;
      final points = entry.value;
      return '${_formatBonusType(type)}: +$points';
    }).toList();
  }

  Map<String, dynamic> toJson() {
    return {
      'roundNumber': roundNumber,
      'baseScore': baseScore,
      'bonuses': bonuses,
      'totalScore': totalScore,
      'scoreCategory': scoreCategory,
      'roundCategory': roundCategory,
      'isCounterIntuitive': isCounterIntuitive,
      'isObviousMistake': isObviousMistake,
      'userGuess': userGuess?.displayName,
      'correctAnswer': correctAnswer?.displayName,
      'isCorrect': isCorrect,
      'bonusPoints': bonusPoints,
      'bonusDescriptions': bonusDescriptions,
      'userGuessProbability': userGuessProbability,
      'correctAnswerProbability': correctAnswerProbability,
      'computerCard': computerCard?.displayNameWithSuit,
      'userCard': userCard?.displayNameWithSuit,
      'computerCardStr': computerCardStr ?? computerCard?.displayNameWithSuit,
      'userCardStr': userCardStr ?? userCard?.displayNameWithSuit,
    };
  }

  factory ScoreEntry.fromJson(Map<String, dynamic> json) {
    // Helper function to reconstruct UserGuess from displayName
    UserGuess? _guessFromDisplayName(String? displayName) {
      if (displayName == null) return null;
      for (var guess in UserGuess.values) {
        if (guess.displayName == displayName) {
          return guess;
        }
      }
      return null;
    }

    return ScoreEntry(
      roundNumber: json['roundNumber'] as int,
      baseScore: json['baseScore'] as int,
      bonuses: Map<String, int>.from(json['bonuses'] ?? {}),
      totalScore: json['totalScore'] as int,
      scoreCategory: json['scoreCategory'] as String,
      roundCategory: json['roundCategory'] as String,
      isCounterIntuitive: json['isCounterIntuitive'] as bool,
      isObviousMistake: json['isObviousMistake'] as bool,
      userGuess: _guessFromDisplayName(json['userGuess']),
      correctAnswer: _guessFromDisplayName(json['correctAnswer']),
      isCorrect: json['isCorrect'] as bool,
      userGuessProbability: (json['userGuessProbability'] as num?)?.toDouble() ?? 0.0,
      correctAnswerProbability: (json['correctAnswerProbability'] as num?)?.toDouble() ?? 0.0,
      computerCard: null,
      userCard: null,
      computerCardStr: json['computerCardStr'] as String?,
      userCardStr: json['userCardStr'] as String?,
    );
  }

  String _formatBonusType(String type) {
    switch (type) {
      case 'counterIntuitive':
        return 'Counter-Intuitive Round';
      case 'lowProb':
        return 'Low Probability Round';
      case 'superLowProb':
        return 'Super Low Probability Round';
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
        return type;
    }
  }

  @override
  String toString() {
    final guess = userGuess?.displayName ?? 'None';
    final correct = correctAnswer?.displayName ?? 'Unknown';
    return 'Round $roundNumber: $guess vs $correct | '
           'Base: $baseScore + Bonus: $bonusPoints = Total: $totalScore '
           '($scoreCategory${isCounterIntuitive ? ', Counter-Intuitive' : ''})';
  }
}

