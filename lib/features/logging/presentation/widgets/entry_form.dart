import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:nutrinutri/core/domain/nutrition_metric.dart';
import 'package:nutrinutri/core/utils/icon_utils.dart';
import 'package:nutrinutri/core/utils/met_values.dart';
import 'package:nutrinutri/features/logging/presentation/widgets/icon_picker_button.dart';

class EntryForm extends StatelessWidget {
  const EntryForm({
    super.key,
    required this.nameController,
    required this.metricControllers,
    this.durationController,
    required this.selectedIcon,
    required this.selectedDate,
    required this.selectedTime,
    required this.onIconChanged,
    required this.onPickDate,
    required this.onPickTime,
    this.isExercise = false,
  });
  final TextEditingController nameController;
  final Map<NutritionMetricType, TextEditingController> metricControllers;
  final TextEditingController? durationController;
  final String selectedIcon;
  final DateTime selectedDate;
  final TimeOfDay selectedTime;
  final void Function(String?) onIconChanged;
  final VoidCallback onPickDate;
  final VoidCallback onPickTime;
  final bool isExercise;

  TextEditingController _controllerFor(NutritionMetricType metric) {
    return metricControllers[metric]!;
  }

  @override
  Widget build(BuildContext context) {
    final nonCalorieMetrics = NutritionMetricType.values
        .where((metric) => metric != NutritionMetricType.calories)
        .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Entry Details',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const Gap(16),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              IconPickerButton(
                selectedIcon: selectedIcon,
                onIconChanged: (val) => onIconChanged(val),
                availableIcons: isExercise
                    ? IconUtils.availableExerciseIcons
                    : IconUtils.availableFoodIcons,
              ),
              const Gap(16),
              Expanded(
                child: TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: isExercise ? 'Exercise Name' : 'Food Name',
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (isExercise) ...[
          const Gap(8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: MetValues.commonExercises.keys.map((name) {
              return ActionChip(
                label: Text(name),
                onPressed: () {
                  nameController.text = name;
                  // Map exercise names to icons
                  final icon = IconUtils.exerciseNameMap[name];
                  if (icon != null) {
                    onIconChanged(icon);
                  } else {
                    // Default fallback
                    onIconChanged('sports');
                  }
                },
              );
            }).toList(),
          ),
        ],
        const Gap(16),

        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onPickDate,
                icon: const Icon(Icons.calendar_today),
                label: Text(DateFormat('yyyy-MM-dd').format(selectedDate)),
              ),
            ),
            const Gap(16),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onPickTime,
                icon: const Icon(Icons.access_time),
                label: Text(selectedTime.format(context)),
              ),
            ),
          ],
        ),
        const Gap(16),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controllerFor(NutritionMetricType.calories),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: isExercise ? 'Calories Burned' : 'Calories',
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
            if (isExercise && durationController != null) ...[
              const Gap(16),
              Expanded(
                child: TextField(
                  controller: durationController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Duration (min)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ],
        ),
        if (!isExercise) ...[
          const Gap(16),
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
                      decoration: InputDecoration(
                        labelText: '${metric.label} (${metric.unit})',
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  );
                })
                .toList(growable: false),
          ),
        ],
      ],
    );
  }
}
