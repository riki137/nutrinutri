import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:gap/gap.dart';
import 'package:nutrinutri/core/utils/icon_utils.dart';

class EntryForm extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController caloriesController;
  final TextEditingController proteinController;
  final TextEditingController carbsController;
  final TextEditingController fatsController;
  final String selectedIcon;
  final DateTime selectedDate;
  final TimeOfDay selectedTime;
  final void Function(String?) onIconChanged;
  final VoidCallback onPickDate;
  final VoidCallback onPickTime;

  const EntryForm({
    super.key,
    required this.nameController,
    required this.caloriesController,
    required this.proteinController,
    required this.carbsController,
    required this.fatsController,
    required this.selectedIcon,
    required this.selectedDate,
    required this.selectedTime,
    required this.onIconChanged,
    required this.onPickDate,
    required this.onPickTime,
  });

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
        TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Food Name',
            border: OutlineInputBorder(),
          ),
        ),
        const Gap(16),
        DropdownButtonFormField<String>(
          value: selectedIcon,
          decoration: const InputDecoration(
            labelText: 'Icon',
            border: OutlineInputBorder(),
          ),
          items: IconUtils.availableIcons.map((iconKey) {
            return DropdownMenuItem(
              value: iconKey,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(IconUtils.getIcon(iconKey)),
                  const Gap(8),
                  Text(
                    iconKey
                        .replaceAll('_', ' ')
                        .split(' ')
                        .map(
                          (word) => word.isNotEmpty
                              ? '${word[0].toUpperCase()}${word.substring(1)}'
                              : '',
                        )
                        .join(' '),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: onIconChanged,
        ),
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
                decoration: const InputDecoration(
                  labelText: 'Calories',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const Gap(16),
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
          ],
        ),
        const Gap(16),
        Row(
          children: [
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
    );
  }
}
