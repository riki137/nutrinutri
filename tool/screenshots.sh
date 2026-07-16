#!/usr/bin/env bash
#
# Regenerates the app screenshots and copies them into the landing site.
#
# Renders the key screens (dashboard, add-entry, settings) for phone and
# desktop, in light and dark themes, with no emulator — see
# test/screenshots/screenshots_test.dart. Output PNGs land in build/screenshots/
# and the canonical set is copied into landing/public/img/.
#
# Usage:  bash tool/screenshots.sh
set -euo pipefail

cd "$(dirname "$0")/.."

OUT_DIR="build/screenshots"
LANDING_DIR="landing/public/img"

echo "==> Rendering screenshots (flutter test)"
flutter test test/screenshots/screenshots_test.dart

echo "==> Copying into $LANDING_DIR"
mkdir -p "$LANDING_DIR"
for png in \
  android-screenshot-home.png \
  android-screenshot-home-dark.png \
  android-screenshot-add.png \
  android-screenshot-add-dark.png \
  android-screenshot-settings.png \
  android-screenshot-settings-dark.png \
  macos-screenshot.png \
  macos-screenshot-dark.png; do
  if [[ -f "$OUT_DIR/$png" ]]; then
    cp "$OUT_DIR/$png" "$LANDING_DIR/$png"
    echo "    $png"
  else
    echo "    WARNING: $OUT_DIR/$png missing" >&2
  fi
done

echo "==> Done. Screenshots in $OUT_DIR and $LANDING_DIR"
