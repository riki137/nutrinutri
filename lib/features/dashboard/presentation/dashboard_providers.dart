import 'package:nutrinutri/core/providers.dart';
import 'package:nutrinutri/features/diary/data/diary_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

part 'dashboard_providers.g.dart';

@riverpod
Future<Map<String, double>> dailySummary(Ref ref, DateTime date) async {
  final diaryService = ref.watch(diaryServiceProvider);
  return diaryService.getSummary(date);
}

@riverpod
Future<List<FoodEntry>> dayEntries(Ref ref, DateTime date) async {
  final diaryService = ref.watch(diaryServiceProvider);
  return diaryService.getEntriesForDate(date);
}
