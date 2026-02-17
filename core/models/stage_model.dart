
import 'user_guess.dart';
import '../data/8gua_data.dart';
import '../data/64gua_data.dart';

/// Represents a Stage (3 rounds) in the game
class StageModel {
  final String stageId;           // A, B, C, ..., I
  final int stageNumber;          // 1-9
  final List<int> roundNumbers;   // [1,2,3] for Stage A, [4,5,6] for B, etc.
  final List<RoundResult?> roundResults; // Results for each round (null if not played yet)
  final String? binaryResult;     // 3-digit binary like "110" (null if incomplete)
  final String? gua8Symbol;       // 8gua symbol like "☱"
  final String? gua8Name;         // 8gua name like "兑"
  final String? gua8Pinyin;       // Pinyin like "dui"
  final String? nature_zh;        // Chinese nature description (e.g., "泽")
  final String? nature_en;        // English nature description (e.g., "Lake")
  final DateTime? startTime;
  final DateTime? endTime;

  StageModel({
    required this.stageId,
    required this.stageNumber,
    required this.roundNumbers,
    required this.roundResults,
    this.binaryResult,
    this.gua8Symbol,
    this.gua8Name,
    this.gua8Pinyin,
    this.nature_zh,
    this.nature_en,
    this.startTime,
    this.endTime,
  });

  /// Factory constructor for creating an empty stage
  factory StageModel.createEmpty(int stageNumber) {
    final stageLetter = String.fromCharCode(64 + stageNumber); // A=65 in ASCII
    final startRound = (stageNumber - 1) * 3 + 1;
    final roundNumbers = [startRound, startRound + 1, startRound + 2];

    return StageModel(
      stageId: stageLetter,
      stageNumber: stageNumber,
      roundNumbers: roundNumbers,
      roundResults: [null, null, null], // All rounds not played yet
      binaryResult: null,
      gua8Symbol: null,
      gua8Name: null,
      gua8Pinyin: null,
      nature_zh: null,
      nature_en: null,
      startTime: null,
      endTime: null,
    );
  }

  /// Factory constructor to create StageModel from JSON map
  factory StageModel.fromJson(Map<String, dynamic> json) {
    // Parse round results from JSON
    List<RoundResult?> roundResults = [];
    if (json['roundResults'] != null) {
      for (var result in json['roundResults']) {
        if (result == null) {
          roundResults.add(null);
        } else {
          roundResults.add(RoundResult.values.firstWhere(
            (e) => e.toString() == result,
            orElse: () => RoundResult.values.first,
          ));
        }
      }
    }

    // Parse DateTime fields
    DateTime? startTime;
    DateTime? endTime;
    
    if (json['startTime'] != null) {
      startTime = DateTime.parse(json['startTime']);
    }
    if (json['endTime'] != null) {
      endTime = DateTime.parse(json['endTime']);
    }

    return StageModel(
      stageId: json['stageId'] as String,
      stageNumber: json['stageNumber'] as int,
      roundNumbers: List<int>.from(json['roundNumbers']),
      roundResults: roundResults,
      binaryResult: json['binaryResult'],
      gua8Symbol: json['gua8Symbol'],
      gua8Name: json['gua8Name'],
      gua8Pinyin: json['gua8Pinyin'],
      nature_zh: json['nature_zh'],
      nature_en: json['nature_en'],
      startTime: startTime,
      endTime: endTime,
    );
  }

  /// Convert to JSON map for serialization
  Map<String, dynamic> toJson() {
    // Convert round results to string representation
    List<String?> roundResultsJson = roundResults.map((result) {
      return result?.toString();
    }).toList();

    return {
      'stageId': stageId,
      'stageNumber': stageNumber,
      'roundNumbers': roundNumbers,
      'roundResults': roundResultsJson,
      'binaryResult': binaryResult,
      'gua8Symbol': gua8Symbol,
      'gua8Name': gua8Name,
      'gua8Pinyin': gua8Pinyin,
      'nature_zh': nature_zh,
      'nature_en': nature_en,
      'startTime': startTime?.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'isComplete': isComplete,
      'isInProgress': isInProgress,
      'completedRoundsCount': completedRoundsCount,
      'currentRoundNumber': currentRoundNumber,
      'winCount': winCount,
      'missedCount': missedCount,
      'accuracy': accuracy,
      'formattedDuration': formattedDuration,
    };
  }

