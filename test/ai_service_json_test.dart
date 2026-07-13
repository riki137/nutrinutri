import 'package:flutter_test/flutter_test.dart';
import 'package:nutrinutri/core/services/ai_service.dart';

/// A well-formed reply, exactly the shape the food prompt asks for.
const _clean = '''
{
  "food_name": "KFC Original Recipe Chicken Breast",
  "metrics": {
    "calories": 390.0,
    "carbs": 11.0,
    "sugars": 0.0,
    "fats": 21.0,
    "saturated_fats": 4.0,
    "protein": 39.0,
    "fiber": 0.0,
    "sodium": 1190.0,
    "caffeine": 0.0,
    "water": 88.5
  },
  "icon": "fastfood",
  "confidence": 0.9
}''';

void main() {
  group('parseModelJson', () {
    test('parses a clean object', () {
      final r = parseModelJson(_clean);
      expect(r['food_name'], 'KFC Original Recipe Chicken Breast');
      expect((r['metrics'] as Map)['calories'], 390.0);
      expect(r['confidence'], 0.9);
    });

    test('strips a ```json fenced block', () {
      final r = parseModelJson('```json\n$_clean\n```');
      expect((r['metrics'] as Map)['calories'], 390.0);
    });

    test('strips a bare ``` fenced block', () {
      final r = parseModelJson('```\n$_clean\n```');
      expect((r['metrics'] as Map)['calories'], 390.0);
    });

    // Observed 11x from gemini-3.1-pro-preview:
    // "FormatException: Unexpected character (at line 18, character 1) }".
    // A complete object with a stray extra closing brace appended.
    test('recovers a complete object with a stray trailing brace', () {
      final r = parseModelJson('$_clean\n}');
      expect((r['metrics'] as Map)['calories'], 390.0);
      expect(r['confidence'], 0.9);
    });

    test('recovers a complete object followed by trailing prose', () {
      final r = parseModelJson(
        '$_clean\n\nHope this helps! Let me know if you need more detail.',
      );
      expect((r['metrics'] as Map)['calories'], 390.0);
    });

    test('recovers an object with leading prose before the brace', () {
      final r = parseModelJson('Sure, here is the analysis:\n$_clean');
      expect((r['metrics'] as Map)['protein'], 39.0);
    });

    // Observed 9x from gemini-3.1-pro-preview:
    // "FormatException: Unexpected end of input (at line 16, character 20)".
    // The reply was cut off just before the closing brace.
    test('repairs a reply truncated right before the closing brace', () {
      // Everything up to and including the confidence value, no final `}`.
      final truncated = _clean.substring(0, _clean.length - 2);
      final r = parseModelJson(truncated);
      expect((r['metrics'] as Map)['calories'], 390.0);
      expect(r['confidence'], 0.9);
    });

    test('repairs a reply truncated mid-value, keeping the intact metrics', () {
      final truncated = '''
{
  "food_name": "KFC Original Recipe Chicken Breast",
  "metrics": {
    "calories": 390.0,
    "carbs": 11.0,
    "sugars": 0.0,
    "fats": 21.0,
    "saturated_fats": 4.0,
    "protein": 39.0,
    "fiber": 0.0,
    "sodium": 1190.0,
    "caffeine": 0.0,
    "water": 88.5
  },
  "icon": "fastfood",
  "confidence": 0.''';
      final r = parseModelJson(truncated);
      final metrics = r['metrics'] as Map;
      expect(metrics['calories'], 390.0);
      expect(metrics['water'], 88.5);
      expect(r['icon'], 'fastfood');
    });

    test('repairs truncation inside the nested metrics object', () {
      final truncated = '''
{
  "food_name": "Whole Milk",
  "metrics": {
    "calories": 150.0,
    "carbs": 12.0,
    "sugars": 12.0,
    "fats": 8.0''';
      final r = parseModelJson(truncated);
      final metrics = r['metrics'] as Map;
      expect(metrics['calories'], 150.0);
      expect(metrics['fats'], 8.0);
      expect(r['food_name'], 'Whole Milk');
    });

    test('repairs an unterminated string', () {
      final truncated = '''
{
  "food_name": "Grilled Salmon",
  "metrics": {
    "calories": 400.0,
    "protein": 40.0
  },
  "icon": "outdoor_gr''';
      final r = parseModelJson(truncated);
      expect((r['metrics'] as Map)['calories'], 400.0);
    });

    test('throws with a bounded snippet when nothing is recoverable', () {
      expect(
        () => parseModelJson('the model refused and returned only prose'),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
