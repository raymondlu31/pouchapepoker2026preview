

import 'dart:async';

/// Represents the three timer phases with their durations and colors
enum TimerPhase {
  phase1, // 0-5 seconds: green text on white background
  phase2, // 5-35 seconds: blue text on white background  
  phase3, // 35-155 seconds: black text on yellow background
  countUp, // After 155 seconds: green text on white background (counting up)
}

/// Data class representing current timer state
class TimerState {
  final TimerPhase currentPhase;
  final int elapsedSeconds; // Total seconds elapsed since timer start
  final int remainingSeconds; // Seconds remaining in current phase (negative during countUp)
  final ColorData colors;
  final bool isRunning;
  final bool showCountdown; // Based on game option

  TimerState({
    required this.currentPhase,
    required this.elapsedSeconds,
    required this.remainingSeconds,
    required this.colors,
    required this.isRunning,
    required this.showCountdown,
  });

  /// Get formatted time display based on showCountdown option
  String get displayTime {
    if (!showCountdown) return '';
    
    if (currentPhase == TimerPhase.countUp) {
      // Count up format: +MM:SS
      final minutes = elapsedSeconds ~/ 60;
      final seconds = elapsedSeconds % 60;
      return '+${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      // Countdown format: MM:SS
      final minutes = remainingSeconds ~/ 60;
      final seconds = remainingSeconds % 60;
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }

  /// Get phase description
  String get phaseDescription {
    switch (currentPhase) {
      case TimerPhase.phase1:
        return 'phase 1 (0-5s)';
      case TimerPhase.phase2:
        return 'phase 2 (5-35s)';
      case TimerPhase.phase3:
        return 'phase 3 (35-155s)';
      case TimerPhase.countUp:
        return 'Count Up';
    }
  }

  /// Check if timer has expired (reached countUp phase)
  bool get hasExpired => currentPhase == TimerPhase.countUp;

  /// Get progress percentage (0-100) for current phase
  double get phaseProgress {
    switch (currentPhase) {
      case TimerPhase.phase1:
        return (elapsedSeconds / 5) * 100;
      case TimerPhase.phase2:
        return ((elapsedSeconds - 5) / 30) * 100;
      case TimerPhase.phase3:
        return ((elapsedSeconds - 35) / 120) * 100;
      case TimerPhase.countUp:
        return 100.0;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'currentPhase': currentPhase.toString(),
      'elapsedSeconds': elapsedSeconds,
      'remainingSeconds': remainingSeconds,
      'displayTime': displayTime,
      'phaseDescription': phaseDescription,
      'hasExpired': hasExpired,
      'phaseProgress': phaseProgress,
      'colors': colors.toJson(),
      'isRunning': isRunning,
      'showCountdown': showCountdown,
    };
  }
}

/// Color data for timer display
class ColorData {
  final String backgroundColor;
  final String textColor;
  final String description;

  ColorData({
    required this.backgroundColor,
    required this.textColor,
    required this.description,
  });

  factory ColorData.forPhase(TimerPhase phase) {
    switch (phase) {
      case TimerPhase.phase1:
        return ColorData(
          backgroundColor: 'FFFFFF', // White
          textColor: '00FF00',      // Green
          description: 'White background, Green text',
        );
      case TimerPhase.phase2:
        return ColorData(
          backgroundColor: 'FFFFFF', // White  
          textColor: '0000FF',      // Blue
          description: 'White background, Blue text',
        );
      case TimerPhase.phase3:
        return ColorData(
          backgroundColor: 'FFFF00', // Yellow
          textColor: '000000',      // Black
          description: 'Yellow background, Black text',
        );
      case TimerPhase.countUp:
        return ColorData(
          backgroundColor: 'FFFFFF', // White
          textColor: '00FF00',      // Green
          description: 'White background, Green text',
        );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'backgroundColor': backgroundColor,
      'textColor': textColor,
      'description': description,
    };
  }
}

/// Main timer manager for the 3-phase cumulative timer
class TimerHelper {
  Timer? _timer;
  int _elapsedSeconds = 0;
  bool _isRunning = false;
  bool _showCountdown = false;
  TimerPhase _currentPhase = TimerPhase.phase1;
  
  final StreamController<TimerState> _stateController = 
      StreamController<TimerState>.broadcast();
  
  /// Stream of timer state updates
  Stream<TimerState> get stateStream => _stateController.stream;
  
  /// Current timer state
  TimerState get currentState => TimerState(
    currentPhase: _currentPhase,
    elapsedSeconds: _elapsedSeconds,
    remainingSeconds: _calculateRemainingSeconds(),
    colors: ColorData.forPhase(_currentPhase),
    isRunning: _isRunning,
    showCountdown: _showCountdown,
  );
  
  /// Configure timer display option
  void configure({required bool showCountdown}) {
    _showCountdown = showCountdown;
    _notifyListeners();
  }
  
  /// Start the timer
  void start() {
    if (_isRunning) return;
    
    _isRunning = true;
    _elapsedSeconds = 0;
    _currentPhase = TimerPhase.phase1;
    
    _startTimer();
    _notifyListeners();
  }
  
  /// Pause the timer
  void pause() {
    if (!_isRunning) return;
    
    _isRunning = false;
    _timer?.cancel();
    _timer = null;
    
    _notifyListeners();
  }
  
  /// Resume the timer
  void resume() {
    if (_isRunning) return;
    
    _isRunning = true;
    _startTimer();
    
    _notifyListeners();
  }
  
