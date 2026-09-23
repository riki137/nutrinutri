import 'package:nutrinutri/core/domain/user_profile.dart';
import 'package:nutrinutri/core/providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'charts_providers.g.dart';

enum ChartPeriod { week, month }

/// Local-day bounds `[start, end]` (inclusive) of the period containing
/// [anchor]. Week starts on Monday.
({DateTime start, DateTime end}) chartPeriodBounds(
  ChartPeriod period,
  DateTime anchor,
) {
  final day = DateTime(anchor.year, anchor.month, anchor.day);
  switch (period) {
    case ChartPeriod.week:
      final start = day.subtract(Duration(days: day.weekday - 1));
      return (start: start, end: DateTime(start.year, start.month, start.day + 6));
    case ChartPeriod.month:
      final start = DateTime(day.year, day.month, 1);
      final end = DateTime(day.year, day.month + 1, 0);
      return (start: start, end: end);
  }
}

/// Shifts [anchor] by one whole period, forward or backward.
DateTime shiftChartPeriod(ChartPeriod period, DateTime anchor, int direction) {
  switch (period) {
    case ChartPeriod.week:
      return anchor.add(Duration(days: 7 * direction));
    case ChartPeriod.month:
      return DateTime(anchor.year, anchor.month + direction, anchor.day);
  }
}

class ChartsData {
  const ChartsData({required this.profile, required this.dailyTotals});

  final UserProfile profile;

  /// Ordered by day ascending, one entry per day in the period.
  final Map<DateTime, Map<String, double>> dailyTotals;
}

@riverpod
Future<ChartsData?> chartsData(Ref ref, DateTime start, DateTime end) async {
  ref.watch(syncUpdateProvider);
  final profileFuture = ref.watch(userProfileProvider.future);
  final diaryService = ref.watch(diaryServiceProvider);
  final totalsFuture = diaryService.getDailyTotals(start, end);

  final profile = await profileFuture;
  if (profile == null) return null;

  final dailyTotals = await totalsFuture;
  return ChartsData(profile: profile, dailyTotals: dailyTotals);
}
