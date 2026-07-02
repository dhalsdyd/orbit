import 'package:hive_ce_flutter/hive_ce_flutter.dart';

import '../../domain/entities/orbit_contact.dart';
import '../../domain/entities/orbit_memory.dart';
import '../mappers/orbit_memory_mapper.dart';
import 'orbit_contact_repository.dart';

class HiveOrbitContactRepository implements OrbitContactRepository {
  HiveOrbitContactRepository._({
    required Box<dynamic> memoryBox,
    required OrbitContactRepository seedRepository,
  })  : _memoryBox = memoryBox,
        _seedRepository = seedRepository;

  static const _memoryBoxName = 'orbit_memories';
  static const _storageDirectoryName = 'orbit_hive';

  final Box<dynamic> _memoryBox;
  final OrbitContactRepository _seedRepository;

  static Future<HiveOrbitContactRepository> open({
    OrbitContactRepository seedRepository =
        const SeedOrbitContactRepository(),
  }) async {
    await Hive.initFlutter(_storageDirectoryName);
    final memoryBox = await Hive.openBox<dynamic>(_memoryBoxName);
    final repository = HiveOrbitContactRepository._(
      memoryBox: memoryBox,
      seedRepository: seedRepository,
    );
    await repository._seedMemoriesIfNeeded();

    return repository;
  }

  @override
  List<OrbitContact> getContacts() {
    return _seedRepository.getContacts();
  }

  @override
  List<OrbitMemory> getMemories() {
    final memories = <OrbitMemory>[];

    for (final value in _memoryBox.values) {
      if (value is Map) {
        try {
          memories.add(OrbitMemoryMapper.fromMap(value));
        } catch (_) {
          // Ignore malformed records so one bad local entry does not block launch.
        }
      }
    }

    return memories
      ..sort((a, b) => b.occurredOn.compareTo(a.occurredOn));
  }

  @override
  Future<void> addMemory(OrbitMemory memory) {
    return _memoryBox.put(
      memory.id,
      OrbitMemoryMapper.toMap(memory),
    );
  }

  @override
  Future<void> updateMemory(OrbitMemory memory) {
    return addMemory(memory);
  }

  @override
  Future<void> deleteMemory(String memoryId) {
    return _memoryBox.delete(memoryId);
  }

  Future<void> _seedMemoriesIfNeeded() async {
    if (_memoryBox.isNotEmpty) {
      return;
    }

    for (final memory in _seedRepository.getMemories()) {
      await addMemory(memory);
    }
  }
}
