
import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'core/models/card_model.dart';
import 'core/models/game_state.dart';
import 'core/models/round_info.dart';
import 'core/models/stage_model.dart';
import 'core/models/user_guess.dart';
import 'core/models/flag_options.dart';
import 'core/data/8gua_data.dart';
import 'core/data/64gua_data.dart';
import 'helper/verbose_game_logger.dart';
import 'helper/probability_calculator.dart';
import 'helper/round_probability_data.dart';
import 'helper/score_calculator.dart';
import 'helper/statistics_reporter.dart';
import 'helper/timer_helper.dart';
import 'helper/ui_debug_logger.dart';
import 'helper/shuffle_analyzer.dart';



/// Main game manager that orchestrates the entire game flow
class GameManager {
  // Game State
  GameState _currentState = GameState.initializing;
  GameState get currentState => _currentState;
  
  // Game Configuration
  FlagOptions _gameOptions = FlagOptions();
  FlagOptions get gameOptions => _gameOptions;
  
  // Game Data
  int _currentRound = 0;
  int get currentRound => _currentRound;
  RoundInfo get roundInfo => RoundInfo.fromRoundNumber(_currentRound);
  
  // Card Management
  List<CardModel> _allCards = [];
  List<CardModel> get cardsInDeck => 
      _allCards.where((card) => card.status == CardStatus.inDeck).toList();
  List<CardModel> get cardsDealed => 
      _allCards.where((card) => card.status == CardStatus.dealed).toList();
  List<CardModel> get cardsRevealed => 
      _allCards.where((card) => card.status == CardStatus.revealed).toList();
  
  CardModel? _computerCard;
  CardModel? _userCard;
  CardModel? get computerCard => _computerCard;
  CardModel? get userCard => _userCard;
  
  // Game Components
  final ProbabilityCalculator _probabilityCalculator = ProbabilityCalculator();
  final ScoreCalculator _scoreCalculator = ScoreCalculator();
  final StatisticsReporter _statisticsReporter = StatisticsReporter();
  final ShuffleAnalyzer _shuffleAnalyzer = ShuffleAnalyzer(ProbabilityCalculator());
  final TimerHelper _timerHelper = TimerHelper();
  final VerboseGameLogger _verboseGameLogger = VerboseGameLogger();
  final StageStackManager _stageStackManager = StageStackManager();

  // Random seed for reproducibility
  int? _gameSeed;
  Random? _random;
  int? get gameSeed => _gameSeed;
  
  // Round Tracking
  RoundProbabilityData? _currentRoundProbabilities;
  final List<RoundProbabilityData> _allRoundProbabilities = []; // Store all round probabilities
  UserGuess? _currentUserGuess;
  DateTime? _roundStartTime;
  DateTime? _roundEndTime;

  // Shuffle Tracking
  int _shuffleCount = 0;
  int get shuffleCount => _shuffleCount;

  // Hint tracking for logging
  DateTime? _hintStartTime;
  String? _currentHintType;
  
  /*
  // Tracking for warnings
  int _consecutiveMissedHighProbCount = 0;
  final List<bool> _highProbMissedLast3Rounds = [false, false, false];
  */
  
  // Dialog sequence data
  bool _isDialogSequenceActive = false;
  Map<String, dynamic>? _currentDialogSequenceData;
  
  // Game Flow Control
  final StreamController<GameState> _stateController = 
      StreamController<GameState>.broadcast();
  final StreamController<Map<String, dynamic>> _dialogSequenceController = 
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _hintController = 
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _shuffleController = 
      StreamController<Map<String, dynamic>>.broadcast();
  
  /// Stream for game state changes
  Stream<GameState> get stateStream => _stateController.stream;
  
  /// Stream for dialog sequence requests
  Stream<Map<String, dynamic>> get dialogSequenceStream => _dialogSequenceController.stream;
  
  /// Stream for hint responses
  Stream<Map<String, dynamic>> get hintStream => _hintController.stream;
  
  /// Stream for shuffle notifications
  Stream<Map<String, dynamic>> get shuffleStream => _shuffleController.stream;
  
