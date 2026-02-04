import 'dart:convert';

/// Represents the user information extracted from Google sign-in.
class GoogleUserInfo {
  const GoogleUserInfo({required this.email, this.name, this.photoUrl});

  final String email;
  final String? name;
  final String? photoUrl;

  /// Parses user info from a Google ID token (JWT).
  /// The ID token is a JWT with three parts separated by dots.
  /// The payload (middle part) contains user claims.
  static GoogleUserInfo? fromIdToken(String? idToken) {
    if (idToken == null || idToken.isEmpty) return null;

    try {
      final parts = idToken.split('.');
      if (parts.length != 3) return null;

      // Decode the payload (second part of JWT)
      final payload = base64Url.normalize(parts[1]);
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
