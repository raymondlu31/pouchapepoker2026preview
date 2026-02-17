

import 'package:flutter/material.dart';
import 'dart:convert';
import '../../game_manager.dart';
import '../../core/models/user_guess.dart';
import '../../core/models/game_state.dart';
import '../../core/models/flag_options.dart';
import '../../core/models/score_entry.dart';
import '../../core/models/stage_model.dart';
import '../../helper/timer_helper.dart';
import '../../helper/ui_debug_logger.dart';
import '../../helper/message_order.dart';
import '../../helper/verbose_game_logger.dart';
import '../widgets/card_widget.dart';
import '../widgets/countdown_timer_widget.dart';
import '../widgets/game_buttons.dart';
import '../widgets/dialogs/game_options_dialog.dart';
import '../widgets/dialogs/message_dialogs.dart';
import '../styles/game_colors.dart';

class PokerGameScreen extends StatefulWidget {
  const PokerGameScreen({super.key});

  @override
  State<PokerGameScreen> createState() => _PokerGameScreenState();
}

class _PokerGameScreenState extends State<PokerGameScreen> {
  late GameManager _gameManager;
  UserGuess? _selectedGuess;
  DialogSequencer? _dialogSequencer;
  bool _isInitialSequenceComplete = false;
  bool _isInitializing = true;


