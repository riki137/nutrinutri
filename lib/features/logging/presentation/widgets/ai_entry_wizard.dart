import 'dart:io';

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nutrinutri/features/logging/presentation/widgets/food_image_picker.dart';

class AIEntryWizard extends StatelessWidget {

  const AIEntryWizard({
    super.key,
    required this.isExercise,
    required this.descriptionController,
    this.image,
    required this.canUseCamera,
    required this.onPickImage,
    required this.onAddOptimistic,
    required this.onEnterManually,
  });
  final bool isExercise;
  final TextEditingController descriptionController;
  final File? image;
  final bool canUseCamera;
  final Function(ImageSource) onPickImage;
  final VoidCallback onAddOptimistic;
  final VoidCallback onEnterManually;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!isExercise)
          FoodImagePicker(
            image: image,
            canUseCamera: canUseCamera,
            onPickImage: onPickImage,
          ),
        if (!isExercise) const Gap(16),
        TextField(
          controller: descriptionController,
          decoration: InputDecoration(
            labelText: isExercise
                ? 'Describe the exercise'
                : 'Describe the food (optional if image provided)',
            border: const OutlineInputBorder(),
            hintText: isExercise
                ? 'e.g. 30 mins running'
                : 'e.g. 2 eggs and toast',
          ),
          maxLines: 3,
        ),
        const Gap(24),
        FilledButton.icon(
          onPressed: onAddOptimistic,
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
          onPressed: onEnterManually,
          style: OutlinedButton.styleFrom(padding: const EdgeInsets.all(16)),
          child: const Text('Enter Manually'),
        ),
      ],
    );
  }
}
