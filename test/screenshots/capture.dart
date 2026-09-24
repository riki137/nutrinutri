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

/// Registers a single on-disk font file under [family], for chrome (window
/// frame) rendering that isn't part of the app's own asset bundle.
Future<void> loadFontFile(String family, String path) async {
  final loader = FontLoader(family)
    ..addFont(
      Future.value(ByteData.sublistView(File(path).readAsBytesSync())),
    );
  await loader.load();
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

/// Desktop: 3200×1800 px (16:9). Framed with macOS chrome for the landing
/// site's macOS screenshot.
const desktop = DeviceProfile(
  label: 'desktop',
  logical: Size(1600, 900),
  dpr: 2,
  desktop: true,
);

/// Linux desktop: content sized so the GNOME-framed window (content + the
/// 46px headerbar) lands exactly at Flathub's ≤1000×700 logical screenshot
/// limit (≤2000×1400 px HiDPI). See
/// https://docs.flathub.org/docs/for-app-authors/metainfo-guidelines/quality-guidelines
const linuxDesktop = DeviceProfile(
  label: 'linux-desktop',
  logical: Size(1000, 654),
  dpr: 2,
  desktop: true,
);

/// Tablet: 1600×2560 px (10" portrait, Play Store's recommended size).
/// `desktop: false` matches real behavior — the app has no width-based
/// layout switch, so an Android tablet still renders the mobile UI.
const tablet = DeviceProfile(
  label: 'tablet',
  logical: Size(800, 1280),
  dpr: 2,
  desktop: false,
);

/// Directory (relative to the package root) the PNGs are written to.
const screenshotOutputDir = 'build/screenshots';

/// Rasterizes the [RepaintBoundary] identified by [key] at the view's current
/// device pixel ratio.
///
/// `toImage` is real asynchronous work, so it must run inside
/// [WidgetTester.runAsync] — the test's default fake-async zone would never
/// complete that future. Callers must [ui.Image.dispose] the result.
Future<ui.Image> captureBoundaryImage(WidgetTester tester, GlobalKey key) async {
  final boundary =
      key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final dpr = tester.view.devicePixelRatio;
  return (await tester.runAsync(() => boundary.toImage(pixelRatio: dpr)))!;
}

/// Encodes [image] as a PNG at `build/screenshots/<name>`.
///
/// PNG encoding (`toByteData`) is real asynchronous work, so it must run
/// inside [WidgetTester.runAsync] — see [captureBoundaryImage].
Future<void> writePng(WidgetTester tester, ui.Image image, String name) async {
  await tester.runAsync(() async {
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File('$screenshotOutputDir/$name');
    file.parent.createSync(recursive: true);
    file.writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}

/// Rasterizes the [RepaintBoundary] identified by [key] to a PNG at
/// `build/screenshots/<name>`, at the view's current device pixel ratio.
Future<void> captureToPng(
  WidgetTester tester,
  GlobalKey key,
  String name,
) async {
  final image = await captureBoundaryImage(tester, key);
  try {
    await writePng(tester, image, name);
  } finally {
    image.dispose();
  }
}
