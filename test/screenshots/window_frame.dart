import 'package:flutter/widgets.dart';

/// Which OS's window chrome to draw around a captured screenshot.
enum WindowChrome { macos, gnome }

/// Draws native-looking window chrome (titlebar, window controls, rounded
/// corners, shadow) around [child], which should be the already-captured app
/// content painted at [contentSize] logical pixels.
///
/// Sizing contract: the widget's own size is
/// `contentSize + Offset(0, titlebarHeight(chrome)) + margin(chrome)`
/// (the shadow/corner margin is transparent padding around the framed
/// window). Callers must size the test view to exactly that before pumping
/// this widget, then capture the whole tree.
class WindowFrame extends StatelessWidget {
  const WindowFrame({
    super.key,
    required this.chrome,
    required this.brightness,
    required this.contentSize,
    this.title = 'NutriNutri',
    this.macTitleFamily = 'SF Pro',
    required this.child,
  });

  final WindowChrome chrome;
  final Brightness brightness;
  final Size contentSize;
  final String title;

  /// Font family used for the macOS titlebar text. Falls back to whatever is
  /// registered under this name (bundled 'SF Pro' when available on the host,
  /// else the test harness should register 'Adwaita Sans' under this name).
  final String macTitleFamily;

  final Widget child;

  /// Transparent margin around the window (shadow + corner clearance) that
  /// callers must add to the view size on top of [contentSize] + titlebar.
  static EdgeInsets margin(WindowChrome chrome) => switch (chrome) {
    WindowChrome.macos => const EdgeInsets.fromLTRB(60, 40, 60, 80),
    WindowChrome.gnome => const EdgeInsets.all(24),
  };

  /// Height of the titlebar/headerbar sitting above [contentSize].
  static double titlebarHeight(WindowChrome chrome) => switch (chrome) {
    WindowChrome.macos => 32,
    WindowChrome.gnome => 46,
  };

  bool get _dark => brightness == Brightness.dark;

