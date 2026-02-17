import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../core/models/user_guess.dart';
import 'round_probability_data.dart';
import 'ui_debug_logger.dart';

/// Event types for the new logging system
enum EventType {
  gameStart,
  flagOptions,
  shuffleEvent,
  roundStartEvent,
  hintEvent,
  userGuessEvent,
  gameComplete,
}

/// Main logger class - SINGLETON
class VerboseGameLogger {
  // Singleton instance
  static final VerboseGameLogger instance = VerboseGameLogger._internal();
  
  // Factory constructor to return the singleton instance
  factory VerboseGameLogger() => instance;
  
  // Private internal constructor
  VerboseGameLogger._internal() {
    print('VerboseGameLogger singleton initialized');
  }
  
  // Log storage
  final List<Map<String, dynamic>> _logEntries = [];
  
  // Sequence counter for log entries
  int _logSequenceNumber = 0;
  
  // Game state tracking
  bool _enabled = false;
  String? _sessionId;
  DateTime? _gameStartTime;
  Map<String, dynamic>? _flagOptions;
  
  // Shuffle tracking
  int _shuffleSequenceId = 0;
  final List<Map<String, dynamic>> _shuffles = [];
  
  // Round tracking
  int _currentRoundNumber = 0;
  DateTime? _currentRoundStartTime;
  final List<Map<String, dynamic>> _rounds = [];
  final List<Map<String, dynamic>> _currentRoundHints = [];
  
  // Hint tracking
  int _hintSequenceId = 0;
  
  /// Enable/disable logging
  void setEnabled(bool enabled) {
    UIDebugLogger.logDialog('VerboseGameLogger.setEnabled', 
      'Setting enabled to $enabled (was $_enabled)');
    _enabled = enabled;
  }
  
  /// Check if logging is enabled
  bool get isEnabled => _enabled;
  
  /// Get current session ID
  String? get sessionId => _sessionId;
  
  /// Get game start time
  DateTime? get gameStartTime => _gameStartTime;
  
  /// 1. Log game start event
  void logGameStart() {
    UIDebugLogger.logDialog('VerboseGameLogger.logGameStart', 
      'Starting logGameStart, _enabled=$_enabled');
      
    if (!_enabled) {
      UIDebugLogger.logDialog('VerboseGameLogger.logGameStart', 
        'Logging not enabled, returning early');
      return;
    }
    
    _sessionId = DateTime.now().millisecondsSinceEpoch.toString();
    _gameStartTime = DateTime.now();
    
    UIDebugLogger.logDialog('VerboseGameLogger.logGameStart', 
      'sessionId=$_sessionId, gameStartTime=$_gameStartTime');
    
    _writeLogEntry(
      eventType: EventType.gameStart,
      data: {
        'sessionId': _sessionId,
        'gameStartTime': _gameStartTime!.toIso8601String(),
      },
    );
  }
  
  /// 2. Log flag options event
  void logFlagOptions(Map<String, dynamic> options) {
    UIDebugLogger.logDialog('VerboseGameLogger.logFlagOptions', 
      'Starting logFlagOptions, _enabled=$_enabled');
      
    if (!_enabled) {
      UIDebugLogger.logDialog('VerboseGameLogger.logFlagOptions', 
        'Logging not enabled, returning early');
      return;
    }
    
    _flagOptions = options;
    
    UIDebugLogger.logDialog('VerboseGameLogger.logFlagOptions', 
      'flagOptions stored: $_flagOptions');
    
    _writeLogEntry(
      eventType: EventType.flagOptions,
      data: {
        'verboseLogMode': options['verboseLogMode'] as bool? ?? false,
        'showStageDialog': options['showStageDialog'] as bool? ?? false,
        'showCountDown': options['showCountDown'] as bool? ?? false,
        'showWarnings': options['showWarnings'] as bool? ?? false,
        'gameSpeed': options['gameSpeed'] as int? ?? 10,
      },
    );
  }
  
