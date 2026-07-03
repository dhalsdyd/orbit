import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/entities/memory_kind.dart';
import '../../domain/entities/orbit_contact.dart';
import '../../domain/entities/orbit_decoration.dart';
import '../../domain/entities/orbit_memory.dart';
import 'orbit_scene_layout.dart';

class OrbitPainter extends CustomPainter {
  const OrbitPainter({
    required this.contacts,
    required this.decorations,
    required this.memories,
    required this.elapsed,
    this.selectedContactId,
    this.selectedMemoryId,
    this.archiveReveal = 1,
  });

  final List<OrbitContact> contacts;
  final List<OrbitDecoration> decorations;
  final List<OrbitMemory> memories;
  final Duration elapsed;
  final String? selectedContactId;
  final String? selectedMemoryId;
  final double archiveReveal;

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

    _drawTransitioningArchive(canvas, size, selectedContact);
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
      final palette = _MoodPalette.forSkin(
        _decorationFor(layout.contact.id).planetSkin,
      );
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

  void _drawTransitioningArchive(
    Canvas canvas,
    Size size,
    OrbitContact selectedContact,
  ) {
    final reveal = archiveReveal.clamp(0, 1).toDouble();
    final center = OrbitSceneLayout.centerFor(size);
    final focus = OrbitSceneLayout.focusedPlanetCenter(size);

    _drawWithOpacity(canvas, size, 1 - reveal, () {
      canvas.save();
      final scale = 1 + reveal * 0.18;
      canvas.translate(center.dx, center.dy);
      canvas.scale(scale);
      canvas.translate(-center.dx, -center.dy);
      _drawHomeUniverse(canvas, size);
      canvas.restore();
    });

    _drawWithOpacity(canvas, size, reveal, () {
      canvas.save();
      final scale = 0.88 + reveal * 0.12;
      canvas.translate(focus.dx, focus.dy);
      canvas.scale(scale);
      canvas.translate(-focus.dx, -focus.dy);
      _drawPersonalArchive(canvas, size, selectedContact);
      canvas.restore();
    });
  }

  void _drawWithOpacity(
    Canvas canvas,
    Size size,
    double opacity,
    VoidCallback draw,
  ) {
    if (opacity <= 0) {
      return;
    }

    if (opacity >= 1) {
      draw();
      return;
    }

    canvas.saveLayer(
      Offset.zero & size,
      Paint()..color = Colors.white.withValues(alpha: opacity),
    );
    draw();
    canvas.restore();
  }

