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
              onPressed: () async {
                final url = Uri.parse('https://openrouter.ai/settings/keys');
                final launched = await launchUrl(
                  url,
                  mode: LaunchMode.externalApplication,
                );
                if (!launched && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Could not open browser. Visit openrouter.ai/settings/keys',
                      ),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.open_in_new),
              label: const Text('Get API Key'),
            ),
          ),
        ] else ...[
          const Gap(16),
          InputDecorator(
            decoration: const InputDecoration(
              labelText: 'AI Model',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedModel,
                isExpanded: true,
                itemHeight: null,
                items: availableModels.map((model) {
                  return DropdownMenuItem(
                    value: model.id,
                    child: Padding(
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
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  model.price,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onPrimaryContainer,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Gap(4),
                          Text(
                            model.description,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
                selectedItemBuilder: (context) {
                  return availableModels.map((model) {
                    return Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        model.name,
                        style: const TextStyle(fontWeight: FontWeight.normal),
                      ),
                    );
                  }).toList();
                },
                onChanged: onModelChanged,
              ),
            ),
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
          InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Fallback Model (Optional)',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              helperText: 'Used if the primary model fails',
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: fallbackModel,
                isExpanded: true,
                itemHeight: null,
                hint: const Text('None'),
                items: [
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('None'),
                  ),
                  ...availableModels.map((model) {
                    return DropdownMenuItem(
                      value: model.id,
                      child: Padding(
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
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primaryContainer,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    model.price,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onPrimaryContainer,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const Gap(4),
                            Text(
                              model.description,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
                selectedItemBuilder: (context) {
                  return [
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('None'),
                    ),
                    ...availableModels.map((model) {
                      return Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          model.name,
                          style: const TextStyle(fontWeight: FontWeight.normal),
                        ),
                      );
                    }),
                  ];
                },
                onChanged: onFallbackModelChanged,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
