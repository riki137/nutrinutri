import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:nutrinutri/core/providers.dart';
import 'package:nutrinutri/core/widgets/responsive_center.dart';
import 'package:nutrinutri/features/settings/presentation/settings_controller.dart';
import 'package:nutrinutri/features/settings/presentation/widgets/ai_configuration_section.dart';
import 'package:nutrinutri/features/settings/presentation/widgets/profile_section.dart';
import 'package:nutrinutri/features/settings/presentation/widgets/sync_section.dart';

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
  final _proteinController = TextEditingController();
  final _carbsController = TextEditingController();
  final _fatsController = TextEditingController();

  late String _initialHash = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSettings();
    });
    _apiKeyController.addListener(() {
      if (mounted) setState(() {});
    });
    _ageController.addListener(_calculateRecommendedCalories);
    _weightController.addListener(_calculateRecommendedCalories);
    _heightController.addListener(_calculateRecommendedCalories);
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _customModelController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _goalController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatsController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    await ref
        .read(settingsControllerProvider.notifier)
        .loadSettings(
          onKeyLoaded: (key) => _apiKeyController.text = key,
          onCustomModelLoaded: (model) => _customModelController.text = model,
          onProfileLoaded: (profile) {
            _ageController.text = profile['age']?.toString() ?? '';
            _weightController.text = profile['weight']?.toString() ?? '';
            _heightController.text = profile['height']?.toString() ?? '';
            _goalController.text = profile['goalCalories']?.toString() ?? '';
            _proteinController.text = profile['goalProtein']?.toString() ?? '';
            _carbsController.text = profile['goalCarbs']?.toString() ?? '';
            _fatsController.text = profile['goalFat']?.toString() ?? '';
          },
        );
    if (mounted) {
      setState(() {
        _initialHash = _computeHash();
      });
    }
  }

  void _calculateRecommendedCalories() {
    final age = int.tryParse(_ageController.text);
    final weight = double.tryParse(_weightController.text);
    final height = double.tryParse(_heightController.text);
    final state = ref.read(settingsControllerProvider);

    if (age != null && weight != null && height != null) {
      final calories = ref
          .read(settingsControllerProvider.notifier)
          .calculateDailyCalories(
            age: age,
            weight: weight,
            height: height,
            gender: state.gender,
            activityLevel: state.activityLevel,
          );
      _goalController.text = calories.toString();
    }
  }

  Future<void> _save() async {
    try {
      await ref
          .read(settingsControllerProvider.notifier)
          .save(
            apiKey: _apiKeyController.text,
            customModel: _customModelController.text,
            age: _ageController.text,
            weight: _weightController.text,
            height: _heightController.text,
            goalCalories: _goalController.text,
            protein: _proteinController.text,
            carbs: _carbsController.text,
            fats: _fatsController.text,
          );

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Settings saved')));
        setState(() {
          _initialHash = _computeHash();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving: $e')));
      }
    }
  }

  Future<void> _handleSync() async {
    try {
      final count = await ref.read(settingsControllerProvider.notifier).sync();
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
    }
  }

  bool _hasChanges() {
    return _initialHash != _computeHash();
  }

  String _computeHash() {
    final state = ref.read(settingsControllerProvider);
    return Object.hash(
      _apiKeyController.text,
      state.selectedModel,
      _customModelController.text,
      _ageController.text,
      _weightController.text,
      _heightController.text,
      state.gender,
      state.activityLevel,
      _goalController.text,
      _proteinController.text,
      _carbsController.text,
      _fatsController.text,
    ).toString();
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
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
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

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(settingsControllerProvider);
    final syncService = ref.watch(syncServiceProvider);
    final controller = ref.read(settingsControllerProvider.notifier);

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
              AIConfigurationSection(
                apiKeyController: _apiKeyController,
                customModelController: _customModelController,
                selectedModel: state.selectedModel,
                availableModels: controller.availableModels,
                onModelChanged: (v) =>
                    v != null ? controller.updateModel(v) : null,
              ),
              const Gap(32),
              const Divider(),
              const Gap(16),
              SyncSection(
                currentUser: syncService.currentUser,
                isSyncing: state.isSyncing,
                onSignIn: controller.signIn,
                onSignOut: controller.signOut,
                onSync: _handleSync,
              ),
              const Gap(32),
              const Divider(),
              const Gap(16),
              ProfileSection(
                ageController: _ageController,
                weightController: _weightController,
                heightController: _heightController,
                goalController: _goalController,
                proteinController: _proteinController,
                carbsController: _carbsController,
                fatsController: _fatsController,
                gender: state.gender,
                activityLevel: state.activityLevel,
                onGenderChanged: (v) {
                  if (v != null) {
                    controller.updateGender(v);
                    _calculateRecommendedCalories();
                  }
                },
                onActivityLevelChanged: (v) {
                  if (v != null) {
                    controller.updateActivityLevel(v);
                    _calculateRecommendedCalories();
                  }
                },
              ),
              const Gap(24),
              FilledButton.icon(
                onPressed: state.isLoading ? null : _save,
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
