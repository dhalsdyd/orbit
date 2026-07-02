import 'package:flutter/material.dart';

import '../../data/repositories/orbit_contact_repository.dart';
import '../theme/orbit_theme.dart';
import 'orbit_canvas_screen.dart';

class OrbitApp extends StatelessWidget {
  const OrbitApp({
    required this.repository,
    super.key,
  });

  final OrbitContactRepository repository;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Orbit',
      theme: OrbitTheme.dark(),
      home: OrbitCanvasScreen(repository: repository),
    );
  }
}
