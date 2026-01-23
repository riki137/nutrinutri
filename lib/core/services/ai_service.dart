import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class AIService {
  static const String _baseUrl =
      'https://openrouter.ai/api/v1/chat/completions';
  final String apiKey;
  final String model;

  // Track active clients for cancellation
  final Map<String, http.Client> _activeRequests = {};

  AIService({required this.apiKey, required this.model});

  /// Analyzes food from text description or base64 image
  /// [requestId] is optional. If provided, allows cancellation of the request.
  /// [modelOverride] is optional. If provided, uses this model instead of the default.
  Future<Map<String, dynamic>> analyzeFood({
    String? textDescription,
    String? base64Image,
    String? requestId,
    String? modelOverride,
  }) async {
    if (apiKey.isEmpty) {
      throw Exception('API Key is missing');
    }

    final client = http.Client();
    if (requestId != null) {
      _activeRequests[requestId]?.close(); // Cancel previous if exists
      _activeRequests[requestId] = client;
    }

    final headers = {
      'Authorization': 'Bearer $apiKey',
      'Content-Type': 'application/json',
      'HTTP-Referer':
          'https://nutrinutri.popelis.sk', // Required by OpenRouter usually
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
      'model': modelOverride ?? model, // Use override or configured model
      'messages': messages,
      'response_format': {'type': 'json_object'},
    });

    try {
      final response = await client.post(
        Uri.parse(_baseUrl),
        headers: headers,
        body: body,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'];
        return jsonDecode(_extractJson(content));
      } else {
        throw Exception('AI Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      if (e.toString().contains('ClientException') &&
          requestId != null &&
          !_activeRequests.containsKey(requestId)) {
        throw Exception('Request cancelled');
      }
      debugPrint('AI Service Error: $e');
      rethrow;
    } finally {
      if (requestId != null) {
        _activeRequests.remove(requestId);
      }
      client.close();
    }
  }

  Future<Map<String, dynamic>> analyzeExercise({
    required String textDescription,
    Map<String, dynamic>? userProfile,
    String? requestId,
    String? modelOverride,
  }) async {
    if (apiKey.isEmpty) {
      throw Exception('API Key is missing');
    }

    final client = http.Client();
    if (requestId != null) {
      _activeRequests[requestId]?.close();
      _activeRequests[requestId] = client;
    }

    final headers = {
      'Authorization': 'Bearer $apiKey',
      'Content-Type': 'application/json',
      'HTTP-Referer': 'https://nutrinutri.popelis.sk',
      'X-Title': 'NutriNutri',
    };

    String profileInfo = '';
    if (userProfile != null) {
      profileInfo =
          'User Profile for Calorie Calculation:\n'
          'Age: ${userProfile['age']}\n'
          'Weight: ${userProfile['weight']} kg\n'
          'Height: ${userProfile['height']} cm\n'
          'Gender: ${userProfile['gender']}\n';
    }

    final messages = <Map<String, dynamic>>[
      {
        'role': 'system',
        'content':
            '''
You are a fitness expert AI. Analyze the exercise described.
$profileInfo
Return STRICT JSON ONLY. No markdown.
Select the most appropriate icon from this list:
[directions_run, directions_bike, directions_walk, fitness_center, pool, sports_soccer, sports_tennis, sports_basketball, rowing, hiking, yoga, self_improvement]

Structure:
{
  "food_name": "Short descriptive exercise name",
  "calories": 150,
  "durationMinutes": 30,
  "icon": "directions_run",
  "confidence": 0.9
}
Calculate calories based on the user profile provided and standard MET values.
''',
      },
      {'role': 'user', 'content': textDescription},
    ];

    final body = jsonEncode({
      'model': modelOverride ?? model,
      'messages': messages,
      'response_format': {'type': 'json_object'},
    });

    try {
      final response = await client.post(
        Uri.parse(_baseUrl),
        headers: headers,
        body: body,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'];
        return jsonDecode(_extractJson(content));
      } else {
        throw Exception('AI Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      if (e.toString().contains('ClientException') &&
          requestId != null &&
          !_activeRequests.containsKey(requestId)) {
        throw Exception('Request cancelled');
      }
      debugPrint('AI Service Error: $e');
      rethrow;
    } finally {
      if (requestId != null) {
        _activeRequests.remove(requestId);
      }
      client.close();
    }
  }

  void cancelRequest(String requestId) {
    if (_activeRequests.containsKey(requestId)) {
      _activeRequests[requestId]?.close();
      _activeRequests.remove(requestId);
    }
  }

  String _extractJson(String content) {
    if (content.contains('```json')) {
      final startIndex = content.indexOf('```json') + 7;
      final endIndex = content.lastIndexOf('```');
      if (endIndex > startIndex) {
        return content.substring(startIndex, endIndex).trim();
      }
    } else if (content.contains('```')) {
      final startIndex = content.indexOf('```') + 3;
      final endIndex = content.lastIndexOf('```');
      if (endIndex > startIndex) {
        return content.substring(startIndex, endIndex).trim();
      }
    }
    return content.trim();
  }
}
