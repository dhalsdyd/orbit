import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/entities/memory_kind.dart';
import '../../domain/entities/orbit_contact.dart';
import '../../domain/entities/orbit_memory.dart';

const double orbitTwoPi = math.pi * 2;
const double orbitVerticalCompression = 0.72;

class OrbitPlanetLayout {
  const OrbitPlanetLayout({
    required this.contact,
    required this.position,
    required this.orbitRadius,
    required this.planetRadius,
    required this.angle,
  });

  final OrbitContact contact;
  final Offset position;
  final double orbitRadius;
  final double planetRadius;
  final double angle;
}

class OrbitMemoryLayout {
  const OrbitMemoryLayout({
    required this.memory,
    required this.position,
    required this.visualRadius,
    required this.index,
  });

  final OrbitMemory memory;
  final Offset position;
  final double visualRadius;
  final int index;
}

class OrbitSceneLayout {
  const OrbitSceneLayout._();

  static Offset centerFor(Size size) {
    return Offset(size.width / 2, size.height / 2);
  }

  static List<OrbitPlanetLayout> homePlanets({
    required List<OrbitContact> contacts,
    required Size size,
    required Duration elapsed,
  }) {
    final center = centerFor(size);
    final radiusScale = radiusScaleFor(contacts: contacts, size: size);

    return [
      for (final contact in contacts)
        OrbitPlanetLayout(
          contact: contact,
          orbitRadius: contact.orbitRadius * radiusScale,
          planetRadius: math.max(5, contact.planetRadius * radiusScale),
          angle: angleFor(contact: contact, elapsed: elapsed),
          position: pointOnOrbit(
            center: center,
            radius: contact.orbitRadius * radiusScale,
            angle: angleFor(contact: contact, elapsed: elapsed),
            instability: 0,
            elapsed: elapsed,
          ),
        ),
    ];
  }

  static double radiusScaleFor({
    required List<OrbitContact> contacts,
    required Size size,
  }) {
    final maxOrbit = contacts.fold<double>(
      1,
      (current, contact) => math.max(current, contact.orbitRadius),
    );
    final availableRadius = size.shortestSide * 0.43;

    return math.min(1, availableRadius / maxOrbit);
  }

  static double angleFor({
    required OrbitContact contact,
    required Duration elapsed,
  }) {
    final seconds = elapsed.inMicroseconds / Duration.microsecondsPerSecond;
    final period = contact.orbitalPeriod.inMicroseconds /
        Duration.microsecondsPerSecond;

    return contact.phaseOffsetRadians + (seconds / period * orbitTwoPi);
  }

  static Offset pointOnOrbit({
    required Offset center,
    required double radius,
    required double angle,
    required double instability,
    required Duration elapsed,
  }) {
    final base = Offset(
      center.dx + math.cos(angle) * radius,
      center.dy + math.sin(angle) * radius * orbitVerticalCompression,
    );

    if (instability == 0) {
      return base;
    }

    final seconds = elapsed.inMicroseconds / Duration.microsecondsPerSecond;
    final wobble = math.sin(angle * 5.0 + seconds * 2.4) * instability * 3.4;

    return Offset(
      base.dx + math.cos(angle + math.pi / 2) * wobble,
      base.dy +
          math.sin(angle + math.pi / 2) * wobble * orbitVerticalCompression,
    );
  }

  static List<OrbitMemoryLayout> memoryObjects({
    required List<OrbitMemory> memories,
    required Size size,
    required Duration elapsed,
  }) {
    final center = focusedPlanetCenter(size);
    final giftMemories = memories.where((memory) => memory.kind.isGift).toList();
    final constellationMemories =
        memories.where((memory) => !memory.kind.isGift).toList();

    return [
      for (var index = 0; index < giftMemories.length; index++)
        _giftLayout(
          giftMemories[index],
          index: index,
          count: giftMemories.length,
          center: center,
          elapsed: elapsed,
        ),
      for (var index = 0; index < constellationMemories.length; index++)
        _constellationLayout(
          constellationMemories[index],
          index: index,
          count: constellationMemories.length,
          center: center,
        ),
    ];
  }

  static Offset focusedPlanetCenter(Size size) {
    return Offset(size.width / 2, size.height * 0.45);
  }

  static double focusedPlanetRadius(Size size) {
    return math.min(size.shortestSide * 0.085, 34);
  }

  static OrbitMemoryLayout _giftLayout(
    OrbitMemory memory, {
    required int index,
    required int count,
    required Offset center,
    required Duration elapsed,
  }) {
    final seconds = elapsed.inMicroseconds / Duration.microsecondsPerSecond;
    final ringRadius = 70.0 + (index % 2) * 26.0;
    final baseAngle = -math.pi / 2 + orbitTwoPi * index / math.max(count, 1);
    final angle = baseAngle + seconds * (0.28 + index * 0.03);

    return OrbitMemoryLayout(
      memory: memory,
      index: index,
      visualRadius: 9 + memory.visiblePhotoCount.clamp(0, 4).toDouble() * 0.8,
      position: Offset(
        center.dx + math.cos(angle) * ringRadius,
        center.dy + math.sin(angle) * ringRadius * orbitVerticalCompression,
      ),
    );
  }

  static OrbitMemoryLayout _constellationLayout(
    OrbitMemory memory, {
    required int index,
    required int count,
    required Offset center,
  }) {
    final angle = -math.pi * 0.78 +
        math.pi * 1.56 * (index + 0.5) / math.max(count, 1);
    final distance = 122.0 + (index % 3) * 24.0;

    return OrbitMemoryLayout(
      memory: memory,
      index: index,
      visualRadius:
          11 + memory.visiblePhotoCount.clamp(0, 6).toDouble() * 0.45,
      position: Offset(
        center.dx + math.cos(angle) * distance,
        center.dy + math.sin(angle) * distance * 0.64,
      ),
    );
  }
}
