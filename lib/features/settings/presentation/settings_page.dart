import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutrinutri/core/providers.dart';
import 'package:gap/gap.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  final _apiKeyController = TextEditingController();
  final _customModelController = TextEditingController();
  String _selectedModel = 'openai/gpt-4o-mini';
  bool _isLoading = false;

  final Map<String, String> _models = {
    'openai/gpt-4o-mini': 'GPT-4o Mini',
    'openai/gpt-4o': 'GPT-4o',
    'google/gemini-2.0-flash-exp:free': 'Gemini 2.0 Flash (Free)',
    'google/gemini-flash-1.5': 'Gemini 1.5 Flash',
    'anthropic/claude-3.5-sonnet': 'Claude 3.5 Sonnet',
    'custom': 'Custom...',
  };

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final key = await ref.read(apiKeyProvider.future);
    if (key != null) {
      _apiKeyController.text = key;
    }
    final model = await ref.read(settingsServiceProvider).getAIModel();
    if (_models.containsKey(model)) {
      _selectedModel = model;
    } else {
      _selectedModel = 'custom';
      _customModelController.text = model;
    }
    setState(() {});
  }

  Future<void> _save() async {
    setState(() => _isLoading = true);
    try {
      final settings = ref.read(settingsServiceProvider);
      await settings.saveApiKey(_apiKeyController.text.trim());

      final modelToSave = _selectedModel == 'custom'
          ? _customModelController.text.trim()
          : _selectedModel;

      if (modelToSave.isNotEmpty) {
        await settings.saveAIModel(modelToSave);
      }

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Settings saved')));
        ref.invalidate(apiKeyProvider); // Refresh provider
        ref.invalidate(aiServiceProvider); // Refresh AI service with new model
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'AI Configuration',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const Gap(16),
          const Text(
            'This app uses OpenRouter to analyze your food. You need to provide your own API Key.',
            style: TextStyle(color: Colors.grey),
          ),
          const Gap(8),
          TextField(
            controller: _apiKeyController,
            decoration: const InputDecoration(
              labelText: 'OpenRouter API Key',
              border: OutlineInputBorder(),
              hintText: 'sk-or-...',
            ),
            obscureText: true,
          ),
          const Gap(16),
          DropdownButtonFormField<String>(
            value: _selectedModel,
            decoration: const InputDecoration(
              labelText: 'AI Model',
              border: OutlineInputBorder(),
            ),
            items: _models.entries.map((e) {
              return DropdownMenuItem(value: e.key, child: Text(e.value));
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedModel = value);
              }
            },
          ),
          if (_selectedModel == 'custom') ...[
            const Gap(8),
            TextField(
              controller: _customModelController,
              decoration: const InputDecoration(
                labelText: 'Custom Model ID (OpenRouter)',
                border: OutlineInputBorder(),
                hintText: 'e.g. meta-llama/llama-3-70b-instruct',
              ),
            ),
          ],
          const Gap(24),
          FilledButton.icon(
            onPressed: _isLoading ? null : _save,
            icon: const Icon(Icons.save),
            label: const Text('Save API Key'),
          ),
        ],
      ),
    );
  }
}