  /// Reset the timer to initial state
  void reset() {
    _timer?.cancel();
    _timer = null;
    
    _isRunning = false;
    _elapsedSeconds = 0;
    _currentPhase = TimerPhase.phase1;
    
    _notifyListeners();
  }
  
  /// Get time spent in the current phase
  int get timeInCurrentPhase {
    switch (_currentPhase) {
      case TimerPhase.phase1:
        return _elapsedSeconds;
      case TimerPhase.phase2:
        return _elapsedSeconds - 5;
      case TimerPhase.phase3:
        return _elapsedSeconds - 35;
      case TimerPhase.countUp:
        return _elapsedSeconds - 155;
    }
  }
  
  /// Check if timer is in a specific phase
  bool isInPhase(TimerPhase phase) => _currentPhase == phase;
  
  /// Check if timer has passed a specific time threshold
  bool hasPassedSeconds(int seconds) => _elapsedSeconds >= seconds;
  
  /// Calculate remaining seconds in current phase
  int _calculateRemainingSeconds() {
    switch (_currentPhase) {
      case TimerPhase.phase1:
        return 5 - _elapsedSeconds;
      case TimerPhase.phase2:
        return 35 - _elapsedSeconds;
      case TimerPhase.phase3:
        return 155 - _elapsedSeconds;
      case TimerPhase.countUp:
        return _elapsedSeconds - 155; // Negative during countUp
    }
  }
  
  /// Start the timer ticker
  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _elapsedSeconds++;
      _updatePhase();
      _notifyListeners();
      
      // Log timer ticks for debugging (every 10 seconds or on phase changes)
      if (_elapsedSeconds % 10 == 0 || _isPhaseTransition()) {
        _logTimerTick();
      }
    });
  }
  
  /// Update current phase based on elapsed time
  void _updatePhase() {
    final previousPhase = _currentPhase;
    
    if (_elapsedSeconds < 5) {
      _currentPhase = TimerPhase.phase1;
    } else if (_elapsedSeconds < 35) {
      _currentPhase = TimerPhase.phase2;
    } else if (_elapsedSeconds < 155) {
      _currentPhase = TimerPhase.phase3;
    } else {
      _currentPhase = TimerPhase.countUp;
    }
    
    // Check if phase changed
    if (previousPhase != _currentPhase) {
      _onPhaseChanged(previousPhase, _currentPhase);
    }
  }
  
  /// Check if this is a phase transition tick
  bool _isPhaseTransition() {
    return _elapsedSeconds == 5 || _elapsedSeconds == 35 || _elapsedSeconds == 155;
  }
  
  /// Handle phase changes
  void _onPhaseChanged(TimerPhase from, TimerPhase to) {
    // Could trigger events here (like phase change notifications)
    // For now, just log it
    print('Timer phase changed: $from -> $to at $_elapsedSeconds seconds');
  }
  
  /// Notify listeners of state change
  void _notifyListeners() {
    if (!_stateController.isClosed) {
      _stateController.add(currentState);
    }
  }
  
  /// Log timer tick for debugging
  void _logTimerTick() {
    final data = {
      'timestamp': DateTime.now().toIso8601String(),
      'elapsedSeconds': _elapsedSeconds,
      'currentPhase': _currentPhase.toString(),
      'remainingSeconds': _calculateRemainingSeconds(),
      'displayTime': currentState.displayTime,
      'isRunning': _isRunning,
    };
    
    // This would be sent to DebugLogger in production
    print('Timer Tick: $data');
  }
  
  /// Clean up resources
  void dispose() {
    _timer?.cancel();
    _stateController.close();
  }
  
  /// Get timer statistics
  Map<String, dynamic> get statistics {
    return {
      'elapsedSeconds': _elapsedSeconds,
      'currentPhase': _currentPhase.toString(),
      'isRunning': _isRunning,
      'showCountdown': _showCountdown,
      'timeInCurrentPhase': timeInCurrentPhase,
      'hasExpired': _currentPhase == TimerPhase.countUp,
      'phaseProgress': currentState.phaseProgress,
    };
  }
}

/// Extension for timer logging
extension TimerLogging on TimerHelper {
  /// Get timer data for debug logging
  Map<String, dynamic> getLogData() {
    return {
      'timerState': currentState.toJson(),
      'statistics': statistics,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
  
  /// Record timer start event
  Map<String, dynamic> recordStartEvent() {
    return {
      'event': 'timer_started',
      'timestamp': DateTime.now().toIso8601String(),
      'initialState': currentState.toJson(),
    };
  }
  
  /// Record timer pause event
  Map<String, dynamic> recordPauseEvent() {
    return {
      'event': 'timer_paused',
      'timestamp': DateTime.now().toIso8601String(),
      'elapsedSeconds': _elapsedSeconds,
      'currentPhase': _currentPhase.toString(),
    };
  }
  
  /// Record timer resume event
  Map<String, dynamic> recordResumeEvent() {
    return {
      'event': 'timer_resumed',
      'timestamp': DateTime.now().toIso8601String(),
      'elapsedSeconds': _elapsedSeconds,
      'currentPhase': _currentPhase.toString(),
    };
  }
  
  /// Record timer reset event
  Map<String, dynamic> recordResetEvent() {
    return {
      'event': 'timer_reset',
      'timestamp': DateTime.now().toIso8601String(),
      'previousElapsed': _elapsedSeconds,
      'previousPhase': _currentPhase.toString(),
    };
  }
}

