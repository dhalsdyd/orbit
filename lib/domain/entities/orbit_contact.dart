import 'contact_mood.dart';

class OrbitContact {
  const OrbitContact({
    required this.id,
    required this.name,
    required this.contactCadence,
    required this.orbitRadius,
    required this.orbitalPeriod,
    required this.phaseOffsetRadians,
    required this.planetRadius,
    required this.mood,
  });

  final String id;
  final String name;

  /// Real relationship cadence, such as a week, a month, or a quarter.
  final Duration contactCadence;

  /// Visual orbit radius in logical pixels before screen-fit scaling.
  final double orbitRadius;

  /// Visual period for one complete orbit animation.
  final Duration orbitalPeriod;

  final double phaseOffsetRadians;
  final double planetRadius;
  final ContactMood mood;
}
