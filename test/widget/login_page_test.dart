import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:stock_flutter/features/auth/presentation/pages/login_page.dart';
import 'package:stock_flutter/features/auth/presentation/providers/auth_provider.dart';

@GenerateMocks([AuthNotifier])
import 'login_page_test.mocks.dart';

/// Helper: wraps a widget in ProviderScope + MaterialApp
Widget makeTestable(Widget widget, {List<Override> overrides = const []}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(home: widget),
  );
}

void main() {
  group('LoginPage widget', () {
    // ── Renders correctly ─────────────────────────────────────────────────
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

      // Should have some "inscription" or "créer un compte" text
      expect(
        find.textContaining(RegExp(r'(inscription|compte|register)', caseSensitive: false)),
        findsAtLeastNWidgets(1),
      );
    });

    // ── Validation ────────────────────────────────────────────────────────
    testWidgets('shows validation error for empty email', (tester) async {
      await tester.pumpWidget(makeTestable(const LoginPage()));

      // Tap login without filling in fields
      await tester.tap(find.widgetWithText(ElevatedButton, 'Connexion'));
      await tester.pump();

      expect(find.text('Email requis'), findsOneWidget);
    });

    testWidgets('shows validation error for invalid email format', (tester) async {
      await tester.pumpWidget(makeTestable(const LoginPage()));

      await tester.enterText(
        find.byType(TextFormField).first,
        'pas-un-email',
      );
      await tester.tap(find.widgetWithText(ElevatedButton, 'Connexion'));
      await tester.pump();

      expect(find.text('Email invalide'), findsOneWidget);
    });

    testWidgets('shows validation error for empty password', (tester) async {
      await tester.pumpWidget(makeTestable(const LoginPage()));

      await tester.enterText(
        find.byType(TextFormField).first,
        'valid@email.com',
      );
      await tester.tap(find.widgetWithText(ElevatedButton, 'Connexion'));
      await tester.pump();

      expect(find.text('Mot de passe requis'), findsOneWidget);
    });

    testWidgets('shows validation error for short password', (tester) async {
      await tester.pumpWidget(makeTestable(const LoginPage()));

      await tester.enterText(find.byType(TextFormField).first, 'a@b.com');
      await tester.enterText(find.byType(TextFormField).last, '123');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Connexion'));
      await tester.pump();

      expect(
        find.textContaining('6 caractères'),
        findsOneWidget,
      );
    });

    // ── Input acceptance ──────────────────────────────────────────────────
    testWidgets('accepts valid email and password without validation errors', (tester) async {
      await tester.pumpWidget(makeTestable(const LoginPage()));

      await tester.enterText(find.byType(TextFormField).first, 'test@example.com');
      await tester.enterText(find.byType(TextFormField).last, 'password123');
      await tester.pump();

      // No validation error messages
      expect(find.text('Email requis'), findsNothing);
      expect(find.text('Email invalide'), findsNothing);
      expect(find.text('Mot de passe requis'), findsNothing);
    });

    // ── Password visibility toggle ─────────────────────────────────────────
    testWidgets('has password field obscured by default', (tester) async {
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
