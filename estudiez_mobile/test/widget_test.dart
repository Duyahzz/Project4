import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:estudiez_mobile/main.dart';
import 'package:estudiez_mobile/providers/auth_provider.dart';

import 'package:estudiez_mobile/providers/language_provider.dart';

void main() {
  testWidgets('Smoke test for Login page title', (WidgetTester tester) async {
    // Mock the SharedPreferences initial values to avoid blocking platform channels
    SharedPreferences.setMockInitialValues({});

    // Build our app and trigger a frame.
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ],
        child: const EStudiezApp(),
      ),
    );

    // Let futures and microtasks execute
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Verify that the title 'eStudiez' is displayed on the login page.
    expect(find.text('eStudiez'), findsOneWidget);
  });
}
