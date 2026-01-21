import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutrinutri/core/providers.dart';
import 'package:gap/gap.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:nutrinutri/core/widgets/responsive_center.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class AIModelInfo {
  final String id;
  final String name;
  final String price;
  final String description;
  final List<String> tags;

  const AIModelInfo({
    required this.id,
    required this.name,
    required this.price,
    this.description = '',
    this.tags = const [],
  });
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  final _apiKeyController = TextEditingController();
  final _customModelController = TextEditingController();
  final _ageController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _goalController = TextEditingController();
  final _proteinController = TextEditingController();
  final _carbsController = TextEditingController();
  final _fatsController = TextEditingController();

  String _selectedModel = 'google/gemini-2.0-flash-exp:free';
  String _gender = 'male';
  String _activityLevel = 'sedentary';
  bool _isLoading = false;
  bool _isSyncing = false;
  GoogleSignInAccount? _currentUser;

  final List<AIModelInfo> _availableModels = [
    const AIModelInfo(
      id: 'google/gemini-3-flash-preview',
      name: 'Gemini 3 Flash',
      price: r'~$0.008',
      description: 'Recommended, Default, Fast, Accurate',
    ),
    const AIModelInfo(
      id: 'google/gemini-3-pro-preview',
      name: 'Gemini 3 Pro',
      price: r'~$0.04',
      description: 'Best, expensive',
    ),
    const AIModelInfo(
      id: 'openai/gpt-5.2',
      name: 'GPT-5.2',
      price: r'~$0.008',
      description: 'Reliable, Accurate',
    ),
    const AIModelInfo(
      id: 'openai/gpt-5-mini',
      name: 'GPT-5 Mini',
      price: r'~$0.003',
      description: 'Cheaper, less knowledge',
    ),
    const AIModelInfo(
      id: 'anthropic/claude-sonnet-4.5',
      name: 'Claude Sonnet 4.5',
      price: r'~$0.007',
      description: 'Not very accurate',
    ),
    const AIModelInfo(
      id: 'anthropic/claude-opus-4.5',
      name: 'Claude Opus 4.5',
      price: r'~$0.01',
      description: 'Not very accurate',
    ),
    const AIModelInfo(
      id: 'x-ai/grok-4',
      name: 'Grok 4',
      price: '?',
      description: 'Latest model from xAI',
    ),
    const AIModelInfo(
      id: 'custom',
      name: 'Custom OpenRouter model',
      price: 'Varies',
      description: 'Advanced, not recommended',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _initSync();
    _apiKeyController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  void _initSync() {
    final syncService = ref.read(syncServiceProvider);
    _currentUser = syncService.currentUser;
    syncService.onCurrentUserChanged.listen((account) {
      if (mounted) setState(() => _currentUser = account);
    });
    // Silent sign-in to restore session if available
    syncService.restoreSession();
  }

  Future<void> _handleSignIn() async {
    try {
      await ref.read(syncServiceProvider).signIn();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Sign in failed: $e')));
      }
    }
  }

  Future<void> _handleSignOut() async {
    await ref.read(syncServiceProvider).signOut();
  }

  Future<void> _handleSync() async {
    setState(() => _isSyncing = true);
    try {
      final count = await ref.read(syncServiceProvider).sync();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sync complete. $count items updated.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Sync failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  Future<void> _loadSettings() async {
    final settings = ref.read(settingsServiceProvider);

    // Load API Key & Model
    final key = await ref.read(apiKeyProvider.future);
    if (key != null) {
      _apiKeyController.text = key;
    }
    final model = await settings.getAIModel();
    if (_availableModels.any((m) => m.id == model)) {
      _selectedModel = model;
    } else {
      _selectedModel = 'custom';
      _customModelController.text = model;
    }

    // Load Profile
    final profile = await settings.getUserProfile();
    if (profile != null) {
      _ageController.text = profile['age']?.toString() ?? '';
      _weightController.text = profile['weight']?.toString() ?? '';
      _heightController.text = profile['height']?.toString() ?? '';
      _goalController.text = profile['goalCalories']?.toString() ?? '';
      setState(() {
        _gender = profile['gender'] ?? 'male';
        _activityLevel = profile['activityLevel'] ?? 'sedentary';
        _proteinController.text = profile['goalProtein']?.toString() ?? '';
        _carbsController.text = profile['goalCarbs']?.toString() ?? '';
        _fatsController.text = profile['goalFat']?.toString() ?? '';
      });
    }

    setState(() {
      _initialHash = _computeHash();
    });
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
          goalProtein: int.tryParse(_proteinController.text),
          goalCarbs: int.tryParse(_carbsController.text),
          goalFat: int.tryParse(_fatsController.text),
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Settings saved')));

        setState(() {
          _initialHash = _computeHash();
        });

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

  Future<bool> _onWillPop() async {
    if (!_hasChanges()) return true;

    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unsaved Changes'),
        content: const Text(
          'You have unsaved changes. Do you want to save them before leaving?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false), // Stay
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true), // Leave
            child: const Text('Discard'),
          ),
          FilledButton(
            onPressed: () async {
              await _save();
              if (context.mounted) Navigator.of(context).pop(true);
            },
            child: const Text('Save & Leave'),
          ),
        ],
      ),
    );

    return shouldPop ?? false;
  }

  bool _hasChanges() {
    return _initialHash != _computeHash();
  }

  String _computeHash() {
    return Object.hash(
      _apiKeyController.text,
      _selectedModel,
      _customModelController.text,
      _ageController.text,
      _weightController.text,
      _heightController.text,
      _gender,
      _activityLevel,
      _goalController.text,
      _proteinController.text,
      _carbsController.text,
      _fatsController.text,
    ).toString();
  }

  late String _initialHash = '';

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Settings')),
        body: ResponsiveCenter(
          child: ListView(
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
              if (_apiKeyController.text.isEmpty) ...[
                const Gap(8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final url = Uri.parse(
                        'https://openrouter.ai/settings/keys',
                      );
                      if (await canLaunchUrl(url)) {
                        await launchUrl(url);
                      }
                    },
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('Get API Key'),
                  ),
                ),
              ] else ...[
                const Gap(16),
                InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'AI Model',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedModel,
                      isExpanded: true,
                      itemHeight: null, // Allow items to be taller
                      items: _availableModels.map((model) {
                        return DropdownMenuItem(
                          value: model.id,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      model.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const Spacer(),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primaryContainer,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        model.price,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onPrimaryContainer,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const Gap(4),
                                Text(
                                  model.description,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                if (model.tags.isNotEmpty) ...[
                                  const Gap(4),
                                  Wrap(
                                    spacing: 4,
                                    runSpacing: 4,
                                    children: model.tags.map((tag) {
                                      return Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 1,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                          border: Border.all(
                                            color: Colors.blue.withOpacity(0.3),
                                          ),
                                        ),
                                        child: Text(
                                          tag,
                                          style: const TextStyle(
                                            fontSize: 10,
                                            color: Colors.blue,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                      selectedItemBuilder: (context) {
                        return _availableModels.map((model) {
                          return Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              model.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                          );
                        }).toList();
                      },
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
              ],

              const Gap(32),
              const Divider(),
              const Gap(16),

              const Text(
                'Data Synchronization',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const Gap(8),
              const Text(
                'Sync your diary with Google Drive.',
                style: TextStyle(color: Colors.grey),
              ),
              const Gap(16),
              if (_currentUser == null)
                FilledButton.icon(
                  onPressed: _handleSignIn,
                  icon: const Icon(Icons.login),
                  label: const Text('Sign in with Google'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    side: const BorderSide(color: Colors.grey),
                  ),
                )
              else ...[
                ListTile(
                  leading: GoogleUserCircleAvatar(identity: _currentUser!),
                  title: Text(_currentUser!.displayName ?? ''),
                  subtitle: Text(_currentUser!.email),
                  trailing: IconButton(
                    icon: const Icon(Icons.logout),
                    onPressed: _handleSignOut,
                  ),
                ),
                const Gap(8),
                FilledButton.icon(
                  onPressed: _isSyncing ? null : _handleSync,
                  icon: _isSyncing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.sync),
                  label: Text(_isSyncing ? 'Syncing...' : 'Sync Now'),
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
                            DropdownMenuItem(
                              value: 'male',
                              child: Text('Male'),
                            ),
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
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
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
                      controller: _proteinController,
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
                      controller: _carbsController,
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
                      controller: _fatsController,
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

              const Gap(24),
              FilledButton.icon(
                onPressed: _isLoading ? null : _save,
                icon: const Icon(Icons.save),
                label: const Text('Save Settings'),
              ),
              const Gap(40),
            ],
          ),
        ),
      ),
    );
  }
}