  /// Check if all rounds in this stage have been completed
  bool get isComplete => roundResults.every((result) => result != null);

  /// Check if this stage is currently in progress (some but not all rounds done)
  bool get isInProgress => 
      roundResults.any((result) => result != null) && !isComplete;

  /// Get the number of completed rounds in this stage
  int get completedRoundsCount => 
      roundResults.where((result) => result != null).length;

  /// Get the current round number being played in this stage
  /// Returns null if stage is complete or not started
  int? get currentRoundNumber {
    if (!isInProgress) return null;
    
    for (int i = 0; i < roundResults.length; i++) {
      if (roundResults[i] == null) {
        return roundNumbers[i];
      }
    }
    return null;
  }

  /// Update a round result in this stage
  StageModel updateRoundResult(int roundNumber, RoundResult result) {
    final index = roundNumbers.indexOf(roundNumber);
    if (index == -1) {
      throw ArgumentError('Round $roundNumber is not part of stage $stageId');
    }

    final newResults = List<RoundResult?>.from(roundResults);
    newResults[index] = result;

    String? newBinary;
    String? newSymbol;
    String? newName;
    String? newPinyin;
    String? newNature_zh;
    String? newNature_en;

    // If all rounds are now complete, calculate binary result
    if (newResults.every((r) => r != null)) {
      newBinary = _calculateBinaryResult(newResults);

      // Get 8gua data and populate the fields
      final gua8Data = Gua8Data.get8Gua(newBinary);
      if (gua8Data != null) {
        newSymbol = gua8Data.symbol;
        newName = gua8Data.name_zh;
        newPinyin = gua8Data.name_pinyin_std;
        newNature_zh = gua8Data.nature_zh;
        newNature_en = gua8Data.nature_en;
      }
    }

    DateTime? newEndTime = endTime;
    if (isComplete && newResults.every((r) => r != null)) {
      newEndTime = DateTime.now();
    }

    return StageModel(
      stageId: stageId,
      stageNumber: stageNumber,
      roundNumbers: roundNumbers,
      roundResults: newResults,
      binaryResult: newBinary,
      gua8Symbol: newSymbol,
      gua8Name: newName,
      gua8Pinyin: newPinyin,
      nature_zh: newNature_zh,
      nature_en: newNature_en,
      startTime: startTime,
      endTime: newEndTime,
    );
  }

  /// Calculate the 3-digit binary result from round results
  String _calculateBinaryResult(List<RoundResult?> results) {
    // Binary construction: Round1=MSB (leftmost), Round3=LSB (rightmost)
    // Example: Win-Win-Missed = "110"
    return results.map((result) => result!.toBinary).join();
  }

  /// Get duration of this stage (null if not started or not completed)
  Duration? get duration {
    if (startTime == null || endTime == null) return null;
    return endTime!.difference(startTime!);
  }

  /// Get formatted duration string
  String get formattedDuration {
    final dur = duration;
    if (dur == null) return 'Not completed';
    
    final minutes = dur.inMinutes;
    final seconds = dur.inSeconds % 60;
    return '${minutes}m ${seconds}s';
  }

  /// Get win count in this stage
  int get winCount => roundResults.where((r) => r == RoundResult.win).length;

  /// Get missed count in this stage
  int get missedCount => roundResults.where((r) => r == RoundResult.missed).length;

  /// Get accuracy percentage for this stage (0-100)
  double get accuracy {
    if (!isComplete) return 0.0;
    return (winCount / 3) * 100;
  }

  @override
  String toString() {
    return 'Stage $stageId (Rounds ${roundNumbers.first}-${roundNumbers.last}) '
           '${isComplete ? "Complete: $binaryResult" : "In Progress: ${completedRoundsCount}/3"}';
  }
}

