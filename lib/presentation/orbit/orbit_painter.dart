import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/entities/contact_mood.dart';
import '../../domain/entities/orbit_contact.dart';

const double _twoPi = math.pi * 2;
const double _verticalCompression = 0.72;

class OrbitPainter extends CustomPainter {
  const OrbitPainter({
    required this.contacts,
    required this.elapsed,
  });

  final List<OrbitContact> contacts;
  final Duration elapsed;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) {
      return;
    }

    final center = Offset(size.width / 2, size.height / 2);
    final radiusScale = _radiusScaleFor(size);

    _drawBackground(canvas, size, center);
    _drawStars(canvas, size);
    _drawSun(canvas, center);

    for (final contact in contacts) {
      final radius = contact.orbitRadius * radiusScale;
      final planetRadius = math.max(5, contact.planetRadius * radiusScale);
      final palette = _MoodPalette.forMood(contact.mood);
      final angle = _angleFor(contact);

      _drawOrbit(canvas, center, radius);
      _drawTrail(
        canvas,
        center: center,
        radius: radius,
        angle: angle,
        planetRadius: planetRadius,
        palette: palette,
      );
      _drawPlanet(
        canvas,
        position: _pointOnOrbit(
          center: center,
          radius: radius,
          angle: angle,
          instability: palette.instability,
        ),
        radius: planetRadius * palette.sizeScale,
        palette: palette,
      );
    }
  }

  double _radiusScaleFor(Size size) {
    final maxOrbit = contacts.fold<double>(
      1,
      (current, contact) => math.max(current, contact.orbitRadius),
    );
    final availableRadius = size.shortestSide * 0.43;

    return math.min(1, availableRadius / maxOrbit);
  }

  double _angleFor(OrbitContact contact) {
    final seconds = elapsed.inMicroseconds / Duration.microsecondsPerSecond;
    final period = contact.orbitalPeriod.inMicroseconds /
        Duration.microsecondsPerSecond;

    return contact.phaseOffsetRadians + (seconds / period * _twoPi);
  }

  void _drawBackground(Canvas canvas, Size size, Offset center) {
    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.black);

    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF111A3C).withValues(alpha: 0.56),
          const Color(0xFF030713).withValues(alpha: 0.24),
          Colors.black,
        ],
        stops: const [0, 0.42, 1],
      ).createShader(
        Rect.fromCircle(
          center: center,
          radius: size.longestSide * 0.58,
        ),
      );

    canvas.drawRect(Offset.zero & size, glowPaint);
  }

  void _drawStars(Canvas canvas, Size size) {
    final paint = Paint();

    for (var i = 0; i < 92; i++) {
      final x = _noise(i * 17 + 3) * size.width;
      final y = _noise(i * 31 + 11) * size.height;
      final twinkle = 0.5 + 0.5 * math.sin(
        elapsed.inMilliseconds / 900 + i * 0.71,
      );
      final opacity = 0.08 + twinkle * 0.22;
      final radius = 0.45 + _noise(i * 43 + 19) * 1.2;

      paint.color = const Color(0xFFE8ECFF).withValues(alpha: opacity);
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  double _noise(int seed) {
    final value = math.sin(seed * 12.9898) * 43758.5453;

    return value - value.floorToDouble();
  }

  void _drawSun(Canvas canvas, Offset center) {
    final glowPaint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20)
      ..color = const Color(0xFFFFD27A).withValues(alpha: 0.32);
    canvas.drawCircle(center, 34, glowPaint);

    final coronaPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFFF3C7),
          const Color(0xFFFFB956).withValues(alpha: 0.72),
          const Color(0xFFFF8E3C).withValues(alpha: 0.04),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: 25));
    canvas.drawCircle(center, 18, coronaPaint);

    final corePaint = Paint()..color = const Color(0xFFFFFFFF);
    canvas.drawCircle(center.translate(-4, -5), 4, corePaint);
  }

  void _drawOrbit(Canvas canvas, Offset center, double radius) {
    final orbitPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = const Color(0xFFE8ECFF).withValues(alpha: 0.10);

    canvas.drawOval(
      Rect.fromCenter(
        center: center,
        width: radius * 2,
        height: radius * 2 * _verticalCompression,
      ),
      orbitPaint,
    );
  }

  void _drawTrail(
    Canvas canvas, {
    required Offset center,
    required double radius,
    required double angle,
    required double planetRadius,
    required _MoodPalette palette,
  }) {
    const segments = 34;
    final trailArc = math.pi * (palette.instability > 0 ? 0.62 : 0.76);

    for (var i = 0; i < segments; i++) {
      final fromProgress = i / segments;
      final toProgress = (i + 1) / segments;
      final fromAngle = angle - trailArc * (1 - fromProgress);
      final toAngle = angle - trailArc * (1 - toProgress);
      final color = Color.lerp(
        palette.tail,
        palette.head,
        toProgress,
      )!
          .withValues(
        alpha: 0.06 + math.pow(toProgress, 1.7).toDouble() * 0.64,
      );
      final width =
          0.4 + math.pow(toProgress, 1.35).toDouble() * planetRadius * 0.78;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = width
        ..color = color;

      final path = Path()
        ..moveTo(
          _pointOnOrbit(
            center: center,
            radius: radius,
            angle: fromAngle,
            instability: palette.instability,
          ).dx,
          _pointOnOrbit(
            center: center,
            radius: radius,
            angle: fromAngle,
            instability: palette.instability,
          ).dy,
        )
        ..lineTo(
          _pointOnOrbit(
            center: center,
            radius: radius,
            angle: toAngle,
            instability: palette.instability,
          ).dx,
          _pointOnOrbit(
            center: center,
            radius: radius,
            angle: toAngle,
            instability: palette.instability,
          ).dy,
        );

      canvas.drawPath(path, paint);
    }
  }

  Offset _pointOnOrbit({
    required Offset center,
    required double radius,
    required double angle,
    required double instability,
  }) {
    final base = Offset(
      center.dx + math.cos(angle) * radius,
      center.dy + math.sin(angle) * radius * _verticalCompression,
    );

    if (instability == 0) {
      return base;
    }

    final seconds = elapsed.inMicroseconds / Duration.microsecondsPerSecond;
    final wobble = math.sin(angle * 5.0 + seconds * 2.4) * instability * 3.4;

    return Offset(
      base.dx + math.cos(angle + math.pi / 2) * wobble,
      base.dy + math.sin(angle + math.pi / 2) * wobble * _verticalCompression,
    );
  }

  void _drawPlanet(
    Canvas canvas, {
    required Offset position,
    required double radius,
    required _MoodPalette palette,
  }) {
    final glowPaint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12)
      ..color = palette.glow.withValues(alpha: 0.36);
    canvas.drawCircle(position, radius * 2.6, glowPaint);

    final planetPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.35, -0.42),
        colors: [
          Colors.white.withValues(alpha: 0.92),
          palette.core,
          palette.shadow,
        ],
        stops: const [0, 0.46, 1],
      ).createShader(Rect.fromCircle(center: position, radius: radius * 1.45));
    canvas.drawCircle(position, radius, planetPaint);

    final rimPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.white.withValues(alpha: 0.30);
    canvas.drawCircle(position, radius, rimPaint);
  }

  @override
  bool shouldRepaint(covariant OrbitPainter oldDelegate) {
    return oldDelegate.elapsed != elapsed || oldDelegate.contacts != contacts;
  }
}

