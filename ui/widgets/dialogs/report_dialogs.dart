import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../styles/game_colors.dart';
import '../../../helper/ui_debug_logger.dart';

/// Report 1: Stage and Stack Summary
class Report1_StageStackSummary extends StatelessWidget {
  final Map<String, dynamic> reports;
  final VoidCallback onNext;

  const Report1_StageStackSummary({
    super.key,
    required this.reports,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    UIDebugLogger.logDialog('Report1', 'Building Report1 dialog');
    
    final stackSummary = reports['stackSummary'] as Map<String, dynamic>?;
    final stageSummary = reports['stageSummary'] as Map<String, dynamic>?;
    final stackDetails = stackSummary?['stackDetails'] as List<dynamic>? ?? [];
    final stageDetails = stageSummary?['stageDetails'] as List<dynamic>? ?? [];
    
    UIDebugLogger.logDialog('Report1', 'stackSummary: $stackSummary');
    UIDebugLogger.logDialog('Report1', 'stageSummary: $stageSummary');
    UIDebugLogger.logDialog('Report1', 'stackDetails length: ${stackDetails.length}');
    UIDebugLogger.logDialog('Report1', 'stageDetails length: ${stageDetails.length}');

    return Dialog(
      backgroundColor: GameColors.dialogBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: GameColors.textBlack, width: 3),
      ),
      child: Container(
        width: 800,
        height: 700,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Report 1: Stage & Stack Summary',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: GameColors.primaryPurple,
              ),
            ),
            const SizedBox(height: 20),
            const Divider(color: GameColors.textBlack, thickness: 2),

