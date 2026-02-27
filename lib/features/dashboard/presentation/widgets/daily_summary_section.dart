import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:nutrinutri/core/domain/nutrition_metric.dart';
import 'package:nutrinutri/core/domain/user_profile.dart';
import 'package:nutrinutri/features/dashboard/presentation/dashboard_providers.dart';

class DailySummarySection extends ConsumerWidget {
  const DailySummarySection({super.key, required this.today});
  final DateTime today;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryDataAsync = ref.watch(dailySummaryDataProvider(today));

    return summaryDataAsync.when(
      data: (summaryData) {
        if (summaryData == null) return const Text('Profile not found');
        return _buildContent(context, summaryData.profile, summaryData.summary);
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Text('Error: $err'),
    );
  }

  Widget _buildContent(
    BuildContext context,
    UserProfile profile,
    Map<String, double> summary,
  ) {
    final consumed = summary[NutritionMetricType.calories.key] ?? 0;
    final burned = summary['caloriesBurned'] ?? 0.0;
    final goal = profile.goalFor(NutritionMetricType.calories);
    final effectiveGoal = goal + burned;
    final remaining = effectiveGoal - consumed;
    final isOver = remaining < 0;

    final progress = effectiveGoal <= 0
        ? 0.0
        : (consumed / effectiveGoal).clamp(0.0, 1.0);

    final statusColor = isOver ? Colors.redAccent : Colors.green;
    final secondaryColor = isOver
        ? Colors.red.withValues(alpha: 0.1)
        : Colors.grey[200]!;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Calories Today',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Goal: ${effectiveGoal.round()} kcal',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    if (burned > 0)
                      Text(
                        '(+${burned.round()} burned)',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.orange,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const Gap(16),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _MetricRing(
                    label: NutritionMetricType.caffeine.label,
                    value: summary[NutritionMetricType.caffeine.key] ?? 0,
                    goal: profile.goalFor(NutritionMetricType.caffeine),
                    unit: NutritionMetricType.caffeine.unit,
                    color: _metricColor(NutritionMetricType.caffeine),
                  ),
                  SizedBox(
                    height: 150,
                    width: 150,
                    child: Stack(
                      children: [
                        PieChart(
                          PieChartData(
                            sections: [
                              PieChartSectionData(
                                value: progress,
                                color: statusColor,
                                radius: 20,
                                showTitle: false,
                              ),
                              PieChartSectionData(
                                value: 1 - progress,
                                color: secondaryColor,
                                radius: 20,
                                showTitle: false,
                              ),
                            ],
                            startDegreeOffset: 270,
                          ),
                        ),
                        Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                isOver
                                    ? remaining.abs().round().toString()
                                    : remaining.round().toString(),
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: isOver
                                      ? Colors.redAccent
                                      : Theme.of(
                                          context,
                                        ).textTheme.headlineMedium?.color,
                                ),
                              ),
                              Text(
                                isOver ? 'Over' : 'Left',
                                style: TextStyle(
                                  color: isOver
                                      ? Colors.redAccent
                                      : Colors.grey,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  _MetricRing(
                    label: NutritionMetricType.water.label,
                    value: summary[NutritionMetricType.water.key] ?? 0,
                    goal: profile.goalFor(NutritionMetricType.water),
                    unit: NutritionMetricType.water.unit,
                    color: _metricColor(NutritionMetricType.water),
                  ),
                ],
              ),
            ),
            const Gap(24),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              alignment: WrapAlignment.center,
              children: [
                _MetricRing(
                  label: NutritionMetricType.protein.label,
                  value: summary[NutritionMetricType.protein.key] ?? 0,
                  goal: profile.goalFor(NutritionMetricType.protein),
                  unit: NutritionMetricType.protein.unit,
                  color: _metricColor(NutritionMetricType.protein),
                ),
                _NestedMetricRing(
                  outerLabel: NutritionMetricType.carbs.label,
                  outerValue: summary[NutritionMetricType.carbs.key] ?? 0,
                  outerGoal: profile.goalFor(NutritionMetricType.carbs),
                  outerUnit: NutritionMetricType.carbs.unit,
                  outerColor: _metricColor(NutritionMetricType.carbs),
                  innerLabel: NutritionMetricType.sugars.label,
                  innerValue: summary[NutritionMetricType.sugars.key] ?? 0,
                  innerGoal: profile.goalFor(NutritionMetricType.sugars),
                  innerColor: _metricColor(NutritionMetricType.sugars),
                ),
                _NestedMetricRing(
                  outerLabel: NutritionMetricType.fats.label,
                  outerValue: summary[NutritionMetricType.fats.key] ?? 0,
                  outerGoal: profile.goalFor(NutritionMetricType.fats),
                  outerUnit: NutritionMetricType.fats.unit,
                  outerColor: _metricColor(NutritionMetricType.fats),
                  innerLabel: 'Sat. Fats',
                  innerValue:
                      summary[NutritionMetricType.saturatedFats.key] ?? 0,
                  innerGoal: profile.goalFor(NutritionMetricType.saturatedFats),
                  innerColor: _metricColor(NutritionMetricType.saturatedFats),
                ),
                _MetricRing(
                  label: NutritionMetricType.fiber.label,
                  value: summary[NutritionMetricType.fiber.key] ?? 0,
                  goal: profile.goalFor(NutritionMetricType.fiber),
                  unit: NutritionMetricType.fiber.unit,
                  color: _metricColor(NutritionMetricType.fiber),
                ),
                _MetricRing(
                  label: NutritionMetricType.sodium.label,
                  value: summary[NutritionMetricType.sodium.key] ?? 0,
                  goal: profile.goalFor(NutritionMetricType.sodium),
                  unit: NutritionMetricType.sodium.unit,
                  color: _metricColor(NutritionMetricType.sodium),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _metricColor(NutritionMetricType metric) {
    switch (metric) {
      case NutritionMetricType.protein:
        return Colors.blue;
      case NutritionMetricType.carbs:
        return Colors.orange;
      case NutritionMetricType.sugars:
        return Colors.amber;
      case NutritionMetricType.fats:
        return Colors.red;
      case NutritionMetricType.saturatedFats:
        return Colors.redAccent;
      case NutritionMetricType.fiber:
        return Colors.green;
      case NutritionMetricType.sodium:
        return Colors.teal;
      case NutritionMetricType.caffeine:
        return Colors.brown;
      case NutritionMetricType.water:
        return Colors.lightBlue;
      case NutritionMetricType.calories:
        return Colors.deepOrange;
    }
  }
}

class _MetricRing extends StatelessWidget {
  const _MetricRing({
    required this.label,
    required this.value,
    required this.goal,
    required this.unit,
    required this.color,
  });
  final String label;
  final double value;
  final double goal;
  final String unit;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final hasGoal = goal > 0;
    final isOver = hasGoal && value > goal;
    final chartProgress = hasGoal ? (value / goal).clamp(0.0, 1.0) : 0.0;
    final percentage = hasGoal ? ((value / goal) * 100).round() : 0;

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
                    sections: [
                      PieChartSectionData(
                        value: chartProgress,
                        color: color,
                        radius: 8,
                        showTitle: false,
                      ),
                      PieChartSectionData(
                        value: 1 - chartProgress,
                        color: color.withValues(alpha: 0.2),
                        radius: 8,
                        showTitle: false,
                      ),
                    ],
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
        ],
      ),
    );
  }

