import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:nutrinutri/core/providers.dart';
import 'package:nutrinutri/core/utils/icon_utils.dart';
import 'package:nutrinutri/core/widgets/confirm_dialog.dart';
import 'package:nutrinutri/features/dashboard/presentation/dashboard_providers.dart';
import 'package:nutrinutri/features/diary/application/diary_controller.dart';
import 'package:nutrinutri/features/diary/domain/diary_entry.dart';

class EntriesList extends ConsumerWidget {
  const EntriesList({super.key, required this.today, required this.onRefresh});
  final DateTime today;
  final VoidCallback onRefresh;

  bool _isErrorStatus(FoodEntryStatus status) {
    return status == FoodEntryStatus.failed ||
        status == FoodEntryStatus.cancelled;
  }

  String _subtitleFor(DiaryEntry entry, String caloriesText) {
    return switch (entry.status) {
      FoodEntryStatus.processing => 'Analyzing with AI...',
      FoodEntryStatus.failed => 'AI Analysis Failed. Tap to edit/retry.',
      FoodEntryStatus.cancelled => 'Analysis Cancelled. Tap to edit/retry.',
      FoodEntryStatus.synced =>
        '${DateFormat('HH:mm').format(entry.timestamp)} • $caloriesText kcal',
    };
  }

  void _refreshDay(WidgetRef ref) {
    ref.invalidate(dayEntriesProvider(today));
    ref.invalidate(dailySummaryProvider(today));
    onRefresh();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(dayEntriesProvider(today));

    return entriesAsync.when(
      data: (entries) {
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
                final iconData = IconUtils.getIcon(entry.icon);
                final caloriesText =
                    entry.calories == entry.calories.roundToDouble()
                    ? entry.calories.round().toString()
                    : entry.calories.toStringAsFixed(1);
                final isProcessing = entry.status == FoodEntryStatus.processing;
                final isError = _isErrorStatus(entry.status);

                return ListTile(
                  onTap: () async {
                    if (isProcessing) return;

                    await context.push('/add-entry', extra: entry);
                    _refreshDay(ref);
                  },
                  leading: CircleAvatar(
                    backgroundColor: isError
                        ? Theme.of(context).colorScheme.errorContainer
                        : null,
                    child: isProcessing
                        ? const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : isError
                        ? Icon(
                            Icons.priority_high,
                            color: Theme.of(context).colorScheme.error,
                          )
                        : Icon(iconData),
                  ),
                  title: Text(
                    entry.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isError
                          ? Theme.of(context).colorScheme.error
                          : null,
                    ),
                  ),
                  subtitle: Text(
                    _subtitleFor(entry, caloriesText),
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isProcessing)
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            ref
                                .read(diaryControllerProvider.notifier)
                                .cancelAnalysis(entry);
                          },
                        ),
                      if (isError)
                        IconButton(
                          icon: const Icon(Icons.refresh),
                          onPressed: () {
                            ref
                                .read(diaryControllerProvider.notifier)
                                .retryAnalysis(entry);
                          },
                        ),
                      if (!isProcessing)
                        IconButton(
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
                              await ref
                                  .read(diaryServiceProvider)
                                  .deleteEntry(entry);
                              _refreshDay(ref);
                            }
                          },
                        ),
                    ],
                  ),
                );
              },
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Text('Error loading entries: $err'),
    );
  }
}
