import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:nutrinutri/features/settings/domain/ai_model_info.dart';
import 'package:nutrinutri/features/settings/domain/ai_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class AIConfigurationSection extends StatelessWidget {
  const AIConfigurationSection({
    super.key,
    required this.apiKeyController,
    required this.customModelController,
    required this.customFallbackModelController,
    required this.customBaseUrlController,
    required this.nutritionistInstructionsController,
    required this.trainerInstructionsController,
    required this.selectedProvider,
    required this.selectedModel,
    this.fallbackModel,
    required this.availableModels,
    required this.onProviderChanged,
    required this.onModelChanged,
    required this.onFallbackModelChanged,
  });
  final TextEditingController apiKeyController;
  final TextEditingController customModelController;
  final TextEditingController customFallbackModelController;
  final TextEditingController customBaseUrlController;
  final TextEditingController nutritionistInstructionsController;
  final TextEditingController trainerInstructionsController;
  final String selectedProvider;
  final String selectedModel;
  final String? fallbackModel;
  final List<AIModelInfo> availableModels;
  final ValueChanged<String?> onProviderChanged;
  final ValueChanged<String?> onModelChanged;
  final ValueChanged<String?> onFallbackModelChanged;

  AiProviderInfo get _provider => providerById(selectedProvider);

  Future<void> _openApiKeysPage(BuildContext context) async {
    final apiKeyUrl = _provider.apiKeyUrl;
    if (apiKeyUrl == null) return;
    final url = Uri.parse(apiKeyUrl);
    final launched = await launchUrl(url, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open browser. Visit $apiKeyUrl')),
      );
    }
  }

  Color _accuracyColor(ColorScheme colorScheme, int accuracy) {
    if (accuracy >= 95) return Colors.green;
    if (accuracy >= 90) return Colors.orange;
    return colorScheme.error;
  }

  /// Extracts the dollar figure from a price label like "~$0.22 / 100 logs".
  /// Returns null when there's no number to color (e.g. "Varies").
  double? _parsePrice(String price) {
    final match = RegExp(r'\$([0-9]+(?:\.[0-9]+)?)').firstMatch(price);
    if (match == null) return null;
    return double.tryParse(match.group(1)!);
  }

  /// Red-yellow-green scale for price per 100 logs. Cheaper is greener.
  /// Null (unpriced/custom) keeps the neutral chip styling.
  Color? _priceColor(ColorScheme colorScheme, String price) {
    final value = _parsePrice(price);
    if (value == null) return null;
    if (value <= 0.30) return Colors.green;
    if (value <= 0.80) return Colors.orange;
    return colorScheme.error;
  }

  Widget _buildPriceChip(ColorScheme colorScheme, String price) {
    final color = _priceColor(colorScheme, price);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color == null
            ? colorScheme.primaryContainer
            : color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        price,
        style: TextStyle(
          fontSize: 12,
          color: color ?? colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildAccuracyBadge(ColorScheme colorScheme, int accuracy) {
    final color = _accuracyColor(colorScheme, accuracy);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.track_changes, size: 12, color: color),
          const Gap(4),
          Text(
            '$accuracy% accurate',
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModelTile(BuildContext context, AIModelInfo model) {
    final colorScheme = Theme.of(context).colorScheme;
    final accuracy = model.accuracy;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  model.name,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const Gap(8),
              _buildPriceChip(colorScheme, model.price),
            ],
          ),
          if (accuracy != null) ...[
            const Gap(4),
            _buildAccuracyBadge(colorScheme, accuracy),
          ],
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

  Widget _buildProviderDropdown(BuildContext context) {
    return InputDecorator(
      decoration: const InputDecoration(
        labelText: 'AI Provider',
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedProvider,
          isExpanded: true,
          items: kAiProviders
              .map(
                (provider) => DropdownMenuItem<String>(
                  value: provider.id,
                  child: Text(provider.name),
                ),
              )
              .toList(),
          onChanged: onProviderChanged,
        ),
      ),
    );
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

  /// OpenRouter's rich preset dropdowns (+ custom model text fields).
  List<Widget> _buildPresetModelFields(BuildContext context) {
    return [
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
      if (fallbackModel == 'custom') ...[
        const Gap(8),
        TextField(
          controller: customFallbackModelController,
          decoration: const InputDecoration(
            labelText: 'Custom Fallback Model ID (OpenRouter)',
            border: OutlineInputBorder(),
            hintText: 'e.g. meta-llama/llama-3-70b-instruct',
          ),
        ),
      ],
    ];
  }

  /// Free-text model id fields used by every non-OpenRouter provider.
  List<Widget> _buildFreeTextModelFields() {
    final suggested = _provider.suggestedModel;
    return [
      TextField(
        controller: customModelController,
        decoration: InputDecoration(
          labelText: 'Model ID',
          border: const OutlineInputBorder(),
          hintText: suggested.isEmpty ? 'e.g. gpt-5.5' : suggested,
        ),
      ),
      const Gap(16),
      TextField(
        controller: customFallbackModelController,
        decoration: const InputDecoration(
          labelText: 'Fallback Model ID (Optional)',
          border: OutlineInputBorder(),
          helperText: 'Used if the primary model fails',
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final provider = _provider;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'AI Configuration',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const Gap(16),
        const Text(
          'This app uses an AI provider to analyze your food — OpenRouter, '
          'OpenAI, Anthropic, any OpenAI-compatible API, and more. Pick a '
          'provider and supply your own API key.',
          style: TextStyle(color: Colors.grey),
        ),
        const Gap(16),
        _buildProviderDropdown(context),
        if (provider.isCustom) ...[
          const Gap(16),
          TextField(
            controller: customBaseUrlController,
            decoration: const InputDecoration(
              labelText: 'API Base URL',
              border: OutlineInputBorder(),
              hintText: 'https://your-host/v1',
              helperText: 'OpenAI-compatible chat completions base URL',
            ),
            keyboardType: TextInputType.url,
          ),
        ],
        const Gap(16),
        TextField(
          controller: apiKeyController,
          decoration: InputDecoration(
            labelText: '${provider.name} API Key',
            border: const OutlineInputBorder(),
            hintText: provider.keyHint,
          ),
          obscureText: true,
        ),
        if (apiKeyController.text.isEmpty) ...[
          if (provider.apiKeyUrl != null) ...[
            const Gap(8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _openApiKeysPage(context),
                icon: const Icon(Icons.open_in_new),
                label: const Text('Get API Key'),
              ),
            ),
          ],
        ] else ...[
          const Gap(16),
          ...(provider.id == kDefaultProviderId
              ? _buildPresetModelFields(context)
              : _buildFreeTextModelFields()),
        ],
        const Gap(16),
        TextField(
          controller: nutritionistInstructionsController,
          minLines: 3,
          maxLines: 8,
          keyboardType: TextInputType.multiline,
          decoration: const InputDecoration(
            labelText: 'Nutritionist Instructions (Optional)',
            border: OutlineInputBorder(),
            alignLabelWithHint: true,
            helperText:
                'Extra guidance for food analysis, added on top of the '
                'built-in instructions. Use it to get responses in your '
                'language, set your country, or refine how portions are '
                'estimated. Leave empty for the default.',
            helperMaxLines: 4,
            hintText:
                'e.g. Reply in Slovak; I live in Slovakia; estimate '
                'portions generously.',
          ),
        ),
        const Gap(16),
        TextField(
          controller: trainerInstructionsController,
          minLines: 3,
          maxLines: 8,
          keyboardType: TextInputType.multiline,
          decoration: const InputDecoration(
            labelText: 'Fitness Trainer Instructions (Optional)',
            border: OutlineInputBorder(),
            alignLabelWithHint: true,
            helperText:
                'Extra guidance for exercise analysis, added on top of the '
                'built-in instructions. Use it to get responses in your '
                'language or refine how burned calories are estimated. Leave '
                'empty for the default.',
            helperMaxLines: 4,
            hintText:
                'e.g. Reply in Slovak; I mostly do strength training.',
          ),
        ),
      ],
    );
  }
}
