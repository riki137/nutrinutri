import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:nutrinutri/core/domain/nutrition_metric.dart';
import 'package:nutrinutri/core/domain/user_profile.dart';
import 'package:nutrinutri/features/charts/presentation/charts_providers.dart';

class ChartsPage extends ConsumerStatefulWidget {
  const ChartsPage({super.key});

  @override
  ConsumerState<ChartsPage> createState() => _ChartsPageState();
}

class _ChartsPageState extends ConsumerState<ChartsPage> {
  ChartPeriod _period = ChartPeriod.week;
  late DateTime _anchor;
  NutritionMetricType _metric = NutritionMetricType.calories;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _anchor = DateTime(now.year, now.month, now.day);
  }

  ({DateTime start, DateTime end}) get _bounds =>
      chartPeriodBounds(_period, _anchor);

  bool get _containsToday {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final bounds = _bounds;
    return !today.isBefore(bounds.start) && !today.isAfter(bounds.end);
  }

  void _shiftPeriod(int direction) {
    setState(() => _anchor = shiftChartPeriod(_period, _anchor, direction));
  }

  String get _periodLabel {
    final bounds = _bounds;
    switch (_period) {
      case ChartPeriod.week:
        return '${DateFormat('d MMM').format(bounds.start)} – ${DateFormat('d MMM').format(bounds.end)}';
      case ChartPeriod.month:
        return DateFormat('MMMM y').format(bounds.start);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bounds = _bounds;
    final dataAsync = ref.watch(
      chartsDataProvider(bounds.start, bounds.end),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Charts')),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SegmentedButton<ChartPeriod>(
                    segments: const [
                      ButtonSegment(
                        value: ChartPeriod.week,
                        label: Text('Week'),
                      ),
                      ButtonSegment(
                        value: ChartPeriod.month,
                        label: Text('Month'),
                      ),
                    ],
                    selected: {_period},
                    onSelectionChanged: (selection) {
                      setState(() => _period = selection.first);
                    },
                  ),
                  const Gap(12),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: () => _shiftPeriod(-1),
                      ),
                      Expanded(
                        child: Text(
                          _periodLabel,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: _containsToday
                            ? null
                            : () => _shiftPeriod(1),
                      ),
                    ],
                  ),
                  const Gap(8),
                  DropdownButtonFormField<NutritionMetricType>(
                    initialValue: _metric,
                    decoration: const InputDecoration(
                      labelText: 'Metric',
                      border: OutlineInputBorder(),
                    ),
                    items: NutritionMetricType.values
                        .map(
                          (type) => DropdownMenuItem(
                            value: type,
                            child: Text('${type.label} (${type.unit})'),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) setState(() => _metric = value);
                    },
                  ),
                  const Gap(24),
                  dataAsync.when(
                    data: (data) {
                      if (data == null) {
                        return const Text('Profile not found');
                      }
                      return _ChartContent(
                        profile: data.profile,
                        dailyTotals: data.dailyTotals,
                        metric: _metric,
                      );
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (err, stack) => Text('Error: $err'),
                  ),
                  const Gap(24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ChartContent extends StatelessWidget {
  const _ChartContent({
    required this.profile,
    required this.dailyTotals,
    required this.metric,
  });

  final UserProfile profile;
  final Map<DateTime, Map<String, double>> dailyTotals;
  final NutritionMetricType metric;

  @override
  Widget build(BuildContext context) {
    final days = dailyTotals.keys.toList()..sort();
    final values = [
      for (final day in days) dailyTotals[day]?[metric.key] ?? 0.0,
    ];
    final goal = profile.goalFor(metric);
    final total = values.fold(0.0, (a, b) => a + b);
    final average = values.isEmpty ? 0.0 : total / values.length;
    final maxValue = [
      goal,
      ...values,
    ].fold(0.0, (a, b) => b > a ? b : a);
    final isSingleMonth = days.length > 7;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _StatTile(label: 'Average', value: average, unit: metric.unit),
            _StatTile(label: 'Total', value: total, unit: metric.unit),
          ],
        ),
        const Gap(24),
        SizedBox(
          height: 260,
          child: maxValue <= 0
              ? const Center(child: Text('No data for this period'))
              : BarChart(
                  BarChartData(
                    maxY: maxValue * 1.15,
                    barTouchData: const BarTouchData(enabled: true),
                    titlesData: FlTitlesData(
                      topTitles: const AxisTitles(),
                      rightTitles: const AxisTitles(),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 44,
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (index < 0 || index >= days.length) {
                              return const SizedBox.shrink();
                            }
                            final day = days[index];
                            final label = isSingleMonth
                                ? '${day.day}'
                                : DateFormat('EEEEE').format(day);
                            return Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                label,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    gridData: const FlGridData(drawVerticalLine: false),
                    extraLinesData: goal > 0
                        ? ExtraLinesData(
                            horizontalLines: [
                              HorizontalLine(
                                y: goal,
                                color: metric.color,
                                strokeWidth: 1.5,
                                dashArray: [6, 4],
                              ),
                            ],
                          )
                        : const ExtraLinesData(),
                    barGroups: [
                      for (var i = 0; i < values.length; i++)
                        BarChartGroupData(
                          x: i,
                          barRods: [
                            BarChartRodData(
                              toY: values[i],
                              color: metric.color,
                              width: isSingleMonth ? 8 : 20,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value, required this.unit});

  final String label;
  final double value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        Text(
          '${value.toStringAsFixed(value == value.roundToDouble() ? 0 : 1)} $unit',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }
}
