import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:nutrinutri/core/providers.dart';
import 'package:nutrinutri/core/services/google_user_info.dart';
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
      final result = await ref.read(settingsControllerProvider.notifier).sync();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Sync complete: ↓${result.downloaded} ↑${result.uploaded}',
            ),
          ),
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

  void _onModelChanged(SettingsController controller, String? value) {
    if (value == null) return;
    controller.updateModel(value);
  }

  void _onGenderChanged(SettingsController controller, String? value) {
    if (value == null) return;
    controller.updateGender(value);
    _formManager.recalculateCalories();
  }

  void _onActivityLevelChanged(SettingsController controller, String? value) {
    if (value == null) return;
    controller.updateActivityLevel(value);
    _formManager.recalculateCalories();
  }

  Future<void> _openLicenses() async {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      const platform = MethodChannel('sk.popelis.nutrinutri/licenses');
      try {
        await platform.invokeMethod('showLicenses');
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to load licenses: '$e'.")),
        );
      }
      return;
    }

    showLicensePage(
      context: context,
      applicationName: 'NutriNutri',
      useRootNavigator: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(settingsControllerProvider);
    final currentUser = ref.watch(currentUserProvider).value;
    final controller = ref.read(settingsControllerProvider.notifier);
    final isDesktop = PlatformHelper.isDesktopOrWeb;
    final theme = Theme.of(context);
    final settingsSections = _SettingsSections(
      state: state,
      currentUser: currentUser,
      controller: controller,
      formManager: _formManager,
      onModelChanged: (value) => _onModelChanged(controller, value),
      onFallbackModelChanged: controller.updateFallbackModel,
      onGenderChanged: (value) => _onGenderChanged(controller, value),
      onActivityLevelChanged: (value) =>
          _onActivityLevelChanged(controller, value),
      onSync: () => unawaited(_handleSync()),
      onOpenLicenses: () => unawaited(_openLicenses()),
    );

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
            ? _buildDesktopLayout(context, theme, state, settingsSections)
            : _buildMobileLayout(state, settingsSections),
      ),
    );
  }

  Widget _buildDesktopLayout(
    BuildContext context,
    ThemeData theme,
    SettingsState state,
    Widget settingsSections,
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
                children: [settingsSections],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(SettingsState state, Widget settingsSections) {
    return ResponsiveCenter(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          settingsSections,
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
}

class _SettingsSections extends StatelessWidget {
  const _SettingsSections({
    required this.state,
    required this.currentUser,
    required this.controller,
    required this.formManager,
    required this.onModelChanged,
    required this.onFallbackModelChanged,
    required this.onGenderChanged,
    required this.onActivityLevelChanged,
    required this.onSync,
    required this.onOpenLicenses,
  });

  final SettingsState state;
  final GoogleUserInfo? currentUser;
  final SettingsController controller;
  final SettingsFormManager formManager;
  final ValueChanged<String?> onModelChanged;
  final ValueChanged<String?> onFallbackModelChanged;
  final ValueChanged<String?> onGenderChanged;
  final ValueChanged<String?> onActivityLevelChanged;
  final VoidCallback onSync;
  final VoidCallback onOpenLicenses;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AIConfigurationSection(
          apiKeyController: formManager.apiKeyController,
          customModelController: formManager.customModelController,
          selectedModel: state.selectedModel,
          fallbackModel: state.fallbackModel,
          availableModels: controller.availableModels,
          onModelChanged: onModelChanged,
          onFallbackModelChanged: onFallbackModelChanged,
        ),
        const _SettingsSectionBreak(),
        SyncSection(
          currentUser: currentUser,
          isSyncing: state.isSyncing,
          onSignIn: controller.signIn,
          onSignOut: controller.signOut,
          onSync: onSync,
          webSignInButton: controller.webSignInButton,
        ),
        const _SettingsSectionBreak(),
        ProfileSection(
          ageController: formManager.ageController,
          weightController: formManager.weightController,
          heightController: formManager.heightController,
          metricGoalControllers: formManager.metricGoalControllers,
          gender: state.gender,
          activityLevel: state.activityLevel,
          onGenderChanged: onGenderChanged,
          onActivityLevelChanged: onActivityLevelChanged,
        ),
        const _SettingsSectionBreak(),
        _AboutSection(onOpenLicenses: onOpenLicenses),
      ],
    );
  }
}

class _SettingsSectionBreak extends StatelessWidget {
  const _SettingsSectionBreak();

  @override
  Widget build(BuildContext context) {
    return const Column(children: [Gap(32), Divider(), Gap(16)]);
  }
}

class _AboutSection extends StatelessWidget {
  const _AboutSection({required this.onOpenLicenses});

  final VoidCallback onOpenLicenses;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text('About', style: Theme.of(context).textTheme.titleMedium),
        ),
        const Gap(8),
        ListTile(
          title: const Text('Open Source Licenses'),
          leading: const Icon(Icons.description),
          trailing: const Icon(Icons.chevron_right),
          onTap: onOpenLicenses,
        ),
      ],
    );
  }
}
