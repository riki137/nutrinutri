import 'dart:io';

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nutrinutri/core/utils/icon_utils.dart';
import 'package:nutrinutri/features/diary/domain/diary_entry.dart';
import 'package:nutrinutri/features/logging/presentation/widgets/food_image_picker.dart';

class AIEntryWizard extends StatefulWidget {
  const AIEntryWizard({
    super.key,
    required this.isExercise,
    required this.descriptionController,
    this.image,
    required this.canUseCamera,
    required this.onPickImage,
    required this.onPromptSearch,
    required this.onAddOptimistic,
    required this.onEnterManually,
    required this.onEntrySelected,
  });
  final bool isExercise;
  final TextEditingController descriptionController;
  final File? image;
  final bool canUseCamera;
  final Function(ImageSource) onPickImage;
  final Future<List<DiaryEntry>> Function(String) onPromptSearch;
  final VoidCallback onAddOptimistic;
  final VoidCallback onEnterManually;
  final Function(DiaryEntry) onEntrySelected;

  @override
  State<AIEntryWizard> createState() => _AIEntryWizardState();
}

class _AIEntryWizardState extends State<AIEntryWizard> {
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  String _suggestionText(DiaryEntry entry) {
    final prompt = entry.description?.trim();
    if (prompt != null && prompt.isNotEmpty) return prompt;
    return entry.name;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!widget.isExercise)
          FoodImagePicker(
            image: widget.image,
            canUseCamera: widget.canUseCamera,
            onPickImage: widget.onPickImage,
          ),
        if (!widget.isExercise) const Gap(16),
        LayoutBuilder(
          builder: (context, constraints) {
            return RawAutocomplete<DiaryEntry>(
              textEditingController: widget.descriptionController,
              focusNode: _focusNode,
              optionsViewOpenDirection: OptionsViewOpenDirection.up,
              optionsBuilder: (text) async {
                if (text.text.trim().length < 3) {
                  return const Iterable<DiaryEntry>.empty();
                }
                return widget.onPromptSearch(text.text);
              },
              displayStringForOption: _suggestionText,
              onSelected: (entry) {
                widget.onEntrySelected(entry);
              },
              fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
                return TextField(
                  controller: controller,
                  focusNode: focusNode,
                  decoration: InputDecoration(
                    labelText: widget.isExercise
                        ? 'Describe the exercise'
                        : 'AI prompt (optional if image provided)',
                    border: const OutlineInputBorder(),
                    hintText: widget.isExercise
                        ? 'e.g. 30 mins running'
                        : 'e.g. 2 eggs and toast',
                    suffixIcon: const Icon(Icons.history),
                  ),
                  maxLines: 3,
                );
              },
              optionsViewBuilder: (context, onSelected, options) {
                return Align(
                  alignment: Alignment.bottomLeft,
                  child: Material(
                    elevation: 4,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: constraints.maxWidth,
                        maxHeight: 280,
                      ),
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        reverse: true,
                        itemCount: options.length,
                        itemBuilder: (context, index) {
                          final option = options.elementAt(index);
                          final title = _suggestionText(option);
                          final showNameAsSubtitle =
                              option.description?.trim().isNotEmpty == true &&
                              option.name.trim().isNotEmpty &&
                              option.name.trim() != title;
                          final subtitleParts = <String>[];
                          if (showNameAsSubtitle) {
                            subtitleParts.add(option.name);
                          }
                          final calories =
                              option.calories == option.calories.roundToDouble()
                              ? option.calories.round().toString()
                              : option.calories.toStringAsFixed(1);
                          subtitleParts.add(
                            '$calories cal | P:${option.protein.toStringAsFixed(1)} C:${option.carbs.toStringAsFixed(1)} F:${option.fats.toStringAsFixed(1)}',
                          );

                          final iconName = option.icon?.trim();
                          return ListTile(
                            leading: iconName != null && iconName.isNotEmpty
                                ? Icon(IconUtils.getIcon(iconName))
                                : null,
                            title: Text(title, maxLines: 2),
                            subtitle: Text(
                              subtitleParts.join(' • '),
                              style: const TextStyle(fontSize: 12),
                              maxLines: 2,
                            ),
                            onTap: () => onSelected(option),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
        const Gap(24),
        FilledButton.icon(
          onPressed: widget.onAddOptimistic,
          icon: const Icon(Icons.auto_awesome),
          label: const Text('Add Entry with AI'),
          style: FilledButton.styleFrom(padding: const EdgeInsets.all(16)),
        ),
        const Gap(16),
        Row(
          children: [
            const Expanded(child: Divider()),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text('OR'),
            ),
            const Expanded(child: Divider()),
          ],
        ),
        const Gap(16),
        OutlinedButton(
          onPressed: widget.onEnterManually,
          style: OutlinedButton.styleFrom(padding: const EdgeInsets.all(16)),
          child: const Text('Enter Manually'),
        ),
      ],
    );
  }
}
