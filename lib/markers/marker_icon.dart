import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../theme/tokens.dart';

/// Coastal price pills: white pill, coral 2px border, dark bold text.
/// Selected pill adds a coral glow ring + dot (spec active state).
/// Same bucketed cache keeps hundreds of venues cheap.
Future<BitmapDescriptor> createPriceMarker({
  required String price,
  Color backgroundColor = Colors.white,
  Color borderColor = AppTokens.primary,
  Color textColor = AppTokens.ink,
  double pixelRatio = 2.0,
  bool selected = false,
}) async {
  final bucketed = _bucket(price);
  final cacheKey =
      '$bucketed|${backgroundColor.toARGB32()}|${borderColor.toARGB32()}|${pixelRatio.toStringAsFixed(1)}|$selected';
  final cached = _markerCache[cacheKey];
  if (cached != null) return cached;

  final created = await _renderPriceMarker(
    price: bucketed,
    backgroundColor: selected ? Colors.white : backgroundColor,
    borderColor: borderColor,
    textColor: selected ? AppTokens.ink : textColor,
    pixelRatio: pixelRatio,
    selected: selected,
  );
  // Bound cache: hundreds of venues -> bucketed prices keep this tiny.
  if (_markerCache.length > 64) _markerCache.clear();
  _markerCache[cacheKey] = created;
  return created;
}

/// Cluster badge: white circle, dark 2px border, bold count (spec).
Future<BitmapDescriptor> createClusterMarker({
  required int count,
  double pixelRatio = 2.0,
}) async {
  final cacheKey = 'cluster|$count|${pixelRatio.toStringAsFixed(1)}';
  final cached = _markerCache[cacheKey];
  if (cached != null) return cached;

  final label = count > 99 ? '99+' : '$count';
  final textPainter = TextPainter(
    text: TextSpan(
      text: label,
      style: TextStyle(
        fontSize: 15 * pixelRatio,
        fontWeight: FontWeight.w800,
        color: AppTokens.ink,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();

  final diameter =
      (textPainter.width + 26 * pixelRatio).clamp(44.0 * pixelRatio, 1024.0);
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final center = Offset(diameter / 2, diameter / 2);

  canvas.drawCircle(
      center, diameter / 2, Paint()..color = Colors.white);
  canvas.drawCircle(
      center,
      diameter / 2 - pixelRatio,
      Paint()
        ..color = AppTokens.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2 * pixelRatio);
  textPainter.paint(
      canvas,
      Offset((diameter - textPainter.width) / 2,
          (diameter - textPainter.height) / 2));

  final picture = recorder.endRecording();
  final d = diameter.ceil().clamp(1, 1024);
  final image = await picture.toImage(d, d);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);

  final created = BitmapDescriptor.bytes(
    bytes!.buffer.asUint8List(),
    imagePixelRatio: pixelRatio,
  );
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
  bool selected = false,
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

  final dotR = selected ? 5 * pixelRatio : 0.0;
  final dotGap = selected ? (dotR * 2 + 8 * pixelRatio) : 0.0;
  final bubbleWidth = textPainter.width + paddingX * 2 + dotGap;
  final bubbleHeight = textPainter.height + paddingY * 2;
  final totalHeight = bubbleHeight + tailHeight;

  final fill = Paint()..color = backgroundColor;
  final border = Paint()
    ..color = borderColor
    ..style = PaintingStyle.stroke
    ..strokeWidth = (selected ? 3 : 2) * pixelRatio;

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

  // Selected glow ring behind the pill (canvas shifted so it fits).
  if (selected) {
    canvas.translate(6 * pixelRatio, 6 * pixelRatio);
    final glow = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(-6 * pixelRatio, -6 * pixelRatio,
              bubbleWidth + 12 * pixelRatio, bubbleHeight + 12 * pixelRatio),
          Radius.circular(radius + 6 * pixelRatio),
        ),
      );
    canvas.drawPath(
        glow, Paint()..color = AppTokens.primary.withValues(alpha: 0.22));
  }

  canvas.drawPath(path, fill);
  canvas.drawPath(path, border);

  // Text (with leading coral dot when selected).
  final textLeft =
      (bubbleWidth - textPainter.width) / 2 + (selected ? dotGap / 2 : 0);
  if (selected) {
    canvas.drawCircle(
      Offset(paddingX, bubbleHeight / 2),
      dotR,
      Paint()..color = AppTokens.primary,
    );
  }
  textPainter.paint(
    canvas,
    Offset(
      textLeft,
      (bubbleHeight - textPainter.height) / 2,
    ),
  );

  final picture = recorder.endRecording();
  final pad = selected ? 12 * pixelRatio : 0.0;
  final image = await picture.toImage(
    (bubbleWidth + pad).ceil().clamp(1, 1024),
    (totalHeight + pad).ceil().clamp(1, 1024),
  );
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);

  return BitmapDescriptor.bytes(
    bytes!.buffer.asUint8List(),
    imagePixelRatio: pixelRatio,
  );
}
