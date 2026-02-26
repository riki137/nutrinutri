import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:nutrinutri/core/domain/nutrition_metric.dart';
import 'package:nutrinutri/core/domain/user_profile.dart';
import 'package:nutrinutri/core/providers.dart';
import 'package:nutrinutri/core/services/ai_service.dart';
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
      icon: _defaultIconForType(type),
    );

    await diaryService.addEntry(entry);
    _invalidateDay(timestamp);
    unawaited(_analyzeAndFill(entry));
  }

  Future<void> cancelAnalysis(DiaryEntry entry) async {
    final aiService = await ref.read(aiServiceProvider.future);
    aiService.cancelRequest(entry.id);

    final cancelledEntry = _entryWithStatus(
      entry,
      name: 'Analysis Cancelled',
      status: FoodEntryStatus.cancelled,
      icon: 'warning',
    );
    await ref.read(diaryServiceProvider).updateEntry(cancelledEntry);
    _invalidateDay(entry.timestamp);
  }

  Future<void> retryAnalysis(DiaryEntry entry) async {
    final processingEntry = _entryWithStatus(
      entry,
      name: 'Analyzing...',
      status: FoodEntryStatus.processing,
      icon: _defaultIconForType(entry.type),
    );
    await ref.read(diaryServiceProvider).updateEntry(processingEntry);
    _invalidateDay(entry.timestamp);
    unawaited(_analyzeAndFill(processingEntry));
  }

  Future<void> _analyzeAndFill(DiaryEntry entry) async {
    final aiService = await ref.read(aiServiceProvider.future);
    final settingsService = ref.read(settingsServiceProvider);
    final fallbackModel = await settingsService.getFallbackModel();
    final userProfile = await settingsService.getUserProfile();
    final base64Image = await _imageToBase64(entry.imagePath);

    try {
      final result = await _analyzeEntry(
        aiService: aiService,
        entry: entry,
        userProfile: userProfile,
        base64Image: base64Image,
      );
      await _updateSuccess(entry, result);
      return;
    } catch (error) {
      if (_isCancellationError(error)) {
        return;
      }
    }

    if (fallbackModel != null && fallbackModel.isNotEmpty) {
      try {
        final result = await _analyzeEntry(
          aiService: aiService,
          entry: entry,
          userProfile: userProfile,
          base64Image: base64Image,
          modelOverride: fallbackModel,
        );
        await _updateSuccess(entry, result);
        return;
      } catch (error) {
        if (_isCancellationError(error)) {
          return;
        }
      }
    }

    await _updateFailed(entry);
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
      name: result['food_name'] ?? _fallbackName(entry.type),
      type: entry.type,
      metrics: metrics,
      timestamp: entry.timestamp,
      imagePath: entry.imagePath,
      description: entry.description,
      status: FoodEntryStatus.synced,
      icon: _validateIcon(result['icon'], entry.type),
      durationMinutes: entry.type == EntryType.exercise
          ? _toInt(result['durationMinutes'])
          : null,
    );

    await ref.read(diaryServiceProvider).updateEntry(updatedEntry);
    _invalidateDay(entry.timestamp);
  }

  Future<Map<String, dynamic>> _analyzeEntry({
    required AIService aiService,
    required DiaryEntry entry,
    required UserProfile? userProfile,
    required String? base64Image,
    String? modelOverride,
  }) {
    if (entry.type == EntryType.exercise) {
      return aiService.analyzeExercise(
        textDescription: entry.description ?? 'Unspecified exercise',
        userProfile: userProfile,
        requestId: entry.id,
        modelOverride: modelOverride,
      );
    }

    return aiService.analyzeFood(
      textDescription: entry.description,
      base64Image: base64Image,
      requestId: entry.id,
      modelOverride: modelOverride,
    );
  }

  Future<void> _updateFailed(DiaryEntry entry) async {
    final failedEntry = _entryWithStatus(
      entry,
      name: 'Analysis Failed',
      status: FoodEntryStatus.failed,
      icon: 'warning',
    );
    await ref.read(diaryServiceProvider).updateEntry(failedEntry);
    _invalidateDay(entry.timestamp);
  }

  DiaryEntry _entryWithStatus(
    DiaryEntry entry, {
    required String name,
    required FoodEntryStatus status,
    required String icon,
  }) {
    return DiaryEntry(
      id: entry.id,
      name: name,
      type: entry.type,
      metrics: const {NutritionMetricType.calories: 0},
      timestamp: entry.timestamp,
      imagePath: entry.imagePath,
      description: entry.description,
      status: status,
      icon: icon,
      durationMinutes: entry.durationMinutes,
    );
  }

  Future<String?> _imageToBase64(String? imagePath) async {
    if (imagePath == null || imagePath.isEmpty) return null;
    final file = File(imagePath);
    if (!await file.exists()) return null;
    final bytes = await file.readAsBytes();
    return base64Encode(bytes);
  }

  bool _isCancellationError(Object error) {
    return error.toString().contains('Request cancelled');
  }

  void _invalidateDay(DateTime dateTime) {
    final date = DateTime(dateTime.year, dateTime.month, dateTime.day);
    ref.invalidate(dayEntriesProvider(date));
    ref.invalidate(dailySummaryProvider(date));
  }

  String _fallbackName(EntryType type) {
    return type == EntryType.exercise ? 'Unknown Exercise' : 'Unknown Food';
  }

  String _defaultIconForType(EntryType type) {
    return type == EntryType.exercise ? 'directions_run' : 'restaurant';
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

  String _validateIcon(dynamic icon, EntryType type) {
    if (icon is String && IconUtils.availableIcons.contains(icon)) {
      return icon;
    }
    return _defaultIconForType(type);
  }
}
