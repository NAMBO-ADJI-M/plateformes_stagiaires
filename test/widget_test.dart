import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:plateforme_stagiaires/main.dart';

void main() {
  testWidgets('MonApplication se construit sans erreur', (WidgetTester tester) async {
    await tester.pumpWidget(const MonApplication());

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(Scaffold), findsWidgets);
  });
}
