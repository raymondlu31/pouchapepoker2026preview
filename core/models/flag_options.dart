/// Configuration flags for game options
class FlagOptions {
  bool verboseLogMode;
  bool showStageDialog;
  bool showCountDown;
  bool showWarnings;
  int gameSpeed; // 1=fast (1s), 2=medium (3s), 3=slow (10s)
  
  FlagOptions({
    this.verboseLogMode = true,
    this.showStageDialog = true,
    this.showCountDown = true,
    this.showWarnings = true,
    this.gameSpeed = 3, // slow by default
  });

  /// Factory constructor to create FlagOptions from JSON map
  factory FlagOptions.fromJson(Map<String, dynamic> json) {
    return FlagOptions(
      verboseLogMode: json['verboseLogMode'] as bool,
      showStageDialog: json['showStageDialog'] as bool,
      showCountDown: json['showCountDown'] as bool,
      showWarnings: json['showWarnings'] as bool,
      gameSpeed: json['gameSpeed'] as int,
    );
  }
  
  /// Get auto-close duration in milliseconds based on game speed
  int get autoCloseDuration {
    switch (gameSpeed) {
      case 1:
        return 1000; // 1 second
      case 2:
        return 3000; // 3 seconds
      case 3:
        return 10000; // 10 seconds
      default:
        return 10000; // default to slow
    }
  }
  
  /// Create a copy with optional overrides
  FlagOptions copyWith({
    bool? verboseLogMode,
    bool? showStageDialog,
    bool? showCountDown,
    bool? showWarnings,
    int? gameSpeed,
  }) {
    return FlagOptions(
      verboseLogMode: verboseLogMode ?? this.verboseLogMode,
      showStageDialog: showStageDialog ?? this.showStageDialog,
      showCountDown: showCountDown ?? this.showCountDown,
      showWarnings: showWarnings ?? this.showWarnings,
      gameSpeed: gameSpeed ?? this.gameSpeed,
    );
  }

  /// Convert to JSON map for logging/serialization
  Map<String, dynamic> toJson() {
    return {
      'verboseLogMode': verboseLogMode,
      'showStageDialog': showStageDialog,
      'showCountDown': showCountDown,
      'showWarnings': showWarnings,
      'gameSpeed': gameSpeed,
      'autoCloseDuration': autoCloseDuration,
    };
  }
  
  @override
  String toString() {
    return 'FlagOptions(verboseLogMode: $verboseLogMode, showStageDialog: $showStageDialog, '
           'showCountDown: $showCountDown, showWarnings: $showWarnings, gameSpeed: $gameSpeed)';
  }
  
}