import 'package:flutter_test/flutter_test.dart';
import 'package:nutrinutri/core/domain/ai_api_protocol.dart';
import 'package:nutrinutri/features/settings/domain/ai_provider.dart';

void main() {
  test('known provider endpoints', () {
    expect(resolveChatEndpoint(providerById('openrouter'), null),
        'https://openrouter.ai/api/v1/chat/completions');
    expect(resolveChatEndpoint(providerById('openai'), null),
        'https://api.openai.com/v1/chat/completions');
    expect(resolveChatEndpoint(providerById('groq'), null),
        'https://api.groq.com/openai/v1/chat/completions');
  });

  test('anthropic resolves to the messages endpoint', () {
    final anthropic = providerById('anthropic');
    expect(anthropic.protocol, AiApiProtocol.anthropicMessages);
    expect(resolveChatEndpoint(anthropic, null),
        'https://api.anthropic.com/v1/messages');
    expect(providerHeaders(anthropic), isEmpty);
  });

  test('unknown id falls back to openrouter', () {
    expect(providerById('nope').id, 'openrouter');
    expect(providerById(null).id, 'openrouter');
  });

  test('custom base url normalization', () {
    expect(resolveChatEndpoint(providerById('custom'), 'https://my.host/v1'),
        'https://my.host/v1/chat/completions');
    expect(resolveChatEndpoint(providerById('custom'), 'https://my.host/v1/'),
        'https://my.host/v1/chat/completions');
    expect(
        resolveChatEndpoint(
            providerById('custom'), 'https://my.host/v1/chat/completions'),
        'https://my.host/v1/chat/completions');
    expect(resolveChatEndpoint(providerById('custom'), null), '');
    expect(resolveChatEndpoint(providerById('custom'), '  '), '');
  });

  test('headers only for openrouter', () {
    expect(providerHeaders(providerById('openrouter')), contains('X-Title'));
    expect(providerHeaders(providerById('openai')), isEmpty);
    expect(providerHeaders(providerById('custom')), isEmpty);
  });
}
