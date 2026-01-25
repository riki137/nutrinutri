import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Represents the user information extracted from Google sign-in.
class GoogleUserInfo {
  const GoogleUserInfo({required this.email, this.name, this.photoUrl});

  final String email;
  final String? name;
  final String? photoUrl;

  /// Fetches user info from Google's userinfo endpoint using an access token.
  static Future<GoogleUserInfo?> fromAccessToken(String? accessToken) async {
    if (accessToken == null || accessToken.isEmpty) return null;

    try {
      debugPrint('Fetching user info with token: ${accessToken.substring(0, 20)}...');
      final response = await http.get(
        Uri.parse('https://www.googleapis.com/oauth2/v3/userinfo'),
        headers: {'Authorization': 'Bearer $accessToken'},
      );

      debugPrint('User info response status: ${response.statusCode}');
      debugPrint('User info response body: ${response.body}');

      if (response.statusCode != 200) return null;

      final data = json.decode(response.body) as Map<String, dynamic>;
      final email = data['email'] as String?;
      if (email == null) return null;

      return GoogleUserInfo(
        email: email,
        name: data['name'] as String?,
        photoUrl: data['picture'] as String?,
      );
    } catch (e, stackTrace) {
      debugPrint('Error fetching user info: $e');
      debugPrint('Stack trace: $stackTrace');
      return null;
    }
  }

  /// Parses user info from a Google ID token (JWT).
  /// The ID token is a JWT with three parts separated by dots.
  /// The payload (middle part) contains user claims.
  static GoogleUserInfo? fromIdToken(String? idToken) {
    if (idToken == null || idToken.isEmpty) return null;

    try {
      final parts = idToken.split('.');
      if (parts.length != 3) return null;

      // Decode the payload (second part of JWT)
      String payload = parts[1];
      // Add padding if needed for base64 decoding
      switch (payload.length % 4) {
        case 1:
          payload += '===';
          break;
        case 2:
          payload += '==';
          break;
        case 3:
          payload += '=';
          break;
      }

      final decoded = utf8.decode(base64Url.decode(payload));
      final claims = json.decode(decoded) as Map<String, dynamic>;

      final email = claims['email'] as String?;
      if (email == null) return null;

      return GoogleUserInfo(
        email: email,
        name: claims['name'] as String?,
        photoUrl: claims['picture'] as String?,
      );
    } catch (e) {
      return null;
    }
  }
}
