import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:nutrinutri/core/domain/user_profile.dart';

/// An error raised while talking to the AI provider that carries a message
/// suitable for showing directly to the user (either the provider's own error
/// text or a friendly "no internet connection" message).
class AiRequestException implements Exception {
  const AiRequestException(this.message);
  final String message;

  @override
  String toString() => message;
}

class AIService {
  AIService({
    required this.apiKey,
    required this.model,
    required this.baseUrl,
    this.extraHeaders = const {},
  });

  /// Full chat-completions endpoint of the selected provider.
  final String baseUrl;
  final String apiKey;
  final String model;

  /// Provider-specific extra headers (e.g. OpenRouter's HTTP-Referer/X-Title).
  final Map<String, String> extraHeaders;

  // Track active clients for cancellation
  final Map<String, http.Client> _activeRequests = {};

  Map<String, String> _headers() => {
    'Authorization': 'Bearer $apiKey',
    'Content-Type': 'application/json',
    ...extraHeaders,
  };

  List<Map<String, dynamic>> _foodMessages({
    String? textDescription,
    String? base64Image,
  }) {
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
  "metrics": {
    "calories": 100.0,
    "carbs": 20.0,
    "sugars": 6.0,
    "fats": 5.0,
    "saturated_fats": 1.5,
    "protein": 10.0,
    "fiber": 3.0,
    "sodium": 300.0,
    "caffeine": 0.0,
    "water": 50.0
  },
  "icon": "fastfood",
  "confidence": 0.9
}
Use one decimal place for every metric value.
Always include all metric keys shown above.
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

    return messages;
  }

  List<Map<String, dynamic>> _exerciseMessages({
    required String textDescription,
    UserProfile? userProfile,
  }) {
    final profileInfo = userProfile == null
        ? ''
        : 'User Profile for Calorie Calculation:\n'
              'Age: ${userProfile.age}\n'
              'Weight: ${userProfile.weightKg} kg\n'
              'Height: ${userProfile.heightCm} cm\n'
              'Gender: ${userProfile.gender}\n';

    return <Map<String, dynamic>>[
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
  "metrics": {
    "calories": 150.0
  },
  "durationMinutes": 30,
  "icon": "directions_run",
  "confidence": 0.9
}
Calculate calories based on the user profile provided and standard MET values.
''',
      },
      {'role': 'user', 'content': textDescription},
    ];
  }

  bool _looksLikeClientException(Object error) {
    return error is http.ClientException ||
        error.toString().contains('ClientException');
  }

  /// Whether [error] looks like a connectivity failure rather than an API
  /// error.  Avoids importing `dart:io` (which would break web builds) by
  /// matching on type and message text.
  bool _isNetworkError(Object error) {
    if (error is http.ClientException) return true;
    final text = error.toString();
    return text.contains('SocketException') ||
        text.contains('Failed host lookup') ||
        text.contains('Connection refused') ||
        text.contains('Network is unreachable') ||
        text.contains('Connection closed') ||
        text.contains('XMLHttpRequest') ||
        text.contains('Failed to fetch');
  }

  /// Builds a user-facing message from a non-200 response, using the provider's
  /// own error text when it can be parsed out of the body.
  String _describeApiError(int statusCode, String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map) {
        final error = decoded['error'];
        if (error is Map && error['message'] is String) {
          return 'API error ($statusCode): ${error['message']}';
        }
        if (error is String && error.isNotEmpty) {
          return 'API error ($statusCode): $error';
        }
        if (decoded['message'] is String) {
          return 'API error ($statusCode): ${decoded['message']}';
        }
      }
    } catch (_) {
      // Body was not JSON; fall through to the raw text.
    }

    final trimmed = body.trim();
    return trimmed.isEmpty
        ? 'API request failed (HTTP $statusCode).'
        : 'API error ($statusCode): $trimmed';
  }

  Future<Map<String, dynamic>> _chatCompletion({
    required List<Map<String, dynamic>> messages,
    String? modelOverride,
    String? requestId,
  }) async {
    if (apiKey.isEmpty) {
      throw Exception('API Key is missing');
    }
    if (baseUrl.isEmpty) {
      throw const AiRequestException(
        'No API base URL configured. Set a provider or custom URL in Settings.',
      );
    }

    final client = http.Client();
    if (requestId != null) {
      _activeRequests[requestId]?.close(); // Cancel previous if exists
      _activeRequests[requestId] = client;
    }

    final body = jsonEncode({
      'model': modelOverride ?? model,
      'messages': messages,
      'response_format': {'type': 'json_object'},
    });

    try {
      final response = await client.post(
        Uri.parse(baseUrl),
        headers: _headers(),
        body: body,
      );

      if (response.statusCode != 200) {
        throw AiRequestException(
          _describeApiError(response.statusCode, response.body),
        );
      }

      final data = jsonDecode(response.body);
      final content = data['choices'][0]['message']['content'];
      return jsonDecode(_extractJson(content));
    } catch (e) {
      if (requestId != null &&
          _looksLikeClientException(e) &&
          _activeRequests[requestId] != client) {
        throw Exception('Request cancelled');
      }
      debugPrint('AI Service Error: $e');
      if (e is AiRequestException) rethrow;
      if (_isNetworkError(e)) {
        throw const AiRequestException(
          'No internet connection. Please check your network and try again.',
        );
      }
      rethrow;
    } finally {
      if (requestId != null && _activeRequests[requestId] == client) {
        _activeRequests.remove(requestId);
      }
      client.close();
    }
  }

  /// Analyzes food from text description or base64 image
  /// [requestId] is optional. If provided, allows cancellation of the request.
  /// [modelOverride] is optional. If provided, uses this model instead of the default.
  Future<Map<String, dynamic>> analyzeFood({
    String? textDescription,
    String? base64Image,
    String? requestId,
    String? modelOverride,
  }) async {
    return _chatCompletion(
      messages: _foodMessages(
        textDescription: textDescription,
        base64Image: base64Image,
      ),
      modelOverride: modelOverride,
      requestId: requestId,
    );
  }

  Future<Map<String, dynamic>> analyzeExercise({
    required String textDescription,
    UserProfile? userProfile,
    String? requestId,
    String? modelOverride,
  }) async {
    return _chatCompletion(
      messages: _exerciseMessages(
        textDescription: textDescription,
        userProfile: userProfile,
      ),
      modelOverride: modelOverride,
      requestId: requestId,
    );
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
