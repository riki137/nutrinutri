import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:nutrinutri/core/domain/nutrition_metric.dart';
import 'package:nutrinutri/core/providers.dart';
import 'package:nutrinutri/core/utils/icon_utils.dart';
import 'package:nutrinutri/features/dashboard/presentation/dashboard_providers.dart';
import 'package:nutrinutri/features/diary/domain/diary_entry.dart';
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
      metrics: const {NutritionMetricType.calories: 0},
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
    unawaited(_analyzeAndFill(entry));
  }

  Future<void> cancelAnalysis(DiaryEntry entry) async {
    final aiService = await ref.read(aiServiceProvider.future);
    aiService.cancelRequest(entry.id);

    // Update status to cancelled
    final diaryService = ref.read(diaryServiceProvider);
    final cancelledEntry = DiaryEntry(
      id: entry.id,
      name: 'Analysis Cancelled',
      metrics: const {NutritionMetricType.calories: 0},
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
      metrics: const {NutritionMetricType.calories: 0},
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
    unawaited(_analyzeAndFill(processingEntry));
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
        metrics: const {NutritionMetricType.calories: 0},
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
    final metrics = entry.type == EntryType.exercise
        ? {
            NutritionMetricType.calories: _metricValue(
              result,
              NutritionMetricType.calories,
            ),
          }
        : _extractFoodMetrics(result);

    final updatedEntry = DiaryEntry(
      id: entry.id,
      name:
          result['food_name'] ??
          (entry.type == EntryType.exercise
              ? 'Unknown Exercise'
              : 'Unknown Food'),
      type: entry.type,
      metrics: metrics,
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

  Map<NutritionMetricType, double> _extractFoodMetrics(
    Map<String, dynamic> result,
  ) {
    final metrics = <NutritionMetricType, double>{};
    for (final type in NutritionMetricType.values) {
      final value = _metricValue(result, type);
      if (value > 0 || type == NutritionMetricType.calories) {
        metrics[type] = value;
      }
    }
    return metrics;
  }

  double _metricValue(Map<String, dynamic> result, NutritionMetricType type) {
    final metrics = result['metrics'];
    final source = metrics is Map<String, dynamic>
        ? metrics
        : metrics is Map
        ? Map<String, dynamic>.from(metrics)
        : result;

    final value = switch (type) {
      NutritionMetricType.calories => source['calories'] ?? source['kcal'],
      NutritionMetricType.carbs => source['carbs'] ?? source['carb'],
      NutritionMetricType.sugars => source['sugars'] ?? source['sugar'],
      NutritionMetricType.fats => source['fats'] ?? source['fat'],
      NutritionMetricType.saturatedFats =>
        source['saturated_fats'] ??
            source['saturatedFats'] ??
            source['saturated_fat'] ??
            source['sat_fat'],
      NutritionMetricType.protein => source['protein'],
      NutritionMetricType.fiber => source['fiber'] ?? source['fibre'],
      NutritionMetricType.sodium => source['sodium'],
      NutritionMetricType.caffeine => source['caffeine'],
      NutritionMetricType.water => source['water'],
    };
    return _toDouble(value);
  }

  String _validateIcon(dynamic icon) {
    if (icon is String && IconUtils.availableIcons.contains(icon)) {
      return icon;
    }
    return 'restaurant';
  }
}