  String _formatValue(double value) {
    if (value == value.roundToDouble()) {
      return value.round().toString();
    }
    return value.toStringAsFixed(1);
  }
}

class _NestedMetricRing extends StatelessWidget {
  const _NestedMetricRing({
    required this.outerLabel,
    required this.outerValue,
    required this.outerGoal,
    required this.outerUnit,
    required this.outerColor,
    required this.innerLabel,
    required this.innerValue,
    required this.innerGoal,
    required this.innerColor,
  });
  final String outerLabel;
  final double outerValue;
  final double outerGoal;
  final String outerUnit;
  final Color outerColor;
  final String innerLabel;
  final double innerValue;
  final double innerGoal;
  final Color innerColor;

  @override
  Widget build(BuildContext context) {
    final outerHasGoal = outerGoal > 0;
    final outerIsOver = outerHasGoal && outerValue > outerGoal;
    final outerChartProgress = outerHasGoal
        ? (outerValue / outerGoal).clamp(0.0, 1.0)
        : 0.0;
    final outerPercentage = outerHasGoal
        ? ((outerValue / outerGoal) * 100).round()
        : 0;

    final innerHasGoal = innerGoal > 0;
    final innerIsOver = innerHasGoal && innerValue > innerGoal;
    final innerChartProgress = innerHasGoal
        ? (innerValue / innerGoal).clamp(0.0, 1.0)
        : 0.0;

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
                    sections: [
                      PieChartSectionData(
                        value: outerChartProgress,
                        color: outerColor,
                        radius: 8,
                        showTitle: false,
                      ),
                      PieChartSectionData(
                        value: 1 - outerChartProgress,
                        color: outerColor.withValues(alpha: 0.2),
                        radius: 8,
                        showTitle: false,
                      ),
                    ],
                    startDegreeOffset: 270,
                    sectionsSpace: 0,
                    centerSpaceRadius: 24,
                  ),
                ),
                PieChart(
                  PieChartData(
                    sections: [
                      PieChartSectionData(
                        value: innerChartProgress,
                        color: innerColor,
                        radius: 6,
                        showTitle: false,
                      ),
                      PieChartSectionData(
                        value: 1 - innerChartProgress,
                        color: innerColor.withValues(alpha: 0.2),
                        radius: 6,
                        showTitle: false,
                      ),
                    ],
                    startDegreeOffset: 270,
                    sectionsSpace: 0,
                    centerSpaceRadius: 16,
                  ),
                ),
                Center(
                  child: Text(
                    outerHasGoal ? '$outerPercentage%' : '--',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: outerIsOver
                          ? outerColor
                          : Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Gap(8),
          Text(
            outerLabel,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
          Text(
            outerHasGoal
                ? '${_formatValue(outerValue)}/${_formatValue(outerGoal)} $outerUnit'
                : 'No goal',
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10,
              color: outerIsOver ? outerColor : Colors.grey[600],
              fontWeight: outerIsOver ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            '$innerLabel: ${_formatValue(innerValue)}${innerHasGoal ? '/${_formatValue(innerGoal)}' : ''} $outerUnit',
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10,
              color: innerIsOver ? innerColor : Colors.grey[600],
              fontWeight: innerIsOver ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  String _formatValue(double value) {
    if (value == value.roundToDouble()) {
      return value.round().toString();
    }
    return value.toStringAsFixed(1);
  }
}
