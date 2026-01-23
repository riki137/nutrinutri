import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:nutrinutri/features/dashboard/presentation/dashboard_providers.dart';
import 'package:nutrinutri/features/dashboard/presentation/widgets/daily_summary_section.dart';
import 'package:nutrinutri/features/dashboard/presentation/widgets/date_switcher.dart';
import 'package:nutrinutri/features/dashboard/presentation/widgets/entries_list.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset('assets/images/nutrinutri.svg', height: 32),
            const Gap(8),
            const Text('NutriNutri'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 900;

          if (isWide) {
            return Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left Column: Date & Summary
                      SizedBox(
                        width: 400,
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              DateSwitcher(
                                selectedDate: _selectedDate,
                                onDateChange: _updateDate,
                              ),
                              const Gap(8),
                              DailySummarySection(today: _selectedDate),
                            ],
                          ),
                        ),
                      ),
                      const Gap(24),
                      // Right Column: Entries
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              const Gap(16),
                              EntriesList(
                                today: _selectedDate,
                                onRefresh: _refresh,
                              ),
                              const Gap(80),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          // Mobile Layout
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                // Date Switcher
                // Date Switcher
                DateSwitcher(
                  selectedDate: _selectedDate,
                  onDateChange: _updateDate,
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
          );
        },
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.small(
            heroTag: 'log_exercise',
            onPressed: () async {
              await context.push(
                Uri(
                  path: '/add-entry',
                  queryParameters: {'type': 'exercise'},
                ).toString(),
              );
              _refresh();
            },
            tooltip: 'Log Exercise',
            child: const Icon(Icons.fitness_center),
          ),
          const Gap(16),
          FloatingActionButton.extended(
            heroTag: 'log_food',
            onPressed: () async {
              await context.push('/add-entry');
              _refresh();
            },
            label: const Text('Log Food'),
            icon: const Icon(Icons.restaurant),
          ),
        ],
      ),
    );
  }
}
