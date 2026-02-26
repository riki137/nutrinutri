import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:nutrinutri/core/domain/nutrition_metric.dart';

class ProfileSection extends StatelessWidget {
  const ProfileSection({
    super.key,
    required this.ageController,
    required this.weightController,
    required this.heightController,
    required this.metricGoalControllers,
    required this.homeMetricTypes,
    required this.gender,
    required this.activityLevel,
    required this.onGenderChanged,
    required this.onActivityLevelChanged,
    required this.onHomeMetricChanged,
  });
  final TextEditingController ageController;
  final TextEditingController weightController;
  final TextEditingController heightController;
  final Map<NutritionMetricType, TextEditingController> metricGoalControllers;
  final List<NutritionMetricType> homeMetricTypes;
  final String gender;
  final String activityLevel;
  final ValueChanged<String?> onGenderChanged;
  final ValueChanged<String?> onActivityLevelChanged;
  final void Function(int slot, NutritionMetricType? metric)
  onHomeMetricChanged;

  TextEditingController _controllerFor(NutritionMetricType metric) {
    return metricGoalControllers[metric]!;
  }

  @override
  Widget build(BuildContext context) {
    final nonCalorieMetrics = NutritionMetricType.values
        .where((metric) => metric != NutritionMetricType.calories)
        .toList(growable: false);

    final selectedHomeMetrics = List<NutritionMetricType>.from(homeMetricTypes);
    while (selectedHomeMetrics.length < 6) {
      selectedHomeMetrics.add(
        defaultHomeMetricTypes[selectedHomeMetrics.length %
            defaultHomeMetricTypes.length],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Personal Profile',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const Gap(16),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: ageController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Age',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const Gap(16),
            Expanded(
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Biological Sex',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: gender,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(value: 'male', child: Text('Male')),
                      DropdownMenuItem(value: 'female', child: Text('Female')),
                    ],
                    onChanged: onGenderChanged,
                  ),
                ),
              ),
            ),
          ],
        ),
        const Gap(16),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: weightController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Weight (kg)',
                  border: OutlineInputBorder(),
                  suffixText: 'kg',
                ),
              ),
            ),
            const Gap(16),
            Expanded(
              child: TextField(
                controller: heightController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Height (cm)',
                  border: OutlineInputBorder(),
                  suffixText: 'cm',
                ),
              ),
            ),
          ],
        ),
        const Gap(16),
        InputDecorator(
          decoration: const InputDecoration(
            labelText: 'Activity Level',
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: activityLevel,
              isExpanded: true,
              items: const [
                DropdownMenuItem(
                  value: 'sedentary',
                  child: Text('Sedentary (Office job)'),
                ),
                DropdownMenuItem(
                  value: 'light',
                  child: Text('Light (Exercise 1-3x/week)'),
                ),
                DropdownMenuItem(
                  value: 'moderate',
                  child: Text('Moderate (Exercise 3-5x/week)'),
                ),
                DropdownMenuItem(
                  value: 'very_active',
                  child: Text('Active (Exercise 6-7x/week)'),
                ),
                DropdownMenuItem(
                  value: 'super_active',
                  child: Text('Super Active (Physical job)'),
                ),
              ],
              onChanged: onActivityLevelChanged,
            ),
          ),
        ),
        const Gap(16),
        TextField(
          controller: _controllerFor(NutritionMetricType.calories),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
          ],
          decoration: const InputDecoration(
            labelText: 'Daily Calorie Goal',
            border: OutlineInputBorder(),
            helperText: 'Auto-calculated (Maintenance - 250)',
          ),
        ),
        const Gap(16),
        const Text(
          'Metric Goals (Optional)',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const Gap(8),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: nonCalorieMetrics
              .map((metric) {
                return SizedBox(
                  width: 190,
                  child: TextField(
                    controller: _controllerFor(metric),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                    ],
                    decoration: InputDecoration(
                      labelText: '${metric.label} (${metric.unit})',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                );
              })
              .toList(growable: false),
        ),
        const Gap(24),
        const Text(
          'Homepage Metrics',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const Gap(8),
        const Text('Choose 6 metric rings shown on the dashboard.'),
        const Gap(12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: List.generate(6, (index) {
            return SizedBox(
              width: 220,
              child: DropdownButtonFormField<NutritionMetricType>(
                key: ValueKey(
                  'home_metric_${index}_${selectedHomeMetrics[index].key}',
                ),
                initialValue: selectedHomeMetrics[index],
                decoration: InputDecoration(
                  labelText: 'Slot ${index + 1}',
                  border: const OutlineInputBorder(),
                ),
                items: nonCalorieMetrics
                    .map(
                      (metric) => DropdownMenuItem(
                        value: metric,
                        child: Text(metric.label),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (metric) => onHomeMetricChanged(index, metric),
              ),
            );
          }),
        ),
      ],
    );
  }
}
