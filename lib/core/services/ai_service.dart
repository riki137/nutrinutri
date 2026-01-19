import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class AIService {
  static const String _baseUrl =
      'https://openrouter.ai/api/v1/chat/completions';
  final String apiKey;
  final String model;

  AIService({required this.apiKey, required this.model});

  /// Analyzes food from text description or base64 image
  Future<Map<String, dynamic>> analyzeFood({
    String? textDescription,
    String? base64Image,
  }) async {
    if (apiKey.isEmpty) {
      throw Exception('API Key is missing');
    }

    final headers = {
      'Authorization': 'Bearer $apiKey',
      'Content-Type': 'application/json',
      'HTTP-Referer':
          'https://nutrinutri.app', // Required by OpenRouter usually
      'X-Title': 'NutriNutri',
    };

    final messages = <Map<String, dynamic>>[
      {
        'role': 'system',
        'content': '''
You are a nutritionist AI. Analyze the food provided (text or image).
Return STRICT JSON ONLY. No markdown, no intro/outro.
Select the most appropriate icon from this list:
[bakery_dining, brunch_dining, bento, cake, coffee, cookie, egg_alt, fastfood, flatware, liquor, microwave, nightlife, outdoor_grill, ramen_dining, restaurant, rice_bowl, sports_bar, tapas]

Structure:
{
  "food_name": "Short descriptive name",
  "calories": 100,
  "protein": 10,
  "carbs": 20,
  "fats": 5,
  "icon": "fastfood",
  "confidence": 0.9
}
If unclear, provide best guess with lower confidence.
''',
      },
    ];

    if (base64Image != null) {
      messages.add({
        'role': 'user',
        'content': [
          {'type': 'text', 'text': textDescription ?? 'Analyze this food'},
          {
            'type': 'image_url',
            'image_url': {'url': 'data:image/jpeg;base64,$base64Image'},
          },
        ],
      });
    } else {
      messages.add({
        'role': 'user',
        'content': textDescription ?? 'Analyze this food',
      });
    }

    final body = jsonEncode({
      'model': model, // Use configured model
      'messages': messages,
      'response_format': {'type': 'json_object'},
    });

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: headers,
        body: body,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'];
        return jsonDecode(content);
      } else {
        throw Exception('AI Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('AI Service Error: $e');
      rethrow;
    }
  }
}
