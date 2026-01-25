import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:nutrinutri/core/utils/icon_utils.dart';
import 'package:nutrinutri/core/utils/met_values.dart';
import 'package:nutrinutri/features/diary/data/diary_service.dart';
import 'package:nutrinutri/features/logging/presentation/widgets/icon_picker_button.dart';

class EntryForm extends StatelessWidget {
  const EntryForm({
    super.key,
    required this.nameController,
    required this.caloriesController,
    required this.proteinController,
    required this.carbsController,
    required this.fatsController,
    this.durationController,
    required this.selectedIcon,
    required this.selectedDate,
    required this.selectedTime,
    required this.onIconChanged,
    required this.onPickDate,
    required this.onPickTime,
    this.isExercise = false,
    this.onFoodSearch,
    this.onAutofill,
  });
  final TextEditingController nameController;
  final TextEditingController caloriesController;
  final TextEditingController proteinController;
  final TextEditingController carbsController;
  final TextEditingController fatsController;
  final TextEditingController? durationController;
  final String selectedIcon;
  final DateTime selectedDate;
  final TimeOfDay selectedTime;
  final void Function(String?) onIconChanged;
  final VoidCallback onPickDate;
  final VoidCallback onPickTime;
  final bool isExercise;
  final Future<List<DiaryEntry>> Function(String)? onFoodSearch;
  final void Function(DiaryEntry)? onAutofill;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Entry Details',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const Gap(16),
        LayoutBuilder(
          builder: (context, constraints) {
            // IconPickerButton width (60) + Gap (16) = 76
            final dropdownWidth = (constraints.maxWidth - 76).clamp(
              0.0,
              double.infinity,
            );

            return IntrinsicHeight(
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
                    child: isExercise
                        ? TextField(
                            controller: nameController,
                            decoration: const InputDecoration(
                              labelText: 'Exercise Name',
                              border: OutlineInputBorder(),
                            ),
                          )
                        : RawAutocomplete<DiaryEntry>(
                            textEditingController: nameController,
                            focusNode: FocusNode(),
                            optionsBuilder: (text) async {
                              if (onFoodSearch == null) return [];
                              return onFoodSearch!(text.text);
                            },
                            displayStringForOption: (option) => option.name,
                            onSelected: (entry) {
                              if (onAutofill != null) onAutofill!(entry);
                            },
                            fieldViewBuilder:
                                (context, controller, focusNode, onSubmitted) {
                                  return TextField(
                                    controller: controller,
                                    focusNode: focusNode,
                                    decoration: const InputDecoration(
                                      labelText: 'Food Name',
                                      border: OutlineInputBorder(),
                                      suffixIcon: Icon(Icons.search),
                                    ),
                                  );
                                },
                            optionsViewBuilder: (context, onSelected, options) {
                              return Align(
                                alignment: Alignment.topLeft,
                                child: Material(
                                  elevation: 4,
                                  child: ConstrainedBox(
                                    constraints: BoxConstraints(
                                      maxWidth: dropdownWidth,
                                      maxHeight: 250,
                                    ),
                                    child: ListView.builder(
                                      padding: EdgeInsets.zero,
                                      shrinkWrap: true,
                                      itemCount: options.length,
                                      itemBuilder: (context, index) {
                                        final option = options.elementAt(index);
                                        return ListTile(
                                          leading: Icon(
                                            IconUtils.getIcon(option.icon) ??
                                                Icons.restaurant,
                                          ),
                                          title: Text(option.name),
                                          subtitle: Text(
                                            '${option.calories} cal | P:${option.protein} C:${option.carbs} F:${option.fats}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                            ),
                                          ),
                                          onTap: () => onSelected(option),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
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
                controller: caloriesController,
                keyboardType: TextInputType.number,
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
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: proteinController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Protein (g)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const Gap(16),
              Expanded(
                child: TextField(
                  controller: carbsController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Carbs (g)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const Gap(16),
              Expanded(
                child: TextField(
                  controller: fatsController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Fats (g)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