  /// Timer state stream
  Stream<TimerState> get timerStream => _timerHelper.stateStream;
  
  /// Initialize the game manager
  GameManager() {
    _initializeGame();
  }
  
  /// Initialize game components
  void _initializeGame() {
    _timerHelper.configure(showCountdown: _gameOptions.showCountDown);
    _verboseGameLogger.setEnabled(_gameOptions.verboseLogMode);
    
    _changeState(GameState.showingInstructions);
  }
  
  /// Change game state and notify listeners
  void _changeState(GameState newState) {
    if (_currentState == newState) return;
    
    final oldState = _currentState;
    _currentState = newState;
    
    _stateController.add(newState);
    
    // Log state change
    if (_gameOptions.verboseLogMode) {
      print('Game State: $oldState → $newState');
    }
    
    // Handle state-specific logic
    _onStateChanged(oldState, newState);
  }
  
  /// Handle state transitions
  void _onStateChanged(GameState oldState, GameState newState) {
    switch (newState) {
      case GameState.showingInstructions:
        _handleShowingInstructions();
        break;
      case GameState.showingOptions:
        _handleShowingOptions();
        break;
      case GameState.newGameStarting:
        _handleNewGameStarting();
        break;
      case GameState.shuffling:
        _handleShuffling();
        break;
      case GameState.dealing:
        _handleDealing();
        break;
      case GameState.waitingForGuess:
        _handleWaitingForGuess();
        break;
      case GameState.processingGuess:
        _handleProcessingGuess();
        break;
      case GameState.showingCardFlip:
        _handleShowingCardFlip();
        break;
      case GameState.showingScore:
        _handleShowingScore();
        break;
      case GameState.showingDialogSequence:
        _handleShowingDialogSequence();
        break;
      case GameState.betweenRounds:
        _handleBetweenRounds();
        break;
      case GameState.showingReports:
        _handleShowingReports();
        break;
      case GameState.showingFinalScores:
        _handleShowingFinalScores();
        break;
      default:
        break;
    }
  }
  
  // --- Game Flow Methods ---
  
  /// Start a new game with given options
  void startNewGame(FlagOptions options) {
    _gameOptions = options;
    _timerHelper.configure(showCountdown: options.showCountDown);
    _verboseGameLogger.setEnabled(options.verboseLogMode);
    
    // Log game options with new format
    if (options.verboseLogMode) {
      _verboseGameLogger.logFlagOptions(options.toJson());
    }
    
    _changeState(GameState.newGameStarting);
  }
  
  /// Handle showing instructions
  void _handleShowingInstructions() {
    // Instructions are handled by UI via dialog sequence
  }
  
  /// Handle showing options
  void _handleShowingOptions() {
    // Options are handled by UI via dialog sequence
  }
  
  /// Handle new game initialization
  void _handleNewGameStarting() {
    // Reset game state
    _currentRound = 0;
    _computerCard = null;
    _userCard = null;
    _currentRoundProbabilities = null;
    _allRoundProbabilities.clear(); // Clear stored probabilities
    _currentUserGuess = null;
    _isDialogSequenceActive = false;
    _currentDialogSequenceData = null;
    _hintStartTime = null;
    _currentHintType = null;

    // Generate seed from timestamp for reproducibility
    _gameSeed = DateTime.now().millisecondsSinceEpoch;
    _random = Random(_gameSeed!);

    // Log game start with new format
    if (_gameOptions.verboseLogMode) {
      _verboseGameLogger.logGameStart();
    }

    // Reset components
    _scoreCalculator.reset();
    _statisticsReporter.reset();
    _stageStackManager.reset();
    _timerHelper.reset();

    /*
    // Reset tracking
    _consecutiveMissedHighProbCount = 0;
    _highProbMissedLast3Rounds.fillRange(0, 3, false);
    */

    // Create full deck
    _allCards = DeckManager.createFullDeck();

    _changeState(GameState.shuffling);
  }
  
  /// Handle shuffling
  void _handleShuffling() {
    _shuffleDeck(isInitialShuffle: true);
    _changeState(GameState.dealing);
  }
  