  /// 3. Log shuffle event
  void logShuffle({
    required int cardsInDeck,
    required List<String> cardSequenceBefore,
    required List<String> cardSequenceAfter,
    required Map<String, dynamic> predictions,
    required int shuffleSeed,
    int? roundNumber,
  }) {
    if (!_enabled) return;
    
    _shuffleSequenceId++;
    
    final shuffleData = {
      'shuffleSequenceId': _shuffleSequenceId,
      'shuffleTime': DateTime.now().toIso8601String(),
      'roundNumber': roundNumber ?? 0,
      'shuffleSeed': shuffleSeed,
      'cardsInDeck': cardsInDeck,
      'cardSequenceBefore': cardSequenceBefore,
      'cardSequenceAfter': cardSequenceAfter,
      'predictions': predictions,
    };
    
    _shuffles.add(shuffleData);
    
    _writeLogEntry(
      eventType: EventType.shuffleEvent,
      data: shuffleData,
    );
  }
  
  /// 4. Log round start event
  void logRoundStart({
    required int roundNumber,
    required DateTime roundStartTime,
  }) {
    if (!_enabled) return;
    
    _currentRoundNumber = roundNumber;
    _currentRoundStartTime = roundStartTime;
    _currentRoundHints.clear();
    _hintSequenceId = 0;
    
    _writeLogEntry(
      eventType: EventType.roundStartEvent,
      data: {
        'roundNumber': roundNumber,
        'roundStartTime': roundStartTime.toIso8601String(),
      },
    );
  }
  
  /// 5.2 Log hint event (with both start and end times)
  void logHint({
    required String hintType,
    required DateTime hintStartTime,
    required DateTime hintEndTime,
  }) {
    if (!_enabled) return;
    
    _hintSequenceId++;
    
    final hintDuration = hintEndTime.difference(hintStartTime).inSeconds.toDouble();
    
    final hintData = {
      'hintStartTime': hintStartTime.toIso8601String(),
      'roundNumber': _currentRoundNumber,
      'hintSequenceId': _hintSequenceId,
      'hintType': hintType,
      'hintEndTime': hintEndTime.toIso8601String(),
      'hintDuration': hintDuration,
    };
    
    _currentRoundHints.add(hintData);
    
    _writeLogEntry(
      eventType: EventType.hintEvent,
      data: hintData,
    );
  }
  
