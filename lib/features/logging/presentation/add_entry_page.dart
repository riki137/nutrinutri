import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nutrinutri/core/widgets/responsive_center.dart';
import 'package:nutrinutri/features/diary/data/diary_service.dart';
import 'package:nutrinutri/features/logging/presentation/add_entry_controller.dart';
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
  final _descriptionController = TextEditingController();
  final _nameController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _proteinController = TextEditingController();
  final _carbsController = TextEditingController();
  final _fatsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.existingEntry != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(addEntryControllerProvider.notifier)
            .initializeWithEntry(widget.existingEntry!);
        _initializeControllers(widget.existingEntry!);
      });
    }
  }

  void _initializeControllers(FoodEntry entry) {
    _nameController.text = entry.name;
    _caloriesController.text = entry.calories.toString();
    _proteinController.text = entry.protein.toString();
    _carbsController.text = entry.carbs.toString();
    _fatsController.text = entry.fats.toString();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _nameController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatsController.dispose();
    super.dispose();
  }

  bool get _canUseCamera {
    if (kIsWeb) return false;
    return Platform.isAndroid || Platform.isIOS;
  }

  Future<void> _addOptimistic() async {
    final state = ref.read(addEntryControllerProvider);
    if (_descriptionController.text.isEmpty && state.image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide text or an image.')),
      );
      return;
    }

    try {
      await ref
          .read(addEntryControllerProvider.notifier)
          .addOptimistic(description: _descriptionController.text);
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
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
      await ref
          .read(addEntryControllerProvider.notifier)
          .saveEntry(
            existingEntry: widget.existingEntry,
            name: _nameController.text,
            calories: _caloriesController.text,
            protein: _proteinController.text,
            carbs: _carbsController.text,
            fats: _fatsController.text,
          );
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
                  controller: _descriptionController,
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
                  nameController: _nameController,
                  caloriesController: _caloriesController,
                  proteinController: _proteinController,
                  carbsController: _carbsController,
                  fatsController: _fatsController,
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
                      await ref
                          .read(addEntryControllerProvider.notifier)
                          .deleteEntry(widget.existingEntry!);
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
