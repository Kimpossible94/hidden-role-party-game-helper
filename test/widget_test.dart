// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hidden_role_party_game_helper/screens/home_screen.dart';

void main() {
  testWidgets('Home screen loads correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const MaterialApp(
        home: HomeScreen(),
      ),
    );

    // Verify that key UI elements are present
    expect(find.text('히든 역할\n파티 게임'), findsOneWidget);
    expect(find.text('게임 도우미 앱'), findsOneWidget);
    expect(find.text('새 게임 만들기'), findsOneWidget);
    expect(find.text('게임 참가하기'), findsOneWidget);
  });
}