/// Represents a Stack (2 stages = 6 rounds) in the game
class StackModel {
  final int stackNumber;          // 1-4
  final List<String> stageIds;    // ["A","B"] for Stack1, ["C","D"] for Stack2, etc.
  final List<StageModel> stages;  // The two stages in this stack
  final String? binaryResult;     // 6-digit binary like "110001" (null if incomplete)
  final String? gua64Symbol;      // 64gua symbol like "䷨"
  final String? gua64Name;        // 64gua name like "损"
  final String? gua64Pinyin;      // Pinyin like "sun"
  final String? stackDescription; // "下兑上艮" (Bottom dui Top gen)
  final String? stack_zh;         // Chinese stack description (e.g., "下兑上艮")
  final String? stack_en;         // English stack description (e.g., "Bottom dui Top gen")
  final DateTime? startTime;
  final DateTime? endTime;

  StackModel({
    required this.stackNumber,
    required this.stageIds,
    required this.stages,
    this.binaryResult,
    this.gua64Symbol,
    this.gua64Name,
    this.gua64Pinyin,
    this.stackDescription,
    this.stack_zh,
    this.stack_en,
    this.startTime,
    this.endTime,
  });

  /// Factory constructor for creating an empty stack
  factory StackModel.createEmpty(int stackNumber) {
    final firstStageNumber = (stackNumber - 1) * 2 + 1;
    final stageIds = [
      String.fromCharCode(64 + firstStageNumber),
      String.fromCharCode(64 + firstStageNumber + 1),
    ];

    final stages = [
      StageModel.createEmpty(firstStageNumber),
      StageModel.createEmpty(firstStageNumber + 1),
    ];

    return StackModel(
      stackNumber: stackNumber,
      stageIds: stageIds,
      stages: stages,
      binaryResult: null,
      gua64Symbol: null,
      gua64Name: null,
      gua64Pinyin: null,
      stackDescription: null,
      stack_zh: null,
      stack_en: null,
      startTime: null,
      endTime: null,
    );
  }

  /// Factory constructor to create StackModel from JSON map
  factory StackModel.fromJson(Map<String, dynamic> json) {
    // Parse stages from JSON
    List<StageModel> stages = [];
    if (json['stages'] != null) {
      for (var stageJson in json['stages']) {
        stages.add(StageModel.fromJson(stageJson));
      }
    }

    // Parse DateTime fields
    DateTime? startTime;
    DateTime? endTime;
    
    if (json['startTime'] != null) {
      startTime = DateTime.parse(json['startTime']);
    }
    if (json['endTime'] != null) {
      endTime = DateTime.parse(json['endTime']);
    }

    return StackModel(
      stackNumber: json['stackNumber'] as int,
      stageIds: List<String>.from(json['stageIds']),
      stages: stages,
      binaryResult: json['binaryResult'],
      gua64Symbol: json['gua64Symbol'],
      gua64Name: json['gua64Name'],
      gua64Pinyin: json['gua64Pinyin'],
      stackDescription: json['stackDescription'],
      stack_zh: json['stack_zh'],
      stack_en: json['stack_en'],
      startTime: startTime,
      endTime: endTime,
    );
  }

  /// Convert to JSON map for serialization
  Map<String, dynamic> toJson() {
    // Convert stages to JSON
    List<Map<String, dynamic>> stagesJson = stages.map((stage) => stage.toJson()).toList();

    return {
      'stackNumber': stackNumber,
      'stageIds': stageIds,
      'stages': stagesJson,
      'binaryResult': binaryResult,
      'gua64Symbol': gua64Symbol,
      'gua64Name': gua64Name,
      'gua64Pinyin': gua64Pinyin,
      'stackDescription': stackDescription,
      'stack_zh': stack_zh,
      'stack_en': stack_en,
      'startTime': startTime?.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'isComplete': isComplete,
      'isInProgress': isInProgress,
      'winCount': winCount,
      'missedCount': missedCount,
      'accuracy': accuracy,
      'formattedDuration': formattedDuration,
    };
  }

  /// Check if both stages in this stack are complete
  bool get isComplete => stages.every((stage) => stage.isComplete);

  /// Check if this stack is in progress (at least one round played)
  bool get isInProgress => stages.any((stage) => stage.isInProgress || stage.isComplete);

