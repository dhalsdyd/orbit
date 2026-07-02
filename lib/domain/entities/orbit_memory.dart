import 'memory_kind.dart';

const Object _unchanged = Object();

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
    this.photoPaths = const [],
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
  final List<String> photoPaths;

  int get visiblePhotoCount {
    return photoCount + photoPaths.length;
  }

  OrbitMemory copyWith({
    String? title,
    String? note,
    Object? location = _unchanged,
    int? photoCount,
    List<String>? photoPaths,
  }) {
    return OrbitMemory(
      id: id,
      contactId: contactId,
      kind: kind,
      title: title ?? this.title,
      note: note ?? this.note,
      occurredOn: occurredOn,
      colorSeed: colorSeed,
      location: location == _unchanged ? this.location : location as String?,
      photoCount: photoCount ?? this.photoCount,
      photoPaths: photoPaths ?? this.photoPaths,
    );
  }
}
