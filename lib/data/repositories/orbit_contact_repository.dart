import '../../domain/entities/contact_mood.dart';
import '../../domain/entities/orbit_contact.dart';

abstract interface class OrbitContactRepository {
  List<OrbitContact> getContacts();
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
      ),
    ];
  }
}
