import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutrinutri/core/providers.dart';
import 'package:gap/gap.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  final _apiKeyController = TextEditingController();
  final _customModelController = TextEditingController();
  final _ageController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _goalController = TextEditingController();

  String _selectedModel = 'google/gemini-3-flash-preview';
  String _gender = 'male';
  String _activityLevel = 'sedentary';
  bool _isLoading = false;

  final Map<String, String> _models = {
    'google/gemini-3-flash-preview':
        'Gemini 3 Flash (Recommended, Default, Fast, Accurate)',
    'google/gemini-3-pro-preview': 'Gemini 3 Pro (Best, expensive)',
    'google/gemini-2.0-flash-exp:free': 'Gemini 2.0 Flash (Free)',
    'openai/gpt-5.2': 'GPT-5.2 (Expensive, good)',
    'openai/gpt-5-mini': 'GPT-5 Mini (Cheaper, less knowledge)',
    'anthropic/claude-sonnet-4.5':
        'Claude Sonnet 4.5 (Expensive, not accurate)',
    'anthropic/claude-opus-4.5':
        'Claude Opus 4.5 (More expensive than accurate)',
    'x-ai/grok-4': 'Grok 4',
    'custom': 'Custom OpenRouter model (Advanced, not recommended)',
  };

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = ref.read(settingsServiceProvider);

    // Load API Key & Model
    final key = await ref.read(apiKeyProvider.future);
    if (key != null) {
      _apiKeyController.text = key;
    }
    final model = await settings.getAIModel();
    if (_models.containsKey(model)) {
      _selectedModel = model;
    } else {
      _selectedModel = 'custom';
      _customModelController.text = model;
    }

    // Load Profile
    final profile = await settings.getUserProfile();
    if (profile != null) {
      _ageController.text = profile['age'].toString();
      _weightController.text = profile['weight'].toString();
      _heightController.text = profile['height'].toString();
      _goalController.text = profile['goalCalories'].toString();
      setState(() {
        _gender = profile['gender'] ?? 'male';
        _activityLevel = profile['activityLevel'] ?? 'sedentary';
      });
    }

    setState(() {});
  }

  void _calculateRecommendedCalories() {
    final age = int.tryParse(_ageController.text);
    final weight = double.tryParse(_weightController.text);
    final height = double.tryParse(_heightController.text);

    if (age != null && weight != null && height != null) {
      double bmr;
      if (_gender == 'male') {
        bmr = (10 * weight) + (6.25 * height) - (5 * age) + 5;
      } else {
        bmr = (10 * weight) + (6.25 * height) - (5 * age) - 161;
      }

      double multiplier;
      switch (_activityLevel) {
        case 'sedentary':
          multiplier = 1.2;
          break;
        case 'light':
          multiplier = 1.375;
          break;
        case 'moderate':
          multiplier = 1.55;
          break;
        case 'very_active':
          multiplier = 1.725;
          break;
        case 'super_active':
          multiplier = 1.9;
          break;
        default:
          multiplier = 1.2;
      }

      final tdee = (bmr * multiplier).round();
      _goalController.text = (tdee - 250).toString();
    }
  }

  Future<void> _save() async {
    setState(() => _isLoading = true);
    try {
      final settings = ref.read(settingsServiceProvider);

      // Save API Key
      await settings.saveApiKey(_apiKeyController.text.trim());

      // Save Model
      final modelToSave = _selectedModel == 'custom'
          ? _customModelController.text.trim()
          : _selectedModel;
      if (modelToSave.isNotEmpty) {
        await settings.saveAIModel(modelToSave);
      }

      // Save Profile
      if (_ageController.text.isNotEmpty &&
          _weightController.text.isNotEmpty &&
          _heightController.text.isNotEmpty &&
          _goalController.text.isNotEmpty) {
        await settings.saveUserProfile(
          age: int.parse(_ageController.text),
          weight: double.parse(_weightController.text),
          height: double.parse(_heightController.text),
          gender: _gender,
          activityLevel: _activityLevel,
          goalCalories: int.parse(_goalController.text),
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Settings saved')));
        ref.invalidate(apiKeyProvider);
        ref.invalidate(aiServiceProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'AI Configuration',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const Gap(16),
          const Text(
            'This app uses OpenRouter to analyze your food. You need to provide your own API Key.',
            style: TextStyle(color: Colors.grey),
          ),
          const Gap(8),
          TextField(
            controller: _apiKeyController,
            decoration: const InputDecoration(
              labelText: 'OpenRouter API Key',
              border: OutlineInputBorder(),
              hintText: 'sk-or-...',
            ),
            obscureText: true,
          ),
          const Gap(16),
          InputDecorator(
            decoration: const InputDecoration(
              labelText: 'AI Model',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedModel,
                isExpanded: true,
                items: _models.entries.map((e) {
                  return DropdownMenuItem(value: e.key, child: Text(e.value));
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedModel = value);
                  }
                },
              ),
            ),
          ),
          if (_selectedModel == 'custom') ...[
            const Gap(8),
            TextField(
              controller: _customModelController,
              decoration: const InputDecoration(
                labelText: 'Custom Model ID (OpenRouter)',
                border: OutlineInputBorder(),
                hintText: 'e.g. meta-llama/llama-3-70b-instruct',
              ),
            ),
          ],

          const Gap(32),
          const Divider(),
          const Gap(16),

          const Text(
            'Personal Profile',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const Gap(16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _ageController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Age',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) => _calculateRecommendedCalories(),
                ),
              ),
              const Gap(16),
              Expanded(
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Gender',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _gender,
                      isExpanded: true,
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
                ),
              ),
            ],
          ),
          const Gap(16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _weightController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Weight (kg)',
                    border: OutlineInputBorder(),
                    suffixText: 'kg',
                  ),
                  onChanged: (_) => _calculateRecommendedCalories(),
                ),
              ),
              const Gap(16),
              Expanded(
                child: TextField(
                  controller: _heightController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Height (cm)',
                    border: OutlineInputBorder(),
                    suffixText: 'cm',
                  ),
                  onChanged: (_) => _calculateRecommendedCalories(),
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
                value: _activityLevel,
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
                onChanged: (v) {
                  setState(() => _activityLevel = v!);
                  _calculateRecommendedCalories();
                },
              ),
            ),
          ),
          const Gap(16),
          TextField(
            controller: _goalController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Daily Calorie Goal',
              border: OutlineInputBorder(),
              helperText: 'Auto-calculated (Maintenance - 250)',
            ),
          ),

          const Gap(24),
          FilledButton.icon(
            onPressed: _isLoading ? null : _save,
            icon: const Icon(Icons.save),
            label: const Text('Save Settings'),
          ),
          const Gap(40),
        ],
      ),
    );
  }
}