  /// 5.3 Log user guess event
  void logUserGuess({
    required DateTime guessTime,
    required String guess,
    required String correctAnswer,
    required String result,
    required Map<String, dynamic> scoreData,
    required RoundProbabilityData probabilityData,
    required String computerCard,
    required String userCard,
  }) {
    if (!_enabled) return;
    
    final roundDuration = _currentRoundStartTime != null
        ? guessTime.difference(_currentRoundStartTime!).inSeconds.toDouble()
        : 0.0;
    
    _writeLogEntry(
      eventType: EventType.userGuessEvent,
      data: {
        'guessTime': guessTime.toIso8601String(),
        'guess': guess,
        'correctAnswer': correctAnswer,
        'result': result,
        'roundDuration': roundDuration,
        'score': {
          'roundNumber': _currentRoundNumber,
          'userGuess': guess,
          'correctAnswer': correctAnswer,
          'isCorrect': result == 'win',
          'baseScore': scoreData['baseScore'] as int? ?? 0,
          'bonuses': scoreData['bonuses'] as Map<String, int>? ?? {},
          'totalScore': scoreData['totalScore'] as int? ?? 0,
          'scoreCategory': scoreData['scoreCategory'] as String? ?? '',
          'roundCategory': scoreData['roundCategory'] as String? ?? '',
          'isCounterIntuitive': scoreData['isCounterIntuitive'] as bool? ?? false,
          'isObviousMistake': scoreData['isObviousMistake'] as bool? ?? false,
          'bonusPoints': scoreData['bonusPoints'] as int? ?? 0,
          'bonusDescriptions': scoreData['bonusDescriptions'] as List<String>? ?? [],
          'userGuessProbability': probabilityData.getProbabilityForGuess(
            guess == 'Higher' ? UserGuess.higher : 
            guess == 'Tie' ? UserGuess.tie : UserGuess.lower
          ),
          'correctAnswerProbability': probabilityData.correctAnswerProbability,
        },
      },
    );
    
    // Store round data for CompleteGameHistory
    _rounds.add({
      'roundNumber': _currentRoundNumber,
      'roundStartTime': _currentRoundStartTime?.toIso8601String(),
      'computerCard': computerCard,
      'userCard': userCard,
      'userGuess': guess,
      'correctAnswer': correctAnswer,
      'result': result,
      'roundDuration': roundDuration,
      'hints': List.from(_currentRoundHints),
      'score': {
        'roundNumber': _currentRoundNumber,
        'userGuess': guess,
        'correctAnswer': correctAnswer,
        'isCorrect': result == 'win',
        'baseScore': scoreData['baseScore'] as int? ?? 0,
        'bonuses': scoreData['bonuses'] as Map<String, int>? ?? {},
        'totalScore': scoreData['totalScore'] as int? ?? 0,
        'scoreCategory': scoreData['scoreCategory'] as String? ?? '',
        'roundCategory': scoreData['roundCategory'] as String? ?? '',
        'isCounterIntuitive': scoreData['isCounterIntuitive'] as bool? ?? false,
        'isObviousMistake': scoreData['isObviousMistake'] as bool? ?? false,
        'bonusPoints': scoreData['bonusPoints'] as int? ?? 0,
        'bonusDescriptions': scoreData['bonusDescriptions'] as List<String>? ?? [],
        'userGuessProbability': probabilityData.getProbabilityForGuess(
          guess == 'Higher' ? UserGuess.higher : 
          guess == 'Tie' ? UserGuess.tie : UserGuess.lower
        ),
        'correctAnswerProbability': probabilityData.correctAnswerProbability,
      },
    });
  }
  
  /// 6. Log game complete event with CompleteGameHistory
  Future<void> logGameComplete({
    required Map<String, dynamic> finalScores,
  }) async {
    UIDebugLogger.logDialog('VerboseGameLogger.logGameComplete', 
      'Starting logGameComplete, _enabled=$_enabled');
      
    if (!_enabled) {
      UIDebugLogger.logDialog('VerboseGameLogger.logGameComplete', 
        'Logging is not enabled, returning early');
      return;
    }
    
    final completeTime = DateTime.now();
    final totalDuration = _gameStartTime != null
        ? completeTime.difference(_gameStartTime!).inSeconds.toDouble()
        : 0.0;
    
    UIDebugLogger.logDialog('VerboseGameLogger.logGameComplete', 
      'completeTime=$completeTime, totalDuration=$totalDuration');
    UIDebugLogger.logDialog('VerboseGameLogger.logGameComplete', 
      '_sessionId=$_sessionId, _gameStartTime=$_gameStartTime');
    UIDebugLogger.logDialog('VerboseGameLogger.logGameComplete', 
      '_flagOptions=$_flagOptions');
    UIDebugLogger.logDialog('VerboseGameLogger.logGameComplete', 
      '_shuffles count=${_shuffles.length}');
    UIDebugLogger.logDialog('VerboseGameLogger.logGameComplete', 
      '_rounds count=${_rounds.length}');
    
    final completeGameHistory = {
      'sessionId': _sessionId,
      'gameStartTime': _gameStartTime?.toIso8601String(),
      'flagOptions': _flagOptions,
      'shuffles': _shuffles,
      'rounds': _rounds,
    };
    
    UIDebugLogger.logDialog('VerboseGameLogger.logGameComplete', 
      'completeGameHistory created, calling _writeLogEntry');
    
    _writeLogEntry(
      eventType: EventType.gameComplete,
      data: {
        'completeTime': completeTime.toIso8601String(),
        'totalDuration': totalDuration,
        'finalScores': finalScores,
        'completeGameHistory': completeGameHistory,
      },
    );
    
    UIDebugLogger.logDialog('VerboseGameLogger.logGameComplete', 
      '_writeLogEntry completed, calling exportLogs');
    
    // Export logs to file
    await exportLogs();
    
    UIDebugLogger.logDialog('VerboseGameLogger.logGameComplete', 
      'exportLogs completed, calling clearLogs');
    
    // Clear logs for next game
    clearLogs();
    
    UIDebugLogger.logDialog('VerboseGameLogger.logGameComplete', 
      'logGameComplete completed successfully');
  }
  