  /// Handle dealing cards
  void _handleDealing() {
    if (_currentRound >= 27) {
      _changeState(GameState.showingReports);
      return;
    }
    
    _currentRound++;
    _roundStartTime = DateTime.now();
    
    // Deal two cards
    _dealCards();
    
    // Reveal computer card
    if (_computerCard != null) {
      _computerCard!.status = CardStatus.revealed;
    }
    
    // Calculate probabilities
    if (_computerCard != null && _userCard != null) {
      _currentRoundProbabilities = _probabilityCalculator.calculateRoundProbabilities(
        allCards: _allCards,
        computerCard: _computerCard!,
        userCard: _userCard!,
        roundNumber: _currentRound,
      );
      
      // Store the probability data for baseline calculation
      if (_currentRoundProbabilities != null) {
        _allRoundProbabilities.add(_currentRoundProbabilities!);
      }
    }
    
    // Log round start after computer card is revealed (new format)
    if (_gameOptions.verboseLogMode && _computerCard != null) {
      _verboseGameLogger.logRoundStart(
        roundNumber: _currentRound,
        roundStartTime: _roundStartTime!,
      );
    }
    
    _changeState(GameState.waitingForGuess);
  }
  
  /// Handle waiting for user guess
  void _handleWaitingForGuess() {
    // Start the timer
    _timerHelper.start();
  }
  
  /// Handle processing user guess
  void _handleProcessingGuess() {
    // Stop the timer
    _timerHelper.pause();
    _roundEndTime = DateTime.now();
    
    // Determine round result
    final isCorrect = _currentRoundProbabilities?.isGuessCorrect(_currentUserGuess!) ?? false;
    final isObviousMistake = _currentRoundProbabilities?.isObviousMistake(_currentUserGuess!) ?? false;
    
    // Update stage/stack manager
    final result = isCorrect ? RoundResult.win : RoundResult.missed;
    _stageStackManager.updateRoundResult(_currentRound, result);
    
    // Add completed stages and stacks to statistics reporter
    final updatedStage = _stageStackManager.getStageForRound(_currentRound);
    if (updatedStage != null && updatedStage.isComplete) {
      _statisticsReporter.addStageData(updatedStage);
    }
    
    final updatedStack = _stageStackManager.getStackForRound(_currentRound);
    if (updatedStack != null && updatedStack.isComplete) {
      _statisticsReporter.addStackData(updatedStack);
    }
    
    // Calculate score
    final scoreEntry = _scoreCalculator.calculateRoundScore(
      roundNumber: _currentRound,
      probabilityData: _currentRoundProbabilities!,
      userGuess: _currentUserGuess!,
    );

    // DEBUG: The tracker should have been updated by calculateRoundScore
    UIDebugLogger.logDialog('GameManager._handleProcessingGuess', 
      'After calculateRoundScore, missedHighProbTracker: '
      'shouldShowWarning=${_scoreCalculator.shouldShowMissedHighProbWarning()}');
    
    // Log user guess event with new format
    if (_gameOptions.verboseLogMode && _computerCard != null && _userCard != null) {
      _verboseGameLogger.logUserGuess(
        guessTime: _roundEndTime!,
        guess: _currentUserGuess!.displayName,
        correctAnswer: _currentRoundProbabilities!.correctAnswer!.displayName,
        result: isCorrect ? 'win' : 'missed',
        scoreData: {
          'baseScore': scoreEntry.baseScore,
          'totalScore': scoreEntry.totalScore,
          'bonuses': scoreEntry.bonuses,
          'scoreCategory': scoreEntry.scoreCategory,
          'roundCategory': scoreEntry.roundCategory,
          'isCounterIntuitive': scoreEntry.isCounterIntuitive,
          'isObviousMistake': scoreEntry.isObviousMistake,
          'bonusPoints': scoreEntry.bonuses.values.fold(0, (sum, val) => sum + (val as int)),
          'bonusDescriptions': scoreEntry.bonuses.keys.toList(),
        },
        probabilityData: _currentRoundProbabilities!,
        computerCard: _computerCard!.displayNameWithSuit,
        userCard: _userCard!.displayNameWithSuit,
      );
    }
    
    // Update statistics
    if (_computerCard != null && _userCard != null) {
      _statisticsReporter.addRoundData(
        roundNumber: _currentRound,
        computerCard: _computerCard!,
        userCard: _userCard!,
        userGuess: _currentUserGuess,
        probabilityData: _currentRoundProbabilities!,
        scoreEntry: scoreEntry,
      );
    }
    
    // Log round completion
    if (_gameOptions.verboseLogMode) {
      // Round completion is now logged in logUserGuess
    }
    
    // Check for obvious mistakes (case 3: consecutive missed high prob), 
    // REMOVE this line (now handled by score calculator):
    // _updateHighProbMissedTracking(isCorrect);
    
    // Reveal user card
    if (_userCard != null) {
      _userCard!.status = CardStatus.revealed;
    }
    
    _changeState(GameState.showingCardFlip);
  }
  
