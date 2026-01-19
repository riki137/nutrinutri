import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:gap/gap.dart';
import 'package:nutrinutri/core/providers.dart';
import 'package:nutrinutri/features/diary/data/diary_service.dart';
import 'package:nutrinutri/core/widgets/confirm_dialog.dart';

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
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            // Date Switcher
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () => _updateDate(-1),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          _isToday
                              ? "Today"
                              : DateFormat('EEEE').format(_selectedDate),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          DateFormat('d MMM y').format(_selectedDate),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: _isToday ? null : () => _updateDate(1),
                  ),
                ],
              ),
            ),
            const Gap(8),
            // Summary Card
            _DailySummarySection(today: _selectedDate),
            const Gap(24),
            // Entries
            _EntriesList(today: _selectedDate, onRefresh: _refresh),
            const Gap(80), // Bottom padding for FAB
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

        final Map<String, dynamic>? profile = snapshot.data![0];
        final Map<String, double> summary =
            snapshot.data![1] as Map<String, double>;

        if (profile == null) return const Text('Profile not found');

        final goal = profile['goalCalories'] as int;
        final consumed = summary['calories']!;
        final remaining = goal - consumed;
        final progress = (consumed / goal).clamp(0.0, 1.0);

        // Macro Goals Calculation (Default split: 30% P, 40% C, 30% F)
        final proteinGoal = (goal * 0.30) / 4;
        final carbsGoal = (goal * 0.40) / 4;
        final fatsGoal = (goal * 0.30) / 9;

        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Calories Today',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Goal: $goal',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
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
                    _MacroRing(
                      label: 'Protein',
                      value: summary['protein']!,
                      goal: proteinGoal,
                      color: Colors.blue,
                    ),
                    _MacroRing(
                      label: 'Carbs',
                      value: summary['carbs']!,
                      goal: carbsGoal,
                      color: Colors.orange,
                    ),
                    _MacroRing(
                      label: 'Fats',
                      value: summary['fats']!,
                      goal: fatsGoal,
                      color: Colors.red,
                    ),
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

class _MacroRing extends StatelessWidget {
  final String label;
  final double value;
  final double goal;
  final Color color;

  const _MacroRing({
    required this.label,
    required this.value,
    required this.goal,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (value / goal).clamp(0.0, 1.0);
    final percentage = (progress * 100).round();

    return Column(
      children: [
        SizedBox(
          height: 60,
          width: 60,
          child: Stack(
            children: [
              PieChart(
                PieChartData(
                  sections: [
                    PieChartSectionData(
                      value: progress,
                      color: color,
                      radius: 8,
                      showTitle: false,
                    ),
                    PieChartSectionData(
                      value: 1 - progress,
                      color: color.withValues(alpha: 0.2),
                      radius: 8,
                      showTitle: false,
                    ),
                  ],
                  startDegreeOffset: 270,
                  sectionsSpace: 0,
                  centerSpaceRadius: 22,
                ),
              ),
              Center(
                child: Text(
                  '${percentage}%',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
        const Gap(8),
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
        Text(
          '${value.round()}/${goal.round()}g',
          style: TextStyle(fontSize: 10, color: Colors.grey[600]),
        ),
      ],
    );
  }
}

class _EntriesList extends ConsumerWidget {
  final DateTime today;
  final VoidCallback onRefresh;

  const _EntriesList({required this.today, required this.onRefresh});

  static const Map<String, IconData> _iconMap = {
    'bakery_dining': Icons.bakery_dining,
    'brunch_dining': Icons.brunch_dining,
    'bento': Icons.bento,
    'cake': Icons.cake,
    'coffee': Icons.coffee,
    'cookie': Icons.cookie,
    'egg_alt': Icons.egg_alt,
    'fastfood': Icons.fastfood,
    'flatware': Icons.flatware,
    'liquor': Icons.liquor,
    'microwave': Icons.microwave,
    'nightlife': Icons.nightlife,
    'outdoor_grill': Icons.outdoor_grill,
    'ramen_dining': Icons.ramen_dining,
    'restaurant': Icons.restaurant,
    'rice_bowl': Icons.rice_bowl,
    'sports_bar': Icons.sports_bar,
    'tapas': Icons.tapas,
  };

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
                final iconData = _iconMap[entry.icon] ?? Icons.fastfood;

                return ListTile(
                  onTap: () async {
                    await context.push('/add-entry', extra: entry);
                    onRefresh();
                  },
                  leading: CircleAvatar(child: Icon(iconData)),
                  title: Text(
                    entry.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    '${DateFormat('HH:mm').format(entry.timestamp)} • ${entry.calories} kcal',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (context) => const ConfirmDialog(
                          title: 'Delete Entry',
                          content:
                              'Are you sure you want to delete this entry?',
                        ),
                      );

                      if (confirmed == true) {
                        await ref.read(diaryServiceProvider).deleteEntry(entry);
                        onRefresh();
                      }
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