            // Stack Summary (Top Row)
            const SizedBox(height: 10),
            const Text(
              'Stack Summary',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: GameColors.textBlack,
              ),
            ),
            const SizedBox(height: 10),
            _buildStackGrid(stackDetails, stageSummary!),

            const SizedBox(height: 20),

            // Stage Summary (Bottom Row)
            const Text(
              'Stage Summary',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: GameColors.textBlack,
              ),
            ),
            const SizedBox(height: 28),
            _buildStageGrid(stageDetails),

            const Spacer(),

            const Divider(color: GameColors.textBlack, thickness: 2),
            const SizedBox(height: 28),
            Center(
              child: ElevatedButton(
                onPressed: onNext,
                style: ElevatedButton.styleFrom(
                  backgroundColor: GameColors.primaryPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                ),
                child: const Text(
                  'Next Report',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStackGrid(List<dynamic> stackDetails, Map<String, dynamic> stageSummary) {
    UIDebugLogger.logDialog('Report1', '_buildStackGrid called with ${stackDetails.length} stacks');
    
    return Row(
      children: List.generate(4, (index) {
        final stack = stackDetails.length > index 
            ? stackDetails[index] as Map<String, dynamic>
            : null;
        
        UIDebugLogger.logDialog('Report1', 'Stack $index: $stack');
        
        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: GameColors.background,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: GameColors.textBlack, width: 2),
            ),
            child: Column(
              children: [
                Text(
                  'Stack${index + 1}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: GameColors.primaryPurple,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  stack?['symbol'] ?? '?',
                  style: const TextStyle(fontSize: 40),
                ),
                const SizedBox(height: 6),
                Text(
                  stack?['binary'] ?? 'Incomplete',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                if (stack != null && stack['stages'] != null && (stack['stages'] as List).length >= 2)
                  _buildStackEndTime(stack['stages'] as List, stageSummary)
                else if (stack != null && stack['endTime'] != null)
                  Text(
                    _formatDateTime(stack['endTime']),
                    style: const TextStyle(
                      fontSize: 11,
                      color: GameColors.textBlack,
                    ),
                  ),
              ],
            ),
          ),
        );
      }),
    );
  }


  Widget _buildStackEndTime(List<dynamic> stages, Map<String, dynamic> stackSummary) {
    if (stages.length >= 2) {
      final secondStageId = stages[1] as String;
      final stageDetails = stackSummary['stageDetails'] as List<dynamic>? ?? [];
      
      // Find the stage with matching stageId
      final secondStageData = stageDetails.firstWhere(
        (s) => (s as Map<String, dynamic>)['stageId'] == secondStageId,
        orElse: () => <String, dynamic>{},
      );
      
      if (secondStageData.isNotEmpty && secondStageData['endTime'] != null) {
        return Text(
          _formatDateTime(secondStageData['endTime']),
          style: const TextStyle(
            fontSize: 12,
            color: GameColors.textBlack,
          ),
        );
      }
    }
    return const SizedBox.shrink();
  }

  Widget _buildStageGrid(List<dynamic> stageDetails) {
    UIDebugLogger.logDialog('Report1', '_buildStageGrid called with ${stageDetails.length} stages');
    
    // Row 1: StageB, StageD, StageF, StageH, empty
    // Row 2: StageA, StageC, StageE, StageG, StageI
    final row1StageIds = ['B', 'D', 'F', 'H', null];
    final row2StageIds = ['A', 'C', 'E', 'G', 'I'];
    
    UIDebugLogger.logDialog('Report1', 'stageDetails: $stageDetails');

    return Column(
      children: [
        _buildStageRow(row1StageIds, stageDetails),
        const SizedBox(height: 8),
        _buildStageRow(row2StageIds, stageDetails),
      ],
    );
  }

  Widget _buildStageRow(List<String?> stageIds, List<dynamic> stageDetails) {
    UIDebugLogger.logDialog('Report1', '_buildStageRow: stageIds=$stageIds');
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: stageIds.map((stageId) {
        if (stageId == null) {
          return const SizedBox(width: 70, height: 78);
        }

        final stageData = stageDetails.firstWhere(
          (s) => (s as Map<String, dynamic>)['stageId'] == stageId,
          orElse: () => <String, dynamic>{},
        );

        final isComplete = stageData.isNotEmpty;
        final symbol = stageData['symbol'] ?? '?';
        
        UIDebugLogger.logDialog('Report1', 'Stage $stageId: stageData=$stageData, isComplete=$isComplete, symbol=$symbol');

        return Container(
          width: 70,
          height: 78,
          decoration: BoxDecoration(
            color: isComplete 
                ? GameColors.primaryPurple.withOpacity(0.1)
                : GameColors.background,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: GameColors.textBlack, width: 1),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                stageId,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: GameColors.textBlack,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                symbol,
                style: TextStyle(
                  fontSize: 26,
                  color: isComplete ? GameColors.primaryPurple : Colors.grey,
                ),
              ),
              if (stageData['duration'] != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    _formatDateTime(stageData['endTime']),
                    style: const TextStyle(
                      fontSize: 7,
                      color: GameColors.textBlack,
                    ),
                  ),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  String _formatDateTime(String? dateTimeStr) {
    if (dateTimeStr == null) return '';
    try {
      final dt = DateTime.parse(dateTimeStr);
      return '${dt.month.toString().padLeft(2, '0')}-'
             '${dt.day.toString().padLeft(2, '0')} '
             '${dt.hour.toString().padLeft(2, '0')}:'
             '${dt.minute.toString().padLeft(2, '0')}:'
             '${dt.second.toString().padLeft(2, '0')}';
    } catch (e) {
      return '';
    }
  }
}

/// Report 2: 4 Stack 64 Gua Explanation
class Report2_4Stack_64Gua_Explanation extends StatelessWidget {
  final Map<String, dynamic> reports;
  final VoidCallback onNext;

  const Report2_4Stack_64Gua_Explanation({
    super.key,
    required this.reports,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    UIDebugLogger.logDialog('Report2', 'Building Report2 dialog');
    
    final stackSummary = reports['stackSummary'] as Map<String, dynamic>?;
    final stackDetails = stackSummary?['stackDetails'] as List<dynamic>? ?? [];
    final hexagramExplanation = reports['hexagramExplanation'] as Map<String, dynamic>?;
    
    UIDebugLogger.logDialog('Report2', 'stackDetails length: ${stackDetails.length}');

    return Dialog(
      backgroundColor: GameColors.dialogBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: GameColors.textBlack, width: 3),
      ),
      child: Container(
        width: 900,
        height: 650,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Report 2: 64 Hexagram Explanation',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: GameColors.primaryPurple,
              ),
            ),
            const SizedBox(height: 20),
            const Divider(color: GameColors.textBlack, thickness: 2),

            Expanded(
              child: Row(
                children: List.generate(4, (index) {
                  final stack = stackDetails.length > index 
                      ? stackDetails[index] as Map<String, dynamic>
                      : null;
                  
                  return Expanded(
                    child: _buildStackCard(stack, index, hexagramExplanation),
                  );
                }),
              ),
            ),

            const Divider(color: GameColors.textBlack, thickness: 2),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: onNext,
                style: ElevatedButton.styleFrom(
                  backgroundColor: GameColors.primaryPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                ),
                child: const Text(
                  'Next Report',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStackCard(Map<String, dynamic>? stack, int index, Map<String, dynamic>? hexagramExplanation) {
    if (stack == null) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: GameColors.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: GameColors.textBlack, width: 2),
        ),
        child: Center(
          child: Text(
            'Stack ${index + 1}\nIncomplete',
            textAlign: TextAlign.center,
            style: const TextStyle(color: GameColors.textBrightGrey),
          ),
        ),
      );
    }

    final symbol = stack['symbol'] ?? '?';
    final nameZh = stack['name'] ?? 'Unknown';
    final namePinyin = stack['name_pinyin_std'] ?? '';
    final nameEn = stack['name_en_meaning'] ?? '';
    final stackZh = stack['description'] ?? '';
    final stackEn = stack['stack_en'] ?? '';
    final explanationZh = stack['explanation_zh'] ?? '';
    final explanationEn = stack['explanation_en'] ?? '';
    final luckZh = stack['luck_zh'] ?? '';
    final luckEn = stack['luck_en'] ?? '';
    final signZh = stack['sign_zh'] ?? '';
    final signEn = stack['sign_en'] ?? '';
    
    final color = _getSignColor(signZh.isNotEmpty ? signZh : signEn);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: GameColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Stack ${index + 1}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: GameColors.primaryPurple,
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              symbol,
              style: const TextStyle(fontSize: 52),
            ),
          ),
          const SizedBox(height: 4),
          // Name row: name_zh, name_pinyin_std, name_en_meaning
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                nameZh,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: GameColors.textBrightGold,
                ),
              ),
              if (namePinyin.isNotEmpty || nameEn.isNotEmpty)
                Text(
                  '$namePinyin${namePinyin.isNotEmpty && nameEn.isNotEmpty ? " - " : ""}$nameEn',
                  style: const TextStyle(
                    fontSize: 12,
                    color: GameColors.textBrightGreyDark,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 2),
          // Stack description row: stack_zh, stack_en
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                stackZh,
                style: const TextStyle(
                  fontSize: 12,
                  color: GameColors.textBrightGold,
                ),
              ),
              if (stackEn.isNotEmpty)
                Text(
                  stackEn,
                  style: const TextStyle(
                    fontSize: 11,
                    color: GameColors.textBrightGreyDark,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          // Explanation, Luck, Sign rows
          if (explanationZh.isNotEmpty)
            _buildInfoRow('Explanation (ZH):', explanationZh),
          if (explanationEn.isNotEmpty)
            _buildInfoRow('Explanation (EN):', explanationEn),
          if (luckZh.isNotEmpty)
            _buildInfoRow('Luck (ZH):', luckZh),
          if (luckEn.isNotEmpty)
            _buildInfoRow('Luck (EN):', luckEn),
          if (signZh.isNotEmpty || signEn.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: color, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (signZh.isNotEmpty)
                    Text(
                      signZh,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  if (signEn.isNotEmpty)
                    Text(
                      signEn,
                      style: TextStyle(
                        fontSize: 11,
                        color: color,
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: GameColors.textBrightGrey,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 11,
              color: GameColors.textWhite,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Color _getSignColor(String sign) {
    switch (sign.toLowerCase()) {
      case '大吉':
      case 'very auspicious':
        return Colors.green;
      case '吉':
      case 'auspicious':
        return Colors.lightGreen;
      case '平':
      case 'neutral':
        return Colors.yellow;
      case '凶':
      case 'inauspicious':
        return Colors.orange;
      case '大凶':
      case 'very inauspicious':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

/// Custom painter for X-shaped scatter points (for wrong answers)
class _ScatterXPainter extends FlDotPainter {
  final Color color;
  final double size;

  _ScatterXPainter({
    required this.color,
    required this.size,
  });

  @override
  Size getSize(FlSpot spot) => Size(size, size);

  @override
  void draw(Canvas canvas, FlSpot spot, Offset offset) {
    final halfSize = size / 2;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Draw X shape
    canvas.drawLine(
      Offset(offset.dx - halfSize, offset.dy - halfSize),
      Offset(offset.dx + halfSize, offset.dy + halfSize),
      paint,
    );
    canvas.drawLine(
      Offset(offset.dx + halfSize, offset.dy - halfSize),
      Offset(offset.dx - halfSize, offset.dy + halfSize),
      paint,
    );
  }

  @override
  Color get mainColor => color;

  @override
  FlDotPainter lerp(FlDotPainter a, FlDotPainter b, double t) {
    if (a is _ScatterXPainter && b is _ScatterXPainter) {
      return _ScatterXPainter(
        color: Color.lerp(a.color, b.color, t) ?? a.color,
        size: ui.lerpDouble(a.size, b.size, t) ?? a.size,
      );
    }
    return this;
  }

  @override
  List<Object?> get props => [color, size];
}

/// Report 3: Round Statistics
class Report3a_RoundStatistics extends StatelessWidget {
  final Map<String, dynamic> reports;
  final VoidCallback onNext;

  const Report3a_RoundStatistics({
    super.key,
    required this.reports,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final roundSummary = reports['roundSummary'] as Map<String, dynamic>?;
    final roundDetails = roundSummary?['roundDetails'] as List<dynamic>? ?? [];

    // Extract probability data
    final probabilities = _extractProbabilities(roundDetails);
    final stats = _calculateStatistics(probabilities);
    final histogramData = _calculateHistogram(probabilities);
    final categoryStats = _calculateCategoryStats(roundDetails);

    return Dialog(
      backgroundColor: GameColors.dialogBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: GameColors.textBlack, width: 3),
      ),
      child: Container(
        width: 800,
        height: 700,
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Report 3: Round Statistics',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: GameColors.primaryPurple,
                ),
              ),
              const SizedBox(height: 20),
              const Divider(color: GameColors.textBlack, thickness: 2),

              // Line Chart
              const Text(
                'Correct Answer Probability Trend',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: GameColors.textBlack,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 200,
                child: _buildLineChart(probabilities),
              ),

              const SizedBox(height: 20),

              // Histogram
              const Text(
                'Probability Distribution',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: GameColors.textBlack,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 150,
                child: _buildHistogram(histogramData),
              ),

              const SizedBox(height: 20),

              // Scatter Plot
              const Text(
                'Probability vs Result',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: GameColors.textBlack,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 150,
                child: _buildScatterPlot(roundDetails),
              ),

              const SizedBox(height: 20),

              // Statistics Summary
              _buildStatisticsSummary(stats, categoryStats),

              const SizedBox(height: 20),

              const Divider(color: GameColors.textBlack, thickness: 2),
              const SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: onNext,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GameColors.primaryPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                  ),
                  child: const Text(
                    'Next Report',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _extractProbabilities(List<dynamic> roundDetails) {
    return roundDetails.map((round) {
      final roundData = round as Map<String, dynamic>;
      final probs = roundData['probabilities'] as Map<String, dynamic>? ?? {};
      final correctProbStr = probs['correct'] as String? ?? '0%';
      final probValue = double.tryParse(correctProbStr.replaceAll('%', '')) ?? 0.0;
      return {
        'roundNumber': roundData['roundNumber'] as int? ?? 0,
        'probability': probValue,
        'isCorrect': roundData['isCorrect'] as bool? ?? false,
      };
    }).toList();
  }

  Map<String, double> _calculateStatistics(List<Map<String, dynamic>> probabilities) {
    if (probabilities.isEmpty) {
      return {'avg': 0.0, 'median': 0.0, 'min': 0.0, 'max': 0.0};
    }

    final values = probabilities.map((p) => p['probability'] as double).toList();
    values.sort();

    final avg = values.reduce((a, b) => a + b) / values.length;
    final min = values.first;
    final max = values.last;
    final median = values.length % 2 == 0
        ? (values[values.length ~/ 2 - 1] + values[values.length ~/ 2]) / 2
        : values[values.length ~/ 2];

    return {'avg': avg, 'median': median, 'min': min, 'max': max};
  }

  List<Map<String, dynamic>> _calculateHistogram(List<Map<String, dynamic>> probabilities) {
    final bins = [
      {'label': '0-10%', 'min': 0.0, 'max': 10.0, 'color': GameColors.probSuperLow},
      {'label': '10-30%', 'min': 10.0, 'max': 30.0, 'color': GameColors.probLow},
      {'label': '30-50%', 'min': 30.0, 'max': 50.0, 'color': GameColors.probLow},
      {'label': '50-70%', 'min': 50.0, 'max': 70.0, 'color': GameColors.probHigh},
      {'label': '70-90%', 'min': 70.0, 'max': 90.0, 'color': GameColors.probHigh},
      {'label': '90-100%', 'min': 90.0, 'max': 100.0, 'color': GameColors.probObviousWin},
    ];

    return bins.map((bin) {
      final count = probabilities.where((p) {
        final prob = p['probability'] as double;
        final min = bin['min'] as double;
        final max = bin['max'] as double;
        return prob >= min && prob < max;
      }).length;

      return {
        'label': bin['label'],
        'count': count,
        'color': bin['color'],
      };
    }).toList();
  }

  Map<String, dynamic> _calculateCategoryStats(List<dynamic> roundDetails) {
    final categories = {
      'obviousWin': {'label': 'Obvious Win (100%)', 'total': 0, 'correct': 0},
      'high': {'label': 'High (50-100%)', 'total': 0, 'correct': 0},
      'low': {'label': 'Low (10-50%)', 'total': 0, 'correct': 0},
      'superLow': {'label': 'Super Low (0-10%)', 'total': 0, 'correct': 0},
    };

    for (final round in roundDetails) {
      final roundData = round as Map<String, dynamic>;
      final probs = roundData['probabilities'] as Map<String, dynamic>? ?? {};
      final correctProbStr = probs['correct'] as String? ?? '0%';
      final probValue = double.tryParse(correctProbStr.replaceAll('%', '')) ?? 0.0;
      final isCorrect = roundData['isCorrect'] as bool? ?? false;

      String category;
      if (probValue >= 100) {
        category = 'obviousWin';
      } else if (probValue >= 50) {
        category = 'high';
      } else if (probValue >= 10) {
        category = 'low';
      } else {
        category = 'superLow';
      }

      final currentTotal = categories[category]!['total'] as int;
      final currentCorrect = categories[category]!['correct'] as int;
      categories[category]!['total'] = currentTotal + 1;
      if (isCorrect) {
        categories[category]!['correct'] = currentCorrect + 1;
      }
    }

    return categories;
  }

  Widget _buildLineChart(List<Map<String, dynamic>> probabilities) {
    if (probabilities.isEmpty) {
      return const Center(child: Text('No data available'));
    }

    final spots = probabilities.asMap().entries.map((entry) {
      final index = entry.key;
      final prob = entry.value['probability'] as double;
      return FlSpot(index.toDouble(), prob);
    }).toList();

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 20,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey.withOpacity(0.3),
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 5,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(fontSize: 10, color: GameColors.textBlack),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              interval: 20,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toInt()}%',
                  style: const TextStyle(fontSize: 10, color: GameColors.textBlack),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: GameColors.textBlack, width: 1),
        ),
        minX: 0,
        maxX: (probabilities.length - 1).toDouble(),
        minY: 0,
        maxY: 100,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: false,
            color: GameColors.primaryPurple,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                final prob = probabilities[index]['probability'] as double;
                Color color;
                if (prob >= 100) {
                  color = GameColors.probObviousWin;
                } else if (prob >= 50) {
                  color = GameColors.probHigh;
                } else if (prob >= 10) {
                  color = GameColors.probLow;
                } else {
                  color = GameColors.probSuperLow;
                }
                return FlDotCirclePainter(
                  radius: 4,
                  color: color,
                  strokeWidth: 0,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              color: GameColors.primaryPurple.withOpacity(0.1),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final index = spot.x.toInt();
                final prob = probabilities[index]['probability'] as double;
                return LineTooltipItem(
                  'R${index + 1}: ${prob.toStringAsFixed(1)}%',
                  const TextStyle(color: GameColors.textBlack, fontSize: 12),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHistogram(List<Map<String, dynamic>> histogramData) {
    final maxCount = histogramData.map((bin) => bin['count'] as int).reduce((a, b) => a > b ? a : b);

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxCount.toDouble() * 1.3,
        barGroups: histogramData.map((bin) {
          final count = bin['count'] as int;
          return BarChartGroupData(
            x: histogramData.indexOf(bin),
            barRods: [
              BarChartRodData(
                toY: count.toDouble(),
                color: Colors.blue,
                width: 40,
                borderRadius: BorderRadius.zero,
              ),
            ],
          );
        }).toList(),
        gridData: const FlGridData(show: false),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < histogramData.length) {
                  final count = histogramData[index]['count'] as int;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Text(
                      count.toString(),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: GameColors.textBlack,
                      ),
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < histogramData.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      histogramData[index]['label'] as String,
                      style: const TextStyle(fontSize: 9, color: GameColors.textBlack),
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(fontSize: 10, color: GameColors.textBlack),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: GameColors.textBlack, width: 1),
        ),
        barTouchData: const BarTouchData(enabled: false),
      ),
    );
  }

  Widget _buildScatterPlot(List<dynamic> roundDetails) {
    final correctSpots = <FlSpot>[];
    final wrongSpots = <FlSpot>[];

    for (final round in roundDetails) {
      final roundData = round as Map<String, dynamic>;
      final roundNumber = roundData['roundNumber'] as int? ?? 0;
      final probs = roundData['probabilities'] as Map<String, dynamic>? ?? {};
      final correctProbStr = probs['correct'] as String? ?? '0%';
      final probValue = double.tryParse(correctProbStr.replaceAll('%', '')) ?? 0.0;
      final isCorrect = roundData['isCorrect'] as bool? ?? false;

      if (isCorrect) {
        correctSpots.add(FlSpot(roundNumber.toDouble(), probValue));
      } else {
        wrongSpots.add(FlSpot(roundNumber.toDouble(), probValue));
      }
    }

    if (correctSpots.isEmpty && wrongSpots.isEmpty) {
      return const Center(child: Text('No data available'));
    }

    return ScatterChart(
      ScatterChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 20,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey.withOpacity(0.3),
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 5,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(fontSize: 10, color: GameColors.textBlack),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              interval: 20,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toInt()}%',
                  style: const TextStyle(fontSize: 10, color: GameColors.textBlack),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: GameColors.textBlack, width: 1),
        ),
        minX: 0,
        maxX: (roundDetails.length).toDouble(),
        minY: 0,
        maxY: 100,
        scatterSpots: [
          ...correctSpots.map((spot) => ScatterSpot(
            spot.x,
            spot.y,
            show: true,
            dotPainter: FlDotCirclePainter(
              radius: 6,
              color: GameColors.correctGreen,
              strokeWidth: 0,
            ),
          )),
          ...wrongSpots.map((spot) => ScatterSpot(
            spot.x,
            spot.y,
            show: true,
            dotPainter: _ScatterXPainter(
              color: GameColors.wrongRed,
              size: 10,
            ),
          )),
        ],
        scatterTouchData: ScatterTouchData(
          touchTooltipData: ScatterTouchTooltipData(
            getTooltipItems: (touchedSpot) {
              final roundNumber = touchedSpot.x.toInt();
              if (roundNumber > 0 && roundNumber <= roundDetails.length) {
                final roundData = roundDetails[roundNumber - 1] as Map<String, dynamic>;
                final isCorrect = roundData['isCorrect'] as bool? ?? false;
                return ScatterTooltipItem(
                  'R$roundNumber: ${touchedSpot.y.toStringAsFixed(1)}%\n${isCorrect ? "✓ Correct" : "✗ Wrong"}',
                  textStyle: const TextStyle(color: GameColors.textBlack, fontSize: 12),
                );
              }
              return null;
            },
          ),
        ),
      ),
    );
  }

  Widget _buildStatisticsSummary(Map<String, double> stats, Map<String, dynamic> categoryStats) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: GameColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: GameColors.textBlack, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Statistics Summary',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: GameColors.textWhite,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatItem('Average Probability', '${stats['avg']?.toStringAsFixed(1) ?? 0}%'),
              ),
              Expanded(
                child: _buildStatItem('Median Probability', '${stats['median']?.toStringAsFixed(1) ?? 0}%'),
              ),
              Expanded(
                child: _buildStatItem('Min Probability', '${stats['min']?.toStringAsFixed(1) ?? 0}%'),
              ),
              Expanded(
                child: _buildStatItem('Max Probability', '${stats['max']?.toStringAsFixed(1) ?? 0}%'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: Colors.grey),
          const SizedBox(height: 12),
          const Text(
            'Success Rate by Category',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: GameColors.textWhite,
            ),
          ),
          const SizedBox(height: 8),
          ...categoryStats.entries.map((entry) {
            final cat = entry.value as Map<String, dynamic>;
            final total = cat['total'] as int;
            final correct = cat['correct'] as int;
            final successRate = total > 0 ? (correct / total * 100).toStringAsFixed(0) : '0';
            final label = cat['label'] as String;
            
            Color color;
            if (entry.key == 'obviousWin') {
              color = GameColors.probObviousWin;
            } else if (entry.key == 'high') {
              color = GameColors.probHigh;
            } else if (entry.key == 'low') {
              color = GameColors.probLow;
            } else {
              color = GameColors.probSuperLow;
            }

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '$label: $successRate% correct ($correct/$total)',
                      style: const TextStyle(fontSize: 12, color: GameColors.textWhite),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: GameColors.textBrightGrey,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
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

/// Report 4: Guess Accuracy
class Report3_GuessAccuracy extends StatelessWidget {
  final Map<String, dynamic> reports;
  final VoidCallback onNext;

  const Report3_GuessAccuracy({
    super.key,
    required this.reports,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final roundSummary = reports['roundSummary'] as Map<String, dynamic>?;
    final consecutiveWins = reports['consecutiveWins'] as Map<String, dynamic>?;
    
    final totalRounds = roundSummary?['totalRounds'] as int? ?? 0;
    final correctRounds = roundSummary?['correctRounds'] as int? ?? 0;
    final accuracy = roundSummary?['accuracy'] as double? ?? 0.0;

    return Dialog(
      backgroundColor: GameColors.dialogBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: GameColors.textBlack, width: 3),
      ),
      child: Container(
        width: 700,
        height: 600,
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Report 4: Guess Accuracy',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: GameColors.primaryPurple,
                ),
              ),
              const SizedBox(height: 20),
              const Divider(color: GameColors.textBlack, thickness: 2),

              // Overall Accuracy with Pie Chart
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Overall Accuracy',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: GameColors.textBlack,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '${accuracy.toStringAsFixed(1)}%',
                          style: const TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: GameColors.primaryPurple,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$correctRounds / $totalRounds',
                          style: const TextStyle(
                            fontSize: 16,
                            color: GameColors.textBlack,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 150,
                    height: 150,
                    child: PieChart(
                      PieChartData(
                        sections: [
                          PieChartSectionData(
                            value: correctRounds.toDouble(),
                            color: GameColors.correctGreen,
                            title: 'Correct',
                            radius: 50,
                          ),
                          PieChartSectionData(
                            value: (totalRounds - correctRounds).toDouble(),
                            color: GameColors.wrongRed,
                            title: 'Wrong',
                            radius: 50,
                          ),
                        ],
                        centerSpaceRadius: 30,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // Consecutive Performance
              const Text(
                'Consecutive Performance',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: GameColors.textBlack,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Longest Win Streak',
                      '${consecutiveWins?['longestWinStreak'] ?? 0}',
                      GameColors.correctGreen,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildStatCard(
                      'Longest Lose Streak',
                      '${consecutiveWins?['longestLoseStreak'] ?? 0}',
                      GameColors.wrongRed,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // Probability Category Performance
              const Text(
                'Performance by Probability Category',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: GameColors.textBlack,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 200,
                child: _buildProbabilityCategoryChart(
                  roundSummary,
                  reports['shuffleLuck'] as Map<String, dynamic>?,
                ),
              ),

              const SizedBox(height: 20),

              const Divider(color: GameColors.textBlack, thickness: 2),
              const SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: onNext,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GameColors.primaryPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                  ),
                  child: const Text(
                    'Next Report',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: 2),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: GameColors.textBlack,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProbabilityCategoryChart(
    Map<String, dynamic>? roundSummary,
    Map<String, dynamic>? shuffleLuck,
  ) {
    final roundDetails = roundSummary?['roundDetails'] as List<dynamic>? ?? [];
    final categoryData = _calculateProbabilityCategoryData(roundDetails, shuffleLuck);

    final maxValue = categoryData.values.fold(0, (sum, data) {
      final total = (data['wins'] as int) + (data['losses'] as int);
      return sum > total ? sum : total;
    });

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxValue.toDouble() * 1.3,
        barGroups: categoryData.entries.map((entry) {
          final data = entry.value as Map<String, dynamic>;
          final wins = data['wins'] as int;
          final losses = data['losses'] as int;
          final index = categoryData.keys.toList().indexOf(entry.key);

          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: (wins + losses).toDouble(),
                width: 50,
                borderRadius: BorderRadius.zero,
                rodStackItems: [
                  BarChartRodStackItem(0, wins.toDouble(), GameColors.correctGreen),
                  BarChartRodStackItem(wins.toDouble(), (wins + losses).toDouble(), GameColors.wrongRed),
                ],
              ),
            ],
          );
        }).toList(),
        gridData: const FlGridData(show: false),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                final labels = categoryData.keys.toList();
                if (index >= 0 && index < labels.length) {
                  final data = categoryData[labels[index]] as Map<String, dynamic>;
                  final wins = data['wins'] as int;
                  final losses = data['losses'] as int;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Text(
                      '$wins win/$losses missed',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: GameColors.textBlack,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                final labels = categoryData.keys.toList();
                if (index >= 0 && index < labels.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      labels[index],
                      style: const TextStyle(fontSize: 10, color: GameColors.textBlack),
                      textAlign: TextAlign.center,
                    ),
                  );
                }
                return const Text('');
              },
              reservedSize: 80,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(fontSize: 10, color: GameColors.textBlack),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: GameColors.textBlack, width: 1),
        ),
        barTouchData: const BarTouchData(enabled: false),
      ),
    );
  }

  Map<String, Map<String, int>> _calculateProbabilityCategoryData(
    List<dynamic> roundDetails,
    Map<String, dynamic>? shuffleLuckReport,
  ) {
    final data = {
      'Highest\nProb\nWin': {'wins': 0, 'losses': 0},
      '2nd High\nProb\nWin': {'wins': 0, 'losses': 0},
      'Lowest\nProb\nWin': {'wins': 0, 'losses': 0},
    };

    // Build a map of round number to round data for quick lookup
    final roundMap = <int, Map<String, dynamic>>{};
    for (final round in roundDetails) {
      final roundData = round as Map<String, dynamic>;
      final roundNumber = roundData['roundNumber'] as int? ?? 0;
      roundMap[roundNumber] = roundData;
    }

    // Get shuffle details
    final shuffleDetails = shuffleLuckReport?['shuffleDetails'] as List<dynamic>? ?? [];

    if (shuffleDetails.isEmpty) {
      // Fallback to original logic if no shuffle data
      return data;
    }

    // Map round numbers to their category from shuffle predictions
    final roundCategoryMap = <int, String>{};

    // Process shuffles from last to first
    // Keep track of rounds that have already been assigned a category
    final assignedRounds = <int>{};

    // Sort shuffles by shuffle number descending (last to first)
    final sortedShuffles = List<Map<String, dynamic>>.from(
      shuffleDetails.map((s) => s as Map<String, dynamic>),
    );
    sortedShuffles.sort((a, b) => (b['shuffleNumber'] as int).compareTo(a['shuffleNumber'] as int));

    for (final shuffle in sortedShuffles) {
      final shuffleNumber = shuffle['shuffleNumber'] as int;
      final predictions = shuffle['predictions'] as List<dynamic>? ?? [];

      // Track rounds from this shuffle
      final shuffleRounds = <int>{};

      for (final prediction in predictions) {
        final pred = prediction as Map<String, dynamic>;
        final roundNumber = pred['roundNumber'] as int;

        // Skip if this round already has a category from a later shuffle
        if (assignedRounds.contains(roundNumber)) {
          continue;
        }

        // Map category
        final category = pred['category'] as String? ?? '';
        String displayCategory;

        switch (category) {
          case 'highest':
          case 'obvious':
            displayCategory = 'Highest\nProb\nWin';
            break;
          case 'second':
          case 'draw':
            displayCategory = '2nd High\nProb\nWin';
            break;
          case 'lowest':
            displayCategory = 'Lowest\nProb\nWin';
            break;
          default:
            continue; // Skip unknown categories
        }

        roundCategoryMap[roundNumber] = displayCategory;
        assignedRounds.add(roundNumber);
        shuffleRounds.add(roundNumber);
      }
    }

    // Count wins and losses based on categories
    for (final entry in roundCategoryMap.entries) {
      final roundNumber = entry.key;
      final category = entry.value;

      final roundData = roundMap[roundNumber];
      if (roundData == null) continue;

      final isCorrect = roundData['isCorrect'] as bool? ?? false;
      final categoryData = data[category];

      if (categoryData != null) {
        if (isCorrect) {
          categoryData['wins'] = (categoryData['wins'] as int? ?? 0) + 1;
        } else {
          categoryData['losses'] = (categoryData['losses'] as int? ?? 0) + 1;
        }
      }
    }

    return data;
  }
}

