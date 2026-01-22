import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutrinutri/features/diary/data/diary_service.dart';
import 'package:nutrinutri/features/logging/presentation/add_entry_controller.dart';

class AddEntryFormManager {
  final WidgetRef ref;
  final VoidCallback onStateChanged;

  final descriptionController = TextEditingController();
  final nameController = TextEditingController();
  final caloriesController = TextEditingController();
  final proteinController = TextEditingController();
  final carbsController = TextEditingController();
  final fatsController = TextEditingController();

  AddEntryFormManager({required this.ref, required this.onStateChanged});

  void dispose() {
    descriptionController.dispose();
    nameController.dispose();
    caloriesController.dispose();
    proteinController.dispose();
    carbsController.dispose();
    fatsController.dispose();
  }

  void initializeWithEntry(FoodEntry entry) {
    ref.read(addEntryControllerProvider.notifier).initializeWithEntry(entry);
    nameController.text = entry.name;
    caloriesController.text = entry.calories.toString();
    proteinController.text = entry.protein.toString();
    carbsController.text = entry.carbs.toString();
    fatsController.text = entry.fats.toString();
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

  Future<void> saveEntry(FoodEntry? existingEntry) async {
    await ref
        .read(addEntryControllerProvider.notifier)
        .saveEntry(
          existingEntry: existingEntry,
          name: nameController.text,
          calories: caloriesController.text,
          protein: proteinController.text,
          carbs: carbsController.text,
          fats: fatsController.text,
        );
  }

  Future<void> deleteEntry(FoodEntry entry) async {
    await ref.read(addEntryControllerProvider.notifier).deleteEntry(entry);
  }
}
