import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class MetricRing extends StatelessWidget {
  const MetricRing({
    super.key,
    required this.label,
    required this.value,
    required this.goal,
    required this.unit,
    required this.color,
    this.subLabel,
    this.subValue,
    this.subGoal,
    this.subColor,
  });

  final String label;
  final double value;
  final double goal;
  final String unit;
  final Color color;

  final String? subLabel;
  final double? subValue;
  final double? subGoal;
  final Color? subColor;

  @override
  Widget build(BuildContext context) {
    final hasGoal = goal > 0;
    final isOver = hasGoal && value > goal;
    final totalProgress = hasGoal ? (value / goal).clamp(0.0, 1.0) : 0.0;
    final percentage = hasGoal ? ((value / goal) * 100).round() : 0;

    double subProgress = 0.0;
    double primaryProgress = totalProgress;

    if (subValue != null && hasGoal) {
      subProgress = (subValue! / goal).clamp(0.0, totalProgress);
      primaryProgress = totalProgress - subProgress;
    }

    final subHasGoal = subGoal != null && subGoal! > 0;
    final subIsOver = subHasGoal && subValue != null && subValue! > subGoal!;

    return SizedBox(
      width: 100,
      child: Column(
        children: [
          SizedBox(
            height: 70,
            width: 70,
            child: Stack(
              children: [
                PieChart(
                  PieChartData(
                    sections: _buildSections(
                      subProgress,
                      primaryProgress,
                      totalProgress,
                    ),
                    startDegreeOffset: 270,
                    sectionsSpace: 0,
                    centerSpaceRadius: 24,
                  ),
                ),
                Center(
                  child: Text(
                    hasGoal ? '$percentage%' : '--',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: isOver
                          ? color
                          : Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Gap(8),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
          Text(
            hasGoal
                ? '${_formatValue(value)}/${_formatValue(goal)} $unit'
                : 'No goal',
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10,
              color: isOver ? color : Colors.grey[600],
              fontWeight: isOver ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          if (subLabel != null && subValue != null)
            Text(
              '$subLabel: ${_formatValue(subValue!)}${subHasGoal ? '/${_formatValue(subGoal!)}' : ''} $unit',
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                color: subIsOver ? (subColor ?? color) : Colors.grey[600],
                fontWeight: subIsOver ? FontWeight.bold : FontWeight.normal,
              ),
            ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildSections(
    double subProgress,
    double primaryProgress,
    double totalProgress,
  ) {
    final sections = <PieChartSectionData>[];

    if (subValue != null && subColor != null && subProgress > 0) {
      sections.add(
        PieChartSectionData(
          value: subProgress,
          color: subColor!,
          radius: 8,
          showTitle: false,
        ),
      );
    }

    if (primaryProgress > 0) {
      sections.add(
        PieChartSectionData(
          value: primaryProgress,
          color: color,
          radius: 8,
          showTitle: false,
        ),
      );
    }

    if (1 - totalProgress > 0) {
      sections.add(
        PieChartSectionData(
          value: 1 - totalProgress,
          color: color.withValues(alpha: 0.2),
          radius: 8,
          showTitle: false,
        ),
      );
    }

    if (sections.isEmpty) {
      sections.add(
        PieChartSectionData(
          value: 1,
          color: color.withValues(alpha: 0.2),
          radius: 8,
          showTitle: false,
        ),
      );
    }

    return sections;
  }

  String _formatValue(double val) {
    if (val == val.roundToDouble()) {
      return val.round().toString();
    }
    return val.toStringAsFixed(1);
  }
}