  /// Handle card flip animation
  void _handleShowingCardFlip() {
    // Wait 1 second for card flip animation
    Timer(const Duration(seconds: 1), () {
      _changeState(GameState.showingScore);
    });
  }
  
  /// Handle showing score
  void _handleShowingScore() {
    // Prepare dialog sequence data
    final scoreEntry = _scoreCalculator.scoreHistory.lastWhere(
      (e) => e.roundNumber == _currentRound,
    );
    
    final stage = _stageStackManager.getStageForRound(_currentRound);
    final stack = _stageStackManager.getStackForRound(_currentRound);
    
    final isObviousMistake = _currentRoundProbabilities?.isObviousMistake(_currentUserGuess!) ?? false;

    // DEBUG: Log the warning logic
    UIDebugLogger.logDialog('GameManager._handleShowingScore', 
      'Checking warnings for round $_currentRound:');
    UIDebugLogger.logDialog('GameManager._handleShowingScore', 
      'isObviousMistake=$isObviousMistake');
    UIDebugLogger.logDialog('GameManager._handleShowingScore', 
      'shouldShowMissedHighProbWarning=${_scoreCalculator.shouldShowMissedHighProbWarning()}');
    UIDebugLogger.logDialog('GameManager._handleShowingScore', 
      'showWarnings=${_gameOptions.showWarnings}');


    // final showWarning = isObviousMistake && _gameOptions.showWarnings;
    final showWarning = (isObviousMistake && _gameOptions.showWarnings) ||
                     (_scoreCalculator.shouldShowMissedHighProbWarning() && _gameOptions.showWarnings);

    UIDebugLogger.logDialog('GameManager._handleShowingScore', 
      'showWarning=$showWarning');
    
    // Increment warning dialog counter when warning is shown
    if (showWarning && _gameOptions.showWarnings) {
      if (_scoreCalculator.shouldShowMissedHighProbWarning()) {
        _scoreCalculator.incrementWarningDialogCount();
      }
    }
    
    _currentDialogSequenceData = {
      'type': 'roundComplete',
      'scoreEntry': scoreEntry.toJson(),
      'stage': stage.isComplete ? stage.toJson() : null,
      'stack': (stack != null && stack.isComplete) ? stack.toJson() : null,
      'showWarning': showWarning,
      'warningMessage': _getWarningMessage(),
      'warningTitle': _getWarningTitle(),
      'gameOptions': _gameOptions.toJson(),
    };
    
    _changeState(GameState.showingDialogSequence);
  }
  
  /// Handle showing dialog sequence
  void _handleShowingDialogSequence() {
    if (_currentDialogSequenceData != null && !_isDialogSequenceActive) {
      _isDialogSequenceActive = true;
      _dialogSequenceController.add(_currentDialogSequenceData!);
    }
  }
  
