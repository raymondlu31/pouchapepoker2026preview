
import 'package:flutter/material.dart';
import '../../../helper/score_calculator.dart';
import '../../../core/models/stage_model.dart';
import '../../../core/models/score_entry.dart';
import '../../styles/game_colors.dart';

class ScoreDialog extends StatefulWidget {
  final ScoreEntry scoreEntry;
  final int autoCloseDuration;
  final bool showOnlyBonuses;

  const ScoreDialog({
    super.key,
    required this.scoreEntry,
    this.autoCloseDuration = 3000,
    this.showOnlyBonuses = false,
  });

  @override
  State<ScoreDialog> createState() => _ScoreDialogState();
}

class _ScoreDialogState extends State<ScoreDialog> {
  @override
  void initState() {
    super.initState();
    
    // Auto-close timer
    if (widget.autoCloseDuration > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(Duration(milliseconds: widget.autoCloseDuration), () {
          if (mounted && Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: GameColors.dialogBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: GameColors.textBlack, width: 3),
      ),
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            if (widget.showOnlyBonuses) ...[
              const Text(
                'Bonus Points!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: GameColors.accentGold,
                ),
              ),
            ] else ...[
              Text(
                widget.scoreEntry.isCorrect ? 'Round Won!' : 'Round Missed',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: widget.scoreEntry.isCorrect 
                      ? GameColors.correctGreen 
                      : GameColors.wrongRed,
                ),
              ),
            ],
            const SizedBox(height: 20),

            if (!widget.showOnlyBonuses) ...[
              // Result info
              _buildInfoRow('Computer card', widget.scoreEntry.computerCardStr ?? widget.scoreEntry.computerCard?.displayNameWithSuit ?? 'Unknown'),
              _buildInfoRow('Your card', widget.scoreEntry.userCardStr ?? widget.scoreEntry.userCard?.displayNameWithSuit ?? 'Unknown'),
              _buildInfoRow('Your guess', widget.scoreEntry.userGuess?.displayName ?? 'None'),
              _buildInfoRow('Correct answer', widget.scoreEntry.correctAnswer?.displayName ?? 'Unknown'),

              const Divider(color: GameColors.textBlack, thickness: 1),
              const SizedBox(height: 16),

              // Base score
              _buildScoreRow('Base Score', widget.scoreEntry.baseScore),
            ],

            // Bonus points (only shown in bonus dialog)
            if (widget.showOnlyBonuses && widget.scoreEntry.bonusPoints > 0) ...[
              for (final bonus in widget.scoreEntry.bonusDescriptions)
                _buildScoreRow(bonus.split(':')[0], int.parse(bonus.split('+')[1])),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '$label:',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: GameColors.textBlack,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              color: GameColors.textBlack,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreRow(String label, int points) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                color: GameColors.textBlack,
              ),
            ),
          ),
          Text(
            points > 0 ? '+$points' : '$points',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: points > 0 ? GameColors.positiveScore : GameColors.negativeScore,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalScoreRow(String label, int points) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: GameColors.textBlack,
              ),
            ),
          ),
          Text(
            '$points',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: points > 0 ? GameColors.positiveScore : GameColors.negativeScore,
            ),
          ),
        ],
      ),
    );
  }
}

class StageResultDialog extends StatefulWidget {
  final StageModel stage;
  final StageStackManager stageStackManager;
  final int autoCloseDuration;

  const StageResultDialog({
    super.key,
    required this.stage,
    required this.stageStackManager,
    this.autoCloseDuration = 3000,
  });

  @override
  State<StageResultDialog> createState() => _StageResultDialogState();
}

