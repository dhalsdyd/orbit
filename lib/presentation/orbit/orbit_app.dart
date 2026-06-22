import 'package:flutter/material.dart';

import '../theme/orbit_theme.dart';
import 'orbit_canvas_screen.dart';

class OrbitApp extends StatelessWidget {
  const OrbitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Orbit',
      theme: OrbitTheme.dark(),
      home: const OrbitCanvasScreen(),
    );
  }
}
