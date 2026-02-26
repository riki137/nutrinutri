import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:nutrinutri/core/domain/nutrition_metric.dart';

final FilteringTextInputFormatter _decimalMetricFormatter =
    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'));

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

  Widget _buildMetricGoalField(NutritionMetricType metric) {
    return SizedBox(
      width: 190,
      child: _NumericField(
        controller: _controllerFor(metric),
        labelText: '${metric.label} (${metric.unit})',
        allowDecimal: true,
      ),
    );
  }

  Widget _buildHomeMetricField({
    required int index,
    required NutritionMetricType selected,
    required List<NutritionMetricType> options,
  }) {
    return SizedBox(
      width: 220,
      child: DropdownButtonFormField<NutritionMetricType>(
        key: ValueKey('home_metric_${index}_${selected.key}'),
        initialValue: selected,
        decoration: InputDecoration(
          labelText: 'Slot ${index + 1}',
          border: const OutlineInputBorder(),
        ),
        items: options
            .map(
              (metric) =>
                  DropdownMenuItem(value: metric, child: Text(metric.label)),
            )
            .toList(growable: false),
        onChanged: (metric) => onHomeMetricChanged(index, metric),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nonCalorieMetrics = NutritionMetricType.values
        .where((metric) => metric != NutritionMetricType.calories)
        .toList(growable: false);

    final selectedHomeMetrics = normalizeHomeMetricTypes(homeMetricTypes);

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
              child: _NumericField(controller: ageController, labelText: 'Age'),
            ),
            const Gap(16),
            Expanded(
              child: _DropdownField<String>(
                labelText: 'Biological Sex',
                value: gender,
                items: const [
                  DropdownMenuItem(value: 'male', child: Text('Male')),
                  DropdownMenuItem(value: 'female', child: Text('Female')),
                ],
                onChanged: onGenderChanged,
              ),
            ),
          ],
        ),
        const Gap(16),
        Row(
          children: [
            Expanded(
              child: _NumericField(
                controller: weightController,
                labelText: 'Weight (kg)',
                suffixText: 'kg',
              ),
            ),
            const Gap(16),
            Expanded(
              child: _NumericField(
                controller: heightController,
                labelText: 'Height (cm)',
                suffixText: 'cm',
              ),
            ),
          ],
        ),
        const Gap(16),
        _DropdownField<String>(
          labelText: 'Activity Level',
          value: activityLevel,
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
        const Gap(16),
        _NumericField(
          controller: _controllerFor(NutritionMetricType.calories),
          labelText: 'Daily Calorie Goal',
          helperText: 'Auto-calculated (Maintenance - 250)',
          allowDecimal: true,
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
              .map(_buildMetricGoalField)
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
          children: List.generate(
            homeMetricSlotCount,
            (index) => _buildHomeMetricField(
              index: index,
              selected: selectedHomeMetrics[index],
              options: nonCalorieMetrics,
            ),
          ),
        ),
      ],
    );
  }
}

class _DropdownField<T> extends StatelessWidget {
  const _DropdownField({
    required this.labelText,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String labelText;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: labelText,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _NumericField extends StatelessWidget {
  const _NumericField({
    required this.controller,
    required this.labelText,
    this.helperText,
    this.suffixText,
    this.allowDecimal = false,
  });

  final TextEditingController controller;
  final String labelText;
  final String? helperText;
  final String? suffixText;
  final bool allowDecimal;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: allowDecimal
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.number,
      inputFormatters: allowDecimal ? [_decimalMetricFormatter] : null,
      decoration: InputDecoration(
        labelText: labelText,
        border: const OutlineInputBorder(),
        helperText: helperText,
        suffixText: suffixText,
      ),
    );
  }
}
