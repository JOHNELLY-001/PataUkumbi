import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Airbnb-style daylight markers: white pill, coral border, dark text.
/// Readable in sunlight; same bucketed cache keeps hundreds cheap.
Future<BitmapDescriptor> createPriceMarker({
  required String price,
  Color backgroundColor = Colors.white,
  Color borderColor = const Color(0xFFFF5A5F),
  Color textColor = const Color(0xFF222222),
  double pixelRatio = 2.0,
}) async {
  final bucketed = _bucket(price);
  final cacheKey =
      '$bucketed|${backgroundColor.value}|${borderColor.value}|${pixelRatio.toStringAsFixed(1)}';
  final cached = _markerCache[cacheKey];
  if (cached != null) return cached;

  final created = await _renderPriceMarker(
    price: bucketed,
    backgroundColor: backgroundColor,
    borderColor: borderColor,
    textColor: textColor,
    pixelRatio: pixelRatio,
  );
  // Bound cache: hundreds of venues -> bucketed prices keep this tiny.
  if (_markerCache.length > 64) _markerCache.clear();
  _markerCache[cacheKey] = created;
  return created;
}

/// Shortens "250000" -> "250k" so markers stay small and cache hits stay high.
String _bucket(String raw) {
  final compact = raw.replaceAll(RegExp(r'[^0-9.]'), '');
  final value = double.tryParse(compact);
  if (value == null) return raw.length > 8 ? '${raw.substring(0, 8)}…' : raw;
  if (value >= 1000000) {
    final m = value / 1000000;
    return '${m % 1 == 0 ? m.toInt() : m}M';
  }
  if (value >= 1000) {
    final k = value / 1000;
    return '${k % 1 == 0 ? k.toInt() : k}k';
  }
  return compact;
}

final Map<String, BitmapDescriptor> _markerCache = {};

Future<BitmapDescriptor> _renderPriceMarker({
  required String price,
  required Color backgroundColor,
  required Color borderColor,
  required Color textColor,
  required double pixelRatio,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);

  const double paddingX = 18;
  const double paddingY = 10;
  const double tailWidth = 14;
  const double tailHeight = 10;
  const double radius = 22;

  final textPainter = TextPainter(
    text: TextSpan(
      text: price.startsWith(RegExp(r'[0-9]')) ? 'TSh $price' : price,
      style: TextStyle(
        fontSize: 15 * pixelRatio,
        fontWeight: FontWeight.w800,
        color: textColor,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();

  final bubbleWidth = textPainter.width + paddingX * 2;
  final bubbleHeight = textPainter.height + paddingY * 2;
  final totalHeight = bubbleHeight + tailHeight;

  final fill = Paint()..color = backgroundColor;
  final border = Paint()
    ..color = borderColor
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2 * pixelRatio;

  final path = Path();

  // Rounded bubble
  path.addRRect(
    RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, bubbleWidth, bubbleHeight),
      Radius.circular(radius),
    ),
  );

  // Tail (centered)
  final centerX = bubbleWidth / 2;
  path.moveTo(centerX - tailWidth / 2, bubbleHeight);
  path.lineTo(centerX, bubbleHeight + tailHeight);
  path.lineTo(centerX + tailWidth / 2, bubbleHeight);
  path.close();

  canvas.drawPath(path, fill);
  canvas.drawPath(path, border);

  // Draw text
  textPainter.paint(
    canvas,
    Offset(
      (bubbleWidth - textPainter.width) / 2,
      (bubbleHeight - textPainter.height) / 2,
    ),
  );

  final picture = recorder.endRecording();
  final w = bubbleWidth.ceil().clamp(1, 1024);
  final h = totalHeight.ceil().clamp(1, 1024);
  final image = await picture.toImage(w, h);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);

  return BitmapDescriptor.fromBytes(bytes!.buffer.asUint8List());
}
