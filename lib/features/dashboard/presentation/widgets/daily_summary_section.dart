import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:nutrinutri/core/providers.dart';
import 'package:nutrinutri/core/utils/calorie_calculator.dart';
import 'package:nutrinutri/features/dashboard/presentation/dashboard_providers.dart';

class DailySummarySection extends ConsumerWidget {
  final DateTime today;

  const DailySummarySection({super.key, required this.today});

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
    Map<String, dynamic> profile,
    Map<String, double> summary,
  ) {
    final goal = profile['goalCalories'] as int;
    final consumed = summary['calories']!;
    final burned = summary['caloriesBurned'] ?? 0.0;
    final effectiveGoal = goal + burned;
    final remaining = effectiveGoal - consumed;
    final isOver = remaining < 0;

    // Visual progress clamps at 1.0 (full circle)
    final progress = (consumed / effectiveGoal).clamp(0.0, 1.0);

    final statusColor = isOver ? Colors.redAccent : Colors.green;
    final secondaryColor = isOver
        ? Colors.red.withValues(alpha: 0.1)
        : Colors.grey[200]!;

    // Macro Goals Calculation (Default split: 30% P, 40% C, 30% F)
    // Macro Goals Calculation
    final defaults = CalorieCalculator.calculateMacroGoals(goal);

    final double proteinGoal =
        (profile['goalProtein'] != null && profile['goalProtein'] > 0)
        ? (profile['goalProtein'] as int).toDouble()
        : defaults.protein;

    final double carbsGoal =
        (profile['goalCarbs'] != null && profile['goalCarbs'] > 0)
        ? (profile['goalCarbs'] as int).toDouble()
        : defaults.carbs;

    final double fatsGoal =
        (profile['goalFat'] != null && profile['goalFat'] > 0)
        ? (profile['goalFat'] as int).toDouble()
        : defaults.fats;

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
                      'Goal: ${effectiveGoal.round()}',
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
                            color: isOver ? Colors.redAccent : Colors.black,
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _MacroRing(
                  label: 'Protein',
                  value: summary['protein']!,
                  goal: proteinGoal,
                  color: Colors.blue,
                ),
                _MacroRing(
                  label: 'Carbs',
                  value: summary['carbs']!,
                  goal: carbsGoal,
                  color: Colors.orange,
                ),
                _MacroRing(
                  label: 'Fats',
                  value: summary['fats']!,
                  goal: fatsGoal,
                  color: Colors.red,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MacroRing extends StatelessWidget {
  final String label;
  final double value;
  final double goal;
  final Color color;

  const _MacroRing({
    required this.label,
    required this.value,
    required this.goal,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    // Determine if we are over the goal
    final isOver = value > goal;

    // Visual progress for the chart (clamped to 100%)
    final chartProgress = (value / goal).clamp(0.0, 1.0);

    // Actual percentage for display (can exceed 100%)
    final percentage = ((value / goal) * 100).round();

    // Status color (dim/mix with grey if not full, full color if full)
    // Actually, we want to keep the distinct macro colors.
    // If over, we might want to alert, but the user asked primarily for the number fix.
    // Let's keep the base color but maybe bold the text if over.

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
                  '$percentage%',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: isOver ? color : Colors.black,
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
          '${value.round()}/${goal.round()}g',
          style: TextStyle(
            fontSize: 10,
            color: isOver ? color : Colors.grey[600],
            fontWeight: isOver ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}
