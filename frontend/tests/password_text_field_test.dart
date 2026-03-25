import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:urban_art_drops_app/l10n/app_localizations.dart";
import "package:urban_art_drops_app/shared/widgets/password_text_field.dart";

void main() {
  testWidgets("shows the visibility toggle only after a password was entered", (
    tester,
  ) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: PasswordTextField(
            controller: controller,
            decoration: const InputDecoration(labelText: "Password"),
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.visibility_outlined), findsNothing);
    expect(
      tester.widget<TextField>(find.byType(TextField)).obscureText,
      isTrue,
    );

    await tester.enterText(find.byType(TextField), "PasswordWith16Chars!");
    await tester.pump();

    final context = tester.element(find.byType(PasswordTextField));
    final l10n = AppLocalizations.of(context)!;

    expect(find.byTooltip(l10n.showPasswordAction), findsOneWidget);

    await tester.tap(find.byTooltip(l10n.showPasswordAction));
    await tester.pump();

    expect(
      tester.widget<TextField>(find.byType(TextField)).obscureText,
      isFalse,
    );
    expect(find.byTooltip(l10n.hidePasswordAction), findsOneWidget);

    await tester.enterText(find.byType(TextField), "");
    await tester.pump();

    expect(find.byIcon(Icons.visibility_outlined), findsNothing);
    expect(
      tester.widget<TextField>(find.byType(TextField)).obscureText,
      isTrue,
    );
  });
}
