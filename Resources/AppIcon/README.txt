App icon pipeline
=================

Recommended source format:

  AppIcon.appiconset

Fallback source formats:

  AppIcon.iconset
  AppIcon.icns

Build/package script:

  Scripts/package_mac_app.sh

What the script now does:

1) Reads icon source in this order:
  - APPICON_APPICONSET_PATH
  - Resources/AppIcon/AppIcon.appiconset
   - APPICON_ICONSET_PATH
   - Resources/AppIcon/AppIcon.iconset
   - APPICON_ICNS_PATH
   - Resources/AppIcon/AppIcon.icns

2) If appiconset is used and actool is available, compiles an asset catalog.

3) Otherwise, normalizes icon visual scale (adds transparent margin to avoid an oversized Dock look).

4) Rebuilds AppIcon.icns and embeds it into JobTracker.app/Contents/Resources/AppIcon.icns (fallback flow).

Tuning visual size:

  APPICON_CONTENT_SCALE=0.82 ./Scripts/package_mac_app.sh

- Lower scale => more transparent padding => icon appears smaller in Dock/Finder.
- Range: (0, 1], default: 0.82.

Control actool usage:

  APPICON_USE_ACTOOL=always|auto|never ./Scripts/package_mac_app.sh

Optional dark icon override source:

  APPICON_DARK_ICNS_PATH=/path/to/icon-dark.icns ./Scripts/package_mac_app.sh

Note on light/dark:

When appiconset + actool is used, light/dark icon variants can be expressed in your
asset catalog source. In fallback mode, one AppIcon.icns is packaged per build.

For manual in-app icon mode switching, packaging also writes optional files when available:
- AppIconLight.icns
- AppIconDark.icns