  /// Notify that dialog sequence is complete
  Future<void> onDialogSequenceComplete() async {
    UIDebugLogger.logDialog('GameManager.onDialogSequenceComplete', 
      'Called, _currentState=$_currentState, _isDialogSequenceActive=$_isDialogSequenceActive');
    
    if (_currentDialogSequenceData != null) {
      UIDebugLogger.logDialog('GameManager.onDialogSequenceComplete', 
        'Current dialog type: ${_currentDialogSequenceData!['type']}');
    }
    
    _isDialogSequenceActive = false;
    
    // Save the dialog type before clearing the data
    final dialogType = _currentDialogSequenceData?['type'];
    _currentDialogSequenceData = null;

    // Determine next state based on current context
    if (_currentState == GameState.showingDialogSequence) {
      UIDebugLogger.logDialog('GameManager.onDialogSequenceComplete', 
        'Checking dialog type: $dialogType');
      
      // Check what type of dialog sequence just completed
      if (dialogType == 'gameComplete') {
          UIDebugLogger.logDialog('onDialogSequenceComplete in game_manager.dart', 'gameComplete');
          
          // Log game complete event with new format
          UIDebugLogger.logDialog('onDialogSequenceComplete in game_manager.dart', 
            '_gameOptions.verboseLogMode=$_gameOptions.verboseLogMode');
          
          if (_gameOptions.verboseLogMode) {
            UIDebugLogger.logDialog('onDialogSequenceComplete in game_manager.dart', 
              'Generating all reports for gameComplete');
            final allReports = _statisticsReporter.generateAllReports();
            final totalScore = _scoreCalculator.totalScore;
            final baseline = _scoreCalculator.calculateBaselineScore(getAllRoundProbabilities());
            
            UIDebugLogger.logDialog('onDialogSequenceComplete in game_manager.dart', 
              'Calling _verboseGameLogger.logGameComplete');
            
            await _verboseGameLogger.logGameComplete(
              finalScores: {
                'totalScore': totalScore,
                'baselineScore': baseline,
                'reports': allReports,
              },
            );
            
            UIDebugLogger.logDialog('onDialogSequenceComplete in game_manager.dart', 
              '_verboseGameLogger.logGameComplete completed');
          } else {
            UIDebugLogger.logDialog('onDialogSequenceComplete in game_manager.dart', 
              'verboseLogMode is disabled, skipping logGameComplete');
          }
          
          // Game completion sequence just finished - go back to options
          _changeState(GameState.showingOptions);
      } else if (_currentRound >= 27) {
        UIDebugLogger.logDialog('onDialogSequenceComplete in game_manager.dart', '_currentRound >= 27');
        // Last round just completed - show reports
        _changeState(GameState.showingReports);
      } else {
        UIDebugLogger.logDialog('onDialogSequenceComplete in game_manager.dart', 'betweenRounds');
        // Regular round completed - prepare for next round
        _changeState(GameState.betweenRounds);
      }
    }
  }
  
  /// Handle between rounds
  void _handleBetweenRounds() {
    // Prepare for next round
    _computerCard = null;
    _userCard = null;
    _currentRoundProbabilities = null;
    _currentUserGuess = null;
    _hintStartTime = null;
    _currentHintType = null;

    // Check if game is complete
    if (_currentRound >= 27) {
      // All rounds completed - show reports
      _changeState(GameState.showingReports);
    } else {
      // Small delay before next round
      Timer(const Duration(milliseconds: 1000), () {
        _changeState(GameState.dealing);
      });
    }
  }
  
  /// Handle showing reports
  void _handleShowingReports() {
    // Set warning dialog count before generating reports
    _statisticsReporter.setWarningDialogCount(_scoreCalculator.warningDialogShownCount);
    
    // Generate all reports
    final allReports = _statisticsReporter.generateAllReports();
    
    // Prepare final scores dialog sequence
    final totalScore = _scoreCalculator.totalScore;
    
    UIDebugLogger.logDialog('GameManager._handleShowingReports', 
      'Calculating baseline score');
    
    final allRoundProbabilities = getAllRoundProbabilities();
    UIDebugLogger.logDialog('GameManager._handleShowingReports', 
      'Total rounds: ${allRoundProbabilities.length}');
    
    final baseline = _scoreCalculator.calculateBaselineScore(allRoundProbabilities);
    UIDebugLogger.logDialog('GameManager._handleShowingReports', 
      'Baseline score calculated: $baseline');
    
    _currentDialogSequenceData = {
      'type': 'gameComplete',
      'reports': allReports,
      'totalScore': totalScore,
      'baseline': baseline,
      'gameOptions': _gameOptions.toJson(),
    };
    
    _changeState(GameState.showingDialogSequence);
  }
  
