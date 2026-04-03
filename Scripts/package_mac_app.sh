#!/usr/bin/env bash
set -euo pipefail

# Build release, compile AppIcon (light + dark) from Resources/Assets.xcassets,
# assemble JobTracker.app, and zip for local testing or release upload.
# Usage: from repo root — ./Scripts/package_mac_app.sh

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

APP_NAME="JobTracker"
# Change this to your reverse-DNS id before App Store or notarized distribution.
BUNDLE_ID="io.github.jobtracker.JobTracker"
VERSION="1.0.0"
MIN_OS="14.0"

ASSETS="$ROOT/Resources/Assets.xcassets"
APPICON_DIR="$ASSETS/AppIcon.appiconset"
LIGHT_TEMPLATE="$ROOT/Resources/JobTracker-Light.iconset"

if [[ ! -d "$ASSETS" ]]; then
  echo "error: Missing $ASSETS — add AppIcon.appiconset under Resources/Assets.xcassets"
  exit 1
fi

echo "==> Verifying AppIcon.appiconset files match Contents.json..."
export APPICON_DIR
python3 <<'PY' || exit 1
import json, os, sys
root = os.environ["APPICON_DIR"]
jpath = os.path.join(root, "Contents.json")
with open(jpath) as f:
    data = json.load(f)
missing = []
for im in data.get("images", []):
    fn = im.get("filename")
    if not fn:
        continue
    p = os.path.join(root, fn)
    if not os.path.isfile(p):
        missing.append(fn)
if missing:
    print("error: missing PNG(s) for AppIcon:", ", ".join(missing), file=sys.stderr)
    sys.exit(1)
print("     OK:", len(data["images"]), "image slots, all files on disk.")
PY

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

echo "==> Compiling asset catalog (AppIcon + light/dark)..."
ACTOOL_OUT="$(mktemp -d)"
ACTOOL_LOG="$(mktemp)"
trap 'rm -rf "$ACTOOL_OUT" "$ACTOOL_LOG"' EXIT
PARTIAL="$ACTOOL_OUT/partial.plist"

# actool often returns non-zero on some macOS builds when dyld prints loader noise to stderr,
# even though AppIcon.icns and Assets.car are written. Treat success by output files, not exit code.
set +e
xcrun actool "$ASSETS" \
  --compile "$ACTOOL_OUT" \
  --platform macosx \
  --minimum-deployment-target "$MIN_OS" \
  --app-icon AppIcon \
  --output-partial-info-plist "$PARTIAL" \
  >"$ACTOOL_LOG" 2>&1
ACTOOL_EXIT=$?
set -e

HAVE_ICNS=0
HAVE_CAR=0
[[ -f "$ACTOOL_OUT/AppIcon.icns" ]] && HAVE_ICNS=1
[[ -f "$ACTOOL_OUT/Assets.car" ]] && HAVE_CAR=1

if [[ "$HAVE_ICNS" -eq 1 && "$HAVE_CAR" -eq 1 ]]; then
  if [[ "$ACTOOL_EXIT" -ne 0 ]]; then
    echo "     note: actool exited with $ACTOOL_EXIT but wrote icons (ignoring dyld noise on this OS)."
  fi
  cp "$ACTOOL_OUT/AppIcon.icns" "$RESOURCES/"
  cp "$ACTOOL_OUT/Assets.car" "$RESOURCES/"
  echo "     Embedded AppIcon.icns + Assets.car (light + dark)."
elif [[ "$HAVE_ICNS" -eq 1 ]]; then
  cp "$ACTOOL_OUT/AppIcon.icns" "$RESOURCES/"
  echo "     warning: Assets.car missing; copied AppIcon.icns only."
else
  echo "==> actool did not produce AppIcon.icns; falling back to iconutil (light appearance only)..."
  if [[ "$ACTOOL_EXIT" -ne 0 ]] && [[ -s "$ACTOOL_LOG" ]]; then
    echo "--- actool log (last lines) ---"
    tail -n 5 "$ACTOOL_LOG" || true
    echo "---"
  fi
  FALLBACK_ICONSET="$(mktemp -d)/JobTracker.iconset"
  mkdir -p "$FALLBACK_ICONSET"
  cp "$LIGHT_TEMPLATE/Contents.json" "$FALLBACK_ICONSET/"
  for f in \
    icon_16x16.png icon_16x16@2x.png \
    icon_32x32.png icon_32x32@2x.png \
    icon_128x128.png icon_128x128@2x.png \
    icon_256x256.png icon_256x256@2x.png \
    icon_512x512.png icon_512x512@2x.png \
  ; do
    cp "$APPICON_DIR/$f" "$FALLBACK_ICONSET/"
  done
  iconutil -c icns "$FALLBACK_ICONSET" -o "$RESOURCES/AppIcon.icns"
  rm -rf "$(dirname "$FALLBACK_ICONSET")"
  echo "     Embedded AppIcon.icns from JobTracker-Light.iconset (no dark variant in bundle)."
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
  <key>CFBundleIconFile</key>
  <string>AppIcon</string>
  <key>CFBundleIconName</key>
  <string>AppIcon</string>
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
echo "    Or unzip the zip elsewhere, then open JobTracker.app"