  void _drawPersonalArchive(
    Canvas canvas,
    Size size,
    OrbitContact contact,
  ) {
    final center = OrbitSceneLayout.focusedPlanetCenter(size);
    final planetRadius = OrbitSceneLayout.focusedPlanetRadius(size);
    final decoration = _decorationFor(contact.id);
    final palette = _MoodPalette.forSkin(decoration.planetSkin);
    final contactMemories = _memoriesFor(contact.id);
    final memoryLayouts = OrbitSceneLayout.memoryObjects(
      memories: contactMemories,
      size: size,
      elapsed: elapsed,
    );

    _drawArchiveNebula(canvas, size, contactMemories, decoration.nebulaTheme);
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

  OrbitDecoration _decorationFor(String contactId) {
    for (final decoration in decorations) {
      if (decoration.contactId == contactId) {
        return decoration;
      }
    }

    return OrbitDecoration(
      contactId: contactId,
      planetSkin: PlanetSkin.solarGold,
      nebulaTheme: NebulaTheme.dawn,
    );
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
    NebulaTheme nebulaTheme,
  ) {
    if (contactMemories.isEmpty) {
      return;
    }

    final center = OrbitSceneLayout.focusedPlanetCenter(size);
    final rect = Rect.fromCircle(
      center: center.translate(0, 12),
      radius: size.shortestSide * 0.48,
    );
    final themeColors = _nebulaColors(nebulaTheme);
    final colors = [
      themeColors.$1.withValues(alpha: 0.18),
      for (final memory in contactMemories.take(3))
        Color(memory.colorSeed).withValues(alpha: 0.13),
      themeColors.$2.withValues(alpha: 0.14),
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
    _drawMemorySticker(canvas, layout.position, layout.memory, radius);
    _drawMemoryStamp(canvas, layout.position, layout.memory, radius);
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
    _drawMemorySticker(canvas, layout.position, layout.memory, radius);
    _drawMemoryStamp(canvas, layout.position, layout.memory, radius);
  }

  (Color, Color) _nebulaColors(NebulaTheme theme) {
    return switch (theme) {
      NebulaTheme.dawn => (
          const Color(0xFFFFD27A),
          const Color(0xFFFF8EBC),
        ),
      NebulaTheme.deepSea => (
          const Color(0xFF65E4FF),
          const Color(0xFF233BFF),
        ),
      NebulaTheme.roseGalaxy => (
          const Color(0xFFFF8EBC),
          const Color(0xFFB48CFF),
        ),
      NebulaTheme.snowfall => (
          const Color(0xFFE8FBFF),
          const Color(0xFF8EA7FF),
        ),
      NebulaTheme.firefly => (
          const Color(0xFF9BEA7E),
          const Color(0xFFFFD27A),
        ),
    };
  }

  void _drawMemorySticker(
    Canvas canvas,
    Offset position,
    OrbitMemory memory,
    double radius,
  ) {
    final stickerCenter = position.translate(radius * 1.15, -radius * 1.1);
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = _stickerColor(memory.sticker).withValues(alpha: 0.92);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withValues(alpha: 0.72);

    switch (memory.sticker) {
      case MemorySticker.ribbon:
        final path = Path()
          ..moveTo(stickerCenter.dx - 5, stickerCenter.dy - 4)
          ..lineTo(stickerCenter.dx, stickerCenter.dy)
          ..lineTo(stickerCenter.dx - 5, stickerCenter.dy + 4)
          ..moveTo(stickerCenter.dx + 5, stickerCenter.dy - 4)
          ..lineTo(stickerCenter.dx, stickerCenter.dy)
          ..lineTo(stickerCenter.dx + 5, stickerCenter.dy + 4);
        canvas.drawPath(path, stroke);
      case MemorySticker.cup:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: stickerCenter, width: 10, height: 8),
            const Radius.circular(3),
          ),
          paint,
        );
        canvas.drawArc(
          Rect.fromCenter(
            center: stickerCenter.translate(6, 0),
            width: 7,
            height: 7,
          ),
          -math.pi / 2,
          math.pi,
          false,
          stroke,
        );
      case MemorySticker.plate:
        canvas.drawCircle(stickerCenter, 5.5, paint);
        canvas.drawCircle(stickerCenter, 2.6, stroke);
      case MemorySticker.flag:
        canvas.drawLine(
          stickerCenter.translate(-4, 5),
          stickerCenter.translate(-4, -6),
          stroke,
        );
        final path = Path()
          ..moveTo(stickerCenter.dx - 3, stickerCenter.dy - 6)
          ..lineTo(stickerCenter.dx + 6, stickerCenter.dy - 3)
          ..lineTo(stickerCenter.dx - 3, stickerCenter.dy)
          ..close();
        canvas.drawPath(path, paint);
      case MemorySticker.sparkle:
        _drawStar(canvas, stickerCenter, 6, paint);
      case MemorySticker.bubble:
        canvas.drawOval(
          Rect.fromCenter(center: stickerCenter, width: 13, height: 9),
          paint,
        );
        final tail = Path()
          ..moveTo(stickerCenter.dx - 1, stickerCenter.dy + 4)
          ..lineTo(stickerCenter.dx + 2, stickerCenter.dy + 8)
          ..lineTo(stickerCenter.dx + 4, stickerCenter.dy + 3)
          ..close();
        canvas.drawPath(tail, paint);
    }
  }

  void _drawMemoryStamp(
    Canvas canvas,
    Offset position,
    OrbitMemory memory,
    double radius,
  ) {
    final color = _stampColor(memory.stamp);
    final count = switch (memory.stamp) {
      MemoryStamp.bright => 5,
      MemoryStamp.cozy => 4,
      MemoryStamp.funny => 6,
      MemoryStamp.grateful => 5,
      MemoryStamp.longing => 3,
    };
    final paint = Paint()..color = color.withValues(alpha: 0.58);

    for (var i = 0; i < count; i++) {
      final angle = elapsed.inMilliseconds / 1500 + i * math.pi * 2 / count;
      final point = Offset(
        position.dx + math.cos(angle) * (radius * 1.75),
        position.dy + math.sin(angle) * (radius * 1.75),
      );
      canvas.drawCircle(point, 1.4 + (i % 2) * 0.6, paint);
    }
  }

  Color _stickerColor(MemorySticker sticker) {
    return switch (sticker) {
      MemorySticker.ribbon => const Color(0xFFFF8EBC),
      MemorySticker.cup => const Color(0xFFA8D8FF),
      MemorySticker.plate => const Color(0xFFFFD27A),
      MemorySticker.flag => const Color(0xFFB48CFF),
      MemorySticker.sparkle => const Color(0xFFE8FBFF),
      MemorySticker.bubble => const Color(0xFF65E4FF),
    };
  }

  Color _stampColor(MemoryStamp stamp) {
    return switch (stamp) {
      MemoryStamp.bright => const Color(0xFFFFF3C7),
      MemoryStamp.cozy => const Color(0xFFFFD27A),
      MemoryStamp.funny => const Color(0xFF65E4FF),
      MemoryStamp.grateful => const Color(0xFFFF8EBC),
      MemoryStamp.longing => const Color(0xFFB48CFF),
    };
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
        oldDelegate.decorations != decorations ||
        oldDelegate.memories != memories ||
        oldDelegate.selectedContactId != selectedContactId ||
        oldDelegate.selectedMemoryId != selectedMemoryId ||
        oldDelegate.archiveReveal != archiveReveal;
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

  factory _MoodPalette.forSkin(PlanetSkin skin) {
    return switch (skin) {
      PlanetSkin.solarGold => const _MoodPalette(
          head: Color(0xFFFFD27A),
          tail: Color(0xFFFF6B6B),
          core: Color(0xFFFFB84D),
          shadow: Color(0xFF6E2D10),
          glow: Color(0xFFFFC46B),
          instability: 0,
          sizeScale: 1.08,
        ),
      PlanetSkin.oceanBlue => const _MoodPalette(
          head: Color(0xFFA8D8FF),
          tail: Color(0xFF5B7CFA),
          core: Color(0xFF72B7FF),
          shadow: Color(0xFF15255F),
          glow: Color(0xFF8EA7FF),
          instability: 0,
          sizeScale: 1,
        ),
      PlanetSkin.violetGas => const _MoodPalette(
          head: Color(0xFFD9C7FF),
          tail: Color(0xFF65E4FF),
          core: Color(0xFFB48CFF),
          shadow: Color(0xFF221048),
          glow: Color(0xFFAA7CFF),
          instability: 1,
          sizeScale: 0.94,
        ),
      PlanetSkin.forestMoss => const _MoodPalette(
          head: Color(0xFFC9F2A4),
          tail: Color(0xFF5FE3A1),
          core: Color(0xFF7BCB71),
          shadow: Color(0xFF16381F),
          glow: Color(0xFF9BEA7E),
          instability: 0,
          sizeScale: 1.02,
        ),
      PlanetSkin.crystalIce => const _MoodPalette(
          head: Color(0xFFE8FBFF),
          tail: Color(0xFF8EA7FF),
          core: Color(0xFFBEEFFF),
          shadow: Color(0xFF183452),
          glow: Color(0xFFC9F7FF),
          instability: 0,
          sizeScale: 0.98,
        ),
    };
  }
}
