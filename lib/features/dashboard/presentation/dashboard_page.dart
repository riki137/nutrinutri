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
    final isDesktop = PlatformHelper.isDesktopOrWeb;

    return LayoutBuilder(
      builder: (context, constraints) {
        // On desktop, always use wide layout if window is large enough
        final isWide = constraints.maxWidth >= 700;

        return Scaffold(
          // On desktop, no app bar needed since we have the sidebar
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
                    onPressed: () async {
                      await context.push(
                        Uri(
                          path: '/add-entry',
                          queryParameters: {'type': 'exercise'},
                        ).toString(),
                      );
                      _refresh();
                    },
                    icon: const Icon(Icons.fitness_center),
                    label: const Text('Log Exercise'),
                  ),
                  const Gap(12),
                  FilledButton.icon(
                    onPressed: () async {
                      await context.push('/add-entry');
                      _refresh();
                    },
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
    // Show FAB on mobile phones, or on desktop/web when window is narrow
    // (narrow windows don't have the desktop header buttons)
    final shouldShowFAB = PlatformHelper.isMobile || !isWide;

    if (!shouldShowFAB) {
      return null;
    }

    return Column(
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
    );
  }
}
