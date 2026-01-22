import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:nutrinutri/core/widgets/responsive_center.dart';
import 'package:nutrinutri/features/diary/data/diary_service.dart';
import 'package:nutrinutri/features/logging/presentation/add_entry_controller.dart';
import 'package:nutrinutri/features/logging/presentation/managers/add_entry_form_manager.dart';
import 'package:nutrinutri/features/logging/presentation/widgets/entry_action_buttons.dart';
import 'package:nutrinutri/features/logging/presentation/widgets/entry_form.dart';
import 'package:nutrinutri/features/logging/presentation/widgets/food_image_picker.dart';

class AddEntryPage extends ConsumerStatefulWidget {
  final FoodEntry? existingEntry;
  const AddEntryPage({super.key, this.existingEntry});

  @override
  ConsumerState<AddEntryPage> createState() => _AddEntryPageState();
}

class _AddEntryPageState extends ConsumerState<AddEntryPage> {
  late final AddEntryFormManager _formManager;

  @override
  void initState() {
    super.initState();
    _formManager = AddEntryFormManager(
      ref: ref,
      onStateChanged: () {
        if (mounted) setState(() {});
      },
    );

    if (widget.existingEntry != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _formManager.initializeWithEntry(widget.existingEntry!);
      });
    }
  }

  @override
  void dispose() {
    _formManager.dispose();
    super.dispose();
  }

  bool get _canUseCamera {
    if (kIsWeb) return false;
    return Platform.isAndroid || Platform.isIOS;
  }

  Future<void> _addOptimistic() async {
    try {
      await _formManager.addOptimistic();
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        // If it's a validation error (empty input), just show message
        if (e.toString().contains('Please provide text')) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(e.toString())));
          return;
        }

        // API Key or other errors
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().contains('API Key')
                  ? 'Please set your API Key in Settings'
                  : 'Failed to add entry: $e',
            ),
            action: e.toString().contains('API Key')
                ? SnackBarAction(
                    label: 'Settings',
                    onPressed: () => context.push('/settings'),
                  )
                : null,
          ),
        );
      }
    }
  }

  Future<void> _saveEntry() async {
    try {
      await _formManager.saveEntry(widget.existingEntry);
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to save: $e')));
      }
    }
  }

  Future<void> _pickDate() async {
    final current = ref.read(addEntryControllerProvider).selectedDate;
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null) {
      ref.read(addEntryControllerProvider.notifier).updateDate(pickedDate);
    }
  }

  Future<void> _pickTime() async {
    final current = ref.read(addEntryControllerProvider).selectedTime;
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: current,
    );
    if (pickedTime != null) {
      ref.read(addEntryControllerProvider.notifier).updateTime(pickedTime);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(addEntryControllerProvider);
    final isEditing = widget.existingEntry != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Edit Entry' : 'Log Food')),
      body: SingleChildScrollView(
        child: ResponsiveCenter(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!isEditing) ...[
                FoodImagePicker(
                  image: state.image,
                  canUseCamera: _canUseCamera,
                  onPickImage: (source) => ref
                      .read(addEntryControllerProvider.notifier)
                      .pickImage(source),
                ),
                const Gap(16),
                TextField(
                  controller: _formManager.descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Describe the food (optional if image provided)',
                    border: OutlineInputBorder(),
                    hintText: 'e.g. 2 eggs and toast',
                  ),
                  maxLines: 3,
                ),
                const Gap(24),
                FilledButton.icon(
                  onPressed: _addOptimistic,
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text('Add Entry'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ],
              if (state.showForm) ...[
                const Gap(32),
                EntryForm(
                  nameController: _formManager.nameController,
                  caloriesController: _formManager.caloriesController,
                  proteinController: _formManager.proteinController,
                  carbsController: _formManager.carbsController,
                  fatsController: _formManager.fatsController,
                  selectedIcon: state.selectedIcon,
                  selectedDate: state.selectedDate,
                  selectedTime: state.selectedTime,
                  onIconChanged: (v) => v != null
                      ? ref
                            .read(addEntryControllerProvider.notifier)
                            .updateIcon(v)
                      : null,
                  onPickDate: _pickDate,
                  onPickTime: _pickTime,
                ),
                const Gap(24),
                EntryActionButtons(
                  isEditing: isEditing,
                  onSave: _saveEntry,
                  onDeleteConfirmed: () async {
                    try {
                      await _formManager.deleteEntry(widget.existingEntry!);
                      if (mounted) context.pop();
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to delete: $e')),
                        );
                      }
                    }
                  },
                ),
                const Gap(32),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