/// Report 5: Mistake Summary
class Report4_MistakeSummary extends StatelessWidget {
  final Map<String, dynamic> reports;
  final VoidCallback onNext;

  const Report4_MistakeSummary({
    super.key,
    required this.reports,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    UIDebugLogger.logDialog('Report4_MistakeSummary.build', 
      'Building Report4_MistakeSummary');
    
    UIDebugLogger.logDialog('Report4_MistakeSummary.build', 
      'reports keys: ${reports.keys.toList()}');
    
    final obviousMistakes = reports['obviousMistakes'] as Map<String, dynamic>?;
    UIDebugLogger.logDialog('Report4_MistakeSummary.build', 
      'obviousMistakes: $obviousMistakes');
    
    final mistakes = obviousMistakes?['mistakeDetails'] as List<dynamic>? ?? [];
    UIDebugLogger.logDialog('Report4_MistakeSummary.build', 
      'mistakes count: ${mistakes.length}, mistakes: $mistakes');
    
    final mistakeCounts = obviousMistakes?['mistakeCounts'] as Map<String, dynamic>? ?? {};
    UIDebugLogger.logDialog('Report4_MistakeSummary.build', 
      'mistakeCounts: $mistakeCounts');

    return Dialog(
      backgroundColor: GameColors.dialogBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: GameColors.textBlack, width: 3),
      ),
      child: Container(
        width: 650,
        height: 600,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Report 5: Mistake Summary',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: GameColors.wrongRed,
              ),
            ),
            const SizedBox(height: 20),
            const Divider(color: GameColors.textBlack, thickness: 2),

