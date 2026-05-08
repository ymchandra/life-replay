import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:life_replay/core/theme/app_theme.dart';

/// Variants for the warm hero art shown at the top of each screen.
enum HeroArtVariant { journey, onThisDay, chapters, replay, insights }

/// A custom-drawn atmospheric hero widget that replaces PNG asset banners.
/// Renders warm gradient "scenes" that match the app's narrative theme.
class WarmHeroArt extends StatelessWidget {
  final HeroArtVariant variant;
  final double height;

  const WarmHeroArt({
    super.key,
    required this.variant,
    this.height = 200,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: CustomPaint(
          painter: _HeroArtPainter(variant),
        ),
      ),
    );
  }
}

class _HeroArtPainter extends CustomPainter {
  final HeroArtVariant variant;

  const _HeroArtPainter(this.variant);

  @override
  void paint(Canvas canvas, Size size) {
    switch (variant) {
      case HeroArtVariant.journey:
        _paintJourney(canvas, size);
      case HeroArtVariant.onThisDay:
        _paintOnThisDay(canvas, size);
      case HeroArtVariant.chapters:
        _paintChapters(canvas, size);
      case HeroArtVariant.replay:
        _paintReplay(canvas, size);
      case HeroArtVariant.insights:
        _paintInsights(canvas, size);
    }
  }

  // ─── Shared helpers ──────────────────────────────────────────────────────

