import '../../domain/entities/contact_mood.dart';
import '../../domain/entities/memory_kind.dart';
import '../../domain/entities/orbit_contact.dart';
import '../../domain/entities/orbit_memory.dart';
import '../../domain/entities/relationship_mode.dart';

abstract interface class OrbitContactRepository {
  List<OrbitContact> getContacts();

  List<OrbitMemory> getMemories();
}

class SeedOrbitContactRepository implements OrbitContactRepository {
  const SeedOrbitContactRepository();

  @override
  List<OrbitContact> getContacts() {
    return const [
      OrbitContact(
        id: 'weekly-friend',
        name: 'Mina',
        contactCadence: Duration(days: 7),
        orbitRadius: 86,
        orbitalPeriod: Duration(seconds: 18),
        phaseOffsetRadians: 0.2,
        planetRadius: 8,
        mood: ContactMood.warm,
        relationshipMode: RelationshipMode.archiveOnly,
      ),
      OrbitContact(
        id: 'monthly-friend',
        name: 'Joon',
        contactCadence: Duration(days: 30),
        orbitRadius: 142,
        orbitalPeriod: Duration(seconds: 32),
        phaseOffsetRadians: 2.1,
        planetRadius: 10,
        mood: ContactMood.calm,
        relationshipMode: RelationshipMode.gentleNudge,
      ),
      OrbitContact(
        id: 'quarterly-friend',
        name: 'Ara',
        contactCadence: Duration(days: 90),
        orbitRadius: 204,
        orbitalPeriod: Duration(seconds: 52),
        phaseOffsetRadians: 4.5,
        planetRadius: 12,
        mood: ContactMood.fractured,
        relationshipMode: RelationshipMode.reconnect,
      ),
    ];
  }

  @override
  List<OrbitMemory> getMemories() {
    return [
      OrbitMemory(
        id: 'mina-jomalone',
        contactId: 'weekly-friend',
        kind: MemoryKind.giftGiven,
        title: 'Jo Malone perfume',
        note: 'Birthday gift. She said the scent felt like early summer.',
        occurredOn: DateTime(2026, 7, 1),
        colorSeed: 0xFFFFD27A,
        location: 'Siheung, Jeongwang-dong',
        photoCount: 2,
      ),
      OrbitMemory(
        id: 'mina-cafe',
        contactId: 'weekly-friend',
        kind: MemoryKind.cafe,
        title: 'Late-night cafe',
        note: 'Talked until closing time and saved the receipt photo.',
        occurredOn: DateTime(2026, 6, 18),
        colorSeed: 0xFFA8D8FF,
        location: 'Wolgot harbor',
        photoCount: 4,
      ),
      OrbitMemory(
        id: 'mina-run',
        contactId: 'weekly-friend',
        kind: MemoryKind.hobby,
        title: 'Morning riverside run',
        note: 'A quiet 5K together, followed by iced coffee.',
        occurredOn: DateTime(2026, 5, 25),
        colorSeed: 0xFF65E4FF,
        photoCount: 1,
      ),
      OrbitMemory(
        id: 'joon-dinner',
        contactId: 'monthly-friend',
        kind: MemoryKind.meal,
        title: 'Spicy stew dinner',
        note: 'Caught up after a long month and planned the next hike.',
        occurredOn: DateTime(2026, 6, 3),
        colorSeed: 0xFFFF8E3C,
        location: 'Yeonnam-dong',
        photoCount: 3,
      ),
      OrbitMemory(
        id: 'joon-book',
        contactId: 'monthly-friend',
        kind: MemoryKind.giftReceived,
        title: 'Essay book',
        note: 'A small thank-you gift with a handwritten note inside.',
        occurredOn: DateTime(2026, 4, 12),
        colorSeed: 0xFFD9C7FF,
        photoCount: 1,
      ),
      OrbitMemory(
        id: 'ara-festival',
        contactId: 'quarterly-friend',
        kind: MemoryKind.trip,
        title: 'Summer music festival',
        note: 'The day turned into a bright constellation of tiny moments.',
        occurredOn: DateTime(2025, 8, 9),
        colorSeed: 0xFFB48CFF,
        location: 'Incheon Pentaport',
        photoCount: 7,
      ),
    ];
  }
}