  @override
  void initState() {
    super.initState();
    
    UIDebugLogger.startSection('PokerGameScreen Initialization');
    UIDebugLogger.logStateChange('PokerGameScreen', 'none', 'initializing');
    
    _gameManager = GameManager();
    _setupGameManagerListeners();
    
    // Log the initial state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      UIDebugLogger.logStateChange('PokerGameScreen', 'initState', 'post-frame');
      UIDebugLogger.logLayout('Initial Layout', 
        Size(MediaQuery.of(context).size.width, MediaQuery.of(context).size.height), 
        const BoxConstraints(),
        'Context mounted: ${context.mounted}');
    });
    
    UIDebugLogger.endSection();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    UIDebugLogger.logStateChange('PokerGameScreen', 'init', 'didChangeDependencies');

    // Initialize dialog sequencer

    if (_dialogSequencer == null) {
      _dialogSequencer = DialogSequencer(
        context: context,
        options: _gameManager.gameOptions,
        onSequenceComplete: _onDialogSequenceComplete,
      );
      _isInitializing = false;
      
      // Check if we need to show initial dialogs
      if (_gameManager.currentState == GameState.showingInstructions) {
        _startInitialDialogSequence();
      }
    }
    
    UIDebugLogger.logStateChange('PokerGameScreen', 'didChangeDependencies', 'completed');
  }

  void _setupGameManagerListeners() {
    // Listen for state changes
    _gameManager.stateStream.listen((state) {
      UIDebugLogger.logStateChange('GameManager Stream', _gameManager.currentState.toString(), state.toString());
      
      if (mounted) {
        setState(() {
          UIDebugLogger.logStateChange('GameManager', _gameManager.currentState.toString(), state.toString());
          
          // Reset selected guess when state changes
          if (state != GameState.waitingForGuess) {
            _selectedGuess = null;
          }
          
          // Handle specific states that require UI action
          if (state == GameState.showingInstructions && !_isInitialSequenceComplete) {
            _startInitialDialogSequence();
          } else if (state == GameState.showingDialogSequence) {
            // Dialog sequence will be triggered by the dialogSequenceStream
          }
        });
      } else {
        UIDebugLogger.logStateChange('GameManager', 'mounted=false', 'skip update');
      }
    });

    // Listen for dialog sequence requests
    _gameManager.dialogSequenceStream.listen((data) {
      if (mounted && _dialogSequencer != null && !_dialogSequencer!.isRunning) {
        _handleDialogSequenceRequest(data);
      }
    });

    // Listen for hints
    _gameManager.hintStream.listen((hintInfo) {
      // Handle hint display
      UIDebugLogger.logDialog('Hint', 'Received: ${hintInfo['type']}');
      if (mounted && hintInfo['type'] == 'basic') {
        _showBasicHintDialog(hintInfo);
      }
    });

    // Listen for shuffles
    _gameManager.shuffleStream.listen((shuffleInfo) {
      // Handle shuffle dialog display
      if (mounted) {
        _showShuffleDialog(shuffleInfo);
      }
    });
  }

  void _startInitialDialogSequence() {
    if (_dialogSequencer == null || _dialogSequencer!.isRunning) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final sequence = DialogSequenceFactory.createInitialSequence(
        _gameManager.gameOptions,
        _gameManager.gameOptions,
        (options) {
          UIDebugLogger.logDialog('GameOptionsDialog', 'options changed');
          _gameManager.startNewGame(options);
          _isInitialSequenceComplete = true;
        },
      );
      
      _dialogSequencer!.startSequence(sequence);
    });
  }

  void _handleDialogSequenceState() {
    // This is called when game enters showingDialogSequence state
    // We need to check if we should show a sequence
    if (_dialogSequencer == null || _dialogSequencer!.isRunning) return;
    
    // The actual sequence will be triggered by dialogSequenceStream
    // This is just a safety check
  }

  void _handleDialogSequenceRequest(Map<String, dynamic> data) {
    if (_dialogSequencer == null || _dialogSequencer!.isRunning) return;

    final sequenceType = data['type'];
    List<DialogConfig> sequence = [];

    try{
    
      switch (sequenceType) {
        case 'roundComplete':
          final scoreEntry = ScoreEntry.fromJson(data['scoreEntry']);
          final stageData = data['stage'];
          final stackData = data['stack'];
          final showWarning = data['showWarning'] ?? false;
          final warningMessage = data['warningMessage'] ?? '';
          final warningTitle = data['warningTitle'] ?? '';
          final options = FlagOptions.fromJson(data['gameOptions']);

          final StageModel? stage = stageData != null ?
              StageModel.fromJson(stageData) : null;
          final StackModel? stack = stackData != null ?
              StackModel.fromJson(stackData) : null;

          sequence = DialogSequenceFactory.createRoundCompleteSequence(
            scoreEntry: scoreEntry,
            options: options,
            stage: stage,
            stack: stack,
            showWarning: showWarning,
            warningMessage: warningMessage,
            warningTitle: warningTitle,
            stageStackManager: _gameManager.stageStackManager,
          );
          break;
          
        case 'gameComplete':
          final reports = data['reports'] as Map<String, dynamic>;
          final totalScore = data['totalScore'] as int;
          final baseline = data['baseline'] as int;
          final options = FlagOptions.fromJson(data['gameOptions']);
          
          sequence = DialogSequenceFactory.createGameCompleteSequence(
            reports: reports,
            totalScore: totalScore,
            baseline: baseline,
            options: options,
            // onPlayAgain: _handlePlayAgain,
            onExit: _handleExit,
          );
          break;
          
        default:
          UIDebugLogger.logDialog('DialogSequence', 'Unknown type: $sequenceType');
          return;
      }
      
      _dialogSequencer!.startSequence(sequence);
    } catch (e) {
      UIDebugLogger.logDialog('DialogSequence', 'Error creating sequence: $e');
    }
  }

  Future<void> _onDialogSequenceComplete() async {
    if (_gameManager.currentState == GameState.showingDialogSequence) {
      await _gameManager.onDialogSequenceComplete();
    }
  }


  void _showInstructionsDialog() {
    if (_dialogSequencer == null || _dialogSequencer!.isRunning) return;
    
    final sequence = [
      DialogConfig(
        builder: (context) => InstructionDialog(
          autoCloseDuration: _gameManager.gameOptions.autoCloseDuration,
        ),
        autoCloseDuration: _gameManager.gameOptions.autoCloseDuration,
        type: 'instruction',
      ),
    ];
    
    _dialogSequencer!.startSequence(sequence);
  }

  void _showBasicHintDialog(Map<String, dynamic> hintInfo) {
    showDialog(
      context: context,
      builder: (context) => BasicHintDialog(
        probabilities: hintInfo,
        onGameHistory: () => _showGameHistoryHintDialog(),
        onUnrevealedCards: () => _showUnrevealedCardsHintDialog(),
      ),
    );
  }

  void _showGameHistoryHintDialog() {
    // Get game history from statistics reporter
    final history = _gameManager.statisticsReporter.getGameHistory();
    
    showDialog(
      context: context,
      builder: (context) => GameHistoryHintDialog(
        history: history,
      ),
    );
  }

  void _showUnrevealedCardsHintDialog() {
    // Get unrevealed cards
    final unrevealedCards = _getUnrevealedCards();
    
    showDialog(
      context: context,
      builder: (context) => UnrevealedCardsHintDialog(
        unrevealedCards: unrevealedCards,
      ),
    );
  }

  void _showShuffleDialog(Map<String, dynamic> shuffleInfo) {
    showDialog(
      context: context,
      builder: (context) => ShuffleDialog(
        shuffleNumber: shuffleInfo['shuffleNumber'] as int,
        shuffleTime: shuffleInfo['shuffleTime'] as String,
        shuffleSeed: shuffleInfo['shuffleSeed'] as String,
        gameSpeed: shuffleInfo['gameSpeed'] as int,
      ),
    );
  }

  List<Map<String, dynamic>> _getUnrevealedCards() {
    final cards = _gameManager.cardsInDeck + _gameManager.cardsDealed;
    
    // Sort by suit and value
    final sortedCards = List<Map<String, dynamic>>.from(cards.map((card) {
      return {
        'name': card.displayNameWithSuit,
        'suit': card.suit?.displayName,
        'value': card.value,
      };
    }).toList());
    
    // Sort: first by suit (Spade, Heart, Diamond, Club), then by value
    sortedCards.sort((a, b) {
      final suitOrder = {'Spade': 0, 'Heart': 1, 'Diamond': 2, 'Club': 3, null: 4};
      final suitA = suitOrder[a['suit']] ?? 4;
      final suitB = suitOrder[b['suit']] ?? 4;
      
      if (suitA != suitB) {
        return suitA.compareTo(suitB);
      }
      return a['value'].compareTo(b['value']);
    });
    
    return sortedCards;
  }



  void _makeGuess(UserGuess guess) {
    UIDebugLogger.logGesture('GuessSelection', 'Selected: ${guess.displayName}');
    setState(() {
      _selectedGuess = guess;
    });
    _gameManager.makeGuess(guess);
  }

  /*

  void _handlePlayAgain() async {
    UIDebugLogger.logGesture('FinalScoresDialog', 'Play Again pressed');

    // Save logs before exiting
    await VerboseGameLogger.instance.exportLogs();

    // Restart the game with same settings
    _gameManager.restartGame();
  }
  */

  void _handleExit() async {
    UIDebugLogger.logGesture('FinalScoresDialog', 'Exit pressed');
    
    // Log game complete first (this will call exportLogs internally)
    if (_gameManager.gameOptions.verboseLogMode) {
      UIDebugLogger.logDialog('_handleExit', 'Calling logGameComplete');
      
      final allReports = _gameManager.gameStatistics;
      final totalScore = _gameManager.scoreCalculator.totalScore;
      final baseline = _gameManager.scoreCalculator.calculateBaselineScore(_gameManager.getAllRoundProbabilities());
      
      await _gameManager.verboseGameLogger.logGameComplete(
        finalScores: {
          'totalScore': totalScore,
          'baselineScore': baseline,
          'reports': allReports,
        },
      );
      
      UIDebugLogger.logDialog('_handleExit', 'logGameComplete completed');
    }
    
    // Exit the application
    _gameManager.dispose();
  }



  @override
  Widget build(BuildContext context) {
    // Enable UI debugging based on game options
    UIDebugLogger.setEnabled(_gameManager.gameOptions.verboseLogMode);

    // Show loading indicator while initializing
    if (_isInitializing) {
      return Scaffold(
        backgroundColor: GameColors.background,
        body: Center(
          child: CircularProgressIndicator(
            color: GameColors.primaryGreen,
          ),
        ),
      );
    }
    
    return Scaffold(
      backgroundColor: GameColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top Section (Score & Timer)
            _buildTopSection().withBuildLogging('TopSection'),
            
            // Content Section (3 columns)
            Expanded(
              child: _buildContentSection().withBuildLogging('ContentSection'),
            ),
            
            // Bottom Controls
            _buildBottomControls().withBuildLogging('BottomControls'),
          ],
        ).withBuildLogging('MainColumn'),
      ).withBuildLogging('ScaffoldBody'),
    ).withBuildLogging('PokerGameScreen');
  }

  Widget _buildTopSection() {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: GameColors.primaryPurple,
        border: Border.all(color: GameColors.textWhite, width: 2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Score Display
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'SCORE',
                style: TextStyle(
                  fontSize: 14,
                  color: GameColors.textWhite,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${_gameManager.scoreCalculator.totalScore}',
                style: const TextStyle(
                  fontSize: 32,
                  color: GameColors.textWhite,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ).withBuildLogging('ScoreDisplay'),

          // Round Info
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Round ${_gameManager.currentRound}/27',
                style: const TextStyle(
                  fontSize: 18,
                  color: GameColors.textWhite,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (_gameManager.roundInfo.stageLetter.isNotEmpty)
                Text(
                  'Stage ${_gameManager.roundInfo.stageLetter}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: GameColors.textWhite,
                  ),
                ),
            ],
          ).withBuildLogging('RoundInfo'),

          // Timer
          StreamBuilder<TimerState>(
            stream: _gameManager.timerHelper.stateStream,
            builder: (context, snapshot) {
              final timerState = snapshot.data ?? _gameManager.timerHelper.currentState;
              return CountdownTimerWidget(
                timerState: timerState,
                showCountdown: _gameManager.gameOptions.showCountDown,
              ).withBuildLogging('TimerWidget');
            },
          ),
        ],
      ).withLayoutLogging('TopSectionLayout'),
    );
  }

  Widget _buildContentSection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        UIDebugLogger.logLayout('ContentSection', 
          Size(constraints.maxWidth, constraints.maxHeight), 
          constraints);
        
        // Calculate column widths based on available space
        final sideColumnWidth = 150.0;
        final centerColumnWidth = constraints.maxWidth - (2 * sideColumnWidth);
        
        // Log the calculated widths
        if (centerColumnWidth < 200) {
          UIDebugLogger.logLayout('ContentSection', 
            Size(constraints.maxWidth, constraints.maxHeight), 
            constraints,
            'Switching to responsive layout (center: ${centerColumnWidth.toStringAsFixed(1)}px)');
          
          // For narrow screens, use a simpler layout
          return _buildNarrowContentSection();
        }
        
        return Row(
          children: [
            // Left Column: Action Buttons (150px)
            SizedBox(
              width: sideColumnWidth,
              child: Container(
                padding: const EdgeInsets.all(16),
                color: GameColors.background,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ActionButton(
                      icon: Icons.help_outline,
                      label: 'Instructions',
                      onPressed: _showInstructionsDialog,
                      isEnabled: _dialogSequencer != null && !_dialogSequencer!.isRunning,
                    ).withGestureLogging('InstructionsButton'),
                    const SizedBox(height: 20),
                    ActionButton(
                      icon: Icons.shuffle,
                      label: 'Shuffle',
                      onPressed: () => _gameManager.requestShuffle(),
                      isEnabled: _gameManager.currentState == GameState.waitingForGuess,
                    ).withGestureLogging('ShuffleButton'),
                    const SizedBox(height: 20),
                    ActionButton(
                      icon: Icons.lightbulb_outline,
                      label: 'Hint',
                      onPressed: () => _gameManager.requestHint('basic'),
                      isEnabled: _gameManager.currentState == GameState.waitingForGuess,
                    ).withGestureLogging('HintButton'),
                  ],
                ).withLayoutLogging('LeftColumn'),
              ),
            ).withBuildLogging('LeftColumnContainer'),

            // Center Column: Card Display (flexible)
            Expanded(
              child: Container(
                color: GameColors.background,
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Computer Card
                    Column(
                      children: [
                        const Text(
                          'Computer Card',
                          style: TextStyle(
                            fontSize: 18,
                            color: GameColors.textWhite,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        CardWidget(
                          card: _gameManager.computerCard,
                          isFaceUp: true,
                          isComputerCard: true,
                        ).withBuildLogging('ComputerCard'),
                      ],
                    ),

                    // VS Text
                    const Text(
                      'VS',
                      style: TextStyle(
                        fontSize: 32,
                        color: GameColors.textWhite,
                        fontWeight: FontWeight.bold,
                      ),
                    ).withBuildLogging('VSText'),

                    // User Card
                    Column(
                      children: [
                        
                        const SizedBox(height: 10),
                        CardWidget(
                          card: _gameManager.userCard,
                          isFaceUp: _gameManager.currentState != GameState.waitingForGuess,
                          isComputerCard: false,
                        ).withBuildLogging('UserCard'),
                        const Text(
                          'Your Card',
                          style: TextStyle(
                            fontSize: 18,
                            color: GameColors.textWhite,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ).withLayoutLogging('CenterColumn'),
              ),
            ).withBuildLogging('CenterColumnContainer'),

            // Right Column: Guess Buttons (150px)
            SizedBox(
              width: sideColumnWidth,
              child: Container(
                padding: const EdgeInsets.all(16),
                color: GameColors.background,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Your Guess:',
                      style: TextStyle(
                        fontSize: 18,
                        color: GameColors.textWhite,
                        fontWeight: FontWeight.bold,
                      ),
                    ).withBuildLogging('GuessLabel'),
                    const SizedBox(height: 20),
                    GuessButton(
                      // icon: Icons.forest_outlined,
                      guess: UserGuess.higher,
                      onPressed: () => _makeGuess(UserGuess.higher),
                      isSelected: _selectedGuess == UserGuess.higher,
                      isEnabled: _gameManager.currentState == GameState.waitingForGuess,
                    ).withGestureLogging('HigherButton'),
                    const SizedBox(height: 20),
                    GuessButton(
                      // icon: Icons.handshake_outlined,
                      guess: UserGuess.tie,
                      onPressed: () => _makeGuess(UserGuess.tie),
                      isSelected: _selectedGuess == UserGuess.tie,
                      isEnabled: _gameManager.currentState == GameState.waitingForGuess,
                    ).withGestureLogging('TieButton'),
                    const SizedBox(height: 20),
                    GuessButton(
                      // icon: Icons.grass_outlined,
                      guess: UserGuess.lower,
                      onPressed: () => _makeGuess(UserGuess.lower),
                      isSelected: _selectedGuess == UserGuess.lower,
                      isEnabled: _gameManager.currentState == GameState.waitingForGuess,
                    ).withGestureLogging('LowerButton'),
                  ],
                ).withLayoutLogging('RightColumn'),
              ),
            ).withBuildLogging('RightColumnContainer'),
          ],
        );
      },
    );
  }

  Widget _buildNarrowContentSection() {
    // Simple vertical layout for narrow screens
    return SingleChildScrollView(
      child: Container(
        color: GameColors.background,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Cards
            Column(
              children: [
                // Computer Card
                Column(
                  children: [
                    const Text(
                      'Computer Card',
                      style: TextStyle(
                        fontSize: 18,
                        color: GameColors.textWhite,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    CardWidget(
                      card: _gameManager.computerCard,
                      isFaceUp: true,
                      isComputerCard: true,
                    ).withBuildLogging('ComputerCardNarrow'),
                  ],
                ),

                const SizedBox(height: 20),
                const Text(
                  'VS',
                  style: TextStyle(
                    fontSize: 32,
                    color: GameColors.textWhite,
                    fontWeight: FontWeight.bold,
                  ),
                ).withBuildLogging('VSTextNarrow'),
                const SizedBox(height: 20),

                // User Card
                Column(
                  children: [
                    const Text(
                      'Your Card',
                      style: TextStyle(
                        fontSize: 18,
                        color: GameColors.textWhite,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    CardWidget(
                      card: _gameManager.userCard,
                      isFaceUp: _gameManager.currentState != GameState.waitingForGuess,
                      isComputerCard: false,
                    ).withBuildLogging('UserCardNarrow'),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 30),
            
            // Action Buttons
            Column(
              children: [
                ActionButton(
                  icon: Icons.help_outline,
                  label: 'Instructions',
                  onPressed: _showInstructionsDialog,
                  isEnabled: _dialogSequencer != null && !_dialogSequencer!.isRunning,
                ).withGestureLogging('InstructionsButtonNarrow'),
                const SizedBox(height: 10),
                ActionButton(
                  icon: Icons.shuffle,
                  label: 'Shuffle',
                  onPressed: () => _gameManager.requestShuffle(),
                  isEnabled: _gameManager.currentState == GameState.waitingForGuess,
                ).withGestureLogging('ShuffleButtonNarrow'),
                const SizedBox(height: 10),
                ActionButton(
                  icon: Icons.lightbulb_outline,
                  label: 'Hint',
                  onPressed: () => _gameManager.requestHint('basic'),
                  isEnabled: _gameManager.currentState == GameState.waitingForGuess,
                ).withGestureLogging('HintButtonNarrow'),
              ],
            ),

            const SizedBox(height: 30),
            
            // Guess Buttons
            const Text(
              'Your Guess:',
              style: TextStyle(
                fontSize: 18,
                color: GameColors.textWhite,
                fontWeight: FontWeight.bold,
              ),
            ).withBuildLogging('GuessLabelNarrow'),
            const SizedBox(height: 20),
            
            Column(
              children: [
                GuessButton(
                  guess: UserGuess.higher,
                  onPressed: () => _makeGuess(UserGuess.higher),
                  isSelected: _selectedGuess == UserGuess.higher,
                  isEnabled: _gameManager.currentState == GameState.waitingForGuess,
                ).withGestureLogging('HigherButtonNarrow'),
                const SizedBox(height: 10),
                GuessButton(
                  guess: UserGuess.tie,
                  onPressed: () => _makeGuess(UserGuess.tie),
                  isSelected: _selectedGuess == UserGuess.tie,
                  isEnabled: _gameManager.currentState == GameState.waitingForGuess,
                ).withGestureLogging('TieButtonNarrow'),
                const SizedBox(height: 10),
                GuessButton(
                  guess: UserGuess.lower,
                  onPressed: () => _makeGuess(UserGuess.lower),
                  isSelected: _selectedGuess == UserGuess.lower,
                  isEnabled: _gameManager.currentState == GameState.waitingForGuess,
                ).withGestureLogging('LowerButtonNarrow'),
              ],
            ),
          ],
        ).withLayoutLogging('NarrowContentSection'),
      ),
    ).withBuildLogging('NarrowContentContainer');
  }

  Widget _buildBottomControls() {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: GameColors.primaryPurple,
        border: Border.all(color: GameColors.textWhite, width: 2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          /*
          MainButton(
            label: 'New Game',
            onPressed: () => _gameManager.restartGame(),
            backgroundColor: GameColors.secondaryYellow,
            textColor: GameColors.textBlack,
          ).withGestureLogging('NewGameButton'),
          */
          MainButton(
            label: 'Exit',
            onPressed: () => _handleExit(),
            backgroundColor: Colors.red,
            textColor: GameColors.textWhite,
          ).withGestureLogging('ExitButton'),
        ],
      ).withLayoutLogging('BottomControlsLayout'),
    );
  }

  @override
  void dispose() {
    UIDebugLogger.logStateChange('PokerGameScreen', 'active', 'disposed');
    UIDebugLogger.printBuildStats(); // Print build statistics before disposing
    _gameManager.dispose();
    super.dispose();
  }
}