  /// Handle showing final scores
  void _handleShowingFinalScores() {
    // Final scores are shown in dialog sequence
  }
  
  // --- Game Actions ---
  
  /// User makes a guess
  void makeGuess(UserGuess guess) {
    if (_currentState != GameState.waitingForGuess) return;
    
    _currentUserGuess = guess;
    _changeState(GameState.processingGuess);
  }
  
  /// User requests a hint - opened
  void requestHint(String hintType) {
    if (_computerCard == null || _userCard == null) return;
    
    // Track hint start time for duration calculation
    _hintStartTime = DateTime.now();
    _currentHintType = hintType;
    
    // Calculate hint info
    final hintInfo = _probabilityCalculator.calculateHintInfo(
      allCards: _allCards,
      computerCard: _computerCard!,
      userCard: _userCard!,
      roundNumber: _currentRound,
      hintType: hintType,
    );
    
    _hintController.add(hintInfo);
  }
  
  /// User closes a hint dialog
  void hintClosed() {
    if (_hintStartTime != null && _currentHintType != null) {
      final hintEndTime = DateTime.now();
      final hintDuration = hintEndTime.difference(_hintStartTime!);
      
      // Calculate hint info for logging
      if (_computerCard != null && _userCard != null) {
        final hintInfo = _probabilityCalculator.calculateHintInfo(
          allCards: _allCards,
          computerCard: _computerCard!,
          userCard: _userCard!,
          roundNumber: _currentRound,
          hintType: _currentHintType!,
        );
        
        if (_gameOptions.verboseLogMode) {
          _verboseGameLogger.logHint(
            hintType: _currentHintType!,
            hintStartTime: _hintStartTime!,
            hintEndTime: hintEndTime,
          );
        }
      }
      
      // Reset hint tracking
      _hintStartTime = null;
      _currentHintType = null;
    }
  }
  
  /// User requests shuffle
  void requestShuffle() {
    if (_currentState != GameState.waitingForGuess) return;
    
    _shuffleDeck(isInitialShuffle: false);
    
    // Show shuffle dialog
    _shuffleController.add({
      'shuffleNumber': _shuffleCount,
      'shuffleTime': DateTime.now().toIso8601String().substring(0, 19).replaceFirst('T', ' '), // YYYY-MM-DD HH:mm:ss
      'shuffleSeed': _gameSeed?.toString() ?? 'unknown',
      'gameSpeed': _gameOptions.gameSpeed,
    });
    
    // Recalculate probabilities after shuffle
    if (_computerCard != null && _userCard != null) {
      _currentRoundProbabilities = _probabilityCalculator.calculateRoundProbabilities(
        allCards: _allCards,
        computerCard: _computerCard!,
        userCard: _userCard!,
        roundNumber: _currentRound,
      );
    }
  }
  
  /// User clicks any button
  void logButtonClick(String buttonName) {
    // Button click logging removed - not needed in new format
  }
  
  // --- Helper Methods ---
  
