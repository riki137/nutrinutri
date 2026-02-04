import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:nutrinutri/core/utils/icon_utils.dart';

class IconPickerButton extends StatelessWidget {
  const IconPickerButton({
    super.key,
    required this.selectedIcon,
    required this.onIconChanged,
    required this.availableIcons,
  });
  final String selectedIcon;
  final ValueChanged<String> onIconChanged;
  final List<String> availableIcons;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _showIconPicker(context),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 60,
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).colorScheme.outline),
          borderRadius: BorderRadius.circular(4),
        ),
        alignment: Alignment.center,
        child: Icon(
          IconUtils.getIcon(selectedIcon),
          size: 24,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }

  void _showIconPicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400, maxHeight: 500),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Select Icon',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Gap(16),
                Flexible(
                  child: GridView.builder(
                    shrinkWrap: true,
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 64,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                        ),
                    itemCount: availableIcons.length,
                    itemBuilder: (context, index) {
                      final iconKey = availableIcons[index];
                      final isSelected = iconKey == selectedIcon;
                      return InkWell(
                        onTap: () {
                          onIconChanged(iconKey);
                          Navigator.of(context).pop();
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Theme.of(context).colorScheme.primaryContainer
                                : null,
                            borderRadius: BorderRadius.circular(8),
                            border: isSelected
                                ? Border.all(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                    width: 2,
                                  )
                                : Border.all(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.outlineVariant,
                                  ),
                          ),
                          child: Icon(
                            IconUtils.getIcon(iconKey),
                            color: isSelected
                                ? Theme.of(
                                    context,
                                  ).colorScheme.onPrimaryContainer
                                : Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const Gap(8),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
