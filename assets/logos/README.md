Place source artwork for launcher icons here.

- Preferred filename used by the repo: `app_icon_rounded.png`
- Recommended size: 1024×1024 (PNG)
- Keep a source (Figma/SVG) for future edits.

To regenerate icons:

1. Edit `pubspec.yaml` if you need to change the source image path.
2. Run `flutter pub get`.
3. Run `flutter pub run flutter_launcher_icons:main`.

Notes:

- For App Store submission, you should avoid alpha (transparency) in icons. Set `remove_alpha_ios: true` in `flutter_icons` in `pubspec.yaml` before generating.
- This repo commits generated icons into platform folders so they are versioned.
