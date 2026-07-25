import 'package:nutrinutri/core/domain/ai_api_protocol.dart';

/// Describes an AI provider the user can pick in Settings.
///
/// Most providers speak the OpenAI chat-completions protocol and differ only
/// in base URL, the page where you obtain an API key, and (for OpenRouter) a
/// couple of required extra headers.  Anthropic speaks its own Messages API,
/// which [protocol] captures.  The `custom` provider carries no base URL —
/// the user supplies one at runtime.
class AiProviderInfo {
  const AiProviderInfo({
    required this.id,
    required this.name,
    required this.baseUrl,
    required this.apiKeyUrl,
    required this.keyHint,
    required this.suggestedModel,
    this.sendOpenRouterHeaders = false,
    this.protocol = AiApiProtocol.openAiChat,
  });

  /// Stable identifier persisted in settings (e.g. `openrouter`, `openai`).
  final String id;

  /// Human-readable name shown in the dropdown.
  final String name;

  /// Base URL including the `/v1` segment, or null for [isCustom] providers.
  final String? baseUrl;

  /// Page where the user can create an API key, or null when unknown (custom).
  final String? apiKeyUrl;

  /// Placeholder shown in the API key field (e.g. `sk-or-...`).
  final String keyHint;

  /// A sensible default model id shown as a hint for free-text providers.
  final String suggestedModel;

  /// Whether OpenRouter's required `HTTP-Referer` / `X-Title` headers are sent.
  final bool sendOpenRouterHeaders;

  /// Which wire protocol the provider's API speaks.
  final AiApiProtocol protocol;

  bool get isCustom => id == kCustomProviderId;
}

/// Id of the default provider used when nothing is stored yet.
const String kDefaultProviderId = 'openrouter';

/// Id of the "bring your own base URL" provider.
const String kCustomProviderId = 'custom';

/// All selectable providers, OpenRouter first (the default).
const List<AiProviderInfo> kAiProviders = [
  AiProviderInfo(
    id: 'openrouter',
    name: 'OpenRouter',
    baseUrl: 'https://openrouter.ai/api/v1',
    apiKeyUrl: 'https://openrouter.ai/settings/keys',
    keyHint: 'sk-or-...',
    suggestedModel: 'google/gemini-3-flash-preview',
    sendOpenRouterHeaders: true,
  ),
  AiProviderInfo(
    id: 'openai',
    name: 'OpenAI',
    baseUrl: 'https://api.openai.com/v1',
    apiKeyUrl: 'https://platform.openai.com/api-keys',
    keyHint: 'sk-...',
    suggestedModel: 'gpt-5.5',
  ),
  AiProviderInfo(
    id: 'anthropic',
    name: 'Anthropic',
    baseUrl: 'https://api.anthropic.com/v1',
    apiKeyUrl: 'https://platform.claude.com/settings/keys',
    keyHint: 'sk-ant-...',
    suggestedModel: 'claude-opus-5',
    protocol: AiApiProtocol.anthropicMessages,
  ),
  AiProviderInfo(
    id: 'groq',
    name: 'Groq',
    baseUrl: 'https://api.groq.com/openai/v1',
    apiKeyUrl: 'https://console.groq.com/keys',
    keyHint: 'gsk_...',
    suggestedModel: 'llama-3.3-70b-versatile',
  ),
  AiProviderInfo(
    id: 'together',
    name: 'Together',
    baseUrl: 'https://api.together.xyz/v1',
    apiKeyUrl: 'https://api.together.xyz/settings/api-keys',
    keyHint: 'API key',
    suggestedModel: 'meta-llama/Llama-3.3-70B-Instruct-Turbo',
  ),
  AiProviderInfo(
    id: 'deepseek',
    name: 'DeepSeek',
    baseUrl: 'https://api.deepseek.com/v1',
    apiKeyUrl: 'https://platform.deepseek.com/api_keys',
    keyHint: 'sk-...',
    suggestedModel: 'deepseek-chat',
  ),
  AiProviderInfo(
    id: kCustomProviderId,
    name: 'Custom (OpenAI-compatible)',
    baseUrl: null,
    apiKeyUrl: null,
    keyHint: 'API key',
    suggestedModel: '',
  ),
];

/// Returns the provider with [id], falling back to OpenRouter for unknown ids.
AiProviderInfo providerById(String? id) {
  return kAiProviders.firstWhere(
    (p) => p.id == id,
    orElse: () => kAiProviders.first,
  );
}

/// Resolves the full request endpoint for [provider].
///
/// For custom providers [customBaseUrl] is used, otherwise the provider's own
/// base URL.  The URL is normalized so users can paste either a base
/// (`https://host/v1`) or a full endpoint (`https://host/v1/chat/completions`).
/// Anthropic providers resolve to the Messages API path (`/messages`) instead.
String resolveChatEndpoint(AiProviderInfo provider, String? customBaseUrl) {
  final raw = provider.isCustom ? customBaseUrl : provider.baseUrl;
  var base = (raw ?? '').trim();
  while (base.endsWith('/')) {
    base = base.substring(0, base.length - 1);
  }
  if (base.isEmpty) return '';
  final path = provider.protocol == AiApiProtocol.anthropicMessages
      ? '/messages'
      : '/chat/completions';
  if (base.endsWith(path)) return base;
  return '$base$path';
}

/// Provider-specific extra request headers (OpenRouter requires these).
Map<String, String> providerHeaders(AiProviderInfo provider) {
  if (!provider.sendOpenRouterHeaders) return const {};
  return const {
    'HTTP-Referer': 'https://nutrinutri.popelis.sk',
    'X-Title': 'NutriNutri',
  };
}