  /// Shuffle the deck
  void _shuffleDeck({required bool isInitialShuffle}) {
    if (_random == null) {
      throw StateError('Random instance not initialized. Game seed not set.');
    }

    // Get indices of cards that are in deck
    final deckIndices = <int>[];
    for (int i = 0; i < _allCards.length; i++) {
      if (_allCards[i].status == CardStatus.inDeck) {
        deckIndices.add(i);
      }
    }

    // Record deck before shuffle for logging
    final beforeShuffle = deckIndices.map((i) => _allCards[i].displayNameWithSuit).toList();

    // Fisher-Yates shuffle using seeded random - swap actual cards in _allCards
    for (int i = deckIndices.length - 1; i > 0; i--) {
      final j = _random!.nextInt(i + 1);
      // Swap cards in _allCards using the indices
      final temp = _allCards[deckIndices[i]];
      _allCards[deckIndices[i]] = _allCards[deckIndices[j]];
      _allCards[deckIndices[j]] = temp;
    }

    // Record deck after shuffle
    final afterShuffle = deckIndices.map((i) => _allCards[i].displayNameWithSuit).toList();

    // Get the shuffled deck cards for analysis
    final deckCards = deckIndices.map((i) => _allCards[i]).toList();

    // Analyze deck composition
    final predictions = _probabilityCalculator.analyzeDeckComposition(deckCards);

    // Analyze shuffle luck
    _shuffleCount++;
    final shuffleAnalysis = _shuffleAnalyzer.analyzeShuffle(
      allCards: _allCards,
      currentRound: _currentRound,
      shuffleNumber: _shuffleCount,
      isInitialShuffle: isInitialShuffle,
    );

    // Add to statistics reporter
    _statisticsReporter.addShuffleAnalysis(shuffleAnalysis);

    // Log shuffle with the new format
    if (_gameOptions.verboseLogMode) {
      _verboseGameLogger.logShuffle(
        cardsInDeck: deckCards.length,
        cardSequenceBefore: beforeShuffle,
        cardSequenceAfter: afterShuffle,
        predictions: shuffleAnalysis.toJson(),
        shuffleSeed: _gameSeed!,
        roundNumber: _currentRound,
      );
    }
  }
  
  /// Deal cards for current round
  void _dealCards() {
    if (cardsInDeck.length < 2) {
      throw StateError('Not enough cards in deck to deal');
    }
    
    // Take first two cards from deck
    _computerCard = cardsInDeck[0];
    _userCard = cardsInDeck[1];
    
    // Update card status
    _computerCard!.status = CardStatus.dealed;
    _userCard!.status = CardStatus.dealed;
  }

  /// Update stage with 8gua data
  void _updateStageWithGua8Data(StageModel stage) {
    if (stage.binaryResult == null) return;
    
    final gua8Data = Gua8Data.get8Gua(stage.binaryResult!);
    if (gua8Data != null) {
      // Update the stage with gua data
      // Note: In a real implementation, we'd need to update the stage model
      // This would require modifying the StageModel class or using a different approach
      
      // Example of what you might do:
      // stage.guaName = gua8Data.name_zh;
      // stage.guaSymbol = gua8Data.symbol;
      // stage.nature = gua8Data.nature_en;
    }
  }

  
  /// Update stack with 64gua data
  void _updateStackWithGua64Data(StackModel stack) {
    if (stack.binaryResult == null) return;
    
    final gua64Data = Gua64Data.get64Gua(stack.binaryResult!);
    if (gua64Data != null) {
      // Update the stack with gua data
      // Note: Similar to above, would need model updates
    }
  }
  
  /*
  /// Update tracking for consecutive missed high probability rounds
  void _updateHighProbMissedTracking(bool isCorrect) {
    // Shift the tracking array
    for (int i = 2; i > 0; i--) {
      _highProbMissedLast3Rounds[i] = _highProbMissedLast3Rounds[i - 1];
    }
    
    // Check if this round was a missed high probability opportunity
    final wasHighProbMissed = _checkIfHighProbMissedThisRound(isCorrect);
    _highProbMissedLast3Rounds[0] = wasHighProbMissed;
    
    if (wasHighProbMissed) {
      _consecutiveMissedHighProbCount++;
    } else {
      _consecutiveMissedHighProbCount = 0;
    }
  }
  */
  
  /*
  /// Check if high probability was missed this round
  bool _checkIfHighProbMissedThisRound(bool isCorrect) {
    if (_currentRoundProbabilities == null || _currentUserGuess == null) {
      return false;
    }
    
    // Check if correct answer had high probability (>= 50%)
    final correctProb = _currentRoundProbabilities!.correctAnswerProbability;
    if (correctProb < 0.5) return false;
    
    // Check if user didn't select the correct answer
    final isCorrectGuess = _currentRoundProbabilities!.isGuessCorrect(_currentUserGuess!);
    return !isCorrectGuess;
  }
  */
  
