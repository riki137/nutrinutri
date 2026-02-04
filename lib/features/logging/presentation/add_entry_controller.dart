import 'dart:io';
import 'package:flutter/material.dart';

import 'package:image_picker/image_picker.dart';
import 'package:nutrinutri/core/providers.dart';
import 'package:nutrinutri/core/utils/met_values.dart';
import 'package:nutrinutri/features/diary/application/diary_controller.dart';
import 'package:nutrinutri/features/diary/domain/diary_entry.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

part 'add_entry_controller.g.dart';

class AddEntryState {
  AddEntryState({
    this.image,
    this.showForm = false,
    required this.selectedDate,
    required this.selectedTime,
    this.selectedIcon = 'restaurant',
    this.type = EntryType.food,
  });
  final File? image;
  final bool showForm;
  final DateTime selectedDate;
  final TimeOfDay selectedTime;
  final String selectedIcon;
  final EntryType type;

  AddEntryState copyWith({
    File? image,
    bool? showForm,
    DateTime? selectedDate,
    TimeOfDay? selectedTime,
    String? selectedIcon,
    EntryType? type,
  }) {
    return AddEntryState(
      image: image ?? this.image,
      showForm: showForm ?? this.showForm,
      selectedDate: selectedDate ?? this.selectedDate,
      selectedTime: selectedTime ?? this.selectedTime,
      selectedIcon: selectedIcon ?? this.selectedIcon,
      type: type ?? this.type,
    );
  }
}

@riverpod
class AddEntryController extends _$AddEntryController {
  final _picker = ImagePicker();

  @override
  AddEntryState build() {
    final now = DateTime.now();
    return AddEntryState(
      selectedDate: DateTime(now.year, now.month, now.day),
      selectedTime: TimeOfDay.now(),
      type: EntryType.food,
    );
  }

  void initializeWithType(EntryType type) {
    state = state.copyWith(
      type: type,
      selectedIcon: type == EntryType.exercise
          ? 'directions_run'
          : 'restaurant',
    );
  }

  void initializeWithEntry(DiaryEntry entry) {
    state = state.copyWith(
      image: entry.imagePath != null ? File(entry.imagePath!) : null,
      showForm: true,
      selectedDate: entry.timestamp,
      selectedTime: TimeOfDay.fromDateTime(entry.timestamp),
      selectedIcon:
          entry.icon ??
          (entry.type == EntryType.exercise ? 'directions_run' : 'restaurant'),
      type: entry.type,
    );
  }

  Future<File?> pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(
      source: source,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
    if (pickedFile != null) {
      final image = File(pickedFile.path);
      state = state.copyWith(image: image);
      return image;
    }
    return null;
  }

  void updateDate(DateTime date) {
    state = state.copyWith(selectedDate: date);
  }

  void updateTime(TimeOfDay time) {
    state = state.copyWith(selectedTime: time);
  }

  void updateIcon(String icon) {
    state = state.copyWith(selectedIcon: icon);
  }

  void toggleForm(bool show) {
    state = state.copyWith(showForm: show);
  }

  Future<void> addOptimistic({required String? description}) async {
    final aiService = await ref.read(aiServiceProvider.future);
    if (aiService.apiKey.isEmpty) {
      throw Exception('Please set your API Key in Settings');
    }

    await ref
        .read(diaryControllerProvider.notifier)
        .addOptimisticEntry(
          date: state.selectedDate,
          time: state.selectedTime,
          description: description?.isNotEmpty == true ? description : null,
          imagePath: state.image?.path,
          type: state.type,
        );
  }

  Future<void> saveEntry({
    required DiaryEntry? existingEntry,
    required String name,
    required String calories,
    required String protein,
    required String carbs,
    required String fats,
    String? durationMinutes,
  }) async {
    final diaryService = ref.read(diaryServiceProvider);

    final finalName = name.trim().isEmpty
        ? (state.type == EntryType.exercise
              ? 'Unknown Exercise'
              : 'Unknown Food')
        : name.trim();
    final finalCalories = int.tryParse(calories) ?? 0;
    final finalProtein = double.tryParse(protein) ?? 0.0;
    final finalCarbs = double.tryParse(carbs) ?? 0.0;
    final finalFats = double.tryParse(fats) ?? 0.0;
    final finalDuration = durationMinutes != null
        ? int.tryParse(durationMinutes)
        : null;

    final timestamp = DateTime(
      state.selectedDate.year,
      state.selectedDate.month,
      state.selectedDate.day,
      state.selectedTime.hour,
      state.selectedTime.minute,
    );

    if (existingEntry != null) {
      final updatedEntry = DiaryEntry(
        id: existingEntry.id,
        name: finalName,
        type: state.type,
        calories: finalCalories,
        protein: finalProtein,
        carbs: finalCarbs,
        fats: finalFats,
        timestamp: timestamp,
        imagePath: state.image?.path,
        icon: state.selectedIcon,
        durationMinutes: finalDuration,
      );
      await diaryService.updateEntry(updatedEntry);
    } else {
      final entry = DiaryEntry(
        id: const Uuid().v4(),
        name: finalName,
        type: state.type,
        calories: finalCalories,
        protein: finalProtein,
        carbs: finalCarbs,
        fats: finalFats,
        timestamp: timestamp,
        imagePath: state.image?.path,
        icon: state.selectedIcon,
        durationMinutes: finalDuration,
      );
      await diaryService.addEntry(entry);
    }
  }

  Future<void> deleteEntry(DiaryEntry entry) async {
    await ref.read(diaryServiceProvider).deleteEntry(entry);
  }

  Future<int?> calculateExerciseCalories(
    String name,
    int durationMinutes,
  ) async {
    if (durationMinutes <= 0) return null;

    final settingsService = ref.read(settingsServiceProvider);
    final profile = await settingsService.getUserProfile();
    final weight = profile?.weightKg ?? 70.0;

    final met = MetValues.getMet(name);
    if (met == 0) return null;

    // Calories = MET * Weight(kg) * Duration(hr)
    final calories = (met * weight * (durationMinutes / 60)).round();
    return calories;
  }

  Future<List<DiaryEntry>> searchFood(String query) async {
    return ref.read(diaryServiceProvider).searchFoodSuggestions(query);
  }
}
