// Builds the launcher-icon artwork from the ISLA wordmark.
//
// Usage: dart run tool/make_launcher_icons.dart
//
// Source: assets/icon/isla_logo_source.png, or (only when that is absent)
// assets/images/isla_wordmark.png. Outputs in assets/icon/:
//   icon_full.png        1024x1024 white background, wordmark 80% wide
//   icon_foreground.png  1024x1024 adaptive foreground, wordmark 56% wide
//   icon_monochrome.png  1024x1024 white silhouette for Android 13 themed icons
// and tool/output/icon_preview.png (mask check at 192 px and 48 px).
import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart' as img;

const int _size = 1024;
const List<String> _sources = [
  'assets/icon/isla_logo_source.png',
  'assets/images/isla_wordmark.png',
];

// Adaptive icons are 108 dp; the guaranteed-visible circle is 72 dp.
const double _safeRadius = _size * (72 / 108) / 2;

/// Distance from white, 0 (white) to 1 (the full wordmark blue).
double _ink(num r, num g, num b, num a, double maxDist) {
  // Composite over white so transparent source pixels read as white.
  final k = a / 255;
  final dr = 255 - (r * k + 255 * (1 - k));
  final dg = 255 - (g * k + 255 * (1 - k));
  final db = 255 - (b * k + 255 * (1 - k));
  return (math.sqrt(dr * dr + dg * dg + db * db) / maxDist).clamp(0.0, 1.0);
}

img.Image _loadSource() {
  for (final path in _sources) {
    final file = File(path);
    if (file.existsSync()) {
      stdout.writeln('Source: $path');
      return img.decodeImage(file.readAsBytesSync())!;
    }
  }
  stderr.writeln('No source artwork found: ${_sources.join(' or ')}');
  exit(2);
}

/// Crops to the letters (anything noticeably different from white).
img.Image _cropToInk(img.Image src, double maxDist) {
  var minX = src.width, minY = src.height, maxX = -1, maxY = -1;
  for (final p in src) {
    if (_ink(p.r, p.g, p.b, p.a, maxDist) > 0.08) {
      minX = math.min(minX, p.x);
      maxX = math.max(maxX, p.x);
      minY = math.min(minY, p.y);
      maxY = math.max(maxY, p.y);
    }
  }
  return img.copyCrop(
    src,
    x: minX,
    y: minY,
    width: maxX - minX + 1,
    height: maxY - minY + 1,
  );
}

/// Resizes by width only, keeping the aspect ratio.
img.Image _scaled(img.Image art, double widthFraction) => img.copyResize(
      art,
      width: (_size * widthFraction).round(),
      interpolation: img.Interpolation.cubic,
    );

img.Image _centered(img.Image art, {required bool white}) {
  final canvas = img.Image(width: _size, height: _size, numChannels: 4);
  if (white) img.fill(canvas, color: img.ColorRgba8(255, 255, 255, 255));
  img.compositeImage(
    canvas,
    art,
    dstX: (_size - art.width) ~/ 2,
    dstY: (_size - art.height) ~/ 2,
  );
  return canvas;
}

/// Foreground: the artwork over white inside its own box, transparent outside,
/// so the white wave cutouts stay white pixels.
img.Image _foreground(img.Image art) {
  final boxed = img.Image(width: art.width, height: art.height, numChannels: 4);
  img.fill(boxed, color: img.ColorRgba8(255, 255, 255, 255));
  img.compositeImage(boxed, art);
  return _centered(boxed, white: false);
}

/// Monochrome: white letters whose alpha is the distance from white.
img.Image _monochrome(img.Image art, double maxDist) {
  final mono = img.Image(width: art.width, height: art.height, numChannels: 4);
  for (final p in art) {
    final ink = _ink(p.r, p.g, p.b, p.a, maxDist);
    mono.setPixelRgba(p.x, p.y, 255, 255, 255, (ink * 255).round());
  }
  return _centered(mono, white: false);
}

/// True when every letter pixel lies inside the adaptive-icon safe circle.
bool _insideSafeCircle(img.Image mono) {
  const c = _size / 2;
  for (final p in mono) {
    if (p.a > 8) {
      final dx = p.x + 0.5 - c, dy = p.y + 0.5 - c;
      if (math.sqrt(dx * dx + dy * dy) > _safeRadius) return false;
    }
  }
  return true;
}

