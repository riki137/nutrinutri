import 'package:flutter_test/flutter_test.dart';
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
