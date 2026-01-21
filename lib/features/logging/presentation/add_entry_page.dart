import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nutrinutri/core/providers.dart';
import 'package:nutrinutri/features/diary/data/diary_service.dart';
import 'package:nutrinutri/features/diary/application/diary_controller.dart';
import 'package:nutrinutri/core/widgets/confirm_dialog.dart';
import 'package:uuid/uuid.dart';
import 'package:nutrinutri/core/utils/icon_utils.dart';
import 'package:nutrinutri/core/widgets/responsive_center.dart';

class AddEntryPage extends ConsumerStatefulWidget {
  final FoodEntry? existingEntry; // If null, we are adding a new entry
  const AddEntryPage({super.key, this.existingEntry});

  @override
  ConsumerState<AddEntryPage> createState() => _AddEntryPageState();
}

class _AddEntryPageState extends ConsumerState<AddEntryPage> {
  final _descriptionController = TextEditingController();
  final _picker = ImagePicker();

  // Form controllers
  final _nameController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _proteinController = TextEditingController();
  final _carbsController = TextEditingController();
  final _fatsController = TextEditingController();

  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;

  File? _image;
  bool _showForm = false; // Show form after analysis or if editing

  // Icon handling
  String _selectedIcon = 'restaurant';
  final List<String> _availableIcons = IconUtils.availableIcons;

  @override
  void initState() {
    super.initState();
    if (widget.existingEntry != null) {
      _initializeWithEntry(widget.existingEntry!);
    } else {
      final now = DateTime.now();
      _selectedDate = DateTime(now.year, now.month, now.day);
      _selectedTime = TimeOfDay.now();
    }
  }

  void _initializeWithEntry(FoodEntry entry) {
    _nameController.text = entry.name;
    _caloriesController.text = entry.calories.toString();
    _proteinController.text = entry.protein.toString();
    _carbsController.text = entry.carbs.toString();
    _fatsController.text = entry.fats.toString();

    if (entry.imagePath != null) {
      _image = File(entry.imagePath!);
    }
    _selectedIcon = entry.icon ?? 'restaurant';
    _selectedDate = entry.timestamp;
    _selectedTime = TimeOfDay.fromDateTime(entry.timestamp);
    _showForm = true;
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _nameController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatsController.dispose();
    super.dispose();
  }

  bool get _canUseCamera {
    if (kIsWeb) return false;
    return Platform.isAndroid || Platform.isIOS;
  }

