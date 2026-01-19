import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:gap/gap.dart';
import 'package:nutrinutri/core/providers.dart';
import 'package:nutrinutri/features/diary/data/diary_service.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
  }

  void _updateDate(int days) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: days));
    });
  }

  void _refresh() {
    setState(() {});
  }

  bool get _isToday {
    final now = DateTime.now();
    return _selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NutriNutri'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Date Switcher
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => _updateDate(-1),
                ),
                Text(
                  _isToday
                      ? "Today"
                      : "${_selectedDate.day}/${_selectedDate.month}",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: _isToday ? null : () => _updateDate(1),
                ),
              ],
            ),
            const Gap(16),
            // Summary Card
            _DailySummarySection(today: _selectedDate),
            const Gap(24),
            // Entries
            _EntriesList(today: _selectedDate, onRefresh: _refresh),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await context.push('/add-entry');
          _refresh();
        },
        label: const Text('Add Food'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}

class _DailySummarySection extends ConsumerWidget {
  final DateTime today;
  const _DailySummarySection({required this.today});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // This is a bit of a hack to get async data without dedicated provider,
    // but useful for MVP validation.Ideally I'd make @riverpod providers for these.

    return FutureBuilder(
      future: Future.wait([
        ref.read(settingsServiceProvider).getUserProfile(),
        ref.read(diaryServiceProvider).getSummary(today),
      ]),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());

        final profile = snapshot.data![0] as Map<String, dynamic>?;
        final summary = snapshot.data![1] as Map<String, double>;

        if (profile == null) return const Text('Profile not found');

        final goal = profile['goalCalories'] as int;
        final consumed = summary['calories']!;
        final remaining = goal - consumed;
        final progress = (consumed / goal).clamp(0.0, 1.0);

        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Text('Calories Today', style: TextStyle(fontSize: 16)),
                const Gap(16),
                SizedBox(
                  height: 150,
                  width: 150,
                  child: Stack(
                    children: [
                      PieChart(
                        PieChartData(
                          sections: [
                            PieChartSectionData(
                              value: progress,
                              color: Colors.green,
                              radius: 20,
                              showTitle: false,
                            ),
                            PieChartSectionData(
                              value: 1 - progress,
                              color: Colors.grey[200],
                              radius: 20,
                              showTitle: false,
                            ),
                          ],
                          startDegreeOffset: 270,
                        ),
                      ),
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              remaining.round().toString(),
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Text(
                              'Left',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Gap(24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _NutrientBar('Protein', summary['protein']!, Colors.blue),
                    _NutrientBar('Carbs', summary['carbs']!, Colors.orange),
                    _NutrientBar('Fats', summary['fats']!, Colors.red),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _NutrientBar extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  const _NutrientBar(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '${value.round()}g',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const Gap(4),
        Container(height: 4, width: 40, color: color),
      ],
    );
  }
}

class _EntriesList extends ConsumerWidget {
  final DateTime today;
  final VoidCallback onRefresh;

  const _EntriesList({required this.today, required this.onRefresh});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<List<FoodEntry>>(
      future: ref.read(diaryServiceProvider).getEntriesForDate(today),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();
        final entries = snapshot.data!;
        if (entries.isEmpty) return const Text('No entries yet.');

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Logs",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Gap(8),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: entries.length,
              itemBuilder: (context, index) {
                final entry = entries[index];
                return ListTile(
                  onTap: () async {
                    await context.push('/add-entry', extra: entry);
                    onRefresh();
                  },
                  leading: const CircleAvatar(
                    child: Icon(Icons.fastfood),
                  ), // Todo: Show image thumbnail
                  title: Text(entry.name),
                  subtitle: Text('${entry.calories} kcal'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      await ref.read(diaryServiceProvider).deleteEntry(entry);
                      onRefresh();
                    },
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}
