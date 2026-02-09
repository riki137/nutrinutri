import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:nutrinutri/core/providers.dart';
import 'package:nutrinutri/core/services/google_user_info.dart';
import 'package:nutrinutri/features/settings/presentation/managers/settings_form_manager.dart';
import 'package:nutrinutri/features/settings/presentation/settings_controller.dart';
import 'package:nutrinutri/features/settings/presentation/widgets/ai_configuration_section.dart';
import 'package:nutrinutri/features/settings/presentation/widgets/profile_section.dart';
import 'package:nutrinutri/features/settings/presentation/widgets/sync_section.dart';

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  static const _totalSteps = 3;
  int _currentStep = 0;
  bool _isSaving = false;
  bool _isSigningIn = false;
  bool _hasSyncedAfterSignIn = false;

  late final SettingsFormManager _formManager;

  @override
  void initState() {
    super.initState();
    _formManager = SettingsFormManager(
      ref: ref,
      onStateChanged: () {
        if (mounted) {
          setState(() {});
        }
      },
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSettings();
    });
  }

  @override
  void dispose() {
    _formManager.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    try {
      await _formManager.loadSettings();
    } catch (e) {
      if (mounted) {
        _showSnack('Could not load setup defaults: $e');
      }
    }
  }

  Future<void> _handleSync() async {
    try {
      final count = await ref.read(settingsControllerProvider.notifier).sync();
      await _formManager.loadSettings();
      _hasSyncedAfterSignIn = true;
      if (mounted) {
        _showSnack('Sync complete. $count items updated.');
      }
    } catch (e) {
      if (mounted) {
        _showSnack('Sync failed: $e');
      }
    }
  }

  Future<void> _handleSignIn() async {
    if (_isSigningIn) return;
    setState(() => _isSigningIn = true);
    try {
      await ref.read(settingsControllerProvider.notifier).signIn();
      final currentUser = ref.read(syncServiceProvider).currentUser;
      if (currentUser == null) return;

      _hasSyncedAfterSignIn = false;
      final count = await ref.read(settingsControllerProvider.notifier).sync();
      await _formManager.loadSettings();
      _hasSyncedAfterSignIn = true;
      if (mounted) {
        _showSnack('Connected and synced. $count items updated.');
      }
    } catch (e) {
      if (mounted) {
        _showSnack('Sign-in failed: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isSigningIn = false);
      }
    }
  }

  Future<void> _handleSignOut() async {
    try {
      await ref.read(settingsControllerProvider.notifier).signOut();
      _hasSyncedAfterSignIn = false;
    } catch (e) {
      if (mounted) {
        _showSnack('Sign-out failed: $e');
      }
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String? _validateAndNormalizeProfileStep() {
    final age = int.tryParse(_formManager.ageController.text.trim());
    if (age == null || age <= 0) {
      return 'Please enter a valid age.';
    }

    final weightText = _formManager.weightController.text.trim().replaceAll(
      ',',
      '.',
    );
    final weight = double.tryParse(weightText);
    if (weight == null || weight <= 0) {
      return 'Please enter a valid weight.';
    }

    final heightText = _formManager.heightController.text.trim().replaceAll(
      ',',
      '.',
    );
    final height = double.tryParse(heightText);
    if (height == null || height <= 0) {
      return 'Please enter a valid height.';
    }

    final goal = int.tryParse(_formManager.goalController.text.trim());
    if (goal == null || goal <= 0) {
      return 'Please enter a valid daily calorie goal.';
    }

    final proteinText = _formManager.proteinController.text.trim();
    if (proteinText.isNotEmpty && int.tryParse(proteinText) == null) {
      return 'Please enter a valid protein goal.';
    }

    final carbsText = _formManager.carbsController.text.trim();
    if (carbsText.isNotEmpty && int.tryParse(carbsText) == null) {
      return 'Please enter a valid carbs goal.';
    }

    final fatsText = _formManager.fatsController.text.trim();
    if (fatsText.isNotEmpty && int.tryParse(fatsText) == null) {
      return 'Please enter a valid fats goal.';
    }

    _formManager.ageController.text = age.toString();
    _formManager.weightController.text = weightText;
    _formManager.heightController.text = heightText;
    _formManager.goalController.text = goal.toString();

    return null;
  }

  Future<void> _onPrimaryAction() async {
    final currentUser = ref.read(syncServiceProvider).currentUser;
    if (_currentStep == 0 && currentUser != null && !_hasSyncedAfterSignIn) {
      final profileSyncError = await _syncAndPrefill();
      if (profileSyncError != null) {
        _showSnack(profileSyncError);
        return;
      }
    }

    if (_currentStep == 1) {
      final profileError = _validateAndNormalizeProfileStep();
      if (profileError != null) {
        _showSnack(profileError);
        return;
      }
    }

    if (_currentStep < _totalSteps - 1) {
      setState(() => _currentStep += 1);
      return;
    }

    await _finishOnboarding();
  }

  Future<void> _finishOnboarding() async {
    final profileError = _validateAndNormalizeProfileStep();
    if (profileError != null) {
      if (mounted) {
        setState(() => _currentStep = 1);
        _showSnack(profileError);
      }
      return;
    }

    setState(() => _isSaving = true);
    try {
      await _formManager.save();
      if (mounted) {
        context.go('/');
      }
    } catch (e) {
      if (mounted) {
        _showSnack('Error completing setup: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _goBack() {
    if (_currentStep == 0) return;
    setState(() => _currentStep -= 1);
  }

  void _skipSync() {
    if (_currentStep != 0) return;
    final currentUser = ref.read(syncServiceProvider).currentUser;
    if (currentUser != null && !_hasSyncedAfterSignIn) {
      _showSnack('Sync first, or sign out to skip Google Drive.');
      return;
    }
    setState(() => _currentStep = 1);
  }

  Future<String?> _syncAndPrefill() async {
    try {
      await ref.read(settingsControllerProvider.notifier).sync();
      await _formManager.loadSettings();
      _hasSyncedAfterSignIn = true;
      return null;
    } catch (e) {
      return 'Sync failed. Please sync before continuing: $e';
    }
  }

  _OnboardingStep _currentStepData() {
    switch (_currentStep) {
      case 0:
        return const _OnboardingStep(
          title: 'Connect Google Drive',
          description: 'Optional: sign in to sync your diary across devices.',
        );
      case 1:
        return const _OnboardingStep(
          title: 'Set Your Macros',
          description:
              'Add your body stats and goals. We will auto-calculate calories.',
        );
      case 2:
      default:
        return const _OnboardingStep(
          title: 'Connect OpenRouter',
          description:
              'Add your API key and AI model settings for food analysis.',
        );
    }
  }

  Widget _buildStepContent(
    SettingsState state,
    GoogleUserInfo? currentUser,
    SettingsController controller,
  ) {
    switch (_currentStep) {
      case 0:
        return SyncSection(
          currentUser: currentUser,
          isSyncing: state.isSyncing,
          onSignIn: _handleSignIn,
          onSignOut: _handleSignOut,
          onSync: _handleSync,
          webSignInButton: controller.webSignInButton,
        );
      case 1:
        return ProfileSection(
          ageController: _formManager.ageController,
          weightController: _formManager.weightController,
          heightController: _formManager.heightController,
          goalController: _formManager.goalController,
          proteinController: _formManager.proteinController,
          carbsController: _formManager.carbsController,
          fatsController: _formManager.fatsController,
          gender: state.gender,
          activityLevel: state.activityLevel,
          onGenderChanged: (value) {
            if (value != null) {
              controller.updateGender(value);
              _formManager.recalculateCalories();
            }
          },
          onActivityLevelChanged: (value) {
            if (value != null) {
              controller.updateActivityLevel(value);
              _formManager.recalculateCalories();
            }
          },
        );
      case 2:
      default:
        return AIConfigurationSection(
          apiKeyController: _formManager.apiKeyController,
          customModelController: _formManager.customModelController,
          selectedModel: state.selectedModel,
          fallbackModel: state.fallbackModel,
          availableModels: controller.availableModels,
          onModelChanged: (value) {
            if (value != null) {
              controller.updateModel(value);
            }
          },
          onFallbackModelChanged: controller.updateFallbackModel,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(settingsControllerProvider);
    final currentUser = ref.watch(currentUserProvider).value;
    final controller = ref.read(settingsControllerProvider.notifier);
    final stepData = _currentStepData();
    final currentSyncRequired = currentUser != null && !_hasSyncedAfterSignIn;
    final actionInProgress =
        _isSaving || state.isLoading || state.isSyncing || _isSigningIn;

    return Scaffold(
      appBar: AppBar(title: const Text('Setup NutriNutri')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Step ${_currentStep + 1} of $_totalSteps',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const Gap(8),
                      LinearProgressIndicator(
                        value: (_currentStep + 1) / _totalSteps,
                      ),
                      const Gap(16),
                      Text(
                        stepData.title,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const Gap(4),
                      Text(
                        stepData.description,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: _buildStepContent(state, currentUser, controller),
                  ),
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      if (_currentStep > 0)
                        OutlinedButton(
                          onPressed: actionInProgress ? null : _goBack,
                          child: const Text('Back'),
                        ),
                      const Spacer(),
                      if (_currentStep == 0 && !currentSyncRequired)
                        TextButton(
                          onPressed: actionInProgress ? null : _skipSync,
                          child: const Text('Skip'),
                        ),
                      if (_currentStep == 0 && !currentSyncRequired)
                        const Gap(8),
                      FilledButton(
                        onPressed: actionInProgress ? null : _onPrimaryAction,
                        child: actionInProgress
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                _currentStep == _totalSteps - 1
                                    ? 'Finish Setup'
                                    : 'Continue',
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OnboardingStep {
  const _OnboardingStep({required this.title, required this.description});
  final String title;
  final String description;
}
