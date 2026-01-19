import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nutrinutri/core/providers.dart';
import 'package:nutrinutri/features/diary/data/diary_service.dart';
import 'package:uuid/uuid.dart';

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

  File? _image;
  bool _isAnalyzing = false;
  bool _showForm = false; // Show form after analysis or if editing

  @override
  void initState() {
    super.initState();
    if (widget.existingEntry != null) {
      _initializeWithEntry(widget.existingEntry!);
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

  Future<void> _pickImage(ImageSource source) async {
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

  Future<void> _analyze() async {
    if (_descriptionController.text.isEmpty && _image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide text or an image.')),
      );
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _showForm = false;
    });

    try {
      final aiService = await ref.read(aiServiceProvider.future);
      String? base64Image;

      if (_image != null) {
        final bytes = await _image!.readAsBytes();
        base64Image = base64Encode(bytes);
      }

      final result = await aiService.analyzeFood(
        textDescription: _descriptionController.text.isNotEmpty
            ? _descriptionController.text
            : null,
        base64Image: base64Image,
      );

      // Populate form with AI results
      setState(() {
        _nameController.text = result['food_name'] ?? 'Unknown Food';
        _caloriesController.text = (result['calories'] as num).toString();
        _proteinController.text = (result['protein'] as num).toString();
        _carbsController.text = (result['carbs'] as num).toString();
        _fatsController.text = (result['fats'] as num).toString();
        _showForm = true;
      });
    } catch (e) {
      if (mounted) {
        final message = e.toString();
        if (message.contains('API Key is missing')) {
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
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Analysis failed: $e')));
        }
      }
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
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

      if (widget.existingEntry != null) {
        // Update existing
        final updatedEntry = FoodEntry(
          id: widget.existingEntry!.id,
          name: name,
          calories: calories,
          protein: protein,
          carbs: carbs,
          fats: fats,
          timestamp: widget.existingEntry!.timestamp, // Keep original timestamp
          imagePath: _image?.path,
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
          timestamp: DateTime.now(),
          imagePath: _image?.path,
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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
                          Icon(Icons.add_a_photo, size: 40, color: Colors.grey),
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
                  onPressed: () => _pickImage(ImageSource.camera),
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

            // Text Input for AI (only show if not just editing pure data, or let it overwrite?)
            // Let's allow re-analyzing even in edit mode if they want to replace data
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
              onPressed: _isAnalyzing ? null : _analyze,
              icon: _isAnalyzing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_awesome),
              label: Text(_isAnalyzing ? 'Analyzing...' : 'Analyze with AI'),
              style: FilledButton.styleFrom(padding: const EdgeInsets.all(16)),
            ),

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
              FilledButton(
                onPressed: _saveEntry,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.green,
                  minimumSize: const Size.fromHeight(50),
                ),
                child: Text(isEditing ? 'Update Entry' : 'Save to Diary'),
              ),
              const Gap(32),
            ],
          ],
        ),
      ),
    );
  }
}
