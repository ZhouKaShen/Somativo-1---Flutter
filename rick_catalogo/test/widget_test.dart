// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rick_catalogo/main.dart';

void main() {
  testWidgets('exibe a tela de login ao iniciar sem sessão',
      (WidgetTester tester) async {
    await tester.pumpWidget(const AppRoot());
    await tester.pumpAndSettle();

    expect(find.text('Entrar'), findsWidgets);
    expect(find.text('Criar conta'), findsOneWidget);
  });
}
