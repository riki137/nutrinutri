import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';

import 'package:nutrinutri/core/providers.dart';
import 'package:nutrinutri/core/utils/icon_utils.dart';
import 'package:nutrinutri/features/dashboard/presentation/dashboard_providers.dart';
import 'package:nutrinutri/features/diary/data/diary_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

part 'diary_controller.g.dart';

@Riverpod(keepAlive: true)
class DiaryController extends _$DiaryController {
  @override
  FutureOr<void> build() {
    // No state needed initially
  }

  Future<void> addOptimisticEntry({
    required DateTime date,
    required TimeOfDay time,
    String? description,
    String? imagePath,
    EntryType type = EntryType.food,
  }) async {
    final diaryService = ref.read(diaryServiceProvider);

    // Create optimistic entry
    final timestamp = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );

    final entry = DiaryEntry(
      id: const Uuid().v4(),
      name: 'Analyzing...',
      type: type,
      calories: 0,
      timestamp: timestamp,
      imagePath: imagePath,
      description: description,
      status: FoodEntryStatus.processing,
      icon: type == EntryType.exercise ? 'directions_run' : 'restaurant',
    );

    // 1. Add to local store immediately
    await diaryService.addEntry(entry);

    // 2. Refresh lists (so it shows up in UI)
    // We normalize the date to match DashboardPage's key
    final normalizedDate = DateTime(date.year, date.month, date.day);
    ref.invalidate(dayEntriesProvider(normalizedDate));
    ref.invalidate(dailySummaryProvider(normalizedDate));

