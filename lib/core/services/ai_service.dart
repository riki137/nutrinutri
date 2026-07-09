import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:nutrinutri/core/domain/user_profile.dart';

/// An error raised while talking to OpenRouter that carries a message suitable
/// for showing directly to the user (either OpenRouter's own error text or a
/// friendly "no internet connection" message).
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
    this.nutritionistInstructions,
    this.trainerInstructions,
  });
  static const String _baseUrl =
      'https://openrouter.ai/api/v1/chat/completions';
  final String apiKey;
  final String model;

  /// Optional user-supplied guidance appended on top of the built-in
  /// nutritionist (food analysis) instructions.  The default guidance and
  /// strict-JSON response contract are always kept, so parsing never breaks.
  /// Null / empty means "use the defaults only".
  final String? nutritionistInstructions;

  /// Optional user-supplied guidance appended on top of the built-in fitness
  /// trainer (exercise analysis) instructions.  The default guidance and
  /// strict-JSON response contract are always kept, so parsing never breaks.
  /// Null / empty means "use the defaults only".
  final String? trainerInstructions;

  /// Default instruction shown to the model for food analysis.
  static const String _defaultFoodGuidance =
      'You are a nutritionist AI. Analyze the food provided (text or image).';

  /// Default instruction shown to the model for exercise analysis.
  static const String _defaultExerciseGuidance =
      'You are a fitness expert AI. Analyze the exercise described.';

  /// Returns [base] with the user's [extra] instructions appended when present.
  String _guidance(String base, String? extra) {
    final trimmed = extra?.trim();
    if (trimmed == null || trimmed.isEmpty) return base;
    return '$base\n\nAdditional user instructions:\n$trimmed';
  }

  // Track active clients for cancellation
  final Map<String, http.Client> _activeRequests = {};

  Map<String, String> _headers() => {
    'Authorization': 'Bearer $apiKey',
    'Content-Type': 'application/json',
    'HTTP-Referer': 'https://nutrinutri.popelis.sk', // OpenRouter requirement
    'X-Title': 'NutriNutri',
  };

  List<Map<String, dynamic>> _foodMessages({
    String? textDescription,
    String? base64Image,
  }) {
    final messages = <Map<String, dynamic>>[
      {
        'role': 'system',
        'content': '''
${_guidance(_defaultFoodGuidance, nutritionistInstructions)}
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
${_guidance(_defaultExerciseGuidance, trainerInstructions)}
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

  /// Builds a user-facing message from a non-200 OpenRouter response, using
  /// OpenRouter's own error text when it can be parsed out of the body.
  String _describeApiError(int statusCode, String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map) {
        final error = decoded['error'];
        if (error is Map && error['message'] is String) {
          return 'OpenRouter error ($statusCode): ${error['message']}';
        }
        if (error is String && error.isNotEmpty) {
          return 'OpenRouter error ($statusCode): $error';
        }
        if (decoded['message'] is String) {
          return 'OpenRouter error ($statusCode): ${decoded['message']}';
        }
      }
    } catch (_) {
      // Body was not JSON; fall through to the raw text.
    }

    final trimmed = body.trim();
    return trimmed.isEmpty
        ? 'OpenRouter request failed (HTTP $statusCode).'
        : 'OpenRouter error ($statusCode): $trimmed';
  }

  Future<Map<String, dynamic>> _chatCompletion({
    required List<Map<String, dynamic>> messages,
    String? modelOverride,
    String? requestId,
  }) async {
    if (apiKey.isEmpty) {
      throw Exception('API Key is missing');
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
        Uri.parse(_baseUrl),
        headers: _headers(),
        body: body,
      );

      if (response.statusCode != 200) {
        throw AiRequestException(
          _describeApiError(response.statusCode, response.body),
        );
      }

      final data = jsonDecode(response.body);
      // Some providers return HTTP 200 with a malformed/empty body (no
      // `choices`, or an `error` field). Guard the indexing so that surfaces
      // as a clean, user-facing error rather than a cryptic NoSuchMethodError.
      String? content;
      if (data is Map &&
          data['choices'] is List &&
          (data['choices'] as List).isNotEmpty) {
        final first = (data['choices'] as List).first;
        if (first is Map && first['message'] is Map) {
          final rawContent = (first['message'] as Map)['content'];
          if (rawContent is String) content = rawContent;
        }
      }
      if (content == null) {
        throw AiRequestException(
          _describeApiError(response.statusCode, response.body),
        );
      }
      return parseModelJson(content);
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

}

/// Parses the JSON object out of a model's chat reply.
///
/// Providers do not always return byte-perfect JSON even in `json_object`
/// mode. Two malformations were observed repeatedly in benchmarking (notably
/// from `gemini-3.1-pro-preview`) that discard an otherwise usable — and
/// already paid-for — response:
///
///   1. A complete, valid object followed by trailing junk, e.g. a duplicated
///      closing brace (`...}\n}`) or prose after the object.
///   2. A reply truncated mid-object (the generation was cut off), leaving
///      unclosed braces and possibly a dangling key/value.
///
/// This decodes such replies by (a) stripping markdown fences, (b) extracting
/// the first balanced top-level object so trailing junk is ignored, and
/// (c) repairing a truncated object by closing its open structures. It only
/// throws when nothing usable can be recovered, and then includes a bounded
/// snippet of the raw content so the failure is debuggable from logs without
/// re-issuing (paid) calls.
Map<String, dynamic> parseModelJson(String rawContent) {
  final content = _stripJsonFences(rawContent);

  // Fast path: a clean, strictly-valid JSON object.
  final direct = _tryDecodeObject(content);
  if (direct != null) return direct;

  // Trailing junk (e.g. a stray extra `}` or prose after the object):
  // parse just the first balanced object and ignore anything after it.
  final balanced = _firstBalancedObject(content);
  if (balanced != null) {
    final decoded = _tryDecodeObject(balanced);
    if (decoded != null) return decoded;
  }

  // Truncated reply: close the open structures, trimming the last incomplete
  // token if necessary, until it parses.
  final repaired = _repairTruncatedObject(content);
  if (repaired != null) return repaired;

  final snippet = content.length > 300
      ? '${content.substring(0, 300)}…'
      : content;
  throw FormatException('Could not parse model JSON reply. Content: $snippet');
}

/// Strips a surrounding ```` ```json ```` / ```` ``` ```` markdown fence, if any.
String _stripJsonFences(String content) {
  final trimmed = content.trim();
  if (trimmed.startsWith('```')) {
    var inner = trimmed.substring(3);
    if (inner.startsWith('json')) inner = inner.substring(4);
    final fenceEnd = inner.lastIndexOf('```');
    if (fenceEnd >= 0) inner = inner.substring(0, fenceEnd);
    return inner.trim();
  }
  return trimmed;
}

Map<String, dynamic>? _tryDecodeObject(String content) {
  try {
    final decoded = jsonDecode(content);
    if (decoded is Map<String, dynamic>) return decoded;
  } on FormatException {
    // Not strictly valid; caller falls back to lenient recovery.
  }
  return null;
}

/// Returns the substring from the first `{` to the matching `}` that closes it,
/// or `null` if there is no balanced object (e.g. the reply was truncated).
/// Content after the closing brace is ignored, which recovers replies that
/// append a stray extra brace or trailing prose.
String? _firstBalancedObject(String content) {
  final start = content.indexOf('{');
  if (start < 0) return null;

  var inString = false;
  var escaped = false;
  var depth = 0;
  for (var i = start; i < content.length; i++) {
    final c = content[i];
    if (inString) {
      if (escaped) {
        escaped = false;
      } else if (c == r'\') {
        escaped = true;
      } else if (c == '"') {
        inString = false;
      }
      continue;
    }
    if (c == '"') {
      inString = true;
    } else if (c == '{' || c == '[') {
      depth++;
    } else if (c == '}' || c == ']') {
      depth--;
      if (depth == 0) return content.substring(start, i + 1);
    }
  }
  return null;
}

/// Best-effort recovery of a truncated object: close any open structures,
/// dropping the trailing incomplete key/value and retrying until it parses.
Map<String, dynamic>? _repairTruncatedObject(String content) {
  final start = content.indexOf('{');
  if (start < 0) return null;

  var candidate = content.substring(start);
  for (var attempt = 0; attempt < 6 && candidate.trim().length > 1; attempt++) {
    final closed = _closeOpenStructures(candidate);
    if (closed != null) {
      final decoded = _tryDecodeObject(closed);
      if (decoded != null) return decoded;
    }
    candidate = _dropTrailingFragment(candidate);
  }
  return null;
}

/// Appends the closers needed to balance [content]: terminates a dangling
/// string, drops a trailing comma, then closes every open `{`/`[` in order.
String? _closeOpenStructures(String content) {
  var inString = false;
  var escaped = false;
  final stack = <String>[];
  for (var i = 0; i < content.length; i++) {
    final c = content[i];
    if (inString) {
      if (escaped) {
        escaped = false;
      } else if (c == r'\') {
        escaped = true;
      } else if (c == '"') {
        inString = false;
      }
      continue;
    }
    if (c == '"') {
      inString = true;
    } else if (c == '{') {
      stack.add('}');
    } else if (c == '[') {
      stack.add(']');
    } else if (c == '}' || c == ']') {
      if (stack.isEmpty) return null;
      stack.removeLast();
    }
  }
  if (stack.isEmpty && !inString) return content;

  var result = content;
  if (inString) result += '"';
  result = result.trimRight();
  if (result.endsWith(',')) {
    result = result.substring(0, result.length - 1).trimRight();
  }
  // A dangling key with no value (`..."confidence":`) cannot be closed here;
  // let the caller drop it on the next attempt.
  if (result.endsWith(':')) return null;
  for (final closer in stack.reversed) {
    result += closer;
  }
  return result;
}

/// Trims the last, likely-incomplete key/value or element off [content] by
/// cutting at the last top-level (outside-string) comma.
String _dropTrailingFragment(String content) {
  var inString = false;
  var escaped = false;
  var lastComma = -1;
  for (var i = 0; i < content.length; i++) {
    final c = content[i];
    if (inString) {
      if (escaped) {
        escaped = false;
      } else if (c == r'\') {
        escaped = true;
      } else if (c == '"') {
        inString = false;
      }
      continue;
    }
    if (c == '"') {
      inString = true;
    } else if (c == ',') {
      lastComma = i;
    }
  }
  if (lastComma < 0) return '';
  return content.substring(0, lastComma);
}
