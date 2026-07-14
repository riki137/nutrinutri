// Host-side screenshot harness. Renders key screens to PNGs under
// `build/screenshots/` with no emulator by pumping the real app against a
// seeded in-memory database and rasterizing a RepaintBoundary.
//
// Run:  flutter test test/screenshots/screenshots_test.dart
// Or the wrapper that also copies into the landing site:  tool/screenshots.sh
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nutrinutri/core/db/app_database.dart';
import 'package:nutrinutri/core/providers.dart';
import 'package:nutrinutri/core/router.dart';
import 'package:nutrinutri/core/utils/platform_helper.dart';
import 'package:nutrinutri/features/logging/presentation/add_entry_controller.dart';
import 'package:nutrinutri/main.dart';

import 'capture.dart';
import 'seed_data.dart';

// A single database + provider container is shared across every shot. This is
// deliberate: `SyncService` builds a `GoogleSignIn`, whose global parameters can
// only be initialized once per process, so a fresh container per test would
// throw on the second construction. The seeded data is read-only for the
// screenshots, so sharing is safe.
late AppDatabase _db;
late ProviderContainer _container;

void main() {
  setUpAll(() async {
    // Text must render in the bundled Outfit font, never fetched over the wire.
    GoogleFonts.config.allowRuntimeFetching = false;
    // Register icon fonts etc. that `flutter test` otherwise leaves unloaded.
    await loadAppFonts();
    _db = await buildSeededDb();
    _container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(_db)],
    );
  });

  tearDownAll(() async {
    _container.dispose();
    await _db.close();
  });

  testWidgets('dashboard - phone - light', (tester) async {
    await _shoot(
      tester,
      device: phone,
      brightness: Brightness.light,
      route: '/',
      out: 'android-screenshot-home.png',
    );
  });

  testWidgets('dashboard - phone - dark', (tester) async {
    await _shoot(
      tester,
      device: phone,
      brightness: Brightness.dark,
      route: '/',
      out: 'android-screenshot-home-dark.png',
    );
  });

  testWidgets('add entry - phone - light', (tester) async {
    await _shoot(
      tester,
      device: phone,
      brightness: Brightness.light,
      route: '/add-entry?type=food',
      out: 'android-screenshot-add.png',
      foodPhoto: File('test/assets/bun_bo_nam_bo.jpg'),
    );
  });

  testWidgets('add entry - phone - dark', (tester) async {
    await _shoot(
      tester,
      device: phone,
      brightness: Brightness.dark,
      route: '/add-entry?type=food',
      out: 'android-screenshot-add-dark.png',
      foodPhoto: File('test/assets/bun_bo_nam_bo.jpg'),
    );
  });

  testWidgets('settings - phone - light', (tester) async {
    await _shoot(
      tester,
      device: phone,
      brightness: Brightness.light,
      route: '/settings',
      out: 'android-screenshot-settings.png',
    );
  });

  testWidgets('settings - phone - dark', (tester) async {
    await _shoot(
      tester,
      device: phone,
      brightness: Brightness.dark,
      route: '/settings',
      out: 'android-screenshot-settings-dark.png',
    );
  });

  testWidgets('dashboard - desktop - light', (tester) async {
    await _shoot(
      tester,
      device: desktop,
      brightness: Brightness.light,
      route: '/',
      out: 'macos-screenshot.png',
    );
  });

  testWidgets('dashboard - desktop - dark', (tester) async {
    await _shoot(
      tester,
      device: desktop,
      brightness: Brightness.dark,
      route: '/',
      out: 'macos-screenshot-dark.png',
    );
  });
}

Future<void> _shoot(
  WidgetTester tester, {
  required DeviceProfile device,
  required Brightness brightness,
  required String route,
  required String out,
  File? foodPhoto,
}) async {
  tester.view.physicalSize = device.physical;
  tester.view.devicePixelRatio = device.dpr;
  tester.platformDispatcher.platformBrightnessTestValue = brightness;
  PlatformHelper.debugIsDesktopOrWebOverride = device.desktop;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
    tester.platformDispatcher.clearPlatformBrightnessTestValue();
    PlatformHelper.debugIsDesktopOrWebOverride = null;
  });

  // `flutter test` defaults `debugDisableShadows` to true, which paints every
  // elevation shadow as a solid black shape (ugly hard borders around FABs,
  // cards, etc.). Render real blurred shadows so the shots match the running
  // app. It must be reset before the test body returns (not via addTearDown,
  // which runs after the framework's paint-debug-var invariant check), so the
  // whole body is wrapped in try/finally.
  debugDisableShadows = false;
  try {
    final boundaryKey = GlobalKey();
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: _container,
        child: RepaintBoundary(key: boundaryKey, child: const MyApp()),
      ),
    );
    await _settle(tester);

    // Always navigate (even to '/') so the shared router lands on this shot's
    // route regardless of where the previous shot left it.
    _container.read(routerProvider).go(route);
    await _settle(tester);

    if (foodPhoto != null) {
      // Warm the image cache with the decoded photo FIRST (real file I/O +
      // decoding can't happen under the fake-async zone), then inject it into
      // the AI wizard. When the wizard rebuilds, its `FileImage` resolves
      // straight from the warm cache and paints immediately instead of blank.
      await _precacheFileImage(tester, foodPhoto);
      _container
          .read(addEntryControllerProvider.notifier)
          .debugSetImage(foodPhoto);
      await _settle(tester);
    }

    // Pump on the real event loop so file-image decoding and any other real
    // async work actually completes and paints before capture. This is the only
    // place images like the food photo get decoded — the fake-async zone used
    // by the plain `_settle` pumps never resolves real file I/O.
    await _realAsyncSettle(tester);

    await captureToPng(tester, boundaryKey, out);
  } finally {
    debugDisableShadows = true;
  }
}

/// Decodes [file] on the real event loop and inserts it into the global image
/// cache under the exact key a `FileImage(file)` will look up, so a later build
/// of that provider gets a synchronous cache hit and paints without any async.
Future<void> _precacheFileImage(WidgetTester tester, File file) async {
  await tester.runAsync(() async {
    final provider = FileImage(file);
    final key = await provider.obtainKey(ImageConfiguration.empty);
    final bytes = await file.readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    PaintingBinding.instance.imageCache.putIfAbsent(
      key,
      () => OneFrameImageStreamCompleter(
        Future.value(ImageInfo(image: frame.image)),
      ),
    );
  });
}

/// Pumps a few frames on the *real* event loop so any remaining real async work
/// completes and is painted before capture.
Future<void> _realAsyncSettle(WidgetTester tester) async {
  await tester.runAsync(() async {
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 120));
    }
  });
}

/// Pumps enough frames for async DB reads, bundled-font loading, and one-shot
/// entrance animations to complete. `pumpAndSettle` is avoided because some
/// widgets animate indefinitely.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 250));
  }
}