  /// Write a log entry with sequence number and timestamp
  void _writeLogEntry({
    required EventType eventType,
    required Map<String, dynamic> data,
  }) {
    _logSequenceNumber++;
    
    final entry = {
      'logSequenceNumber': _logSequenceNumber,
      'timestamp': DateTime.now().toIso8601String(),
      'eventType': eventType.toString().split('.').last,
      'data': data,
    };
    
    _logEntries.add(entry);
    
    // Print to console for debugging
    print('[${entry['logSequenceNumber']}] ${entry['eventType']}: ${entry['data']}');
    
    // Debug log
    UIDebugLogger.logDialog('VerboseGameLogger._writeLogEntry', 
      'Added entry #$_logSequenceNumber: ${eventType.toString().split('.').last}, total entries: ${_logEntries.length}');
  }
  
  /// Export logs to JSONL file (one JSON object per line)
  Future<void> exportLogs() async {
    print('=== VERBOSE GAME LOGGER - EXPORT LOGS START ===');
    print('Session ID: $_sessionId');
    print('Enabled: $_enabled');
    print('Log entries count: ${_logEntries.length}');
    
    UIDebugLogger.logDialog('VerboseGameLogger.exportLogs', 
      'Starting exportLogs, _enabled=$_enabled, _logEntries.length=${_logEntries.length}');
      
    if (!_enabled) {
      print('ERROR: Logging not enabled, returning early');
      UIDebugLogger.logDialog('VerboseGameLogger.exportLogs', 
        'Logging not enabled, returning early');
      return;
    }
    
    if (_logEntries.isEmpty) {
      print('ERROR: No entries to write, returning early');
      UIDebugLogger.logDialog('VerboseGameLogger.exportLogs', 
        'No entries to write, returning early');
      return;
    }
    
    try {
      print('Step 1: Getting documents directory...');
      UIDebugLogger.logDialog('VerboseGameLogger.exportLogs', 
        'Getting documents directory');
      final directory = await getApplicationDocumentsDirectory();
      print('Step 1 COMPLETE: Documents directory = ${directory.path}');
      UIDebugLogger.logDialog('VerboseGameLogger.exportLogs', 
        'Documents directory: ${directory.path}');
      
      print('Step 2: Checking directory accessibility...');
      try {
        final dirExists = await directory.exists();
        print('Directory exists: $dirExists');
        final dirList = directory.listSync();
        print('Directory has ${dirList.length} items');
        // Show first few items
        final sampleItems = dirList.take(5).map((f) => f.path).join(', ');
        print('Sample items: $sampleItems');
      } catch (dirError) {
        print('ERROR accessing directory: $dirError');
      }
      
      print('Step 3: Creating file name and path...');
      final fileName = 'pouchape_log_${_sessionId}.jsonl';
      print('File name: $fileName');
      final file = File('${directory.path}/$fileName');
      print('Full file path: ${file.path}');
      UIDebugLogger.logDialog('VerboseGameLogger.exportLogs', 
        'File path: ${file.path}');
      
      // Log all entry types before writing
      final entryTypes = _logEntries.map((e) => e['eventType']).toList();
      print('Entry types to write: $entryTypes');
      UIDebugLogger.logDialog('VerboseGameLogger.exportLogs', 
        'Entry types to write: $entryTypes');
      
      // Check if gameComplete entry exists
      final hasGameComplete = _logEntries.any((e) => e['eventType'] == 'gameComplete');
      print('Has gameComplete entry: $hasGameComplete');
      UIDebugLogger.logDialog('VerboseGameLogger.exportLogs', 
        'Has gameComplete entry: $hasGameComplete');
      
      // Write each log entry as a separate line (JSONL format)
      print('Step 4: Building buffer with ${_logEntries.length} entries...');
      final buffer = StringBuffer();
      for (int i = 0; i < _logEntries.length; i++) {
        final entry = _logEntries[i];
        final jsonLine = jsonEncode(entry);
        buffer.writeln(jsonLine);
        
        // Log first 100 chars of each entry for debugging
        if (i < 3 || i == _logEntries.length - 1) {
          print('Entry $i/${_logEntries.length}: ${entry['eventType']}');
          UIDebugLogger.logDialog('VerboseGameLogger.exportLogs', 
            'Writing entry: ${entry['eventType']} - ${jsonLine.substring(0, jsonLine.length > 100 ? 100 : jsonLine.length)}...');
        }
      }
      
      print('Step 4 COMPLETE: Buffer built, total size: ${buffer.length} bytes');
      UIDebugLogger.logDialog('VerboseGameLogger.exportLogs', 
        'Writing ${_logEntries.length} entries to file');
      
      print('Step 5: Writing buffer to file...');
      print('Writing to path: ${file.path}');
      print('Write mode: create');
      await file.writeAsString(buffer.toString());
      print('Step 5 COMPLETE: File written successfully');
      
      print('Step 6: Verifying file exists...');
      final fileExists = await file.exists();
      print('File exists: $fileExists');
      if (fileExists) {
        final fileSize = await file.length();
        print('File size: $fileSize bytes');
        
        // Try to read it back
        try {
          final content = await file.readAsString();
          print('Successfully read back ${content.length} characters');
          final lineCount = content.split('\n').where((line) => line.isNotEmpty).length;
          print('File contains $lineCount lines');
        } catch (readError) {
          print('ERROR reading file back: $readError');
        }
      } else {
        print('ERROR: File does not exist after write!');
      }
      
      UIDebugLogger.logDialog('VerboseGameLogger.exportLogs', 
        'Logs exported successfully to: ${file.path}');
      print('=== VERBOSE GAME LOGGER - EXPORT LOGS SUCCESS ===');
      print('Logs exported to: ${file.path}');
      print('Total log entries: ${_logEntries.length}');
      print('================================================');
    } catch (e, stackTrace) {
      print('=== VERBOSE GAME LOGGER - EXPORT LOGS ERROR ===');
      print('Error type: ${e.runtimeType}');
      print('Error message: $e');
      print('Stack trace: $stackTrace');
      UIDebugLogger.logDialog('VerboseGameLogger.exportLogs', 
        'Error exporting logs: $e\nStack trace: $stackTrace');
      print('Error exporting logs: $e');
      print('Stack trace: $stackTrace');
      print('================================================');
    }
  }
  
  /// Get complete game history
  Map<String, dynamic>? getCompleteGameHistory() {
    if (_logEntries.isEmpty) return null;
    
    // Find the gameComplete event
    for (final entry in _logEntries.reversed) {
      if (entry['eventType'] == 'gameComplete') {
        return entry['data']['completeGameHistory'] as Map<String, dynamic>;
      }
    }
    
    return null;
  }
  
  /// Clear all logs
  void clearLogs() {
    _logEntries.clear();
    _shuffles.clear();
    _rounds.clear();
    _logSequenceNumber = 0;
    _shuffleSequenceId = 0;
    _currentRoundHints.clear();
    _sessionId = null;
    _gameStartTime = null;
    _flagOptions = null;
    _currentRoundNumber = 0;
    _currentRoundStartTime = null;
    _hintSequenceId = 0;
  }
  
  /// Get all log entries
  List<Map<String, dynamic>> get logEntries => List.from(_logEntries);
}