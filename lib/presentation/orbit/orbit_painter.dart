import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/entities/contact_mood.dart';
import '../../domain/entities/memory_kind.dart';
import '../../domain/entities/orbit_contact.dart';
import '../../domain/entities/orbit_memory.dart';
import 'orbit_scene_layout.dart';

class OrbitPainter extends CustomPainter {
  const OrbitPainter({
    required this.contacts,
    required this.memories,
    required this.elapsed,
    this.selectedContactId,
    this.selectedMemoryId,
  });

  final List<OrbitContact> contacts;
  final List<OrbitMemory> memories;
  final Duration elapsed;
  final String? selectedContactId;
  final String? selectedMemoryId;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) {
      return;
    }

    final center = OrbitSceneLayout.centerFor(size);

    _drawBackground(canvas, size, center);
    _drawStars(canvas, size);

    final selectedContact = _selectedContact();
    if (selectedContact == null) {
      _drawHomeUniverse(canvas, size);
      return;
    }

    _drawPersonalArchive(canvas, size, selectedContact);
  }

  OrbitContact? _selectedContact() {
    final id = selectedContactId;
    if (id == null) {
      return null;
    }

    for (final contact in contacts) {
      if (contact.id == id) {
        return contact;
      }
    }

    return null;
  }

  void _drawHomeUniverse(Canvas canvas, Size size) {
    final center = OrbitSceneLayout.centerFor(size);
    final planetLayouts = OrbitSceneLayout.homePlanets(
      contacts: contacts,
      size: size,
      elapsed: elapsed,
    );

    _drawSun(canvas, center, radius: 18);

    for (final layout in planetLayouts) {
      final palette = _MoodPalette.forMood(layout.contact.mood);
      final memoryCount = _memoriesFor(layout.contact.id).length;

      _drawOrbit(canvas, center, layout.orbitRadius);
      _drawTrail(
        canvas,
        center: center,
        radius: layout.orbitRadius,
        angle: layout.angle,
        planetRadius: layout.planetRadius,
        palette: palette,
      );
      _drawMemoryHalo(
        canvas,
        position: layout.position,
        memoryCount: memoryCount,
        palette: palette,
      );
      _drawPlanet(
        canvas,
        position: OrbitSceneLayout.pointOnOrbit(
          center: center,
          radius: layout.orbitRadius,
          angle: layout.angle,
          instability: palette.instability,
          elapsed: elapsed,
        ),
        radius: layout.planetRadius * palette.sizeScale,
        palette: palette,
      );
    }
  }

  void _drawPersonalArchive(
    Canvas canvas,
    Size size,
    OrbitContact contact,
  ) {
    final center = OrbitSceneLayout.focusedPlanetCenter(size);
    final planetRadius = OrbitSceneLayout.focusedPlanetRadius(size);
    final palette = _MoodPalette.forMood(contact.mood);
    final contactMemories = _memoriesFor(contact.id);
    final memoryLayouts = OrbitSceneLayout.memoryObjects(
      memories: contactMemories,
      size: size,
      elapsed: elapsed,
    );

    _drawArchiveNebula(canvas, size, contactMemories);
    _drawConstellationLines(canvas, memoryLayouts);
    _drawPersonalOrbitRings(canvas, center);
    _drawPlanet(
      canvas,
      position: center,
      radius: planetRadius * palette.sizeScale,
      palette: palette,
    );
    _drawFocusedPlanetAura(canvas, center, planetRadius, palette);

    for (final layout in memoryLayouts) {
      if (layout.memory.kind.isGift) {
        _drawSatellite(canvas, layout);
      } else {
        _drawConstellationNode(canvas, layout);
      }
    }
  }

  List<OrbitMemory> _memoriesFor(String contactId) {
    final filtered = memories
        .where((memory) => memory.contactId == contactId)
        .toList()
      ..sort((a, b) => b.occurredOn.compareTo(a.occurredOn));

    return filtered;
  }

  void _drawBackground(Canvas canvas, Size size, Offset center) {
    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.black);

    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF111A3C).withValues(alpha: 0.58),
          const Color(0xFF030713).withValues(alpha: 0.24),
          Colors.black,
        ],
        stops: const [0, 0.44, 1],
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

    for (var i = 0; i < 110; i++) {
      final x = _noise(i * 17 + 3) * size.width;
      final y = _noise(i * 31 + 11) * size.height;
      final twinkle = 0.5 + 0.5 * math.sin(
        elapsed.inMilliseconds / 900 + i * 0.71,
      );
      final opacity = 0.07 + twinkle * 0.24;
      final radius = 0.45 + _noise(i * 43 + 19) * 1.2;

      paint.color = const Color(0xFFE8ECFF).withValues(alpha: opacity);
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  double _noise(int seed) {
    final value = math.sin(seed * 12.9898) * 43758.5453;

    return value - value.floorToDouble();
  }

  void _drawSun(Canvas canvas, Offset center, {required double radius}) {
    final glowPaint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20)
      ..color = const Color(0xFFFFD27A).withValues(alpha: 0.32);
    canvas.drawCircle(center, radius * 1.9, glowPaint);

    final coronaPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFFF3C7),
          const Color(0xFFFFB956).withValues(alpha: 0.72),
          const Color(0xFFFF8E3C).withValues(alpha: 0.04),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius * 1.4));
    canvas.drawCircle(center, radius, coronaPaint);

    final corePaint = Paint()..color = const Color(0xFFFFFFFF);
    canvas.drawCircle(
      center.translate(-radius * 0.22, -radius * 0.28),
      4,
      corePaint,
    );
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
        height: radius * 2 * orbitVerticalCompression,
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
      final from = OrbitSceneLayout.pointOnOrbit(
        center: center,
        radius: radius,
        angle: fromAngle,
        instability: palette.instability,
        elapsed: elapsed,
      );
      final to = OrbitSceneLayout.pointOnOrbit(
        center: center,
        radius: radius,
        angle: toAngle,
        instability: palette.instability,
        elapsed: elapsed,
      );
      final path = Path()
        ..moveTo(from.dx, from.dy)
        ..lineTo(to.dx, to.dy);

      canvas.drawPath(path, paint);
    }
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

  void _drawMemoryHalo(
    Canvas canvas, {
    required Offset position,
    required int memoryCount,
    required _MoodPalette palette,
  }) {
    if (memoryCount == 0) {
      return;
    }

    final paint = Paint()..color = palette.head.withValues(alpha: 0.62);

    final visibleCount = memoryCount.clamp(0, 8).toInt();

    for (var i = 0; i < visibleCount; i++) {
      final angle = elapsed.inMilliseconds / 1800 + i * math.pi * 0.64;
      final distance = 17 + (i % 3) * 4;
      final point = Offset(
        position.dx + math.cos(angle) * distance,
        position.dy + math.sin(angle) * distance * orbitVerticalCompression,
      );

      canvas.drawCircle(point, 1.8 + (i % 2) * 0.8, paint);
    }
  }

  void _drawArchiveNebula(
    Canvas canvas,
    Size size,
    List<OrbitMemory> contactMemories,
  ) {
    if (contactMemories.isEmpty) {
      return;
    }

    final center = OrbitSceneLayout.focusedPlanetCenter(size);
    final rect = Rect.fromCircle(
      center: center.translate(0, 12),
      radius: size.shortestSide * 0.48,
    );
    final colors = [
      for (final memory in contactMemories.take(4))
        Color(memory.colorSeed).withValues(alpha: 0.16),
      Colors.transparent,
    ];
    final paint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 34)
      ..shader = SweepGradient(
        colors: colors.length > 1
            ? colors
            : [
                const Color(0xFF8EA7FF).withValues(alpha: 0.14),
                Colors.transparent,
              ],
      ).createShader(rect);

    canvas.drawOval(
      Rect.fromCenter(
        center: center.translate(0, 8),
        width: size.shortestSide * 0.78,
        height: size.shortestSide * 0.46,
      ),
      paint,
    );
  }

  void _drawPersonalOrbitRings(Canvas canvas, Offset center) {
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = const Color(0xFFE8ECFF).withValues(alpha: 0.12);

    for (final radius in const [70.0, 96.0, 132.0, 164.0]) {
      canvas.drawOval(
        Rect.fromCenter(
          center: center,
          width: radius * 2,
          height: radius * 2 * orbitVerticalCompression,
        ),
        ringPaint,
      );
    }
  }

  void _drawFocusedPlanetAura(
    Canvas canvas,
    Offset center,
    double radius,
    _MoodPalette palette,
  ) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8)
      ..color = palette.head.withValues(alpha: 0.32);

    canvas.drawCircle(center, radius * 2.2, paint);
  }

  void _drawSatellite(Canvas canvas, OrbitMemoryLayout layout) {
    final memory = layout.memory;
    final isSelected = memory.id == selectedMemoryId;
    final color = Color(memory.colorSeed);
    final radius = layout.visualRadius + (isSelected ? 3 : 0);
    final glowPaint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10)
      ..color = color.withValues(alpha: isSelected ? 0.52 : 0.28);
    final satellitePaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withValues(alpha: 0.90),
          color.withValues(alpha: 0.92),
          color.withValues(alpha: 0.18),
        ],
      ).createShader(Rect.fromCircle(center: layout.position, radius: radius));

    canvas.drawCircle(layout.position, radius * 2.2, glowPaint);
    canvas.drawCircle(layout.position, radius, satellitePaint);
    _drawTinyMoonTail(canvas, layout.position, color, layout.index);
  }

  void _drawTinyMoonTail(
    Canvas canvas,
    Offset position,
    Color color,
    int index,
  ) {
    final tailPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.2
      ..color = color.withValues(alpha: 0.28);
    final sweep = 0.42 + index * 0.08;
    final rect = Rect.fromCircle(center: position, radius: 18 + index % 2 * 4);

    canvas.drawArc(rect, -math.pi * 0.7, sweep, false, tailPaint);
  }

  void _drawConstellationLines(
    Canvas canvas,
    List<OrbitMemoryLayout> memoryLayouts,
  ) {
    final nodes = memoryLayouts
        .where((layout) => !layout.memory.kind.isGift)
        .toList(growable: false);
    if (nodes.length < 2) {
      return;
    }

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = const Color(0xFFA8D8FF).withValues(alpha: 0.22);
    final path = Path()
      ..moveTo(
        nodes.first.position.dx,
        nodes.first.position.dy,
      );

    for (final node in nodes.skip(1)) {
      path.lineTo(node.position.dx, node.position.dy);
    }

    canvas.drawPath(path, paint);
  }

  void _drawConstellationNode(Canvas canvas, OrbitMemoryLayout layout) {
    final memory = layout.memory;
    final isSelected = memory.id == selectedMemoryId;
    final color = Color(memory.colorSeed);
    final radius = layout.visualRadius + (isSelected ? 2.5 : 0);
    final haloPaint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12)
      ..color = color.withValues(alpha: isSelected ? 0.54 : 0.22);
    final nodePaint = Paint()..color = color.withValues(alpha: 0.86);

    canvas.drawCircle(layout.position, radius * 2.4, haloPaint);
    _drawStar(canvas, layout.position, radius, nodePaint);
  }

  void _drawStar(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();

    for (var i = 0; i < 10; i++) {
      final angle = -math.pi / 2 + i * math.pi / 5;
      final pointRadius = i.isEven ? radius : radius * 0.44;
      final point = Offset(
        center.dx + math.cos(angle) * pointRadius,
        center.dy + math.sin(angle) * pointRadius,
      );

      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }

    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant OrbitPainter oldDelegate) {
    return oldDelegate.elapsed != elapsed ||
        oldDelegate.contacts != contacts ||
        oldDelegate.memories != memories ||
        oldDelegate.selectedContactId != selectedContactId ||
        oldDelegate.selectedMemoryId != selectedMemoryId;
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
