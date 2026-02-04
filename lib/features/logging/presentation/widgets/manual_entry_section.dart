import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:nutrinutri/features/diary/domain/diary_entry.dart';
import 'package:nutrinutri/features/logging/presentation/widgets/entry_action_buttons.dart';
import 'package:nutrinutri/features/logging/presentation/widgets/entry_form.dart';

class ManualEntrySection extends StatelessWidget {
  const ManualEntrySection({
    super.key,
    required this.isEditing,
    required this.isExercise,
    required this.nameController,
    required this.caloriesController,
    required this.proteinController,
    required this.carbsController,
    required this.fatsController,
    this.durationController,
    required this.selectedIcon,
    required this.selectedDate,
    required this.selectedTime,
    required this.onBackToWizard,
    required this.onIconChanged,
    required this.onPickDate,
    required this.onPickTime,
    required this.onSave,
    required this.onDeleteConfirmed,
    required this.onFoodSearch,
    required this.onAutofill,
  });
  final bool isEditing;
  final bool isExercise;
  final TextEditingController nameController;
  final TextEditingController caloriesController;
  final TextEditingController proteinController;
  final TextEditingController carbsController;
  final TextEditingController fatsController;
  final TextEditingController? durationController;
  final String selectedIcon;
  final DateTime selectedDate;
  final TimeOfDay selectedTime;
  final VoidCallback onBackToWizard;
  final ValueChanged<String?> onIconChanged;
  final VoidCallback onPickDate;
  final VoidCallback onPickTime;
  final Future<void> Function() onSave;
  final Future<void> Function() onDeleteConfirmed;
  final Future<List<DiaryEntry>> Function(String) onFoodSearch;
  final void Function(DiaryEntry) onAutofill;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!isEditing) ...[
          TextButton.icon(
            onPressed: onBackToWizard,
            icon: const Icon(Icons.arrow_back),
            label: const Text('Back to AI Wizard'),
          ),
          const Gap(16),
        ],
        EntryForm(
          nameController: nameController,
          caloriesController: caloriesController,
          proteinController: proteinController,
          carbsController: carbsController,
          fatsController: fatsController,
          durationController: durationController,
          selectedIcon: selectedIcon,
          selectedDate: selectedDate,
          selectedTime: selectedTime,
          onIconChanged: onIconChanged,
          onPickDate: onPickDate,
          onPickTime: onPickTime,
          isExercise: isExercise,
          onFoodSearch: onFoodSearch,
          onAutofill: onAutofill,
        ),
        const Gap(24),
        EntryActionButtons(
          isEditing: isEditing,
          onSave: onSave,
          onDeleteConfirmed: onDeleteConfirmed,
        ),
        const Gap(32),
      ],
    );
  }
}
