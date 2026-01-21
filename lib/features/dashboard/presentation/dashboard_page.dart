import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';
import 'package:nutrinutri/features/dashboard/presentation/widgets/daily_summary_section.dart';
import 'package:nutrinutri/features/dashboard/presentation/widgets/entries_list.dart';
import 'package:nutrinutri/features/dashboard/presentation/dashboard_providers.dart';

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
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
  }

  void _updateDate(int days) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: days));
    });
  }

  void _refresh() {
    // Invalidate providers to force refresh
    ref.invalidate(dailySummaryProvider(_selectedDate));
    ref.invalidate(dayEntriesProvider(_selectedDate));
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
            DailySummarySection(today: _selectedDate),
            const Gap(24),
            // Entries
            EntriesList(today: _selectedDate, onRefresh: _refresh),
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
