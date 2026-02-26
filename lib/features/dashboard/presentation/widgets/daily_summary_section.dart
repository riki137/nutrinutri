import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:nutrinutri/core/domain/nutrition_metric.dart';
import 'package:nutrinutri/core/domain/user_profile.dart';
import 'package:nutrinutri/core/providers.dart';
import 'package:nutrinutri/features/dashboard/presentation/dashboard_providers.dart';

class DailySummarySection extends ConsumerWidget {
  const DailySummarySection({super.key, required this.today});
  final DateTime today;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(settingsServiceProvider).getUserProfile();
    final summaryAsync = ref.watch(dailySummaryProvider(today));

    return FutureBuilder(
      future: profileAsync,
      builder: (context, profileSnapshot) {
        if (!profileSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final profile = profileSnapshot.data;
        if (profile == null) return const Text('Profile not found');

        return summaryAsync.when(
          data: (summary) => _buildContent(context, profile, summary),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Text('Error: $err'),
        );
      },
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

    final homeMetrics = profile.dashboardMetricTypes;

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
                            color: isOver ? Colors.redAccent : Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Gap(24),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              alignment: WrapAlignment.center,
              children: homeMetrics
                  .map((metric) {
                    return _MetricRing(
                      label: metric.label,
                      value: summary[metric.key] ?? 0,
                      goal: profile.goalFor(metric),
                      unit: metric.unit,
                      color: _metricColor(metric),
                    );
                  })
                  .toList(growable: false),
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

    return Column(
      children: [
        SizedBox(
          height: 60,
          width: 60,
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
                  centerSpaceRadius: 22,
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
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
        Text(
          hasGoal
              ? '${_formatValue(value)}/${_formatValue(goal)} $unit'
              : 'No goal',
          style: TextStyle(
            fontSize: 10,
            color: isOver ? color : Colors.grey[600],
            fontWeight: isOver ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  String _formatValue(double value) {
    if (value == value.roundToDouble()) {
      return value.round().toString();
    }
    return value.toStringAsFixed(1);
  }
}
