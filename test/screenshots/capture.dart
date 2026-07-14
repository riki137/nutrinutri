import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Registers the app's bundled fonts (MaterialIcons, etc.) with the engine.
///
/// `flutter test` runs the tester with `--disable-asset-fonts`, so fonts
/// declared via the asset manifest (icon fonts in particular) are not loaded
/// automatically and render as empty boxes. Loading them manually through
/// [FontLoader] — the same path google_fonts uses — makes them render.
/// (Outfit is handled separately by google_fonts from `assets/google_fonts/`.)
Future<void> loadAppFonts() async {
  final manifest =
      json.decode(await rootBundle.loadString('FontManifest.json')) as List;
  for (final family in manifest.cast<Map<String, dynamic>>()) {
    final loader = FontLoader(family['family'] as String);
    for (final font in (family['fonts'] as List).cast<Map<String, dynamic>>()) {
      loader.addFont(rootBundle.load(font['asset'] as String));
    }
    await loader.load();
  }
}

/// A target form factor for a screenshot. [logical] is the logical window size
/// the app lays itself out for; the captured PNG is [logical] × [dpr] pixels.
class DeviceProfile {
  const DeviceProfile({
    required this.label,
    required this.logical,
    required this.dpr,
    required this.desktop,
  });

  final String label;
  final Size logical;
  final double dpr;

  /// Whether to present the desktop layout (sidebar) vs the mobile layout
  /// (bottom app bar). Drives `PlatformHelper.debugIsDesktopOrWebOverride`.
  final bool desktop;

  Size get physical => Size(logical.width * dpr, logical.height * dpr);
}

/// Phone: 1170×2532 px (≈9:19.5), matching what the landing site expects.
const phone = DeviceProfile(
  label: 'phone',
  logical: Size(390, 844),
  dpr: 3,
  desktop: false,
);

/// Desktop: 3200×1800 px (16:9).
const desktop = DeviceProfile(
  label: 'desktop',
  logical: Size(1600, 900),
  dpr: 2,
  desktop: true,
);

/// Directory (relative to the package root) the PNGs are written to.
const screenshotOutputDir = 'build/screenshots';

/// Rasterizes the [RepaintBoundary] identified by [key] to a PNG at
/// `build/screenshots/<name>`, at the view's current device pixel ratio.
///
/// The rasterization (`toImage`) and PNG encoding (`toByteData`) are real
/// asynchronous work, so they must run inside [WidgetTester.runAsync] — the
/// test's default fake-async zone would never complete those futures.
Future<void> captureToPng(
  WidgetTester tester,
  GlobalKey key,
  String name,
) async {
  final boundary =
      key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final dpr = tester.view.devicePixelRatio;
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: dpr);
    try {
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final file = File('$screenshotOutputDir/$name');
      file.parent.createSync(recursive: true);
      file.writeAsBytesSync(bytes!.buffer.asUint8List());
    } finally {
      image.dispose();
    }
  });
}
