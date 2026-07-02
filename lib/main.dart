import 'package:flutter/material.dart';

import 'data/repositories/hive_orbit_contact_repository.dart';
import 'data/repositories/orbit_contact_repository.dart';
import 'presentation/orbit/orbit_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final repository = await _openRepository();
  runApp(OrbitApp(repository: repository));
}

Future<OrbitContactRepository> _openRepository() async {
  try {
    return await HiveOrbitContactRepository.open();
  } catch (_) {
    return const SeedOrbitContactRepository();
  }
}
