import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutrinutri/core/providers.dart';
import 'package:nutrinutri/features/diary/data/diary_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'dashboard_providers.g.dart';

@riverpod
Stream<void> syncUpdate(Ref ref) {
  return ref.watch(syncServiceProvider).onSyncCompleted;
}

@riverpod
Future<Map<String, double>> dailySummary(Ref ref, DateTime date) async {
  ref.watch(syncUpdateProvider);
  final diaryService = ref.watch(diaryServiceProvider);
  return diaryService.getSummary(date);
}

@riverpod
Future<List<DiaryEntry>> dayEntries(Ref ref, DateTime date) async {
  ref.watch(syncUpdateProvider);
  final diaryService = ref.watch(diaryServiceProvider);
  return diaryService.getEntriesForDate(date);
}