class _StageResultDialogState extends State<StageResultDialog> {
  @override
  void initState() {
    super.initState();
    
    // Auto-close timer
    if (widget.autoCloseDuration > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(Duration(milliseconds: widget.autoCloseDuration), () {
          if (mounted && Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final accuracy = widget.stage.accuracy;
    final resultColor = _getResultColor(accuracy);

    return Dialog(
      backgroundColor: GameColors.dialogBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: GameColors.textBlack, width: 3),
      ),
      child: Container(
        width: 550,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              'Stage ${widget.stage.stageId} Complete!',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: GameColors.primaryPurple,
              ),
            ),
            const SizedBox(height: 16),

            // All Stages Grid (5x2)
            _buildAllStagesGrid(widget.stageStackManager),
            const SizedBox(height: 16),

            // Current Stage Results
            _buildResultsGrid(),
            const SizedBox(height: 16),

            // 8Gua info
            if (widget.stage.gua8Symbol != null) _buildGuaInfo(),

            // Stage I explanation
            if (widget.stage.stageId == 'I') _buildStageIExplanation(),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsGrid() {
    final results = widget.stage.roundResults;
    final roundNumbers = widget.stage.roundNumbers;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(3, (index) {
        final result = results[index];
        final isWin = result?.displayName == 'Win';
        
        return Column(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: isWin ? GameColors.correctGreen : GameColors.wrongRed,
                shape: BoxShape.circle,
                border: Border.all(color: GameColors.textBlack, width: 2),
              ),
              child: Center(
                child: Text(
                  isWin ? '✓' : '✗',
                  style: const TextStyle(
                    fontSize: 32,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Round ${roundNumbers[index]}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: GameColors.textBlack,
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildAllStagesGrid(StageStackManager stageManager) {
    // Row 1: StageB, StageD, StageF, StageH, empty
    // Row 2: StageA, StageC, StageE, StageG, StageI
    final row1StageIds = ['B', 'D', 'F', 'H', null];
    final row2StageIds = ['A', 'C', 'E', 'G', 'I'];

    return Column(
      children: [
        _buildStageRow(row1StageIds, stageManager),
        const SizedBox(height: 8),
        _buildStageRow(row2StageIds, stageManager),
      ],
    );
  }

  Widget _buildStageRow(List<String?> stageIds, StageStackManager stageManager) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: stageIds.map((stageId) {
        if (stageId == null) {
          return const SizedBox(width: 70, height: 70); // Empty cell
        }

        final stage = stageManager.stages.firstWhere(
          (s) => s.stageId == stageId,
          orElse: () => StageModel.createEmpty(stageId.codeUnitAt(0) - 64),
        );

        final isComplete = stage.isComplete;
        final symbol = stage.gua8Symbol ?? '?';
        final isCurrentStage = widget.stage.stageId == stageId;

        return Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            color: isComplete 
                ? GameColors.primaryPurple.withOpacity(0.1)
                : GameColors.background,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isCurrentStage 
                  ? GameColors.secondaryYellow 
                  : GameColors.textBlack,
              width: isCurrentStage ? 3 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                stageId,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isCurrentStage ? GameColors.secondaryYellow : GameColors.textBlack,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                symbol,
                style: TextStyle(
                  fontSize: 28,
                  color: isComplete ? GameColors.primaryPurple : Colors.grey,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStageIExplanation() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.orange, size: 20),
              const SizedBox(width: 8),
              Text(
                'Stage I - Standalone Stage',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'In the last stage (Stage I), only 6 cards remain. The final round has a certain answer. '
            'These rounds are scored, but not divination meaningful.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.orange.shade900,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuaInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(color: GameColors.textBlack, thickness: 1),
        const SizedBox(height: 16),
        const Text(
          'I-Ching Trigram (8 Gua)',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: GameColors.primaryPurple,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Text(
              widget.stage.gua8Symbol ?? '',
              style: const TextStyle(fontSize: 48),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${widget.stage.gua8Name} (${widget.stage.gua8Pinyin})',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: GameColors.textBlack,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Binary: ${widget.stage.binaryResult}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    widget.stage.nature_zh ?? '',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: GameColors.textBlack,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.stage.nature_en ?? '',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '$label:',
              style: const TextStyle(
                fontSize: 16,
                color: GameColors.textBlack,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: GameColors.textBlack,
            ),
          ),
        ],
      ),
    );
  }

  Color _getResultColor(double accuracy) {
    if (accuracy >= 80) return GameColors.correctGreen;
    if (accuracy >= 60) return GameColors.accentBlue;
    if (accuracy >= 40) return Colors.orange;
    return GameColors.wrongRed;
  }

  String _getPerformanceText(double accuracy) {
    if (accuracy >= 80) return 'Excellent Performance!';
    if (accuracy >= 60) return 'Good Performance';
    if (accuracy >= 40) return 'Average Performance';
    return 'Needs Improvement';
  }
}

class StackResultDialog extends StatefulWidget {
  final StackModel stack;
  final StageStackManager stageStackManager;
  final int autoCloseDuration;

  const StackResultDialog({
    super.key,
    required this.stack,
    required this.stageStackManager,
    this.autoCloseDuration = 3000,
  });

  @override
  State<StackResultDialog> createState() => _StackResultDialogState();
}

class _StackResultDialogState extends State<StackResultDialog> {
  @override
  void initState() {
    super.initState();
    
    // Auto-close timer
    if (widget.autoCloseDuration > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(Duration(milliseconds: widget.autoCloseDuration), () {
          if (mounted && Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: GameColors.dialogBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: GameColors.textBlack, width: 3),
      ),
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              'Stack ${widget.stack.stackNumber} Complete!',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: GameColors.primaryPurple,
              ),
            ),
            const SizedBox(height: 16),

            // All Stacks Grid (4 columns)
            _buildAllStacksGrid(),
            const SizedBox(height: 16),

            // Current Stack Hexagram info
            _buildHexagramInfo(),

            // Stage results
            const SizedBox(height: 16),
            const Text(
              'Stage Results:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: GameColors.textBlack,
              ),
            ),
            const SizedBox(height: 10),

            ...widget.stack.stages.reversed.map((stage) =>
              _buildStageRow(stage)
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHexagramInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'I-Ching Hexagram (64 Gua)',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: GameColors.primaryPurple,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Text(
              widget.stack.gua64Symbol ?? '',
              style: const TextStyle(fontSize: 64),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${widget.stack.gua64Name} (${widget.stack.gua64Pinyin})',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: GameColors.textBlack,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Binary: ${widget.stack.binaryResult}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${widget.stack.stack_zh ?? ''}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                      color: GameColors.textBlack,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${widget.stack.stack_en ?? ''}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                      color: GameColors.textBlack,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStageRow(StageModel stage) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Stage ${stage.stageId}: ${stage.gua8Name}',
              style: const TextStyle(
                fontSize: 14,
                color: GameColors.textBlack,
              ),
            ),
          ),
          Expanded(
            child: Text(
              '${stage.gua8Symbol ?? ''} ${stage.binaryResult ?? ''}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: GameColors.textBlack,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '$label:',
              style: const TextStyle(
                fontSize: 16,
                color: GameColors.textBlack,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: GameColors.textBlack,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllStacksGrid() {
    final allStacks = widget.stageStackManager.stacks;
    final currentStack = widget.stack;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: GameColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: GameColors.textBlack, width: 1),
      ),
      child: Column(
        children: [
          const Text(
            'All Stacks (64 Gua)',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: GameColors.textBlack,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: allStacks.map((stack) {
              final isCurrentStack = currentStack.stackNumber == stack.stackNumber;
              final isStackComplete = stack.isComplete;
              final symbol = stack.gua64Symbol ?? '?';
              
              return Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: isStackComplete 
                      ? GameColors.primaryPurple.withOpacity(0.1)
                      : GameColors.background,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isCurrentStack 
                        ? GameColors.secondaryYellow 
                        : GameColors.textBlack,
                    width: isCurrentStack ? 3 : 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'S${stack.stackNumber}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isCurrentStack ? GameColors.secondaryYellow : GameColors.textBlack,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      symbol,
                      style: TextStyle(
                        fontSize: 32,
                        color: isStackComplete ? GameColors.primaryPurple : Colors.grey,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class WarningDialog extends StatefulWidget {
  final String title;
  final String message;
  final int autoCloseDuration;

  const WarningDialog({
    super.key,
    required this.title,
    required this.message,
    this.autoCloseDuration = 3000,
  });

  @override
  State<WarningDialog> createState() => _WarningDialogState();
}

class _WarningDialogState extends State<WarningDialog> {
  @override
  void initState() {
    super.initState();
    
    // Auto-close timer
    if (widget.autoCloseDuration > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(Duration(milliseconds: widget.autoCloseDuration), () {
          if (mounted && Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: GameColors.dialogBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Colors.red, width: 3),
      ),
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Warning icon
            const Icon(
              Icons.warning,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 20),

            // Title
            Text(
              widget.title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 16),

            // Message
            Text(
              widget.message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                color: GameColors.textBlack,
              ),
            ),
            const SizedBox(height: 24),

            // Note
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.yellow.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.yellow, width: 1),
              ),
              child: const Text(
                'Tip: You may check Hint for help.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.orange,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class InstructionDialog extends StatefulWidget {
  final int autoCloseDuration;

  const InstructionDialog({
    super.key,
    this.autoCloseDuration = 3000,
  });

  @override
  State<InstructionDialog> createState() => _InstructionDialogState();
}

class _InstructionDialogState extends State<InstructionDialog> {
  @override
  void initState() {
    super.initState();
    
    // Auto-close timer
    if (widget.autoCloseDuration > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(Duration(milliseconds: widget.autoCloseDuration), () {
          if (mounted && Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: GameColors.dialogBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: GameColors.textBlack, width: 3),
      ),
      child: Container(
        width: 500,
        height: 600,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            const Text(
              'Pouch Ape Poker 2026 preview',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: GameColors.primaryPurple,
              ),
            ),
            const SizedBox(height: 20),
            const Divider(color: GameColors.textBlack, thickness: 1),

            // Content - Scrollable
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('▶️ How to Play'),
                    _buildBulletPoint('Guess whether your card is "Higher", "Tie", or "Lower" than the computer’s card.'),

                    const SizedBox(height: 24),
                    _buildSectionTitle('💡 Tips'),
                    _buildBulletPoint('"Hint" shows the probability of each option.'),
                    _buildBulletPoint('"Shuffle" the deck anytime you like.'),

                    const SizedBox(height: 20),
                    _buildSectionTitle('📊 Game Reports'),
                    _buildBulletPoint('Results are shown using hexagrams from the I Ching, an ancient Chinese system once used to predict the future.'),
                    _buildBulletPoint('Reports also include round probabilities and win/loss scores.'),
                    _buildBulletPoint('Correct guesses earn a base score. Lower-probability wins give extra bonus points.'),
                    _buildBulletPoint('The game explores whether cautious or bold strategies work better — and tests user memory and probability estimation.'),
                  ],
                ),
              ),
            ),

            // Close button (only if auto-close is disabled)
            if (widget.autoCloseDuration <= 0) ...[
              const Divider(color: GameColors.textBlack, thickness: 1),
              const SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GameColors.primaryGreen,
                    foregroundColor: GameColors.textWhite,
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                  ),
                  child: const Text(
                    'Got It!',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: GameColors.primaryPurple,
        ),
      ),
    );
  }

  Widget _buildNumberedStep(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      child: Text(
        text,
        style: const TextStyle(fontSize: 16, height: 1.5),
      ),
    );
  }

  Widget _buildBulletPoint(String text, {List<TextSpan>? children}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('* ', style: TextStyle(fontSize: 16)),
          Expanded(
            child: children != null
                ? Text.rich(
                    TextSpan(
                      style: const TextStyle(fontSize: 16, height: 1.5, color: Colors.black),
                      children: children,
                    ),
                  )
                : Text(
                    text,
                    style: const TextStyle(fontSize: 16, height: 1.5, color: Colors.black),
                  ),
          ),
        ],
      ),
    );
  }
}

class ReportsDialog extends StatelessWidget {
  final Map<String, dynamic> reports;
  final int autoCloseDuration;

  const ReportsDialog({
    super.key,
    required this.reports,
    this.autoCloseDuration = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: GameColors.dialogBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: GameColors.textBlack, width: 3),
      ),
      child: Container(
        width: 500,
        height: 600,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Game Reports',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: GameColors.primaryPurple,
              ),
            ),
            const SizedBox(height: 20),
            const Divider(color: GameColors.textBlack, thickness: 1),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Add your report content here
                    const Text('Game Statistics:'),
                    // Display reports data
                    ..._buildReportSections(),
                  ],
                ),
              ),
            ),

            const Divider(color: GameColors.textBlack, thickness: 1),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: GameColors.primaryGreen,
                  foregroundColor: GameColors.textWhite,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                ),
                child: const Text(
                  'Next',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildReportSections() {
    // Convert reports to display widgets
    final List<Widget> sections = [];
    
    reports.forEach((key, value) {
      sections.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            '$key: $value',
            style: const TextStyle(fontSize: 16),
          ),
        ),
      );
    });
    
    return sections;
  }
}

class FinalScoresDialog extends StatelessWidget {
  final int totalScore;
  final int baseline;
  final int autoCloseDuration;
  // final VoidCallback? onPlayAgain;
  final VoidCallback? onExit;

  const FinalScoresDialog({
    super.key,
    required this.totalScore,
    required this.baseline,
    this.autoCloseDuration = 0,
    // this.onPlayAgain,
    this.onExit,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = baseline > 0 ? (totalScore / baseline) * 100 : 0;
    final performanceColor = _getPerformanceColor(percentage/1.0);

    return Dialog(
      backgroundColor: GameColors.dialogBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: GameColors.textBlack, width: 3),
      ),
      child: Container(
        width: 450,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Final Scores',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: GameColors.primaryPurple,
              ),
            ),
            const SizedBox(height: 30),

            _buildScoreRow('Your Score', totalScore, GameColors.positiveScore),
            _buildScoreRow('Baseline Score', baseline, GameColors.textBlack),
            
            const Divider(color: GameColors.textBlack, thickness: 2),
            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: performanceColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: performanceColor, width: 2),
              ),
              child: Text(
                'Performance: ${percentage.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: performanceColor,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Logo
            Image.asset(
              'assets/logo/ape_full_256.png',
              // '../../../../assets/logo/ape_full_256.png',
              width: 200,
              height: 200,
              fit: BoxFit.contain,
            ),

            const SizedBox(height: 20),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                /*
                // Play Again button
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close the dialog
                    onPlayAgain?.call(); // Trigger play again callback
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GameColors.primaryGreen,
                    foregroundColor: GameColors.textWhite,
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.replay, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Play Again',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                */

                // Exit button
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close the dialog
                    onExit?.call(); // Trigger exit callback
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: GameColors.textWhite,
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.exit_to_app, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Exit',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildScoreRow(String label, int score, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: GameColors.textBlack,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color, width: 2),
            ),
            child: Text(
              score.toString(),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }




  Color _getPerformanceColor(double percentage) {
    if (percentage >= 120) return GameColors.correctGreen;
    if (percentage >= 100) return Colors.green;
    if (percentage >= 80) return Colors.yellow;
    if (percentage >= 60) return Colors.orange;
    return GameColors.wrongRed;
  }

  String _getPerformanceText(double percentage) {
    if (percentage >= 120) return 'Outstanding! You beat the baseline by ${percentage - 100}%';
    if (percentage >= 100) return 'Excellent! You matched the baseline';
    if (percentage >= 80) return 'Good effort! Close to the baseline';
    if (percentage >= 60) return 'Keep practicing!';
    return 'Try again for better results!';
  }
}

/// Basic Hint Dialog showing current round probabilities
class BasicHintDialog extends StatelessWidget {
  final Map<String, dynamic> probabilities;
  final VoidCallback onGameHistory;
  final VoidCallback onUnrevealedCards;

