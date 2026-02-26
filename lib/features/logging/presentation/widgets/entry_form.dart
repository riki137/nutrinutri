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

  Widget _buildDateTimeButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
  }) {
    return Expanded(
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
      ),
    );
  }

  Widget _buildNumericField({
    required TextEditingController controller,
    required String labelText,
    bool allowDecimal = true,
  }) {
    return TextField(
      controller: controller,
      keyboardType: allowDecimal
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.number,
      decoration: InputDecoration(
        labelText: labelText,
        border: const OutlineInputBorder(),
      ),
    );
  }

  Widget _buildMetricField(NutritionMetricType metric) {
    return SizedBox(
      width: 190,
      child: _buildNumericField(
        controller: _controllerFor(metric),
        labelText: '${metric.label} (${metric.unit})',
      ),
    );
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
                onIconChanged: onIconChanged,
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
                  onIconChanged(IconUtils.exerciseNameMap[name] ?? 'sports');
                },
              );
            }).toList(),
          ),
        ],
        const Gap(16),

        Row(
          children: [
            _buildDateTimeButton(
              onPressed: onPickDate,
              icon: Icons.calendar_today,
              label: DateFormat('yyyy-MM-dd').format(selectedDate),
            ),
            const Gap(16),
            _buildDateTimeButton(
              onPressed: onPickTime,
              icon: Icons.access_time,
              label: selectedTime.format(context),
            ),
          ],
        ),
        const Gap(16),
        Row(
          children: [
            Expanded(
              child: _buildNumericField(
                controller: _controllerFor(NutritionMetricType.calories),
                labelText: isExercise ? 'Calories Burned' : 'Calories',
              ),
            ),
            if (isExercise && durationController != null) ...[
              const Gap(16),
              Expanded(
                child: _buildNumericField(
                  controller: durationController!,
                  labelText: 'Duration (min)',
                  allowDecimal: false,
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
                .map(_buildMetricField)
                .toList(growable: false),
          ),
        ],
      ],
    );
  }
}
