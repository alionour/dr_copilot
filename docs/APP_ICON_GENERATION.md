# App Icon Generation Instructions

To generate app icons for all platforms using the Dr Copilot logo:

1. Export your SVG logo as PNGs at the following sizes (using Inkscape, Figma, or an online converter):
   - 1024x1024 (for iOS, Windows, Play Store)
   - 512x512 (Play Store)
   - 192x192, 144x144, 96x96, 72x72, 48x48 (Android mipmaps)
   - Save them in: `assets/png/app_icon/1024/app_icon.png` (and other sizes as needed)

2. Add the following to your `flutter_launcher_icons.yaml`:

```yaml
flutter_icons:
  android: true
  ios: true
  windows:
    generate: true
    image_path: "assets/png/app_icon/1024/app_icon.png"
  image_path: "assets/png/app_icon/1024/app_icon.png"
  adaptive_icon_background: "#ffffff"
  adaptive_icon_foreground: "assets/png/app_icon/1024/app_icon.png"
```

3. Add `flutter_launcher_icons` to your `dev_dependencies` in `pubspec.yaml`:

```yaml
dev_dependencies:
  flutter_launcher_icons: ^0.13.1
```

4. Run the following commands in your terminal:

```powershell
flutter pub get
flutter pub run flutter_launcher_icons
```

This will generate the app icons for Android, iOS, and Windows platforms automatically.
