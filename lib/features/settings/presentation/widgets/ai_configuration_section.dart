import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:nutrinutri/features/settings/domain/ai_model_info.dart';
import 'package:url_launcher/url_launcher.dart';

class AIConfigurationSection extends StatelessWidget {
  const AIConfigurationSection({
    super.key,
    required this.apiKeyController,
    required this.customModelController,
    required this.selectedModel,
    this.fallbackModel,
    required this.availableModels,
    required this.onModelChanged,
    required this.onFallbackModelChanged,
  });
  final TextEditingController apiKeyController;
  final TextEditingController customModelController;
  final String selectedModel;
  final String? fallbackModel;
  final List<AIModelInfo> availableModels;
  final ValueChanged<String?> onModelChanged;
  final ValueChanged<String?> onFallbackModelChanged;

  Future<void> _openApiKeysPage(BuildContext context) async {
    final url = Uri.parse('https://openrouter.ai/settings/keys');
    final launched = await launchUrl(url, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not open browser. Visit openrouter.ai/settings/keys',
          ),
        ),
      );
    }
  }

  Widget _buildModelTile(BuildContext context, AIModelInfo model) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(
                model.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  model.price,
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const Gap(4),
          Text(
            model.description,
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  List<DropdownMenuItem<String>> _buildModelItems(
    BuildContext context, {
    required bool includeNone,
  }) {
    final items = <DropdownMenuItem<String>>[];

    if (includeNone) {
      items.add(
        const DropdownMenuItem<String>(value: null, child: Text('None')),
      );
    }

    items.addAll(
      availableModels.map(
        (model) => DropdownMenuItem<String>(
          value: model.id,
          child: _buildModelTile(context, model),
        ),
      ),
    );
    return items;
  }

  List<Widget> _buildSelectedItems({required bool includeNone}) {
    final items = <Widget>[];

    if (includeNone) {
      items.add(
        const Align(alignment: Alignment.centerLeft, child: Text('None')),
      );
    }

    items.addAll(
      availableModels.map(
        (model) => Align(
          alignment: Alignment.centerLeft,
          child: Text(
            model.name,
            style: const TextStyle(fontWeight: FontWeight.normal),
          ),
        ),
      ),
    );
    return items;
  }

  Widget _buildModelDropdown({
    required BuildContext context,
    required String label,
    required String? value,
    required ValueChanged<String?> onChanged,
    String? helperText,
    String? hintText,
    bool includeNone = false,
  }) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        helperText: helperText,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          itemHeight: null,
          hint: hintText != null ? Text(hintText) : null,
          items: _buildModelItems(context, includeNone: includeNone),
          selectedItemBuilder: (_) {
            return _buildSelectedItems(includeNone: includeNone);
          },
          onChanged: onChanged,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
          controller: apiKeyController,
          decoration: const InputDecoration(
            labelText: 'OpenRouter API Key',
            border: OutlineInputBorder(),
            hintText: 'sk-or-...',
          ),
          obscureText: true,
        ),
        if (apiKeyController.text.isEmpty) ...[
          const Gap(8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _openApiKeysPage(context),
              icon: const Icon(Icons.open_in_new),
              label: const Text('Get API Key'),
            ),
          ),
        ] else ...[
          const Gap(16),
          _buildModelDropdown(
            context: context,
            label: 'AI Model',
            value: selectedModel,
            onChanged: onModelChanged,
          ),
          if (selectedModel == 'custom') ...[
            const Gap(8),
            TextField(
              controller: customModelController,
              decoration: const InputDecoration(
                labelText: 'Custom Model ID (OpenRouter)',
                border: OutlineInputBorder(),
                hintText: 'e.g. meta-llama/llama-3-70b-instruct',
              ),
            ),
          ],
          const Gap(16),
          _buildModelDropdown(
            context: context,
            label: 'Fallback Model (Optional)',
            helperText: 'Used if the primary model fails',
            hintText: 'None',
            value: fallbackModel,
            includeNone: true,
            onChanged: onFallbackModelChanged,
          ),
        ],
      ],
    );
  }
}
