import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:nutrinutri/core/providers.dart';
import 'package:nutrinutri/core/utils/icon_utils.dart';
import 'package:nutrinutri/core/widgets/confirm_dialog.dart';
import 'package:nutrinutri/features/dashboard/presentation/dashboard_providers.dart';

class EntriesList extends ConsumerWidget {
  final DateTime today;
  final VoidCallback onRefresh;

  const EntriesList({super.key, required this.today, required this.onRefresh});

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

                return ListTile(
                  onTap: () async {
                    await context.push('/add-entry', extra: entry);
                    // Invalidating the provider to refresh data
                    ref.invalidate(dayEntriesProvider(today));
                    ref.invalidate(dailySummaryProvider(today));
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
                        ref.invalidate(dayEntriesProvider(today));
                        ref.invalidate(dailySummaryProvider(today));
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
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Text('Error loading entries: $err'),
    );
  }
}
