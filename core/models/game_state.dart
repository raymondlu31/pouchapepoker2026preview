

/// Represents the overall state of the poker intuition game.
/// This enum drives the game flow and UI updates.

enum GameState {
  /// Initial application state - showing splash/loading
  initializing,
  
  /// Showing initial instruction dialog
  showingInstructions,
  
  /// Showing game options dialog for user to configure flags
  showingOptions,
  
  /// New game is being prepared (initial shuffle)
  newGameStarting,
  
  /// Actively shuffling the card deck
  shuffling,
  
  /// Dealing cards for a new round (2 cards: computer + user)
  dealing,
  
  /// Computer card has been revealed, waiting for user guess
  /// Timer is running during this state
  waitingForGuess,
  
  /// User has made a guess, processing the result
  processingGuess,
  
  /// Showing user's card flip animation (1 second pause)
  showingCardFlip,
  
  /// Showing score dialog for the round
  showingScore,
  
  /// Showing dialog sequence (score, bonus, warning, stage/stack results)
  showingDialogSequence,
  
  /// Preparing for next round
  betweenRounds,
  
  /// All 27 rounds completed, showing final reports
  showingReports,
  
  /// Showing final scores and baseline comparison
  showingFinalScores,
  
  /// Game is paused (e.g., app backgrounded)
  paused,
  
  /// Game has encountered an error
  error,
}

/// Extension methods for GameState to provide additional functionality
extension GameStateExtension on GameState {
  /// Check if the game is in an active playing state
  bool get isActiveState => this == GameState.waitingForGuess;
  
  /// Check if the game is showing any dialog/modal
  bool get isShowingDialog => _dialogStates.contains(this);
  
  /// Check if the game is in a transition state between major actions
  bool get isTransitionState => _transitionStates.contains(this);
  
  /// Check if timer should be running in this state
  bool get shouldTimerRun => this == GameState.waitingForGuess;
  
  /// Check if user input should be accepted in this state
  bool get acceptsUserInput => _inputAcceptingStates.contains(this);
  
  /// Get the next logical state after completing the current one
  GameState get nextNormalState {
    switch (this) {
      case GameState.showingInstructions:
        return GameState.showingOptions;
      case GameState.newGameStarting:
        return GameState.shuffling;
      case GameState.shuffling:
        return GameState.dealing;
      case GameState.dealing:
        return GameState.waitingForGuess;
      case GameState.waitingForGuess:
        return GameState.processingGuess;
      case GameState.processingGuess:
        return GameState.showingCardFlip;
      case GameState.showingCardFlip:
        return GameState.showingScore;
      case GameState.showingScore:
        return GameState.showingDialogSequence;
      case GameState.showingDialogSequence:
        return GameState.betweenRounds;
      case GameState.betweenRounds:
        return GameState.dealing;   // Default transition - actual logic is in GameManager

      case GameState.showingReports:
        return GameState.showingFinalScores;
      case GameState.showingFinalScores:
        return GameState.showingOptions;
      default:
        return this;
    }
  }
  
  // Private sets for state categorization
  static final Set<GameState> _dialogStates = {
    GameState.showingInstructions,
    GameState.showingOptions,
    GameState.showingScore,
    GameState.showingDialogSequence,
    GameState.showingReports,
    GameState.showingFinalScores,
  };
  
  static final Set<GameState> _transitionStates = {
    GameState.initializing,
    GameState.newGameStarting,
    GameState.shuffling,
    GameState.dealing,
    GameState.processingGuess,
    GameState.showingCardFlip,
    GameState.betweenRounds,
  };
  
  static final Set<GameState> _inputAcceptingStates = {
    GameState.waitingForGuess,
    GameState.showingOptions,
  };
}