  const BasicHintDialog({
    super.key,
    required this.probabilities,
    required this.onGameHistory,
    required this.onUnrevealedCards,
  });

  @override
  Widget build(BuildContext context) {
    final formattedProbs = probabilities['probabilities'] as Map<String, dynamic>;
    final higherProbStr = formattedProbs['higher'] as String;
    final tieProbStr = formattedProbs['tie'] as String;
    final lowerProbStr = formattedProbs['lower'] as String;
    
    // Get card counts for intermediate steps
    final higherCount = probabilities['higherCount'] as int? ?? 0;
    final tieCount = probabilities['tieCount'] as int? ?? 0;
    final lowerCount = probabilities['lowerCount'] as int? ?? 0;
    final totalUnrevealed = probabilities['totalUnrevealed'] as int? ?? 0;

    return Dialog(
      backgroundColor: GameColors.dialogBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: GameColors.textBlack, width: 3),
      ),
      child: Container(
        width: 450,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            const Text(
              'Basic Hint',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: GameColors.primaryPurple,
              ),
            ),
            const SizedBox(height: 20),

            // Probabilities with intermediate steps
            _buildProbabilityRow('Higher', higherProbStr, higherCount, totalUnrevealed),
            const SizedBox(height: 12),
            _buildProbabilityRow('Tie', tieProbStr, tieCount, totalUnrevealed),
            const SizedBox(height: 12),
            _buildProbabilityRow('Lower', lowerProbStr, lowerCount, totalUnrevealed),
            const SizedBox(height: 20),

