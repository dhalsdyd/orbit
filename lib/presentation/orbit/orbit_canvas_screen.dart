import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../data/repositories/orbit_contact_repository.dart';
import '../../domain/entities/orbit_contact.dart';
import 'orbit_painter.dart';

class OrbitCanvasScreen extends StatefulWidget {
  const OrbitCanvasScreen({super.key});

  @override
  State<OrbitCanvasScreen> createState() => _OrbitCanvasScreenState();
}

class _OrbitCanvasScreenState extends State<OrbitCanvasScreen>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  late final List<OrbitContact> _contacts;
  Duration _elapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _contacts = const SeedOrbitContactRepository().getContacts();
    _ticker = createTicker((elapsed) {
      setState(() {
        _elapsed = elapsed;
      });
    })..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RepaintBoundary(
        child: Semantics(
          label: 'Orbit canvas with the sun and three relationship planets',
          child: CustomPaint(
            painter: OrbitPainter(
              contacts: _contacts,
              elapsed: _elapsed,
            ),
            child: const SizedBox.expand(),
          ),
        ),
      ),
    );
  }
}