            // Mistake Types
            _buildMistakeTypeCard(mistakeCounts),

            const SizedBox(height: 20),

            // Mistake Details
            const Text(
              'Mistake Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: GameColors.textBlack,
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: mistakes.length,
                itemBuilder: (context, index) {
                  UIDebugLogger.logDialog('Report4_MistakeSummary.ListView', 
                    'Building item $index of ${mistakes.length}');
                  final mistake = mistakes[index] as Map<String, dynamic>;
                  return _buildMistakeRow(mistake);
                },
              ),
            ),

            const Divider(color: GameColors.textBlack, thickness: 2),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: onNext,
                style: ElevatedButton.styleFrom(
                  backgroundColor: GameColors.primaryPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                ),
                child: const Text(
                  'Next Report',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMistakeTypeCard(Map<String, dynamic> mistakeCounts) {
    // Get warning dialog count from reports
    final warningDialogCount = reports['warningDialogCount'] as int? ?? 0;
    
    // Define the order and display names
    final orderedMistakes = [
      {'key': 'missedObviousWin', 'display': 'Missed Obvious Win Answer'},
      {'key': 'impossibleOption', 'display': 'Impossible Option'},
      {'key': 'forgetRevealedCards', 'display': 'Forget Revealed Cards'},
      {'key': 'consecutiveMissedHighProb', 'display': 'Continuous Missed High-probability Answers'},
    ];
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: GameColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: GameColors.textBlack, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Mistake Types',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: GameColors.textBrightGold,
            ),
          ),
          const SizedBox(height: 8),
          ...orderedMistakes.map((mistake) {
            final key = mistake['key'] as String;
            final display = mistake['display'] as String;
            final count = key == 'consecutiveMissedHighProb' 
                ? warningDialogCount 
                : (mistakeCounts[key] as int? ?? 0);
            
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    display,
                    style: const TextStyle(
                      fontSize: 12,
                      color: GameColors.textBrightGrey,
                    ),
                  ),
                  Text(
                    '$count',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: GameColors.textBrightGreyDark,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildMistakeRow(Map<String, dynamic> mistake) {
    UIDebugLogger.logDialog('Report4_MistakeSummary._buildMistakeRow', 
      'Building mistake row: $mistake');
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: GameColors.wrongRed.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: GameColors.wrongRed, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Round number
          Text(
            'Round ${mistake['roundNumber']}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: GameColors.textBlack,
            ),
          ),
          const SizedBox(height: 8),
          // Row 2: Computer card and User card
          Row(
            children: [
              Text(
                'Computer Card: ${mistake['computerCard']}',
                style: const TextStyle(
                  fontSize: 12,
                  color: GameColors.textBrightGrey,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                'User Card: ${mistake['userCard']}',
                style: const TextStyle(
                  fontSize: 12,
                  color: GameColors.textBrightGrey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // Row 3: User choice and Correct answer
          Row(
            children: [
              Text(
                'User Choice: ${mistake['userGuess'] ?? 'N/A'}',
                style: const TextStyle(
                  fontSize: 12,
                  color: GameColors.textBrightGrey,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                'Correct Answer: ${mistake['correctAnswer'] ?? 'N/A'}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: GameColors.wrongRed,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Report 5: Radar Chart
class Report5_RadarChart extends StatelessWidget {
  final Map<String, dynamic> reports;
  final VoidCallback onNext;

  const Report5_RadarChart({
    super.key,
    required this.reports,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final scores = _calculateScores(reports);

    return Dialog(
      backgroundColor: GameColors.dialogBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: GameColors.textBlack, width: 3),
      ),
      child: Container(
        width: 700,
        height: 650,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Report 6: Performance Radar',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: GameColors.primaryPurple,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Preview Version! Dummy values for display only.',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 10),
            const Divider(color: GameColors.textBlack, thickness: 2),

            // Radar Chart
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 400,
                      child: RadarChart(
                        RadarChartData(
                          dataSets: [
                            RadarDataSet(
                              dataEntries: [
                                RadarEntry(value: scores['memory'] ?? 0),
                                RadarEntry(value: scores['highProb'] ?? 0),
                                RadarEntry(value: scores['careful'] ?? 0),
                                RadarEntry(value: scores['quick'] ?? 0),
                                RadarEntry(value: scores['luck'] ?? 0),
                              ],
                              fillColor: Colors.blue.withOpacity(0.3),
                              borderColor: Colors.blue,
                              borderWidth: 2,
                            ),
                          ],
                          radarBackgroundColor: Colors.transparent,
                          borderData: FlBorderData(show: true),
                          radarBorderData: const BorderSide(color: GameColors.textBlack, width: 2),
                          radarShape: RadarShape.polygon,
                          titleTextStyle: const TextStyle(
                            color: GameColors.textBlack,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                          tickCount: 5,
                          ticksTextStyle: const TextStyle(
                            color: Colors.grey,
                            fontSize: 10,
                          ),
                          
                          getTitle: (index, angle) {
                            final titles = ['Memory', 'High Prob', 'Careful', 'Quick', 'Luck'];
                            return RadarChartTitle(
                              text: titles[index],
                              angle: angle,
                              positionPercentageOffset: 0.15,
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  // Score Details
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildScoreItem('Memory', scores['memory'] ?? 0, Colors.blue),
                        const SizedBox(height: 10),
                        _buildScoreItem('High Prob', scores['highProb'] ?? 0, Colors.green),
                        const SizedBox(height: 10),
                        _buildScoreItem('Careful', scores['careful'] ?? 0, Colors.orange),
                        const SizedBox(height: 10),
                        _buildScoreItem('Quick', scores['quick'] ?? 0, Colors.purple),
                        const SizedBox(height: 10),
                        _buildScoreItem('Luck', scores['luck'] ?? 0, Colors.red),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const Divider(color: GameColors.textBlack, thickness: 2),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: onNext,
                style: ElevatedButton.styleFrom(
                  backgroundColor: GameColors.primaryGreen,
                  foregroundColor: Colors.white,
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

  Widget _buildScoreItem(String label, double score, Color color) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: GameColors.textBrightGrey,
            ),
          ),
        ),
        Expanded(
          child: LinearProgressIndicator(
            value: score / 100,
            backgroundColor: GameColors.background,
            color: color,
            minHeight: 8,
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 40,
          child: Text(
            '${score.toInt()}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: GameColors.textBrightGreyDark,
            ),
          ),
        ),
      ],
    );
  }

  Map<String, double> _calculateScores(Map<String, dynamic> reports) {
    // Calculate scores based on reports data
    final roundSummary = reports['roundSummary'] as Map<String, dynamic>? ?? {};
    final obviousMistakes = reports['obviousMistakes'] as Map<String, dynamic>? ?? {};
    
    final accuracy = roundSummary['accuracy'] as double? ?? 0.0;
    final totalRounds = roundSummary['totalRounds'] as int? ?? 0;
    final mistakes = (obviousMistakes['mistakes'] as List<dynamic>? ?? []).length;

    // Memory: based on overall accuracy
    final memory = accuracy;

    // High Prob: accuracy on high probability rounds (simplified)
    final highProb = accuracy > 50 ? (accuracy - 50) * 2 : accuracy;

    // Careful: based on hint usage (simplified - assume average)
    final careful = 60.0;

    // Quick: inverse of average decision time (simplified)
    final quick = 70.0;

    // Luck: performance on low probability rounds (simplified)
    final luck = accuracy < 50 ? accuracy * 1.5 : accuracy * 0.8;

    return {
      'memory': memory.clamp(0, 100),
      'highProb': highProb.clamp(0, 100),
      'careful': careful.clamp(0, 100),
      'quick': quick.clamp(0, 100),
      'luck': luck.clamp(0, 100),
    };
  }
}