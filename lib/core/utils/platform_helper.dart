import 'dart:io';

import 'package:flutter/foundation.dart';

/// Helper class for platform-specific detection
class PlatformHelper {
  PlatformHelper._();

  /// Returns true if the app is running on a desktop platform (Windows, macOS, Linux)
  /// or on the web
  static bool get isDesktopOrWeb {
    if (kIsWeb) return true;
    return Platform.isWindows || Platform.isMacOS || Platform.isLinux;
  }

  /// Returns true if the app is running on a mobile platform (iOS, Android)
  static bool get isMobile {
    if (kIsWeb) return false;
    return Platform.isIOS || Platform.isAndroid;
  }

  /// Returns true if running on the web
  static bool get isWeb => kIsWeb;

  /// Returns true if window width suggests desktop layout should be used
  /// This allows responsive behavior even on tablets/large phones
  static bool shouldUseDesktopLayout(double width) {
    // Use desktop layout for screens >= 900px wide
    return width >= 900 && isDesktopOrWeb;
  }
}