  /*
  /// Check for 3 consecutive missed high probability rounds
  bool _checkConsecutiveMissedHighProb() {
    return _highProbMissedLast3Rounds.every((missed) => missed);
  }
  */
  
  /*
  /// Get warning message for obvious mistakes
  String _getWarningMessage() {
    if (_checkConsecutiveMissedHighProb()) {
      return 'Missed high probability option for 3 consecutive rounds!';
    }
    
    final isObviousMistake = _currentRoundProbabilities?.isObviousMistake(_currentUserGuess!) ?? false;
    if (isObviousMistake) {
      return 'You selected an option with 0% probability, or missed a 100% probability option.';
    }
    
    return 'Obvious mistake detected!';
  }
  */

  // UPDATE this method to use the score calculator:
  /// Get warning message for obvious mistakes
  String _getWarningMessage() {

    // Check for consecutive missed high probability first
    UIDebugLogger.logDialog('GameManager._getWarningMessage',
      'Checking missedHighProbTracker: shouldShowWarning=${_scoreCalculator.shouldShowMissedHighProbWarning()}');

    if (_scoreCalculator.shouldShowMissedHighProbWarning()) {
      final warning = _scoreCalculator.getMissedHighProbWarningMessage();
      UIDebugLogger.logDialog('GameManager._getWarningMessage',
        'Returning high prob warning: $warning');
      return warning;
    }

    final isObviousMistake = _currentRoundProbabilities?.isObviousMistake(_currentUserGuess!) ?? false;

    UIDebugLogger.logDialog('GameManager._getWarningMessage',
      'isObviousMistake=$isObviousMistake');

    if (isObviousMistake) {
      if (_currentRoundProbabilities != null && _currentUserGuess != null) {
        final warning = _scoreCalculator.getObviousMistakeWarningMessage(
          _currentRoundProbabilities!,
          _currentUserGuess!,
        );
        UIDebugLogger.logDialog('GameManager._getWarningMessage',
        'Returning obvious mistake warning: $warning');
        return warning;
      }
      return 'You selected an option with 0% probability, or missed a 100% probability option.';
    }

    UIDebugLogger.logDialog('GameManager._getWarningMessage',
      'No warning to show');

    return 'Obvious mistake detected!';
  }

  /// Get warning title
  String _getWarningTitle() {
    if (_scoreCalculator.shouldShowMissedHighProbWarning()) {
      return 'Continuous missed high-probability answers';
    }
    return 'Obvious Mistake!';
  }

  /// Get all round probabilities (for baseline calculation)
  List<RoundProbabilityData> getAllRoundProbabilities() {
    return _allRoundProbabilities;
  }
  
  // --- Public Getters ---
  
  /// Get current game statistics
  Map<String, dynamic> get gameStatistics => _statisticsReporter.generateAllReports();
  
  /// Get statistics reporter
  StatisticsReporter get statisticsReporter => _statisticsReporter;
  
  /// Get score calculator
  ScoreCalculator get scoreCalculator => _scoreCalculator;
  
  /// Get verbose game logger
  VerboseGameLogger get verboseGameLogger => _verboseGameLogger;
  
  /// Get timer helper
  TimerHelper get timerHelper => _timerHelper;
  
  /// Get stage stack manager
  StageStackManager get stageStackManager => _stageStackManager;
  
  /// Get current round probabilities
  RoundProbabilityData? get currentRoundProbabilities => _currentRoundProbabilities;
  
  /// Check if dialog sequence is active
  bool get isDialogSequenceActive => _isDialogSequenceActive;
  
  /// Clean up resources
  void dispose() {
    _stateController.close();
    _dialogSequenceController.close();
    _hintController.close();
    _shuffleController.close();
    _timerHelper.dispose();
    exit(0);
  }
}



