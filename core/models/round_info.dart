/// Represents the current round information
class RoundInfo {
  final int roundNumber;  // 1-27
  final int stageNumber;  // 1-9 (A-I)
  final int stackNumber;  // 1-4 (Stage I has no stack)
  
  RoundInfo({
    required this.roundNumber,
    required this.stageNumber,
    required this.stackNumber,
  });
  
  factory RoundInfo.fromRoundNumber(int roundNumber) {
    // Stage calculation: 3 rounds per stage
    final stageNumber = ((roundNumber - 1) ~/ 3) + 1;
    
    // Stack calculation: 2 stages per stack (except Stage I)
    final stackNumber = stageNumber <= 8 ? ((stageNumber - 1) ~/ 2) + 1 : 0;
    
    return RoundInfo(
      roundNumber: roundNumber,
      stageNumber: stageNumber,
      stackNumber: stackNumber,
    );
  }
  
  /// Get the stage letter (A-I)
  String get stageLetter => String.fromCharCode(64 + stageNumber); // A=65 in ASCII
  
  /// Check if this round completes a stage (round 3, 6, 9, ..., 27)
  bool get isStageCompletion => roundNumber % 3 == 0;
  
  /// Check if this round completes a stack (round 6, 12, 18, 24)
  bool get isStackCompletion => roundNumber % 6 == 0 && roundNumber <= 24;
  
  /// Get position within current stage (1, 2, or 3)
  int get positionInStage => ((roundNumber - 1) % 3) + 1;
  
  /// Get position within current stack (1-6)
  int get positionInStack => ((roundNumber - 1) % 6) + 1;
  
  @override
  String toString() => 'Round $roundNumber (Stage $stageLetter${stackNumber > 0 ? ', Stack $stackNumber' : ''})';
}