class _MoodPalette {
  const _MoodPalette({
    required this.head,
    required this.tail,
    required this.core,
    required this.shadow,
    required this.glow,
    required this.instability,
    required this.sizeScale,
  });

  final Color head;
  final Color tail;
  final Color core;
  final Color shadow;
  final Color glow;
  final double instability;
  final double sizeScale;

  factory _MoodPalette.forMood(ContactMood mood) {
    return switch (mood) {
      ContactMood.warm => const _MoodPalette(
          head: Color(0xFFFFD27A),
          tail: Color(0xFFFF6B6B),
          core: Color(0xFFFFB84D),
          shadow: Color(0xFF6E2D10),
          glow: Color(0xFFFFC46B),
          instability: 0,
          sizeScale: 1.08,
        ),
      ContactMood.calm => const _MoodPalette(
          head: Color(0xFFA8D8FF),
          tail: Color(0xFF5B7CFA),
          core: Color(0xFF72B7FF),
          shadow: Color(0xFF15255F),
          glow: Color(0xFF8EA7FF),
          instability: 0,
          sizeScale: 1,
        ),
      ContactMood.fractured => const _MoodPalette(
          head: Color(0xFFD9C7FF),
          tail: Color(0xFF65E4FF),
          core: Color(0xFFB48CFF),
          shadow: Color(0xFF221048),
          glow: Color(0xFFAA7CFF),
          instability: 1,
          sizeScale: 0.94,
        ),
    };
  }
}