            // Buttons
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildDialogButton(
                  'Back to Game',
                  () => Navigator.of(context).pop(),
                  GameColors.primaryPurple,
                ),
                const SizedBox(height: 10),
                _buildDialogButton(
                  'Game History',
                  () {
                    Navigator.of(context).pop();
                    onGameHistory();
                  },
                  GameColors.secondaryYellow,
                ),
                const SizedBox(height: 10),
                _buildDialogButton(
                  'Unrevealed Cards',
                  () {
                    Navigator.of(context).pop();
                    onUnrevealedCards();
                  },
                  GameColors.primaryGreen,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProbabilityRow(String label, String probabilityStr, int count, int total) {
    // probabilityStr is already formatted like "50.0%"
    // Display intermediate step: count/total = percentage
    final intermediateStep = total > 0 ? '$count/$total = $probabilityStr' : probabilityStr;
    
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: GameColors.textBlack,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: GameColors.primaryPurple.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: GameColors.primaryPurple, width: 2),
          ),
          child: Text(
            intermediateStep,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: GameColors.primaryPurple,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDialogButton(String label, VoidCallback onPressed, Color color) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: GameColors.textBlack, width: 2),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// Game History Hint Dialog showing previous rounds
class GameHistoryHintDialog extends StatelessWidget {
  final List<Map<String, dynamic>> history;

