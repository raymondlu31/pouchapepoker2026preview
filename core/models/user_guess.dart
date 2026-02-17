/// Represents user's guess options
enum UserGuess {
  higher,
  tie,
  lower;
  
  String get displayName {
    switch (this) {
      case UserGuess.higher:
        return 'Higher';
      case UserGuess.tie:
        return 'Tie';
      case UserGuess.lower:
        return 'Lower';
    }
  }
  
  String get shortName {
    switch (this) {
      case UserGuess.higher:
        return 'H';
      case UserGuess.tie:
        return 'T';
      case UserGuess.lower:
        return 'L';
    }
  }
}

/// Represents the result of a round
enum RoundResult {
  win,
  missed;
  
  String get displayName {
    switch (this) {
      case RoundResult.win:
        return 'Win';
      case RoundResult.missed:
        return 'Missed';
    }
  }
  
  /// Convert to I-Ching binary (1 for win, 0 for missed)
  String get toBinary => this == RoundResult.win ? '1' : '0';
  
  /// Get opposite result
  RoundResult get opposite => this == RoundResult.win ? RoundResult.missed : RoundResult.win;
}