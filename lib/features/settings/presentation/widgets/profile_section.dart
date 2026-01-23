import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';

class ProfileSection extends StatelessWidget {
  const ProfileSection({
    super.key,
    required this.ageController,
    required this.weightController,
    required this.heightController,
    required this.goalController,
    required this.proteinController,
    required this.carbsController,
    required this.fatsController,
    required this.gender,
    required this.activityLevel,
    required this.onGenderChanged,
    required this.onActivityLevelChanged,
  });
  final TextEditingController ageController;
  final TextEditingController weightController;
  final TextEditingController heightController;
  final TextEditingController goalController;
  final TextEditingController proteinController;
  final TextEditingController carbsController;
  final TextEditingController fatsController;
  final String gender;
  final String activityLevel;
  final ValueChanged<String?> onGenderChanged;
  final ValueChanged<String?> onActivityLevelChanged;

  @override
  Widget build(BuildContext context) {
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
          controller: goalController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(
            labelText: 'Daily Calorie Goal',
            border: OutlineInputBorder(),
            helperText: 'Auto-calculated (Maintenance - 250)',
          ),
        ),
        const Gap(16),
        const Text(
          'Macro Goals (Optional)',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const Gap(8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: proteinController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Protein (g)',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const Gap(8),
            Expanded(
              child: TextField(
                controller: carbsController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Carbs (g)',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const Gap(8),
            Expanded(
              child: TextField(
                controller: fatsController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
