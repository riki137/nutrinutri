import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nutrinutri/core/providers.dart';
import 'package:nutrinutri/core/utils/calorie_calculator.dart';
import 'package:gap/gap.dart';

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final _formKey = GlobalKey<FormState>();

  final _ageController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _goalController = TextEditingController();

  String _gender = 'male';
  String _activityLevel = 'sedentary';

  bool _isLoading = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final settings = ref.read(settingsServiceProvider);
      await settings.saveUserProfile(
        age: int.parse(_ageController.text),
        weight: double.parse(_weightController.text),
        height: double.parse(_heightController.text),
        gender: _gender,
        activityLevel: _activityLevel,
        goalCalories: int.parse(_goalController.text),
      );

      if (mounted) {
        context.go('/');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving profile: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _calculateRecommendedCalories() {
    final age = int.tryParse(_ageController.text);
    final weight = double.tryParse(_weightController.text);
    final height = double.tryParse(_heightController.text);

    if (age != null && weight != null && height != null) {
      final calories = CalorieCalculator.calculateDailyCalories(
        weightKg: weight,
        heightCm: height,
        age: age,
        gender: _gender,
        activityLevel: _activityLevel,
      );

      _goalController.text = calories.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Setup Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Tell us about yourself so we can calculate your personalized plan.',
                style: TextStyle(fontSize: 16),
              ),
              const Gap(24),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _ageController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Age',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                      onChanged: (_) => _calculateRecommendedCalories(),
                    ),
                  ),
                  const Gap(16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _gender,
                      decoration: const InputDecoration(
                        labelText: 'Gender',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'male', child: Text('Male')),
                        DropdownMenuItem(
                          value: 'female',
                          child: Text('Female'),
                        ),
                      ],
                      onChanged: (v) {
                        setState(() => _gender = v!);
                        _calculateRecommendedCalories();
                      },
                    ),
                  ),
                ],
              ),
              const Gap(16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _weightController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Weight (kg)',
                        border: OutlineInputBorder(),
                        suffixText: 'kg',
                      ),
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                      onChanged: (_) => _calculateRecommendedCalories(),
                    ),
                  ),
                  const Gap(16),
                  Expanded(
                    child: TextFormField(
                      controller: _heightController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Height (cm)',
                        border: OutlineInputBorder(),
                        suffixText: 'cm',
                      ),
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                      onChanged: (_) => _calculateRecommendedCalories(),
                    ),
                  ),
                ],
              ),
              const Gap(16),
              DropdownButtonFormField<String>(
                initialValue: _activityLevel,
                decoration: const InputDecoration(
                  labelText: 'Activity Level',
                  border: OutlineInputBorder(),
                ),
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
                onChanged: (v) {
                  setState(() => _activityLevel = v!);
                  _calculateRecommendedCalories();
                },
              ),
              const Gap(24),
              const Divider(),
              const Gap(24),
              TextFormField(
                controller: _goalController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Daily Calorie Goal',
                  border: OutlineInputBorder(),
                  helperText:
                      'Calculated based on your stats (Maintenance - 250)',
                ),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const Gap(32),
              FilledButton(
                onPressed: _isLoading ? null : _submit,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text('Start Tracking'),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