  Future<void> _pickImage(ImageSource source) async {
    if (source == ImageSource.camera && !_canUseCamera) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Camera not supported on this device')),
      );
      return;
    }

    final pickedFile = await _picker.pickImage(
      source: source,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
    if (pickedFile != null) {
      setState(() => _image = File(pickedFile.path));
    }
  }

  Future<void> _addOptimistic() async {
    if (_descriptionController.text.isEmpty && _image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide text or an image.')),
      );
      return;
    }

    // Try to check for API key before proceeding to avoid immediate failure in background
    // (Optional, but good UX)
    final aiService = await ref.read(aiServiceProvider.future);
    if (aiService.apiKey.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Please set your API Key in Settings'),
            action: SnackBarAction(
              label: 'Settings',
              onPressed: () => context.push('/settings'),
            ),
            duration: const Duration(seconds: 5),
          ),
        );
      }
      return;
    }

    try {
      await ref
          .read(diaryControllerProvider.notifier)
          .addOptimisticEntry(
            date: _selectedDate,
            time: _selectedTime,
            description: _descriptionController.text.isNotEmpty
                ? _descriptionController.text
                : null,
            imagePath: _image?.path,
          );

      if (mounted) {
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to add entry: $e')));
      }
    }
  }

  Future<void> _pickDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null) {
      setState(() => _selectedDate = pickedDate);
    }
  }

  Future<void> _pickTime() async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (pickedTime != null) {
      setState(() => _selectedTime = pickedTime);
    }
  }

  Future<void> _saveEntry() async {
    if (!_showForm) return;

    try {
      final diaryService = ref.read(diaryServiceProvider);

      final name = _nameController.text.trim().isEmpty
          ? 'Unknown Food'
          : _nameController.text.trim();
      final calories = int.tryParse(_caloriesController.text) ?? 0;
      final protein = double.tryParse(_proteinController.text) ?? 0.0;
      final carbs = double.tryParse(_carbsController.text) ?? 0.0;
      final fats = double.tryParse(_fatsController.text) ?? 0.0;

      final timestamp = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      if (widget.existingEntry != null) {
        // Update existing
        final updatedEntry = FoodEntry(
          id: widget.existingEntry!.id,
          name: name,
          calories: calories,
          protein: protein,
          carbs: carbs,
          fats: fats,
          timestamp: timestamp, // Use selected timestamp
          imagePath: _image?.path,
          icon: _selectedIcon,
        );
        await diaryService.updateEntry(updatedEntry);
      } else {
        // Add new
        final entry = FoodEntry(
          id: const Uuid().v4(),
          name: name,
          calories: calories,
          protein: protein,
          carbs: carbs,
          fats: fats,
          timestamp: timestamp,
          imagePath: _image?.path,
          icon: _selectedIcon,
        );
        await diaryService.addEntry(entry);
      }

      if (mounted) {
        context.pop();
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to save: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingEntry != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Edit Entry' : 'Log Food')),
      body: SingleChildScrollView(
        child: ResponsiveCenter(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!isEditing) ...[
                // Image Section
                GestureDetector(
                  onTap: () => _pickImage(ImageSource.gallery),
                  child: Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                      image: _image != null
                          ? DecorationImage(
                              image: FileImage(_image!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: _image == null
                        ? const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_a_photo,
                                size: 40,
                                color: Colors.grey,
                              ),
                              Gap(8),
                              Text(
                                'Tap to add photo',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          )
                        : null,
                  ),
                ),
                const Gap(16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton.icon(
                      onPressed: _canUseCamera
                          ? () => _pickImage(ImageSource.camera)
                          : null,
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Camera'),
                    ),
                    TextButton.icon(
                      onPressed: () => _pickImage(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Gallery'),
                    ),
                  ],
                ),
                const Gap(16),

                // Text Input for AI
                TextField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Describe the food (optional if image provided)',
                    border: OutlineInputBorder(),
                    hintText: 'e.g. 2 eggs and toast',
                  ),
                  maxLines: 3,
                ),
                const Gap(24),

                // Analyze Button
                FilledButton.icon(
                  onPressed: _addOptimistic,
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text('Add Entry'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ],

              if (_showForm) ...[
                const Gap(32),
                const Text(
                  'Entry Details',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Gap(16),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Food Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const Gap(16),

                // Icon Selector
                DropdownButtonFormField<String>(
                  initialValue: _selectedIcon,
                  decoration: const InputDecoration(
                    labelText: 'Icon',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.emoji_food_beverage),
                  ),
                  items: _availableIcons.map((iconKey) {
                    return DropdownMenuItem(
                      value: iconKey,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(IconUtils.getIcon(iconKey)),
                          const Gap(8),
                          Text(
                            iconKey
                                .replaceAll('_', ' ')
                                .split(' ')
                                .map(
                                  (word) => word.isNotEmpty
                                      ? '${word[0].toUpperCase()}${word.substring(1)}'
                                      : '',
                                )
                                .join(' '),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedIcon = value);
                    }
                  },
                ),
                const Gap(16),

                const Gap(16),
                // Date & Time Picker
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickDate,
                        icon: const Icon(Icons.calendar_today),
                        label: Text(
                          DateFormat('yyyy-MM-dd').format(_selectedDate),
                        ),
                      ),
                    ),
                    const Gap(16),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickTime,
                        icon: const Icon(Icons.access_time),
                        label: Text(_selectedTime.format(context)),
                      ),
                    ),
                  ],
                ),
                const Gap(16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _caloriesController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Calories',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const Gap(16),
                    Expanded(
                      child: TextField(
                        controller: _proteinController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Protein (g)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const Gap(16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _carbsController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Carbs (g)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const Gap(16),
                    Expanded(
                      child: TextField(
                        controller: _fatsController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Fats (g)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const Gap(24),
                Row(
                  children: [
                    if (isEditing) ...[
                      Expanded(
                        child: OutlinedButton.icon(
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
                              try {
                                await ref
                                    .read(diaryServiceProvider)
                                    .deleteEntry(widget.existingEntry!);
                                if (mounted) {
                                  context.pop();
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Failed to delete: $e'),
                                    ),
                                  );
                                }
                              }
                            }
                          },
                          icon: const Icon(Icons.delete_outline),
                          label: const Text('Delete'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Theme.of(
                              context,
                            ).colorScheme.error,
                            side: BorderSide(
                              color: Theme.of(context).colorScheme.error,
                            ),
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
                        onPressed: _saveEntry,
                        icon: const Icon(Icons.check_circle_outline),
                        label: Text(
                          isEditing ? 'Update Entry' : 'Save to Diary',
                        ),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const Gap(32),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