  const GameHistoryHintDialog({
    super.key,
    required this.history,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: GameColors.dialogBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: GameColors.textBlack, width: 3),
      ),
      child: Container(
        width: 500,
        height: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Title
            const Text(
              'Game History',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: GameColors.primaryPurple,
              ),
            ),
            const SizedBox(height: 20),

            // History list with scrollbar
            Expanded(
              child: ListView.builder(
                itemCount: history.length,
                itemBuilder: (context, index) {
                  final round = history[index];
                  return _buildHistoryRow(round);
                },
              ),
            ),
            const SizedBox(height: 20),

            // Back to Game button
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: GameColors.primaryPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: GameColors.textBlack, width: 2),
                ),
              ),
              child: const Text(
                'Back to Game',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryRow(Map<String, dynamic> round) {
    final roundNumber = round['roundNumber'] as int;
    final computerCard = round['computerCard'] as String;
    final userCard = round['userCard'] as String;
    final result = round['result'] as String;
    final isWin = result == 'win';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isWin 
            ? GameColors.correctGreen.withOpacity(0.1)
            : GameColors.wrongRed.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isWin ? GameColors.correctGreen : GameColors.wrongRed,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Text(
            'R$roundNumber',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: GameColors.textBlack,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            computerCard,
            style: const TextStyle(
              fontSize: 14,
              color: GameColors.textBlack,
            ),
          ),
          const SizedBox(width: 8),
          const Text('vs', style: TextStyle(color: Colors.grey)),
          const SizedBox(width: 8),
          Text(
            userCard,
            style: const TextStyle(
              fontSize: 14,
              color: GameColors.textBlack,
            ),
          ),
          const Spacer(),
          Icon(
            isWin ? Icons.check_circle : Icons.cancel,
            color: isWin ? GameColors.correctGreen : GameColors.wrongRed,
            size: 20,
          ),
        ],
      ),
    );
  }
}

