import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  const int size = 1024;

  // Colors
  final bgLightTeal = img.ColorRgba8(224, 242, 241, 255); // #E0F2F1 light teal
  final strokeTeal = img.ColorRgba8(0, 150, 136, 255);    // #009688 primary teal

  // ==========================================
  // 1. FULL BLEED ICON (For Legacy & iOS & Web)
  // ==========================================
  final fullBleedImage = img.Image(width: size, height: size, numChannels: 4);
  img.fill(fullBleedImage, color: bgLightTeal);

  // Helper to draw reticle
  void drawReticle(img.Image target, {
    required int left,
    required int top,
    required int right,
    required int bottom,
    required int strokeWidth,
    required int cornerLen,
    required int cornerRadius,
    required img.Color strokeColor,
  }) {
    void drawThickLine(int x1, int y1, int x2, int y2) {
      img.drawLine(target, x1: x1, y1: y1, x2: x2, y2: y2, color: strokeColor, thickness: strokeWidth.toDouble(), antialias: true);
      img.fillCircle(target, x: x1, y: y1, radius: strokeWidth ~/ 2, color: strokeColor, antialias: true);
      img.fillCircle(target, x: x2, y: y2, radius: strokeWidth ~/ 2, color: strokeColor, antialias: true);
    }

    void drawCornerArc(int cx, int cy, int startAngle, int endAngle) {
      final rOuter = strokeWidth / 2.0 + cornerRadius;
      final rInner = (cornerRadius - strokeWidth / 2.0).clamp(0.0, 1000.0);
      final rMid = (rOuter + rInner) / 2.0;
      
      // Draw arc using smooth points
      for (double a = startAngle.toDouble(); a <= endAngle.toDouble(); a += 1.0) {
        final rad = a * 3.141592653589793 / 180.0;
        final px = cx + (rMid * (a >= 0 ? 1 : 1) * (a == 90 || a == 270 ? 0 : (a > 90 && a < 270 ? -1 : 1)) * (a == 0 || a == 180 ? 1 : (a == 90 || a == 270 ? 0 : (a > 90 && a < 270 ? -1 : 1)))).round();
      }
      
      // Fill arc region cleanly
      img.fillCircle(target, x: cx, y: cy, radius: rOuter.round(), color: strokeColor, antialias: true);
    }

    // Top-Left (left, top)
    drawThickLine(left + cornerRadius, top, left + cornerLen, top);
    drawThickLine(left, top + cornerRadius, left, top + cornerLen);
    img.fillCircle(target, x: left + cornerRadius, y: top + cornerRadius, radius: strokeWidth ~/ 2 + cornerRadius, color: strokeColor, antialias: true);
    img.fillCircle(target, x: left + cornerRadius, y: top + cornerRadius, radius: (cornerRadius - strokeWidth ~/ 2).clamp(0, 1000), color: target.getPixel(0, 0), antialias: true);

    // Top-Right (right, top)
    drawThickLine(right - cornerLen, top, right - cornerRadius, top);
    drawThickLine(right, top + cornerRadius, right, top + cornerLen);
    img.fillCircle(target, x: right - cornerRadius, y: top + cornerRadius, radius: strokeWidth ~/ 2 + cornerRadius, color: strokeColor, antialias: true);
    img.fillCircle(target, x: right - cornerRadius, y: top + cornerRadius, radius: (cornerRadius - strokeWidth ~/ 2).clamp(0, 1000), color: target.getPixel(0, 0), antialias: true);

    // Bottom-Left (left, bottom)
    drawThickLine(left, bottom - cornerLen, left, bottom - cornerRadius);
    drawThickLine(left + cornerRadius, bottom, left + cornerLen, bottom);
    img.fillCircle(target, x: left + cornerRadius, y: bottom - cornerRadius, radius: strokeWidth ~/ 2 + cornerRadius, color: strokeColor, antialias: true);
    img.fillCircle(target, x: left + cornerRadius, y: bottom - cornerRadius, radius: (cornerRadius - strokeWidth ~/ 2).clamp(0, 1000), color: target.getPixel(0, 0), antialias: true);

    // Bottom-Right (right, bottom)
    drawThickLine(right - cornerLen, bottom, right - cornerRadius, bottom);
    drawThickLine(right, bottom - cornerLen, right, bottom - cornerRadius);
    img.fillCircle(target, x: right - cornerRadius, y: bottom - cornerRadius, radius: strokeWidth ~/ 2 + cornerRadius, color: strokeColor, antialias: true);
    img.fillCircle(target, x: right - cornerRadius, y: bottom - cornerRadius, radius: (cornerRadius - strokeWidth ~/ 2).clamp(0, 1000), color: target.getPixel(0, 0), antialias: true);
  }

  // Draw large reticle for full bleed icon (occupies ~58% of canvas)
  // bounds: 220 to 804 (width=584, height=584)
  drawReticle(
    fullBleedImage,
    left: 220,
    top: 220,
    right: 804,
    bottom: 804,
    strokeWidth: 72,
    cornerLen: 180,
    cornerRadius: 48,
    strokeColor: strokeTeal,
  );

  // ==========================================
  // 2. FOREGROUND ICON (For Android Adaptive Icons)
  // ==========================================
  final foregroundImage = img.Image(width: size, height: size, numChannels: 4);
  img.fill(foregroundImage, color: img.ColorRgba8(0, 0, 0, 0)); // transparent background

  // Adaptive icon safe zone is 66% (radius ~338px from center).
  // Reticle bounds in center: 270 to 754 (width=484, height=484)
  drawReticle(
    foregroundImage,
    left: 270,
    top: 270,
    right: 754,
    bottom: 754,
    strokeWidth: 64,
    cornerLen: 155,
    cornerRadius: 40,
    strokeColor: strokeTeal,
  );

  // Save master icons
  final assetDir = Directory('assets/icon');
  if (!assetDir.existsSync()) {
    assetDir.createSync(recursive: true);
  }
  File('assets/icon/app_icon.png').writeAsBytesSync(img.encodePng(fullBleedImage));
  print('Saved assets/icon/app_icon.png');

  // ==========================================
  // 3. GENERATE ANDROID ICONS
  // ==========================================
  final androidLegacySizes = {
    'android/app/src/main/res/mipmap-mdpi/ic_launcher.png': 48,
    'android/app/src/main/res/mipmap-hdpi/ic_launcher.png': 72,
    'android/app/src/main/res/mipmap-xhdpi/ic_launcher.png': 96,
    'android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png': 144,
    'android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png': 192,
  };

  for (final entry in androidLegacySizes.entries) {
    final resized = img.copyResize(fullBleedImage, width: entry.value, height: entry.value, interpolation: img.Interpolation.cubic);
    final outFile = File(entry.key);
    outFile.parent.createSync(recursive: true);
    outFile.writeAsBytesSync(img.encodePng(resized));

    // Also write ic_launcher_round.png
    final roundPath = entry.key.replaceAll('ic_launcher.png', 'ic_launcher_round.png');
    File(roundPath).writeAsBytesSync(img.encodePng(resized));
  }

  // Android Adaptive Foreground sizes (108dp base)
  final androidAdaptiveSizes = {
    'android/app/src/main/res/mipmap-mdpi/ic_launcher_foreground.png': 108,
    'android/app/src/main/res/mipmap-hdpi/ic_launcher_foreground.png': 162,
    'android/app/src/main/res/mipmap-xhdpi/ic_launcher_foreground.png': 216,
    'android/app/src/main/res/mipmap-xxhdpi/ic_launcher_foreground.png': 324,
    'android/app/src/main/res/mipmap-xxxhdpi/ic_launcher_foreground.png': 432,
  };

  for (final entry in androidAdaptiveSizes.entries) {
    final resized = img.copyResize(foregroundImage, width: entry.value, height: entry.value, interpolation: img.Interpolation.cubic);
    final outFile = File(entry.key);
    outFile.parent.createSync(recursive: true);
    outFile.writeAsBytesSync(img.encodePng(resized));
  }

  // Create ic_launcher_background.xml
  final bgXmlDir = Directory('android/app/src/main/res/drawable');
  if (!bgXmlDir.existsSync()) bgXmlDir.createSync(recursive: true);
  File('android/app/src/main/res/drawable/ic_launcher_background.xml').writeAsStringSync('''<?xml version="1.0" encoding="utf-8"?>
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="108dp"
    android:height="108dp"
    android:viewportWidth="108"
    android:viewportHeight="108">
    <path
        android:fillColor="#E0F2F1"
        android:pathData="M0,0h108v108h-108z"/>
</vector>
''');

  // Create mipmap-anydpi-v26/ic_launcher.xml and ic_launcher_round.xml
  final anydpiDir = Directory('android/app/src/main/res/mipmap-anydpi-v26');
  if (!anydpiDir.existsSync()) anydpiDir.createSync(recursive: true);

  const adaptiveXml = '''<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@drawable/ic_launcher_background"/>
    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>
</adaptive-icon>
''';

  File('android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml').writeAsStringSync(adaptiveXml);
  File('android/app/src/main/res/mipmap-anydpi-v26/ic_launcher_round.xml').writeAsStringSync(adaptiveXml);

  // ==========================================
  // 4. GENERATE WEB & IOS ICONS
  // ==========================================
  final webSizes = {
    'web/favicon.png': 32,
    'web/icons/Icon-192.png': 192,
    'web/icons/Icon-512.png': 512,
    'web/icons/Icon-maskable-192.png': 192,
    'web/icons/Icon-maskable-512.png': 512,
  };

  for (final entry in webSizes.entries) {
    final resized = img.copyResize(fullBleedImage, width: entry.value, height: entry.value, interpolation: img.Interpolation.cubic);
    final outFile = File(entry.key);
    outFile.parent.createSync(recursive: true);
    outFile.writeAsBytesSync(img.encodePng(resized));
  }

  final iosSizes = {
    'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@1x.png': 20,
    'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@2x.png': 40,
    'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@3x.png': 60,
    'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@1x.png': 29,
    'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@2x.png': 58,
    'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@3x.png': 87,
    'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@1x.png': 40,
    'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@2x.png': 80,
    'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@3x.png': 120,
    'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@2x.png': 120,
    'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@3x.png': 180,
    'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@1x.png': 76,
    'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@2x.png': 152,
    'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-83.5x83.5@2x.png': 167,
    'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png': 1024,
  };

  for (final entry in iosSizes.entries) {
    final resized = img.copyResize(fullBleedImage, width: entry.value, height: entry.value, interpolation: img.Interpolation.cubic);
    final outFile = File(entry.key);
    outFile.parent.createSync(recursive: true);
    outFile.writeAsBytesSync(img.encodePng(resized));
  }

  print('Successfully generated full bleed and adaptive icons!');
}
