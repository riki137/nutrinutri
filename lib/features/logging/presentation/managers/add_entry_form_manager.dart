import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutrinutri/features/diary/data/diary_service.dart';
import 'package:nutrinutri/features/logging/presentation/add_entry_controller.dart';

class AddEntryFormManager {

  AddEntryFormManager({required this.ref, required this.onStateChanged}) {
    nameController.addListener(_updateCalories);
    durationController.addListener(_updateCalories);
  }
  final WidgetRef ref;
  final VoidCallback onStateChanged;

  final descriptionController = TextEditingController();
  final nameController = TextEditingController();
  final caloriesController = TextEditingController();
  final proteinController = TextEditingController();
  final carbsController = TextEditingController();
  final fatsController = TextEditingController();
  final durationController = TextEditingController();

  void _updateCalories() async {
    final state = ref.read(addEntryControllerProvider);
    if (state.type != EntryType.exercise) return;

    final name = nameController.text;
    final duration = int.tryParse(durationController.text);

    if (name.isNotEmpty && duration != null && duration > 0) {
      final calories = await ref
          .read(addEntryControllerProvider.notifier)
          .calculateExerciseCalories(name, duration);
      if (calories != null) {
        caloriesController.text = calories.toString();
      }
    }
  }

  void dispose() {
    descriptionController.dispose();
    nameController.dispose();
    caloriesController.dispose();
    proteinController.dispose();
    carbsController.dispose();
    fatsController.dispose();
    durationController.dispose();
  }

  void initializeWithEntry(DiaryEntry entry) {
    ref.read(addEntryControllerProvider.notifier).initializeWithEntry(entry);
    nameController.text = entry.name;
    caloriesController.text = entry.calories.toString();
    proteinController.text = entry.protein.toString();
    carbsController.text = entry.carbs.toString();
    fatsController.text = entry.fats.toString();
    durationController.text = entry.durationMinutes?.toString() ?? '';
    onStateChanged();
  }

  void initializeWithType(EntryType type) {
    ref.read(addEntryControllerProvider.notifier).initializeWithType(type);
    onStateChanged();
  }

  Future<void> addOptimistic() async {
    final state = ref.read(addEntryControllerProvider);
    if (descriptionController.text.isEmpty && state.image == null) {
      throw Exception('Please provide text or an image.');
    }

    await ref
        .read(addEntryControllerProvider.notifier)
        .addOptimistic(description: descriptionController.text);
  }

  Future<void> saveEntry(DiaryEntry? existingEntry) async {
    await ref
        .read(addEntryControllerProvider.notifier)
        .saveEntry(
          existingEntry: existingEntry,
          name: nameController.text,
          calories: caloriesController.text,
          protein: proteinController.text,
          carbs: carbsController.text,
          fats: fatsController.text,
          durationMinutes: durationController.text,
        );
  }

  Future<void> deleteEntry(DiaryEntry entry) async {
    await ref.read(addEntryControllerProvider.notifier).deleteEntry(entry);
  }
}