/// Unrevealed Cards Hint Dialog showing remaining cards
class UnrevealedCardsHintDialog extends StatelessWidget {
  final List<Map<String, dynamic>> unrevealedCards;

  const UnrevealedCardsHintDialog({
    super.key,
    required this.unrevealedCards,
  });

  @override
  Widget build(BuildContext context) {
    // Group cards by suit
    final spadeCards = <Map<String, dynamic>>[];
    final heartCards = <Map<String, dynamic>>[];
    final clubCards = <Map<String, dynamic>>[];
    final diamondCards = <Map<String, dynamic>>[];
    final jokerCards = <Map<String, dynamic>>[];

    for (final card in unrevealedCards) {
      final suit = card['suit'] as String?;
      if (suit == null) {
        jokerCards.add(card);
      } else if (suit == 'Spade') {
        spadeCards.add(card);
      } else if (suit == 'Heart') {
        heartCards.add(card);
      } else if (suit == 'Club') {
        clubCards.add(card);
      } else if (suit == 'Diamond') {
        diamondCards.add(card);
      }
    }

    // Sort each column by value
    spadeCards.sort((a, b) => (a['value'] as int).compareTo(b['value'] as int));
    heartCards.sort((a, b) => (a['value'] as int).compareTo(b['value'] as int));
    clubCards.sort((a, b) => (a['value'] as int).compareTo(b['value'] as int));
    diamondCards.sort((a, b) => (a['value'] as int).compareTo(b['value'] as int));
    jokerCards.sort((a, b) => (a['value'] as int).compareTo(b['value'] as int));

    return Dialog(
      backgroundColor: GameColors.dialogBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: GameColors.textBlack, width: 3),
      ),
      child: Container(
        width: 700,
        height: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Title
            const Text(
              'Unrevealed Cards',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: GameColors.primaryPurple,
              ),
            ),
            const SizedBox(height: 20),