  /// Update a stage in this stack
  StackModel updateStage(StageModel updatedStage) {
    if (!stageIds.contains(updatedStage.stageId)) {
      throw ArgumentError('Stage ${updatedStage.stageId} is not part of stack $stackNumber');
    }

    final newStages = List<StageModel>.from(stages);
    final index = stageIds.indexOf(updatedStage.stageId);
    newStages[index] = updatedStage;

    String? newBinary;
    String? newSymbol;
    String? newName;
    String? newPinyin;
    String? newDescription;
    String? newStack_zh;
    String? newStack_en;

    // If both stages are complete, calculate stack binary result
    if (newStages.every((stage) => stage.isComplete)) {
      newBinary = _calculateStackBinary(newStages);

      // Get 64gua data and populate the fields
      final gua64Data = Gua64Data.get64Gua(newBinary);
      if (gua64Data != null) {
        newSymbol = gua64Data.symbol;
        newName = gua64Data.name_zh;
        newPinyin = gua64Data.name_pinyin_std;
        newDescription = gua64Data.stack_zh;
        newStack_zh = gua64Data.stack_zh;
        newStack_en = gua64Data.stack_en;
      }
    }

    // Update start time if first stage just started
    DateTime? newStartTime = startTime;
    if (newStartTime == null && newStages[0].startTime != null) {
      newStartTime = newStages[0].startTime;
    }

    // Update end time if stack just completed
    DateTime? newEndTime = endTime;
    if (isComplete && newStages.every((stage) => stage.isComplete)) {
      newEndTime = DateTime.now();
    }

    return StackModel(
      stackNumber: stackNumber,
      stageIds: stageIds,
      stages: newStages,
      binaryResult: newBinary,
      gua64Symbol: newSymbol,
      gua64Name: newName,
      gua64Pinyin: newPinyin,
      stackDescription: newDescription,
      stack_zh: newStack_zh,
      stack_en: newStack_en,
      startTime: newStartTime,
      endTime: newEndTime,
    );
  }

  /// Calculate the 6-digit binary result from two stages
  String _calculateStackBinary(List<StageModel> stages) {
    // Stack binary = StageA binary + StageB binary
    // Example: StageA "110" + StageB "001" = "110001"
    return stages.map((stage) => stage.binaryResult!).join();
  }

  /// Get duration of this stack (null if not started or not completed)
  Duration? get duration {
    if (startTime == null || endTime == null) return null;
    return endTime!.difference(startTime!);
  }

  /// Get formatted duration string
  String get formattedDuration {
    final dur = duration;
    if (dur == null) return 'Not completed';
    
    final minutes = dur.inMinutes;
    final seconds = dur.inSeconds % 60;
    return '${minutes}m ${seconds}s';
  }

  /// Get total win count in this stack (0-6)
  int get winCount => stages.fold(0, (sum, stage) => sum + stage.winCount);

  /// Get total missed count in this stack (0-6)
  int get missedCount => stages.fold(0, (sum, stage) => sum + stage.missedCount);

  /// Get accuracy percentage for this stack (0-100)
  double get accuracy {
    if (!isComplete) return 0.0;
    return (winCount / 6) * 100;
  }

  /// Get the stage that contains a specific round number
  StageModel? getStageForRound(int roundNumber) {
    for (final stage in stages) {
      if (stage.roundNumbers.contains(roundNumber)) {
        return stage;
      }
    }
    return null;
  }

  @override
  String toString() {
    return 'Stack $stackNumber (Stages ${stageIds.join(",")}) '
           '${isComplete ? "Complete: $binaryResult" : "In Progress"}';
  }
}

/// Manages all stages and stacks in the game
class StageStackManager {
  final List<StageModel> stages;
  final List<StackModel> stacks;

  /// Private constructor - use factory constructors instead
  StageStackManager._({
    required this.stages,
    required this.stacks,
  });

  /// Default constructor that creates empty stages and stacks
  StageStackManager() 
    : stages = List.generate(9, (i) => StageModel.createEmpty(i + 1)),
      stacks = List.generate(4, (i) => StackModel.createEmpty(i + 1));

  /// The standalone Stage I (Stage 9) - no stack
  StageModel get stageI => stages[8];

