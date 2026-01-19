import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:nutrinutri/core/providers.dart';
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
    final remaining = goal - consumed;
    final progress = (consumed / goal).clamp(0.0, 1.0);

    // Macro Goals Calculation (Default split: 30% P, 40% C, 30% F)
    final proteinGoal = (goal * 0.30) / 4;
    final carbsGoal = (goal * 0.40) / 4;
    final fatsGoal = (goal * 0.30) / 9;

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
                Text(
                  'Goal: $goal',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
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
                          color: Colors.green,
                          radius: 20,
                          showTitle: false,
                        ),
                        PieChartSectionData(
                          value: 1 - progress,
                          color: Colors.grey[200],
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
                          remaining.round().toString(),
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          'Left',
                          style: TextStyle(color: Colors.grey),
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
    final progress = (value / goal).clamp(0.0, 1.0);
    final percentage = (progress * 100).round();

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
                      value: progress,
                      color: color,
                      radius: 8,
                      showTitle: false,
                    ),
                    PieChartSectionData(
                      value: 1 - progress,
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
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
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
          style: TextStyle(fontSize: 10, color: Colors.grey[600]),
        ),
      ],
    );
  }
}