    // 3. Start background processing (fire and forget from UI perspective)
    _analyzeAndFill(entry);
  }

  Future<void> cancelAnalysis(DiaryEntry entry) async {
    final aiService = await ref.read(aiServiceProvider.future);
    aiService.cancelRequest(entry.id);

    // Update status to cancelled
    final diaryService = ref.read(diaryServiceProvider);
    final cancelledEntry = DiaryEntry(
      id: entry.id,
      name: 'Analysis Cancelled',
      calories: 0,
      protein: 0,
      carbs: 0,
      fats: 0,
      timestamp: entry.timestamp,
      imagePath: entry.imagePath,
      description: entry.description,
      status: FoodEntryStatus.cancelled,
      icon: 'warning',
    );
    await diaryService.updateEntry(cancelledEntry);

    // Invalidate UI
    final normalizedDate = DateTime(
      entry.timestamp.year,
      entry.timestamp.month,
      entry.timestamp.day,
    );
    ref.invalidate(dayEntriesProvider(normalizedDate));
    ref.invalidate(dailySummaryProvider(normalizedDate));
  }

  Future<void> retryAnalysis(DiaryEntry entry) async {
    // Reset to processing state
    final diaryService = ref.read(diaryServiceProvider);
    final processingEntry = DiaryEntry(
      id: entry.id,
      name: 'Analyzing...',
      calories: 0,
      protein: 0,
      carbs: 0,
      fats: 0,
      timestamp: entry.timestamp,
      imagePath: entry.imagePath,
      description: entry.description,
      status: FoodEntryStatus.processing,
      icon: 'restaurant',
    );
    await diaryService.updateEntry(processingEntry);

    // Invalidate UI
    final normalizedDate = DateTime(
      entry.timestamp.year,
      entry.timestamp.month,
      entry.timestamp.day,
    );
    ref.invalidate(dayEntriesProvider(normalizedDate));
    ref.invalidate(dailySummaryProvider(normalizedDate));

    // Start analysis
    _analyzeAndFill(processingEntry);
  }

  Future<void> _analyzeAndFill(DiaryEntry entry) async {
    final aiService = await ref.read(aiServiceProvider.future);
    final settingsService = ref.read(settingsServiceProvider);

    // Get fallback model info
    final fallbackModel = await settingsService.getFallbackModel();
    // Get user profile for exercise calculation
    final userProfile = await settingsService.getUserProfile();

    String? base64Image;

    if (entry.imagePath != null) {
      final file = File(entry.imagePath!);
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        base64Image = base64Encode(bytes);
      }
    }

    try {
      final Map<String, dynamic> result;
      if (entry.type == EntryType.exercise) {
        result = await aiService.analyzeExercise(
          textDescription: entry.description ?? 'Unspecified exercise',
          userProfile: userProfile,
          requestId: entry.id,
        );
      } else {
        result = await aiService.analyzeFood(
          textDescription: entry.description,
          base64Image: base64Image,
          requestId: entry.id,
        );
      }

      await _updateSuccess(entry, result);
    } catch (e) {
      if (e.toString().contains('Request cancelled')) {
        return; // UI already updated in cancelAnalysis
      }

      // Try fallback if available
      if (fallbackModel != null && fallbackModel.isNotEmpty) {
        try {
          final Map<String, dynamic> result;
          if (entry.type == EntryType.exercise) {
            result = await aiService.analyzeExercise(
              textDescription: entry.description ?? 'Unspecified exercise',
              userProfile: userProfile,
              requestId: entry.id,
              modelOverride: fallbackModel,
            );
          } else {
            result = await aiService.analyzeFood(
              textDescription: entry.description,
              base64Image: base64Image,
              requestId: entry.id,
              modelOverride: fallbackModel,
            );
          }
          await _updateSuccess(entry, result);
          return;
        } catch (e2) {
          if (e2.toString().contains('Request cancelled')) {
            return;
          }
        }
      }

      // Update as failed
      final diaryService = ref.read(diaryServiceProvider);
      final failedEntry = DiaryEntry(
        id: entry.id,
        name: 'Analysis Failed',
        type: entry.type,
        calories: 0,
        protein: 0,
        carbs: 0,
        fats: 0,
        timestamp: entry.timestamp,
        imagePath: entry.imagePath,
        description: entry.description,
        status: FoodEntryStatus.failed,
        icon: 'warning',
        durationMinutes: entry.durationMinutes,
      );
      await diaryService.updateEntry(failedEntry);

      // Invalidate to show failed state
      final normalizedDate = DateTime(
        entry.timestamp.year,
        entry.timestamp.month,
        entry.timestamp.day,
      );
      ref.invalidate(dayEntriesProvider(normalizedDate));
      ref.invalidate(dailySummaryProvider(normalizedDate));
    }
  }

  Future<void> _updateSuccess(
    DiaryEntry entry,
    Map<String, dynamic> result,
  ) async {
    final updatedEntry = DiaryEntry(
      id: entry.id,
      name:
          result['food_name'] ??
          (entry.type == EntryType.exercise
              ? 'Unknown Exercise'
              : 'Unknown Food'),
      type: entry.type,
      calories: _toInt(result['calories']),
      protein: _toDouble(result['protein']),
      carbs: _toDouble(result['carbs']),
      fats: _toDouble(result['fats']),
      timestamp: entry.timestamp,
      imagePath: entry.imagePath,
      description: entry.description,
      status: FoodEntryStatus.synced,
      icon: _validateIcon(result['icon']),
      durationMinutes: entry.type == EntryType.exercise
          ? _toInt(result['durationMinutes'])
          : null,
    );

    // Update in store
    final diaryService = ref.read(diaryServiceProvider);
    await diaryService.updateEntry(updatedEntry);

    // Invalidate to show updated data
    final normalizedDate = DateTime(
      entry.timestamp.year,
      entry.timestamp.month,
      entry.timestamp.day,
    );
    ref.invalidate(dayEntriesProvider(normalizedDate));
    ref.invalidate(dailySummaryProvider(normalizedDate));
  }

  int _toInt(dynamic val) {
    if (val is int) return val;
    if (val is double) return val.round();
    if (val is String) return int.tryParse(val) ?? 0;
    return 0;
  }

  double _toDouble(dynamic val) {
    if (val is double) return val;
    if (val is int) return val.toDouble();
    if (val is String) return double.tryParse(val) ?? 0.0;
    return 0.0;
  }

  String _validateIcon(dynamic icon) {
    if (icon is String && IconUtils.availableIcons.contains(icon)) {
      return icon;
    }
    return 'restaurant';
  }
}
