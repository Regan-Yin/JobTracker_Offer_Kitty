#!/usr/bin/env bash
set -euo pipefail

# Build release, normalize icon visual scale, then embed AppIcon.icns into the bundle.
#
# Input priority:
# 1) AppIcon.appiconset (asset catalog via actool, Cursor-like workflow)
# 2) APPICON_ICONSET_PATH=/path/to/AppIcon.iconset
# 3) APPICON_ICNS_PATH=/path/to/icon.icns
# 4) Resources/AppIcon/AppIcon.icns
#
# Visual size tuning:
#   APPICON_CONTENT_SCALE=0.82 ./Scripts/package_mac_app.sh
# A lower value adds more transparent margin so the icon appears less "zoomed in" in Dock/Finder.

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

APP_NAME="JobTracker"
BUNDLE_ID="io.github.jobtracker.JobTracker"
VERSION="1.0.0"
MIN_OS="14.0"

DEFAULT_ICON="$ROOT/Resources/AppIcon/AppIcon.icns"
DEFAULT_DARK_ICON="$ROOT/Resources/AppIcon/AppIcon-dark.icns"
DEFAULT_ICONSET="$ROOT/Resources/AppIcon/AppIcon.iconset"
DEFAULT_APPICONSET="$ROOT/Resources/AppIcon/AppIcon.appiconset"
ICONSET_SRC="${APPICON_ICONSET_PATH:-$DEFAULT_ICONSET}"
ICON_SRC="${APPICON_ICNS_PATH:-$DEFAULT_ICON}"
ICON_DARK_SRC="${APPICON_DARK_ICNS_PATH:-$DEFAULT_DARK_ICON}"
STATIC_LIGHT_ICON_SRC="${APPICON_STATIC_LIGHT_ICNS_PATH:-$DEFAULT_ICON}"
APPICONSET_SRC="${APPICON_APPICONSET_PATH:-$DEFAULT_APPICONSET}"
CONTENT_SCALE="${APPICON_CONTENT_SCALE:-0.82}"
USE_ACTOOL="${APPICON_USE_ACTOOL:-auto}"
NORMALIZER_SCRIPT="$ROOT/Scripts/normalize_iconset.swift"

if [[ ! -f "$NORMALIZER_SCRIPT" ]]; then
  echo "error: Missing icon normalizer script: $NORMALIZER_SCRIPT"
  exit 1
fi

if [[ ! -f "$STATIC_LIGHT_ICON_SRC" ]]; then
  echo "error: Missing static light icon source: $STATIC_LIGHT_ICON_SRC"
  echo "       Set APPICON_STATIC_LIGHT_ICNS_PATH or place Resources/AppIcon/AppIcon.icns"
  exit 1
fi

if [[ "$USE_ACTOOL" != "auto" && "$USE_ACTOOL" != "always" && "$USE_ACTOOL" != "never" ]]; then
  echo "error: APPICON_USE_ACTOOL must be one of: auto, always, never"
  exit 1
fi

ACTOOL_AVAILABLE=0
if command -v xcrun >/dev/null 2>&1 && xcrun --find actool >/dev/null 2>&1; then
  ACTOOL_AVAILABLE=1
fi

if [[ -d "$APPICONSET_SRC" ]]; then
  if [[ "$USE_ACTOOL" == "never" ]]; then
    echo "==> Found appiconset but APPICON_USE_ACTOOL=never, skipping asset-catalog build."
  elif [[ "$ACTOOL_AVAILABLE" -eq 1 ]]; then
    ICON_INPUT_KIND="appiconset"
    ICON_INPUT_PATH="$APPICONSET_SRC"
  elif [[ "$USE_ACTOOL" == "always" ]]; then
    echo "error: APPICON_USE_ACTOOL=always but actool was not found (install Xcode tools)."
    exit 1
  fi
fi

if [[ -z "${ICON_INPUT_KIND:-}" && -d "$ICONSET_SRC" ]]; then
  ICON_INPUT_KIND="iconset"
  ICON_INPUT_PATH="$ICONSET_SRC"
elif [[ -z "${ICON_INPUT_KIND:-}" && -f "$ICON_SRC" ]]; then
  ICON_INPUT_KIND="icns"
  ICON_INPUT_PATH="$ICON_SRC"
fi

if [[ "$USE_ACTOOL" == "always" && "${ICON_INPUT_KIND:-}" != "appiconset" ]]; then
  echo "error: APPICON_USE_ACTOOL=always requires a valid appiconset source."
  echo "       Looked for: $APPICONSET_SRC"
  exit 1
fi

if [[ -z "${ICON_INPUT_KIND:-}" ]]; then
  if [[ "$USE_ACTOOL" == "auto" && -d "$APPICONSET_SRC" && "$ACTOOL_AVAILABLE" -ne 1 ]]; then
    echo "warning: AppIcon.appiconset found, but actool is unavailable. Falling back to iconset/icns."
  fi
fi

if [[ -z "${ICON_INPUT_KIND:-}" ]]; then
  ICON_INPUT_KIND="missing"
fi

if [[ "$ICON_INPUT_KIND" == "missing" ]]; then
  echo "error: Missing app icon source."
  echo "       Looked for appiconset: $APPICONSET_SRC"
  echo "       Looked for iconset:    $ICONSET_SRC"
  echo "       Looked for icns:       $ICON_SRC"
  echo "       Provide APPICON_APPICONSET_PATH, APPICON_ICONSET_PATH, or APPICON_ICNS_PATH."
  exit 1
fi

if [[ "$ICON_INPUT_KIND" == "appiconset" ]]; then
  echo "==> Using icon source (appiconset): $ICON_INPUT_PATH"
  echo "==> Icon pipeline: asset catalog (actool)"