  /// Fills the background with a warm dark gradient.
  void _paintBackground(Canvas canvas, Size size,
      {Color from = const Color(0xFF1E1A16),
      Color to = const Color(0xFF2E2318)}) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [from, to],
        ).createShader(rect),
    );
  }

  Paint get _amberPaint => Paint()
    ..color = AppTheme.primary.withOpacity(0.15)
    ..style = PaintingStyle.fill;

  Paint get _linePaint => Paint()
    ..color = AppTheme.primary.withOpacity(0.35)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5
    ..strokeCap = StrokeCap.round;

  Paint get _dotPaint => Paint()
    ..color = AppTheme.primary.withOpacity(0.7)
    ..style = PaintingStyle.fill;

  // ─── Journey (Timeline) ──────────────────────────────────────────────────
  void _paintJourney(Canvas canvas, Size size) {
    _paintBackground(canvas, size,
        from: const Color(0xFF1A1510), to: const Color(0xFF2A1F14));

    final w = size.width;
    final h = size.height;

    // Soft ambient glow
    canvas.drawCircle(
      Offset(w * 0.25, h * 0.55),
      h * 0.45,
      Paint()
        ..color = AppTheme.primary.withOpacity(0.06)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 40),
    );

    // Winding timeline path
    final path = Path();
    path.moveTo(w * 0.05, h * 0.68);
    path.cubicTo(w * 0.2, h * 0.3, w * 0.45, h * 0.8, w * 0.6, h * 0.4);
    path.cubicTo(w * 0.72, h * 0.1, w * 0.85, h * 0.55, w * 0.98, h * 0.45);
    canvas.drawPath(path, _linePaint..strokeWidth = 2);

    // Moment dots along the path
    final dotPositions = [
      Offset(w * 0.05, h * 0.68),
      Offset(w * 0.32, h * 0.52),
      Offset(w * 0.57, h * 0.42),
      Offset(w * 0.78, h * 0.3),
      Offset(w * 0.98, h * 0.45),
    ];
    for (final pos in dotPositions) {
      canvas.drawCircle(pos, 5, _dotPaint);
      canvas.drawCircle(
          pos,
          9,
          Paint()
            ..color = AppTheme.primary.withOpacity(0.12)
            ..style = PaintingStyle.fill);
    }

    // Label hint (barely visible grain texture using small dots)
    _paintGrain(canvas, size, seed: 1);
  }

  // ─── On This Day ─────────────────────────────────────────────────────────
  void _paintOnThisDay(Canvas canvas, Size size) {
    _paintBackground(canvas, size,
        from: const Color(0xFF1A1510), to: const Color(0xFF221810));

    final w = size.width;
    final h = size.height;

    // Central warm glow (sun-like nostalgia)
    canvas.drawCircle(
      Offset(w * 0.5, h * 0.5),
      h * 0.55,
      Paint()
        ..color = AppTheme.primary.withOpacity(0.08)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 50),
    );

    // Calendar grid lines (faint)
    final gridPaint = Paint()
      ..color = AppTheme.primary.withOpacity(0.1)
      ..strokeWidth = 1;
    const cols = 7;
    const rows = 5;
    final cellW = w / cols;
    final cellH = h / rows;
    for (var c = 0; c <= cols; c++) {
      canvas.drawLine(
          Offset(c * cellW, 0), Offset(c * cellW, h), gridPaint);
    }
    for (var r = 0; r <= rows; r++) {
      canvas.drawLine(
          Offset(0, r * cellH), Offset(w, r * cellH), gridPaint);
    }

    // Highlighted "today" cell (center-ish)
    final todayRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.35, h * 0.25, cellW * 1.3, cellH * 1.3),
      const Radius.circular(6),
    );
    canvas.drawRRect(todayRect, _amberPaint);
    canvas.drawRRect(
      todayRect,
      Paint()
        ..color = AppTheme.primary.withOpacity(0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    _paintGrain(canvas, size, seed: 2);
  }

  // ─── Chapters ────────────────────────────────────────────────────────────
  void _paintChapters(Canvas canvas, Size size) {
    _paintBackground(canvas, size,
        from: const Color(0xFF1A1510), to: const Color(0xFF201A12));

    final w = size.width;
    final h = size.height;

    // Soft page glow
    canvas.drawRect(
      Rect.fromLTWH(w * 0.25, 0, w * 0.5, h),
      Paint()
        ..color = AppTheme.primary.withOpacity(0.05)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30),
    );

    // Open-book silhouette
    final spine = Offset(w * 0.5, h * 0.12);
    final bottomLeft = Offset(w * 0.08, h * 0.88);
    final bottomRight = Offset(w * 0.92, h * 0.88);

    // Left page
    final leftPage = Path();
    leftPage.moveTo(spine.dx, spine.dy);
    leftPage.quadraticBezierTo(w * 0.15, h * 0.1, bottomLeft.dx, bottomLeft.dy);
    leftPage.lineTo(spine.dx, h * 0.9);
    leftPage.close();
    canvas.drawPath(
        leftPage,
        Paint()
          ..color = AppTheme.primary.withOpacity(0.08)
          ..style = PaintingStyle.fill);
    canvas.drawPath(
        leftPage,
        Paint()
          ..color = AppTheme.primary.withOpacity(0.25)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5);

    // Right page
    final rightPage = Path();
    rightPage.moveTo(spine.dx, spine.dy);
    rightPage.quadraticBezierTo(
        w * 0.85, h * 0.1, bottomRight.dx, bottomRight.dy);
    rightPage.lineTo(spine.dx, h * 0.9);
    rightPage.close();
    canvas.drawPath(
        rightPage,
        Paint()
          ..color = AppTheme.primary.withOpacity(0.05)
          ..style = PaintingStyle.fill);
    canvas.drawPath(
        rightPage,
        Paint()
          ..color = AppTheme.primary.withOpacity(0.25)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5);

    // Spine line
    canvas.drawLine(
        spine,
        Offset(w * 0.5, h * 0.9),
        Paint()
          ..color = AppTheme.primary.withOpacity(0.4)
          ..strokeWidth = 2);

    // Text lines on left page
    for (var i = 0; i < 4; i++) {
      final y = h * (0.3 + i * 0.12);
      canvas.drawLine(
        Offset(w * 0.18, y),
        Offset(w * 0.45, y),
        Paint()
          ..color = AppTheme.onSurface.withOpacity(0.1)
          ..strokeWidth = 1.5,
      );
    }

    _paintGrain(canvas, size, seed: 3);
  }

  // ─── Replay ──────────────────────────────────────────────────────────────
  void _paintReplay(Canvas canvas, Size size) {
    _paintBackground(canvas, size,
        from: const Color(0xFF120E0A), to: const Color(0xFF221610));

    final w = size.width;
    final h = size.height;

    // Cinematic spotlight
    final spotRect = Rect.fromCircle(
        center: Offset(w * 0.5, h * 0.4), radius: h * 0.65);
    canvas.drawOval(
      spotRect,
      Paint()
        ..color = AppTheme.primary.withOpacity(0.09)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 45),
    );

    // Film-strip perforations (left and right edges)
    _drawFilmStrip(canvas, size);

    // Large play triangle in center
    final cx = w * 0.5;
    final cy = h * 0.5;
    final r = h * 0.22;
    final trianglePath = Path();
    trianglePath.moveTo(cx - r * 0.6, cy - r);
    trianglePath.lineTo(cx - r * 0.6, cy + r);
    trianglePath.lineTo(cx + r, cy);
    trianglePath.close();
    canvas.drawPath(
        trianglePath,
        Paint()
          ..color = AppTheme.primary.withOpacity(0.5)
          ..style = PaintingStyle.fill);
    canvas.drawPath(
        trianglePath,
        Paint()
          ..color = AppTheme.primary.withOpacity(0.8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5);

    _paintGrain(canvas, size, seed: 4);
  }

  void _drawFilmStrip(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    const holeW = 7.0;
    const holeH = 10.0;
    const gapY = 16.0;
    final holePaint = Paint()
      ..color = AppTheme.primary.withOpacity(0.2)
      ..style = PaintingStyle.fill;
    final count = (h / gapY).floor();
    for (var i = 0; i < count; i++) {
      final y = i * gapY + 4;
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(6, y, holeW, holeH), const Radius.circular(2)),
          holePaint);
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(w - 13, y, holeW, holeH),
              const Radius.circular(2)),
          holePaint);
    }
  }

  // ─── Insights ────────────────────────────────────────────────────────────
  void _paintInsights(Canvas canvas, Size size) {
    _paintBackground(canvas, size,
        from: const Color(0xFF1A1510), to: const Color(0xFF251C12));

    final w = size.width;
    final h = size.height;

    // Ambient glow
    canvas.drawCircle(
      Offset(w * 0.7, h * 0.4),
      h * 0.5,
      Paint()
        ..color = AppTheme.primary.withOpacity(0.07)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 40),
    );

    // Bar chart silhouette
    final bars = [0.3, 0.6, 0.45, 0.8, 0.55, 0.7, 0.4];
    final barW = w * 0.08;
    final barSpacing = w * 0.04;
    final totalW = bars.length * (barW + barSpacing) - barSpacing;
    final startX = (w - totalW) / 2;

    for (var i = 0; i < bars.length; i++) {
      final barH = bars[i] * h * 0.6;
      final x = startX + i * (barW + barSpacing);
      final y = h * 0.85 - barH;
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, barW, barH),
        const Radius.circular(4),
      );
      canvas.drawRRect(
          rect,
          Paint()
            ..color = AppTheme.primary.withOpacity(0.2 + bars[i] * 0.3)
            ..style = PaintingStyle.fill);
    }

    // Baseline
    canvas.drawLine(
      Offset(startX - 4, h * 0.85),
      Offset(startX + totalW + 4, h * 0.85),
      Paint()
        ..color = AppTheme.primary.withOpacity(0.3)
        ..strokeWidth = 1.5,
    );

    _paintGrain(canvas, size, seed: 5);
  }

  // ─── Film grain texture ──────────────────────────────────────────────────
  void _paintGrain(Canvas canvas, Size size, {required int seed}) {
    final rng = math.Random(seed);
    final grainPaint = Paint()
      ..color = Colors.white.withOpacity(0.025)
      ..style = PaintingStyle.fill;
    for (var i = 0; i < 180; i++) {
      canvas.drawCircle(
        Offset(rng.nextDouble() * size.width, rng.nextDouble() * size.height),
        rng.nextDouble() * 1.2,
        grainPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_HeroArtPainter old) => old.variant != variant;
}
