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
  const AddEntryPage({super.key});

  @override
  ConsumerState<AddEntryPage> createState() => _AddEntryPageState();
}

class _AddEntryPageState extends ConsumerState<AddEntryPage> {
  final _textController = TextEditingController();
  final _picker = ImagePicker();
  File? _image;
  bool _isAnalyzing = false;
  Map<String, dynamic>? _analysisResult;

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
    if (_textController.text.isEmpty && _image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide text or an image.')),
      );
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _analysisResult = null;
    });

    try {
      final aiService = await ref.read(aiServiceProvider.future);
      String? base64Image;

      if (_image != null) {
        final bytes = await _image!.readAsBytes();
        base64Image = base64Encode(bytes);
      }

      final result = await aiService.analyzeFood(
        textDescription: _textController.text.isNotEmpty
            ? _textController.text
            : null,
        base64Image: base64Image,
      );

      setState(() => _analysisResult = result);
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
    if (_analysisResult == null) return;

    try {
      final diaryService = ref.read(diaryServiceProvider);

      final entry = FoodEntry(
        id: const Uuid().v4(),
        name: _analysisResult!['food_name'] ?? 'Unknown Food',
        calories: (_analysisResult!['calories'] as num).toInt(),
        protein: (_analysisResult!['protein'] as num).toDouble(),
        carbs: (_analysisResult!['carbs'] as num).toDouble(),
        fats: (_analysisResult!['fats'] as num).toDouble(),
        timestamp: DateTime.now(),
        imagePath: _image?.path, // Store local path for now
      );

      await diaryService.addEntry(entry);

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
    return Scaffold(
      appBar: AppBar(title: const Text('Log Food')),
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
            const Gap(8),
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

            // Text Input
            TextField(
              controller: _textController,
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

            // Result Section
            if (_analysisResult != null) ...[
              const Gap(32),
              const Text(
                'Analysis Result',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Gap(16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        _analysisResult!['food_name'] ?? 'Unknown',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Gap(16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _MacroStat(
                            'Calories',
                            "${_analysisResult!['calories']}",
                          ),
                          _MacroStat(
                            'Protein',
                            "${_analysisResult!['protein']}g",
                          ),
                          _MacroStat('Carbs', "${_analysisResult!['carbs']}g"),
                          _MacroStat('Fat', "${_analysisResult!['fats']}g"),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const Gap(16),
              FilledButton(
                onPressed: _saveEntry,
                style: FilledButton.styleFrom(backgroundColor: Colors.green),
                child: const Text('Save to Diary'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MacroStat extends StatelessWidget {
  final String label;
  final String value;
  const _MacroStat(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}
