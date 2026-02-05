import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:nutrinutri/core/providers.dart';
import 'package:nutrinutri/core/utils/platform_helper.dart';
import 'package:nutrinutri/core/widgets/responsive_center.dart';
import 'package:nutrinutri/features/settings/presentation/managers/settings_form_manager.dart';
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
  late final SettingsFormManager _formManager;

  @override
  void initState() {
    super.initState();
    _formManager = SettingsFormManager(
      ref: ref,
      onStateChanged: () {
        if (mounted) {
          setState(() {});
          ref.read(unsavedSettingsChangesProvider.notifier).state = _formManager
              .hasChanges();
        }
      },
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSettings();
    });
  }

  @override
  void dispose() {
    Future.microtask(
      () => ref.read(unsavedSettingsChangesProvider.notifier).state = false,
    );
    _formManager.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    await _formManager.loadSettings();
  }

  Future<void> _save() async {
    try {
      await _formManager.save();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Settings saved')));
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

  Future<bool> _onWillPop() async {
    if (!_formManager.hasChanges()) return true;

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
    final currentUser = ref.watch(currentUserProvider).valueOrNull;
    final controller = ref.read(settingsControllerProvider.notifier);
    final isDesktop = PlatformHelper.isDesktopOrWeb;
    final theme = Theme.of(context);

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
        appBar: isDesktop ? null : AppBar(title: const Text('Settings')),
        body: isDesktop
            ? _buildDesktopLayout(
                context,
                theme,
                state,
                currentUser,
                controller,
              )
            : _buildMobileLayout(state, currentUser, controller),
      ),
    );
  }

  Widget _buildDesktopLayout(
    BuildContext context,
    ThemeData theme,
    SettingsState state,
    dynamic currentUser,
    SettingsController controller,
  ) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Desktop header
          Row(
            children: [
              Text(
                'Settings',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: state.isLoading ? null : _save,
                icon: const Icon(Icons.save),
                label: const Text('Save Settings'),
              ),
            ],
          ),
          const Gap(24),
          // Main content
          Expanded(
            child: ResponsiveCenter(
              maxWidth: 900,
              child: ListView(
                padding: EdgeInsets.zero,
                children: _buildSettingsSections(
                  state,
                  currentUser,
                  controller,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(
    SettingsState state,
    dynamic currentUser,
    SettingsController controller,
  ) {
    return ResponsiveCenter(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ..._buildSettingsSections(state, currentUser, controller),
          const Gap(24),
          FilledButton.icon(
            onPressed: state.isLoading ? null : _save,
            icon: const Icon(Icons.save),
            label: const Text('Save Settings'),
          ),
          const Gap(40),
        ],
      ),
    );
  }

  List<Widget> _buildSettingsSections(
    SettingsState state,
    dynamic currentUser,
    SettingsController controller,
  ) {
    return [
      AIConfigurationSection(
        apiKeyController: _formManager.apiKeyController,
        customModelController: _formManager.customModelController,
        selectedModel: state.selectedModel,
        fallbackModel: state.fallbackModel,
        availableModels: controller.availableModels,
        onModelChanged: (v) => v != null ? controller.updateModel(v) : null,
        onFallbackModelChanged: controller.updateFallbackModel,
      ),
      const Gap(32),
      const Divider(),
      const Gap(16),
      SyncSection(
        currentUser: currentUser,
        isSyncing: state.isSyncing,
        onSignIn: controller.signIn,
        onSignOut: controller.signOut,
        onSync: _handleSync,
        webSignInButton: controller.webSignInButton,
      ),
      const Gap(32),
      const Divider(),
      const Gap(16),
      ProfileSection(
        ageController: _formManager.ageController,
        weightController: _formManager.weightController,
        heightController: _formManager.heightController,
        goalController: _formManager.goalController,
        proteinController: _formManager.proteinController,
        carbsController: _formManager.carbsController,
        fatsController: _formManager.fatsController,
        gender: state.gender,
        activityLevel: state.activityLevel,
        onGenderChanged: (v) {
          if (v != null) {
            controller.updateGender(v);
            _formManager.recalculateCalories();
          }
        },
        onActivityLevelChanged: (v) {
          if (v != null) {
            controller.updateActivityLevel(v);
            _formManager.recalculateCalories();
          }
        },
      ),
    ];
  }
}
