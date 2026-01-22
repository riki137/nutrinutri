import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:nutrinutri/core/widgets/confirm_dialog.dart';

class EntryActionButtons extends StatelessWidget {
  final bool isEditing;
  final VoidCallback onSave;
  final Future<void> Function()? onDeleteConfirmed;
  final bool isLoading;

  const EntryActionButtons({
    super.key,
    required this.isEditing,
    required this.onSave,
    this.onDeleteConfirmed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (isEditing) ...[
          Expanded(
            child: OutlinedButton.icon(
              onPressed: isLoading
                  ? null
                  : () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (context) => const ConfirmDialog(
                          title: 'Delete Entry',
                          content:
                              'Are you sure you want to delete this entry?',
                        ),
                      );

                      if (confirmed == true && onDeleteConfirmed != null) {
                        await onDeleteConfirmed!();
                      }
                    },
              icon: const Icon(Icons.delete_outline),
              label: const Text('Delete'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
                side: BorderSide(color: Theme.of(context).colorScheme.error),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const Gap(16),
        ],
        Expanded(
          child: FilledButton.icon(
            onPressed: isLoading ? null : onSave,
            icon: const Icon(Icons.check_circle_outline),
            label: Text(isEditing ? 'Update Entry' : 'Save to Diary'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
