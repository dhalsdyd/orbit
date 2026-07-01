import 'memory_kind.dart';

class OrbitMemory {
  const OrbitMemory({
    required this.id,
    required this.contactId,
    required this.kind,
    required this.title,
    required this.note,
    required this.occurredOn,
    required this.colorSeed,
    this.location,
    this.photoCount = 0,
  });

  final String id;
  final String contactId;
  final MemoryKind kind;
  final String title;
  final String note;
  final DateTime occurredOn;
  final int colorSeed;
  final String? location;
  final int photoCount;
}