  @override
  Widget build(BuildContext context) {
    final windowSize = Size(
      contentSize.width,
      contentSize.height + titlebarHeight(chrome),
    );
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Padding(
        padding: margin(chrome),
        child: SizedBox(
          width: windowSize.width,
          height: windowSize.height,
          child: switch (chrome) {
            WindowChrome.macos => _MacWindow(
              size: windowSize,
              dark: _dark,
              title: title,
              titleFamily: macTitleFamily,
              child: child,
            ),
            WindowChrome.gnome => _GnomeWindow(
              size: windowSize,
              dark: _dark,
              title: title,
              child: child,
            ),
          },
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// macOS 27 "Golden Gate" (released 2026-09-14).
//
// Geometry measured with AppKit (NSWindow / standardWindowButton frames,
// _cornerRadius) on macOS 26.6, which matches the macOS 27 reference
// screenshots pixel-for-pixel at 2x:
// https://pbs.twimg.com/media/HP8W-9FXMAAwLtv.png (light)
// https://pbs.twimg.com/media/HP8W_OPXgAA95Ev.png (dark)
// Traffic-light gradient stops were sampled from those same reference
// screenshots (Aqua-style redesign in beta 6, see
// https://daringfireball.net/linked/2026/08/18/golden-gate-27-window-controls).
// ---------------------------------------------------------------------------

const double _macTitlebarHeight = 32;
const double _macCornerRadius = 16;

const Color _macLightBg = Color(0xFFFFFFFF);
const Color _macDarkBg = Color(0xFF1E1E1E);
const Color _macLightSeparator = Color(0x19000000);
const Color _macDarkSeparator = Color(0x19FFFFFF);
const Color _macLightLabel = Color(0xD9000000);
const Color _macDarkLabel = Color(0xD9FFFFFF);
const Color _macLightOuterStroke = Color(0x1F000000);
const Color _macDarkOuterStroke = Color(0x80000000);
const Color _macDarkInnerStroke = Color(0x1AFFFFFF);

class _TrafficLightSpec {
  const _TrafficLightSpec({
    required this.lightTop,
    required this.lightBottom,
    required this.lightRim,
    required this.darkTop,
    required this.darkBottom,
    required this.darkRim,
  });

  final Color lightTop;
  final Color lightBottom;
  final Color lightRim;
  final Color darkTop;
  final Color darkBottom;
  final Color darkRim;
}

const _macClose = _TrafficLightSpec(
  lightTop: Color(0xFFEB766A),
  lightBottom: Color(0xFFE59188),
  lightRim: Color(0x14000000),
  darkTop: Color(0xFFE5695B),
  darkBottom: Color(0xFFDF7065),
  darkRim: Color(0xFFFFA095),
);
const _macMinimize = _TrafficLightSpec(
  lightTop: Color(0xFFF0BC4F),
  lightBottom: Color(0xFFF6D463),
  lightRim: Color(0x14000000),
  darkTop: Color(0xFFF0B500),
  darkBottom: Color(0xFFF6D054),
  darkRim: Color(0xFFFFDE62),
);
const _macZoom = _TrafficLightSpec(
  lightTop: Color(0xFF7ECD4B),
  lightBottom: Color(0xFFA4D785),
  lightRim: Color(0x14000000),
  darkTop: Color(0xFF55BC00),
  darkBottom: Color(0xFF70C150),
  darkRim: Color(0xFF9BEC75),
);

class _MacWindow extends StatelessWidget {
  const _MacWindow({
    required this.size,
    required this.dark,
    required this.title,
    required this.titleFamily,
    required this.child,
  });

  final Size size;
  final bool dark;
  final String title;
  final String titleFamily;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final bg = dark ? _macDarkBg : _macLightBg;
    final separator = dark ? _macDarkSeparator : _macLightSeparator;
    final label = dark ? _macDarkLabel : _macLightLabel;

    return DecoratedBox(
      // Outer stroke + shadow live outside the clip, so they aren't cut by
      // the rounded-corner clip below.
      decoration: ShapeDecoration(
        shape: RoundedSuperellipseBorder(
          borderRadius: BorderRadius.circular(_macCornerRadius),
          side: BorderSide(
            width: 0.5,
            color: dark ? _macDarkOuterStroke : _macLightOuterStroke,
          ),
        ),
        shadows: const [
          BoxShadow(
            color: Color(0x59000000),
            offset: Offset(0, 18),
            blurRadius: 50,
          ),
          BoxShadow(color: Color(0x26000000), blurRadius: 3),
        ],
      ),
      child: ClipRSuperellipse(
        borderRadius: BorderRadius.circular(_macCornerRadius),
        child: SizedBox(
          width: size.width,
          height: size.height,
          child: DecoratedBox(
            // Dark mode gets an extra 0.5pt inner hairline stroke.
            decoration: BoxDecoration(
              border: dark
                  ? Border.all(width: 0.5, color: _macDarkInnerStroke)
                  : null,
            ),
            child: Column(
              // Without this, Column's default center cross-axis alignment
              // shrink-wraps the titlebar row to its Stack's only
              // non-positioned child (the title Text) instead of the full
              // window width, squeezing the traffic lights into the title.
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: _macTitlebarHeight,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: bg,
                      border: Border(
                        bottom: BorderSide(width: 0.5, color: separator),
                      ),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontFamily: titleFamily,
                            fontVariations: const [
                              FontVariation('wght', 590),
                              FontVariation('opsz', 17),
                            ],
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: label,
                          ),
                        ),
                        Positioned(
                          left: 9,
                          top: 9,
                          child: Row(
                            children: [
                              _TrafficLight(spec: _macClose, dark: dark),
                              const SizedBox(width: 8),
                              _TrafficLight(spec: _macMinimize, dark: dark),
                              const SizedBox(width: 8),
                              _TrafficLight(spec: _macZoom, dark: dark),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(child: child),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TrafficLight extends StatelessWidget {
  const _TrafficLight({required this.spec, required this.dark});

  final _TrafficLightSpec spec;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: const [0.3, 0.9],
          colors: dark
              ? [spec.darkTop, spec.darkBottom]
              : [spec.lightTop, spec.lightBottom],
        ),
        border: Border.all(
          width: 0.5,
          color: dark ? spec.darkRim : spec.lightRim,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// GNOME 50 (libadwaita 1.9.4). Values taken from the libadwaita stylesheet:
// https://gitlab.gnome.org/GNOME/libadwaita/-/blob/libadwaita-1-9/src/stylesheet/_colors.scss
// https://gitlab.gnome.org/GNOME/libadwaita/-/blob/libadwaita-1-9/src/stylesheet/widgets/_header-bar.scss
// https://gitlab.gnome.org/GNOME/libadwaita/-/blob/libadwaita-1-9/src/stylesheet/widgets/_window.scss
// https://gitlab.gnome.org/GNOME/libadwaita/-/blob/libadwaita-1-9/src/stylesheet/_common.scss
// Close icon path matches gnome-50's window-close-symbolic.svg (an X from
// (4,4) to (12,12) in a 16px icon, 2px-wide arms).
// ---------------------------------------------------------------------------

const double _gnomeHeaderbarHeight = 46;
const double _gnomeWindowRadius = 15;

const Color _gnomeLightBg = Color(0xFFFFFFFF);
const Color _gnomeDarkBg = Color(0xFF2E2E32);
const Color _gnomeLightFg = Color(0xCC000006);
const Color _gnomeDarkFg = Color(0xFFFFFFFF);
const Color _gnomeLightShade = Color(0x0F000006);
const Color _gnomeDarkShade = Color(0x2E000006);
const Color _gnomeLightButton = Color(0x14000006);
const Color _gnomeDarkButton = Color(0x1AFFFFFF);
const Color _gnomeOutline = Color(0x12FFFFFF);

class _GnomeWindow extends StatelessWidget {
  const _GnomeWindow({
    required this.size,
    required this.dark,
    required this.title,
    required this.child,
  });

  final Size size;
  final bool dark;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final bg = dark ? _gnomeDarkBg : _gnomeLightBg;
    final fg = dark ? _gnomeDarkFg : _gnomeLightFg;
    final shade = dark ? _gnomeDarkShade : _gnomeLightShade;
    final buttonFill = dark ? _gnomeDarkButton : _gnomeLightButton;

    return Container(
      width: size.width,
      height: size.height,
      foregroundDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_gnomeWindowRadius),
        border: Border.all(width: 1, color: _gnomeOutline),
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_gnomeWindowRadius),
        boxShadow: const [
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 14,
            spreadRadius: 5,
          ),
          BoxShadow(color: Color(0x1A000000), blurRadius: 5, spreadRadius: 2),
          BoxShadow(color: Color(0x0D000000), spreadRadius: 1),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_gnomeWindowRadius),
        child: Stack(
          children: [
            // Content painted first so the headerbar's drop shadow (painted
            // after, below) shows on top of it instead of being covered.
            Positioned(
              left: 0,
              right: 0,
              top: _gnomeHeaderbarHeight,
              bottom: 0,
              child: child,
            ),
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              height: _gnomeHeaderbarHeight,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: bg,
                  boxShadow: [
                    BoxShadow(color: shade, offset: const Offset(0, 1)),
                    BoxShadow(
                      color: shade,
                      offset: const Offset(0, 2),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontFamily: 'Adwaita Sans',
                        fontVariations: const [FontVariation('wght', 700)],
                        fontWeight: FontWeight.w700,
                        fontSize: 14.667,
                        color: fg,
                      ),
                    ),
                    Positioned(
                      right: 7,
                      top: (_gnomeHeaderbarHeight - 24) / 2,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: buttonFill,
                        ),
                        child: CustomPaint(
                          painter: _CloseIconPainter(color: fg),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Paints the `window-close-symbolic` X (an X from (4,4) to (12,12) in a
/// 16px icon, 2px-wide arms), centered in whatever box this is painted into.
class _CloseIconPainter extends CustomPainter {
  const _CloseIconPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final offset = Alignment.center.alongSize(size) - const Offset(8, 8);
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.square;
    canvas.drawLine(offset + const Offset(5, 5), offset + const Offset(11, 11), paint);
    canvas.drawLine(offset + const Offset(11, 5), offset + const Offset(5, 11), paint);
  }

  @override
  bool shouldRepaint(covariant _CloseIconPainter oldDelegate) =>
      oldDelegate.color != color;
}
