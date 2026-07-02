import '../../domain/entities/memory_kind.dart';
import '../../domain/entities/orbit_memory.dart';

class OrbitMemoryMapper {
  const OrbitMemoryMapper._();

  static Map<String, Object?> toMap(OrbitMemory memory) {
    return {
      'id': memory.id,
      'contactId': memory.contactId,
      'kind': memory.kind.name,
      'title': memory.title,
      'note': memory.note,
      'occurredOn': memory.occurredOn.toIso8601String(),
      'colorSeed': memory.colorSeed,
      'location': memory.location,
      'photoCount': memory.photoCount,
    };
  }

  static OrbitMemory fromMap(Map<dynamic, dynamic> map) {
    final kindName = map['kind'] as String? ?? MemoryKind.meal.name;

    return OrbitMemory(
      id: map['id'] as String,
      contactId: map['contactId'] as String,
      kind: MemoryKind.values.firstWhere(
        (kind) => kind.name == kindName,
        orElse: () => MemoryKind.meal,
      ),
      title: map['title'] as String,
      note: map['note'] as String,
      occurredOn: DateTime.parse(map['occurredOn'] as String),
      colorSeed: map['colorSeed'] as int,
      location: map['location'] as String?,
      photoCount: map['photoCount'] as int? ?? 0,
    );
  }
}