enum _Mask { circle, squircle, roundedSquare }

bool _inMask(_Mask mask, double x, double y, double size) {
  final c = size / 2;
  final dx = (x - c).abs() / c, dy = (y - c).abs() / c;
  switch (mask) {
    case _Mask.circle:
      return dx * dx + dy * dy <= 1;
    case _Mask.squircle:
      return math.pow(dx, 4) + math.pow(dy, 4) <= 1;
    case _Mask.roundedSquare:
      const r = 0.45; // corner radius as a fraction of the half-size
      final ox = math.max(0.0, dx - (1 - r)), oy = math.max(0.0, dy - (1 - r));
      return ox * ox + oy * oy <= r * r;
  }
}

/// Renders the adaptive icon (white background + foreground, visible 72/108
/// window) under [mask] at [size] px on a grey backdrop.
img.Image _masked(img.Image foreground, _Mask mask, int size) {
  final window = _size * 72 / 108;
  final crop = img.copyCrop(
    foreground,
    x: ((_size - window) / 2).round(),
    y: ((_size - window) / 2).round(),
    width: window.round(),
    height: window.round(),
  );
  final scaled = img.copyResize(
    crop,
    width: size,
    height: size,
    interpolation: img.Interpolation.cubic,
  );
  final out = img.Image(width: size, height: size, numChannels: 4);
  for (final p in out) {
    if (!_inMask(mask, p.x + 0.5, p.y + 0.5, size.toDouble())) {
      out.setPixelRgba(p.x, p.y, 0, 0, 0, 0);
      continue;
    }
    final f = scaled.getPixel(p.x, p.y);
    final k = f.a / 255;
    out.setPixelRgba(
      p.x,
      p.y,
      (f.r * k + 255 * (1 - k)).round(),
      (f.g * k + 255 * (1 - k)).round(),
      (f.b * k + 255 * (1 - k)).round(),
      255,
    );
  }
  return out;
}

void _writePreview(img.Image foreground) {
  const pad = 24;
  const sizes = [192, 48];
  final width = pad + _Mask.values.length * (192 + pad);
  final height = pad + sizes.fold<int>(0, (a, s) => a + s + pad);
  final sheet = img.Image(width: width, height: height, numChannels: 4);
  img.fill(sheet, color: img.ColorRgba8(150, 150, 150, 255));
  var y = pad;
  for (final size in sizes) {
    var x = pad;
    for (final mask in _Mask.values) {
      img.compositeImage(sheet, _masked(foreground, mask, size),
          dstX: x, dstY: y);
      x += 192 + pad;
    }
    y += size + pad;
  }
  File('tool/output/icon_preview.png')
    ..createSync(recursive: true)
    ..writeAsBytesSync(img.encodePng(sheet));
}

void main() {
  final source = _loadSource();
  stdout.writeln('Source size: ${source.width}x${source.height}, '
      'alpha channel: ${source.hasAlpha}');
  // Distance of the wordmark blue from white, used to normalise alpha.
  final blue = source.getPixel(source.width ~/ 12, source.height ~/ 2);
  final maxDist = math.sqrt(
    math.pow(255 - blue.r, 2) +
        math.pow(255 - blue.g, 2) +
        math.pow(255 - blue.b, 2),
  );
  final art = _cropToInk(source, maxDist);
  stdout.writeln('Cropped wordmark: ${art.width}x${art.height}');

  var fraction = 0.56;
  late img.Image mono, foreground;
  while (true) {
    final scaled = _scaled(art, fraction);
    mono = _monochrome(scaled, maxDist);
    foreground = _foreground(scaled);
    if (_insideSafeCircle(mono) || fraction <= 0.3) break;
    fraction -= 0.02;
  }
  stdout.writeln('Foreground width: ${(fraction * 100).round()}%');

  final full = _centered(_scaled(art, 0.80), white: true);
  void save(String name, img.Image image) {
    File('assets/icon/$name')
      ..createSync(recursive: true)
      ..writeAsBytesSync(img.encodePng(image));
    stdout.writeln('assets/icon/$name ${image.width}x${image.height}');
  }

  save('icon_full.png', full);
  save('icon_foreground.png', foreground);
  save('icon_monochrome.png', mono);
  _writePreview(foreground);
  stdout.writeln('tool/output/icon_preview.png');
}
