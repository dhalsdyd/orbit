import '../../domain/entities/orbit_decoration.dart';

class OrbitDecorationMapper {
  const OrbitDecorationMapper._();

  static Map<String, Object?> toMap(OrbitDecoration decoration) {
    return {
      'contactId': decoration.contactId,
      'planetSkin': decoration.planetSkin.name,
      'nebulaTheme': decoration.nebulaTheme.name,
    };
  }

  static OrbitDecoration fromMap(Map<dynamic, dynamic> map) {
    final skinName = map['planetSkin'] as String? ?? PlanetSkin.solarGold.name;
    final themeName = map['nebulaTheme'] as String? ?? NebulaTheme.dawn.name;

    return OrbitDecoration(
      contactId: map['contactId'] as String,
      planetSkin: PlanetSkin.values.firstWhere(
        (skin) => skin.name == skinName,
        orElse: () => PlanetSkin.solarGold,
      ),
      nebulaTheme: NebulaTheme.values.firstWhere(
        (theme) => theme.name == themeName,
        orElse: () => NebulaTheme.dawn,
      ),
    );
  }
}
