import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:nutrinutri/core/utils/platform_helper.dart';
import 'package:nutrinutri/features/dashboard/presentation/dashboard_providers.dart';
import 'package:nutrinutri/features/dashboard/presentation/widgets/daily_summary_section.dart';
import 'package:nutrinutri/features/dashboard/presentation/widgets/date_switcher.dart';
import 'package:nutrinutri/features/dashboard/presentation/widgets/entries_list.dart';
import 'package:nutrinutri/features/dashboard/presentation/widgets/water_log_dialog.dart';
import 'package:nutrinutri/features/diary/application/diary_controller.dart';

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
    ref.invalidate(dailySummaryProvider(_selectedDate));
    ref.invalidate(dayEntriesProvider(_selectedDate));
  }

  String _addEntryRoute({required bool isExercise}) {
    if (!isExercise) return '/add-entry';

    return Uri(
      path: '/add-entry',
      queryParameters: {'type': 'exercise'},
    ).toString();
  }

  Future<void> _openAddEntry(
    BuildContext context, {
    required bool isExercise,
  }) async {
    await context.push(_addEntryRoute(isExercise: isExercise));
    _refresh();
  }

  Future<void> _logWater(BuildContext context) async {
    final amount = await showDialog<int>(
      context: context,
      builder: (context) => const WaterLogDialog(),
    );

    if (amount != null && amount > 0) {
      await ref.read(diaryControllerProvider.notifier).logWater(amount);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Added ${amount}ml water')));
      }
      _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = PlatformHelper.isDesktopOrWeb;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 700;

        return Scaffold(
          appBar: isDesktop
              ? null
              : AppBar(
                  title: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SvgPicture.asset(
                        'assets/images/nutrinutri.svg',
                        height: 32,
                      ),
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
          body: isWide
              ? _buildDesktopLayout(context, constraints)
              : _buildMobileLayout(),
          floatingActionButton: _buildFAB(context, isWide),
        );
      },
    );
  }

  Widget _buildDesktopLayout(BuildContext context, BoxConstraints constraints) {
    final theme = Theme.of(context);

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1400),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Desktop header
              Row(
                children: [
                  Text(
                    'Dashboard',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  // Quick actions
                  FilledButton.tonalIcon(
                    onPressed: () => _logWater(context),
                    icon: const Icon(Icons.water_drop),
                    label: const Text('Log Water'),
                  ),
                  const Gap(12),
                  FilledButton.tonalIcon(
                    onPressed: () => _openAddEntry(context, isExercise: true),
                    icon: const Icon(Icons.fitness_center),
                    label: const Text('Log Exercise'),
                  ),
                  const Gap(12),
                  FilledButton.icon(
                    onPressed: () => _openAddEntry(context, isExercise: false),
                    icon: const Icon(Icons.restaurant),
                    label: const Text('Log Food'),
                  ),
                ],
              ),
              const Gap(24),
              // Main content
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left Column: Date & Summary
                    SizedBox(
                      width: 380,
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            DateSwitcher(
                              selectedDate: _selectedDate,
                              onDateChange: _updateDate,
                            ),
                            const Gap(16),
                            DailySummarySection(today: _selectedDate),
                          ],
                        ),
                      ),
                    ),
                    const Gap(32),
                    // Right Column: Entries
                    Expanded(
                      child: Card(
                        elevation: 0,
                        color: theme.colorScheme.surfaceContainerLowest,
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(20),
                          child: EntriesList(
                            today: _selectedDate,
                            onRefresh: _refresh,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          DateSwitcher(selectedDate: _selectedDate, onDateChange: _updateDate),
          const Gap(8),
          DailySummarySection(today: _selectedDate),
          const Gap(24),
          EntriesList(today: _selectedDate, onRefresh: _refresh),
          const Gap(80),
        ],
      ),
    );
  }

  Widget? _buildFAB(BuildContext context, bool isWide) {
    final shouldShowFAB = PlatformHelper.isMobile || !isWide;

    if (!shouldShowFAB) {
      return null;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        FloatingActionButton.small(
          heroTag: 'log_water',
          onPressed: () => _logWater(context),
          tooltip: 'Log Water',
          child: const Icon(Icons.water_drop),
        ),
        const Gap(16),
        FloatingActionButton.small(
          heroTag: 'log_exercise',
          onPressed: () => _openAddEntry(context, isExercise: true),
          tooltip: 'Log Exercise',
          child: const Icon(Icons.fitness_center),
        ),
        const Gap(16),
        FloatingActionButton.extended(
          heroTag: 'log_food',
          onPressed: () => _openAddEntry(context, isExercise: false),
          label: const Text('Log Food'),
          icon: const Icon(Icons.restaurant),
        ),
      ],
    );
  }
}
