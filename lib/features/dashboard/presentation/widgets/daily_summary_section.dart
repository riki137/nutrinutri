import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:nutrinutri/core/domain/nutrition_metric.dart';
import 'package:nutrinutri/core/domain/user_profile.dart';
import 'package:nutrinutri/features/dashboard/presentation/dashboard_providers.dart';
import 'package:nutrinutri/features/dashboard/presentation/widgets/metric_ring.dart';

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
                  MetricRing(
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
                  MetricRing(
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
                MetricRing(
                  label: NutritionMetricType.protein.label,
                  value: summary[NutritionMetricType.protein.key] ?? 0,
                  goal: profile.goalFor(NutritionMetricType.protein),
                  unit: NutritionMetricType.protein.unit,
                  color: _metricColor(NutritionMetricType.protein),
                ),
                MetricRing(
                  label: NutritionMetricType.carbs.label,
                  value: summary[NutritionMetricType.carbs.key] ?? 0,
                  goal: profile.goalFor(NutritionMetricType.carbs),
                  unit: NutritionMetricType.carbs.unit,
                  color: _metricColor(NutritionMetricType.carbs),
                  subLabel: NutritionMetricType.sugars.label,
                  subValue: summary[NutritionMetricType.sugars.key] ?? 0,
                  subGoal: profile.goalFor(NutritionMetricType.sugars),
                  subColor: _metricColor(NutritionMetricType.sugars),
                ),
                MetricRing(
                  label: NutritionMetricType.fats.label,
                  value: summary[NutritionMetricType.fats.key] ?? 0,
                  goal: profile.goalFor(NutritionMetricType.fats),
                  unit: NutritionMetricType.fats.unit,
                  color: _metricColor(NutritionMetricType.fats),
                  subLabel: 'Sat. Fats',
                  subValue: summary[NutritionMetricType.saturatedFats.key] ?? 0,
                  subGoal: profile.goalFor(NutritionMetricType.saturatedFats),
                  subColor: _metricColor(NutritionMetricType.saturatedFats),
                ),
                MetricRing(
                  label: NutritionMetricType.fiber.label,
                  value: summary[NutritionMetricType.fiber.key] ?? 0,
                  goal: profile.goalFor(NutritionMetricType.fiber),
                  unit: NutritionMetricType.fiber.unit,
                  color: _metricColor(NutritionMetricType.fiber),
                ),
                MetricRing(
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
        return Colors.amber;
      case NutritionMetricType.sugars:
        return Colors.orange;
      case NutritionMetricType.fats:
        return Colors.redAccent;
      case NutritionMetricType.saturatedFats:
        return Colors.red;
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