  /// Factory constructor to create StageStackManager from JSON map
  factory StageStackManager.fromJson(Map<String, dynamic> json) {
    List<StageModel> stages = [];
    List<StackModel> stacks = [];
    
    // Parse stages
    if (json['stages'] != null) {
      for (var stageJson in json['stages']) {
        stages.add(StageModel.fromJson(stageJson));
      }
    } else {
      // Create empty stages if not in JSON
      stages = List.generate(9, (i) => StageModel.createEmpty(i + 1));
    }
    
    // Parse stacks
    if (json['stacks'] != null) {
      for (var stackJson in json['stacks']) {
        stacks.add(StackModel.fromJson(stackJson));
      }
    } else {
      // Create empty stacks if not in JSON
      stacks = List.generate(4, (i) => StackModel.createEmpty(i + 1));
    }
    
    return StageStackManager._(stages: stages, stacks: stacks);
  }

  /// Convert to JSON map for serialization
  Map<String, dynamic> toJson() {
    return {
      'stages': stages.map((stage) => stage.toJson()).toList(),
      'stacks': stacks.map((stack) => stack.toJson()).toList(),
      'gameStatistics': gameStatistics,
    };
  }
  
  

  /// Update a round result and propagate through stages/stacks
  void updateRoundResult(int roundNumber, RoundResult result) {
    // Find which stage this round belongs to (1-9)
    final stageNumber = ((roundNumber - 1) ~/ 3) + 1;
    final stageIndex = stageNumber - 1;
    
    // Update the stage
    final updatedStage = stages[stageIndex].updateRoundResult(roundNumber, result);
    stages[stageIndex] = updatedStage;
    
    // If this stage is part of a stack (1-8), update the stack too
    if (stageNumber <= 8) {
      final stackNumber = ((stageNumber - 1) ~/ 2) + 1;
      final stackIndex = stackNumber - 1;
      
      final updatedStack = stacks[stackIndex].updateStage(updatedStage);
      stacks[stackIndex] = updatedStack;
    }
  }

  /// Get the current stage for a given round number
  StageModel getStageForRound(int roundNumber) {
    final stageNumber = ((roundNumber - 1) ~/ 3) + 1;
    return stages[stageNumber - 1];
  }

  /// Get the current stack for a given round number (returns null for rounds 25-27)
  StackModel? getStackForRound(int roundNumber) {
    final stageNumber = ((roundNumber - 1) ~/ 3) + 1;
    if (stageNumber <= 8) {
      final stackNumber = ((stageNumber - 1) ~/ 2) + 1;
      return stacks[stackNumber - 1];
    }
    return null; // Stage I (rounds 25-27) has no stack
  }

  /// Check if a round completes a stage
  bool isStageCompletion(int roundNumber) => roundNumber % 3 == 0;

  /// Check if a round completes a stack
  bool isStackCompletion(int roundNumber) => roundNumber % 6 == 0 && roundNumber <= 24;

  /// Get all completed stages
  List<StageModel> get completedStages => 
      stages.where((stage) => stage.isComplete).toList();

  /// Get all completed stacks
  List<StackModel> get completedStacks => 
      stacks.where((stack) => stack.isComplete).toList();

  /// Get overall game statistics
  Map<String, dynamic> get gameStatistics {
    final completed = completedStages;
    final totalWins = completed.fold(0, (sum, stage) => sum + stage.winCount);
    final totalRounds = completed.length * 3;
    
    return {
      'totalStagesCompleted': completed.length,
      'totalStacksCompleted': completedStacks.length,
      'totalWins': totalWins,
      'totalMissed': totalRounds - totalWins,
      'overallAccuracy': totalRounds > 0 ? (totalWins / totalRounds * 100) : 0.0,
      'stageAccuracies': completed.map((s) => s.accuracy).toList(),
      'stackAccuracies': completedStacks.map((s) => s.accuracy).toList(),
    };
  }

  /// Reset all stages and stacks for a new game
  void reset() {
    for (int i = 0; i < stages.length; i++) {
      stages[i] = StageModel.createEmpty(i + 1);
    }
    for (int i = 0; i < stacks.length; i++) {
      stacks[i] = StackModel.createEmpty(i + 1);
    }
  }
}


