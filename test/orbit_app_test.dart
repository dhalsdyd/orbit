import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbit/presentation/orbit/orbit_app.dart';

void main() {
  testWidgets('Orbit app shows the custom paint canvas', (tester) async {
    await tester.pumpWidget(const OrbitApp());

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(CustomPaint), findsOneWidget);
  });
}