else
  echo "==> Using icon source ($ICON_INPUT_KIND): $ICON_INPUT_PATH"
  echo "==> Icon content scale: $CONTENT_SCALE"
  echo "==> Icon pipeline: normalized icns"
fi

echo "==> Building release..."
swift build -c release --product "$APP_NAME"

BIN="$ROOT/.build/release/$APP_NAME"
DIST="$ROOT/dist"
APP_PATH="$DIST/${APP_NAME}.app"
CONTENTS="$APP_PATH/Contents"
MACOS_DIR="$CONTENTS/MacOS"
RESOURCES="$CONTENTS/Resources"

rm -rf "$APP_PATH"
mkdir -p "$MACOS_DIR" "$RESOURCES"

cp "$BIN" "$MACOS_DIR/$APP_NAME"
chmod +x "$MACOS_DIR/$APP_NAME"

WORK_DIR="$(mktemp -d)"
trap 'rm -rf "$WORK_DIR"' EXIT

# Static outer app icon: always keep a light icon for Finder and app bundle representation.
STATIC_LIGHT_ICONSET="$WORK_DIR/AppIconStaticLight.iconset"
STATIC_LIGHT_ICNS="$WORK_DIR/AppIconStaticLight.icns"
iconutil -c iconset "$STATIC_LIGHT_ICON_SRC" -o "$STATIC_LIGHT_ICONSET"
swift "$NORMALIZER_SCRIPT" --iconset "$STATIC_LIGHT_ICONSET" --content-scale "$CONTENT_SCALE"
iconutil -c icns "$STATIC_LIGHT_ICONSET" -o "$STATIC_LIGHT_ICNS"
cp "$STATIC_LIGHT_ICNS" "$RESOURCES/AppIcon.icns"
cp "$STATIC_LIGHT_ICNS" "$RESOURCES/AppIconLight.icns"

if [[ "$ICON_INPUT_KIND" == "appiconset" ]]; then
  XCASSETS_DIR="$WORK_DIR/AppIcons.xcassets"
  mkdir -p "$XCASSETS_DIR"
  cp -R "$ICON_INPUT_PATH" "$XCASSETS_DIR/AppIcon.appiconset"

  echo "==> Compiling app icon asset catalog..."
  xcrun actool \
    --compile "$RESOURCES" \
    --platform macosx \
    --minimum-deployment-target "$MIN_OS" \
    --app-icon AppIcon \
    --output-partial-info-plist "$WORK_DIR/asset-info.plist" \
    "$XCASSETS_DIR"

else
  WORK_ICONSET="$WORK_DIR/AppIcon.iconset"
  WORK_ICNS="$WORK_DIR/AppIcon.icns"

  if [[ "$ICON_INPUT_KIND" == "iconset" ]]; then
    echo "==> Preparing iconset source..."
    cp -R "$ICON_INPUT_PATH" "$WORK_ICONSET"
  else
    echo "==> Expanding icns to iconset..."
    iconutil -c iconset "$ICON_INPUT_PATH" -o "$WORK_ICONSET"
  fi

  echo "==> Normalizing icon visual scale..."
  swift "$NORMALIZER_SCRIPT" --iconset "$WORK_ICONSET" --content-scale "$CONTENT_SCALE"

  echo "==> Rebuilding AppIcon.icns..."
  iconutil -c icns "$WORK_ICONSET" -o "$WORK_ICNS"
  cp "$WORK_ICNS" "$RESOURCES/AppIconRuntime.icns"
fi

# Optional explicit dark icon file for manual in-app dark override.
# Process with the same normalization pipeline so light/dark icons keep matching visual scale.
if [[ -f "$ICON_DARK_SRC" ]]; then
  DARK_ICONSET="$WORK_DIR/AppIconDark.iconset"
  DARK_ICNS="$WORK_DIR/AppIconDark.icns"
  iconutil -c iconset "$ICON_DARK_SRC" -o "$DARK_ICONSET"
  swift "$NORMALIZER_SCRIPT" --iconset "$DARK_ICONSET" --content-scale "$CONTENT_SCALE"
  iconutil -c icns "$DARK_ICONSET" -o "$DARK_ICNS"
  cp "$DARK_ICNS" "$RESOURCES/AppIconDark.icns"
fi

PLIST="$CONTENTS/Info.plist"
cat > "$PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key>
  <string>en</string>
  <key>CFBundleExecutable</key>
  <string>${APP_NAME}</string>
  <key>CFBundleIdentifier</key>
  <string>${BUNDLE_ID}</string>
  <key>CFBundleInfoDictionaryVersion</key>
  <string>6.0</string>
  <key>CFBundleName</key>
  <string>${APP_NAME}</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>${VERSION}</string>
  <key>CFBundleVersion</key>
  <string>1</string>
EOF

cat >> "$PLIST" <<EOF
  <key>CFBundleIconFile</key>
  <string>AppIcon</string>
EOF

cat >> "$PLIST" <<EOF
  <key>LSMinimumSystemVersion</key>
  <string>${MIN_OS}</string>
  <key>NSHighResolutionCapable</key>
  <true/>
  <key>NSPrincipalClass</key>
  <string>NSApplication</string>
</dict>
</plist>
EOF

ZIP_NAME="${APP_NAME}-${VERSION}-macOS.zip"
echo "==> Zipping: $DIST/$ZIP_NAME"
(cd "$DIST" && rm -f "$ZIP_NAME" && zip -r -q "$ZIP_NAME" "${APP_NAME}.app")

echo "==> Done."
echo "    App:  $APP_PATH"
echo "    Zip:  $DIST/$ZIP_NAME"
echo "    Test: open \"$APP_PATH\""
