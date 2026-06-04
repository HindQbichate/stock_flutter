import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stock_flutter/features/auth/presentation/pages/login_page.dart';

/// Helper: wraps a widget in ProviderScope + MaterialApp
Widget makeTestable(Widget widget) {
  return ProviderScope(
    child: MaterialApp(home: widget),
  );
}

void main() {
  group('LoginPage widget', () {
    testWidgets('renders email and password fields', (tester) async {
      await tester.pumpWidget(makeTestable(const LoginPage()));
      expect(find.byType(TextFormField), findsNWidgets(2));
    });

    testWidgets('renders a login button', (tester) async {
      await tester.pumpWidget(makeTestable(const LoginPage()));
      expect(find.widgetWithText(ElevatedButton, 'Connexion'), findsOneWidget);
    });

    testWidgets('renders link to register page', (tester) async {
      await tester.pumpWidget(makeTestable(const LoginPage()));
      expect(
        find.textContaining(RegExp(r'(inscription|compte|register)', caseSensitive: false)),
        findsAtLeastNWidgets(1),
      );
    });

    testWidgets('shows validation error for empty email on submit', (tester) async {
      await tester.pumpWidget(makeTestable(const LoginPage()));
      await tester.tap(find.widgetWithText(ElevatedButton, 'Connexion'));
      await tester.pump();
      expect(find.text('Email requis'), findsOneWidget);
    });

    testWidgets('shows validation error for invalid email format', (tester) async {
      await tester.pumpWidget(makeTestable(const LoginPage()));
      await tester.enterText(find.byType(TextFormField).first, 'pas-un-email');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Connexion'));
      await tester.pump();
      expect(find.text('Email invalide'), findsOneWidget);
    });

    testWidgets('shows validation error for empty password', (tester) async {
      await tester.pumpWidget(makeTestable(const LoginPage()));
      await tester.enterText(find.byType(TextFormField).first, 'valid@email.com');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Connexion'));
      await tester.pump();
      expect(find.text('Mot de passe requis'), findsOneWidget);
    });

    testWidgets('password field is obscured by default', (tester) async {
      await tester.pumpWidget(makeTestable(const LoginPage()));
      final passwordField = tester.widget<EditableText>(
        find.descendant(
          of: find.byType(TextFormField).last,
          matching: find.byType(EditableText),
        ),
      );
      expect(passwordField.obscureText, isTrue);
    });
  });
}