            // 5-column table
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCardColumn('♠ Spade', spadeCards, Colors.black),
                  const SizedBox(width: 8),
                  _buildCardColumn('♥ Heart', heartCards, Colors.red),
                  const SizedBox(width: 8),
                  _buildCardColumn('♣ Club', clubCards, Colors.black),
                  const SizedBox(width: 8),
                  _buildCardColumn('♦ Diamond', diamondCards, Colors.red),
                  const SizedBox(width: 8),
                  _buildCardColumn('★ Jokers', jokerCards, GameColors.secondaryYellow),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Back to Game button
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: GameColors.primaryPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: GameColors.textBlack, width: 2),
                ),
              ),
              child: const Text(
                'Back to Game',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardColumn(String title, List<Map<String, dynamic>> cards, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.lightGreen.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color, width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Column header
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const Divider(color: Colors.grey, thickness: 1),
            const SizedBox(height: 8),

            // Card list
            Expanded(
              child: ListView.builder(
                itemCount: cards.length,
                itemBuilder: (context, index) {
                  final card = cards[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      card['name'] as String,
                      style: TextStyle(
                        fontSize: 14,
                        color: color,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dialog shown after shuffling the deck
class ShuffleDialog extends StatefulWidget {
  final int shuffleNumber;
  final String shuffleTime;
  final String shuffleSeed;
  final int gameSpeed;

  const ShuffleDialog({
    super.key,
    required this.shuffleNumber,
    required this.shuffleTime,
    required this.shuffleSeed,
    required this.gameSpeed,
  });

  @override
  State<ShuffleDialog> createState() => _ShuffleDialogState();
}

class _ShuffleDialogState extends State<ShuffleDialog> {
  @override
  void initState() {
    super.initState();
    
    // Calculate auto-close duration based on game speed
    final autoCloseDuration = _getAutoCloseDuration();
    
    // Auto-close timer
    if (autoCloseDuration > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(Duration(milliseconds: autoCloseDuration), () {
          if (mounted && Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        });
      });
    }
  }

  int _getAutoCloseDuration() {
    switch (widget.gameSpeed) {
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

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: GameColors.dialogBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: GameColors.primaryPurple, width: 3),
      ),
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Icon(
              Icons.shuffle,
              size: 48,
              color: GameColors.primaryPurple,
            ),
            const SizedBox(height: 16),
            
            // Title
            const Text(
              'Card Deck Shuffled',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: GameColors.primaryPurple,
              ),
            ),
            const SizedBox(height: 20),
            
            // Shuffle number
            _buildInfoRow('Shuffle Number', widget.shuffleNumber.toString()),
            const SizedBox(height: 12),
            
            // Shuffle time
            _buildInfoRow('Date time', widget.shuffleTime),
            const SizedBox(height: 12),
            
            // Shuffle seed
            _buildInfoRow('Seed', widget.shuffleSeed),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: GameColors.textBlack,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: GameColors.primaryPurple,
          ),
        ),
      ],
    );
  }
}

