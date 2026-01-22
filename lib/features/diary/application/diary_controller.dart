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

    final entry = FoodEntry(
      id: const Uuid().v4(),
      name: 'Analyzing...',
      calories: 0,
      protein: 0,
      carbs: 0,
      fats: 0,
      timestamp: timestamp,
      imagePath: imagePath,
      description: description,
      status: FoodEntryStatus.processing,
      icon: 'restaurant', // Default icon
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

  Future<void> cancelAnalysis(FoodEntry entry) async {
    final aiService = await ref.read(aiServiceProvider.future);
    aiService.cancelRequest(entry.id);

    // Update status to cancelled
    final diaryService = ref.read(diaryServiceProvider);
    final cancelledEntry = FoodEntry(
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

  Future<void> retryAnalysis(FoodEntry entry) async {
    // Reset to processing state
    final diaryService = ref.read(diaryServiceProvider);
    final processingEntry = FoodEntry(
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

  Future<void> _analyzeAndFill(FoodEntry entry) async {
    final aiService = await ref.read(aiServiceProvider.future);
    final settingsService = ref.read(settingsServiceProvider);

    // Get fallback model info
    final fallbackModel = await settingsService.getFallbackModel();

    String? base64Image;

    if (entry.imagePath != null) {
      final file = File(entry.imagePath!);
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        base64Image = base64Encode(bytes);
      }
    }

    try {
      // Try primary model
      final result = await aiService.analyzeFood(
        textDescription: entry.description,
        base64Image: base64Image,
        requestId: entry.id,
      );
      await _updateSuccess(entry, result);
    } catch (e) {
      if (e.toString().contains('Request cancelled')) {
        print('Analysis cancelled for ${entry.id}');
        return; // UI already updated in cancelAnalysis
      }

      print('Primary analysis failed: $e');

      // Try fallback if available
      if (fallbackModel != null && fallbackModel.isNotEmpty) {
        print('Retrying with fallback model: $fallbackModel');
        try {
          final result = await aiService.analyzeFood(
            textDescription: entry.description,
            base64Image: base64Image,
            requestId: entry.id,
            modelOverride: fallbackModel,
          );
          await _updateSuccess(entry, result);
          return;
        } catch (e2) {
          if (e2.toString().contains('Request cancelled')) {
            print('Fallback analysis cancelled for ${entry.id}');
            return;
          }
          print('Fallback analysis failed: $e2');
        }
      }

      // Update as failed
      final diaryService = ref.read(diaryServiceProvider);
      final failedEntry = FoodEntry(
        id: entry.id,
        name: 'Analysis Failed',
        calories: 0,
        protein: 0,
        carbs: 0,
        fats: 0,
        timestamp: entry.timestamp,
        imagePath: entry.imagePath,
        description: entry.description,
        status: FoodEntryStatus.failed,
        icon: 'warning',
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
    FoodEntry entry,
    Map<String, dynamic> result,
  ) async {
    final updatedEntry = FoodEntry(
      id: entry.id,
      name: result['food_name'] ?? 'Unknown Food',
      calories: _toInt(result['calories']),
      protein: _toDouble(result['protein']),
      carbs: _toDouble(result['carbs']),
      fats: _toDouble(result['fats']),
      timestamp: entry.timestamp,
      imagePath: entry.imagePath,
      description: entry.description,
      status: FoodEntryStatus.synced,
      icon: _validateIcon(result['icon']),
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
