import "dart:convert";

import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:flutter_test/flutter_test.dart";
import "package:go_router/go_router.dart";
import "package:http/http.dart" as http;
import "package:http/testing.dart";
import "package:urban_art_drops_app/features/admin/presentation/pages/admin_configuration_page.dart";
import "package:urban_art_drops_app/features/authentication/presentation/bloc/auth_session_cubit.dart";
import "package:urban_art_drops_app/l10n/app_localizations.dart";
import "package:urban_art_drops_app/shared/services/app_api_client.dart";
import "package:urban_art_drops_app/shared/widgets/password_text_field.dart";

void main() {
  testWidgets("shows auth provider configuration status", (tester) async {
    final mockHttpClient = MockClient((request) async {
      if (request.url.path == "/api/admin/configuration") {
        return http.Response(
          jsonEncode({
            "smtpHost": "smtp.example.test",
            "smtpPort": 465,
            "smtpSecurityMode": 1,
            "smtpUserName": "mailer-user",
            "smtpUserEmail": "mailer@example.test",
            "smtpPasswordSecretName": "Smtp:Password",
            "smtpPasswordConfigured": true,
            "publicAppBaseUrl": "https://app.example.test",
            "mainMapRadiusKm": 30,
            "miniMapRadiusKm": 5,
            "unclaimedDropRadiusKm": 3,
            "showExactPositionWhenFullyClaimed": true,
            "authProviders": [
              {
                "provider": "google",
                "displayName": "Google",
                "enabled": true,
                "visibleOnLogin": true,
                "hasClientId": true,
                "hasClientSecret": true,
                "usesPkce": true,
              },
              {
                "provider": "facebook",
                "displayName": "Facebook",
                "enabled": false,
                "visibleOnLogin": false,
                "hasClientId": false,
                "hasClientSecret": false,
                "usesPkce": false,
              },
            ],
          }),
          200,
          headers: {"content-type": "application/json"},
        );
      }

      return http.Response("Not Found", 404);
    });

    await tester.pumpWidget(
      _AdminConfigurationHarness(
        apiClient: AppApiClient(
          httpClient: mockHttpClient,
          baseUrl: "http://localhost",
        ),
      ),
    );
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(AdminConfigurationPage));
    final l10n = AppLocalizations.of(context)!;
    final facebookFinder = find.text("Facebook", skipOffstage: false);
    final providerSectionFinder = find.text(
      l10n.authProviderStatusSectionTitle,
      skipOffstage: false,
    );

    await tester.scrollUntilVisible(
      providerSectionFinder,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(providerSectionFinder, findsOneWidget);
    expect(find.text("Google"), findsOneWidget);
    expect(facebookFinder, findsOneWidget);
    expect(
      find.text(l10n.authProviderStatusVisibleOnLogin, skipOffstage: false),
      findsOneWidget,
    );
    expect(
      find.text(l10n.authProviderStatusHiddenOnLogin, skipOffstage: false),
      findsOneWidget,
    );
    expect(
      find.text(l10n.authProviderStatusClientIdPresent, skipOffstage: false),
      findsOneWidget,
    );
    expect(
      find.text(l10n.authProviderStatusClientIdMissing, skipOffstage: false),
      findsOneWidget,
    );
  });

  testWidgets("saves smtp port and user fields", (tester) async {
    await tester.binding.setSurfaceSize(const Size(1000, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    Map<String, dynamic>? updatePayload;

    final mockHttpClient = MockClient((request) async {
      if (request.url.path == "/api/admin/configuration" &&
          request.method == "GET") {
        return http.Response(
          jsonEncode({
            "smtpHost": "smtp.example.test",
            "smtpPort": 465,
            "smtpSecurityMode": 1,
            "smtpUserName": "mailer-user",
            "smtpUserEmail": "mailer@example.test",
            "smtpPasswordSecretName": "Smtp:Password",
            "smtpPasswordConfigured": true,
            "publicAppBaseUrl": "https://app.example.test",
            "mainMapRadiusKm": 30,
            "miniMapRadiusKm": 5,
            "unclaimedDropRadiusKm": 3,
            "showExactPositionWhenFullyClaimed": true,
            "authProviders": [],
          }),
          200,
          headers: {"content-type": "application/json"},
        );
      }

      if (request.url.path == "/api/admin/configuration" &&
          request.method == "PUT") {
        updatePayload = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response(
          jsonEncode({
            "smtpHost": updatePayload!["smtpHost"],
            "smtpPort": updatePayload!["smtpPort"],
            "smtpSecurityMode": updatePayload!["smtpSecurityMode"],
            "smtpUserName": updatePayload!["smtpUserName"],
            "smtpUserEmail": updatePayload!["smtpUserEmail"],
            "smtpPasswordSecretName": updatePayload!["smtpPasswordSecretName"],
            "smtpPasswordConfigured": updatePayload!["smtpPasswordSecretName"]
                .toString()
                .isNotEmpty,
            "publicAppBaseUrl": updatePayload!["publicAppBaseUrl"],
            "mainMapRadiusKm": updatePayload!["mainMapRadiusKm"],
            "miniMapRadiusKm": updatePayload!["miniMapRadiusKm"],
            "unclaimedDropRadiusKm": updatePayload!["unclaimedDropRadiusKm"],
            "showExactPositionWhenFullyClaimed":
                updatePayload!["showExactPositionWhenFullyClaimed"],
            "authProviders": [],
          }),
          200,
          headers: {"content-type": "application/json"},
        );
      }

      return http.Response("Not Found", 404);
    });

    await tester.pumpWidget(
      _AdminConfigurationHarness(
        apiClient: AppApiClient(
          httpClient: mockHttpClient,
          baseUrl: "http://localhost",
        ),
      ),
    );
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(AdminConfigurationPage));
    final l10n = AppLocalizations.of(context)!;

    await tester.enterText(
      find.widgetWithText(TextField, l10n.smtpPortLabel),
      "465",
    );
    await tester.enterText(
      find.widgetWithText(TextField, l10n.smtpUserNameLabel),
      "mailer-admin",
    );
    await tester.enterText(
      find.widgetWithText(TextField, l10n.smtpUserEmailLabel),
      "smtp-admin@example.test",
    );
    await tester.enterText(
      find.byType(PasswordTextField),
      "TopSecretPassword!123",
    );
    final saveButtonFinder = find.widgetWithText(FilledButton, l10n.saveButton);
    await tester.scrollUntilVisible(
      saveButtonFinder,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(saveButtonFinder);
    await tester.pumpAndSettle();

    expect(updatePayload, isNotNull);
    expect(updatePayload!["smtpPort"], 465);
    expect(updatePayload!["smtpSecurityMode"], 1);
    expect(updatePayload!["smtpUserName"], "mailer-admin");
    expect(updatePayload!["smtpUserEmail"], "smtp-admin@example.test");
    expect(updatePayload!["smtpPasswordSecretName"], "Smtp:Password");
    expect(updatePayload!.containsKey("smtpPassword"), isFalse);
  });

  testWidgets("tests smtp connection with transient password", (tester) async {
    await tester.binding.setSurfaceSize(const Size(1000, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    Map<String, dynamic>? smtpTestPayload;

    final mockHttpClient = MockClient((request) async {
      if (request.url.path == "/api/admin/configuration" &&
          request.method == "GET") {
        return http.Response(
          jsonEncode({
            "smtpHost": "smtp.example.test",
            "smtpPort": 465,
            "smtpSecurityMode": 1,
            "smtpUserName": "mailer-user",
            "smtpUserEmail": "mailer@example.test",
            "smtpPasswordSecretName": "Smtp:Password",
            "smtpPasswordConfigured": true,
            "publicAppBaseUrl": "https://app.example.test",
            "mainMapRadiusKm": 30,
            "miniMapRadiusKm": 5,
            "unclaimedDropRadiusKm": 3,
            "showExactPositionWhenFullyClaimed": true,
            "authProviders": [],
          }),
          200,
          headers: {"content-type": "application/json"},
        );
      }

      if (request.url.path == "/api/admin/configuration/smtp/test" &&
          request.method == "POST") {
        smtpTestPayload = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response(
          jsonEncode({
            "success": true,
            "message": "SMTP connection successful.",
          }),
          200,
          headers: {"content-type": "application/json"},
        );
      }

      return http.Response("Not Found", 404);
    });

    await tester.pumpWidget(
      _AdminConfigurationHarness(
        apiClient: AppApiClient(
          httpClient: mockHttpClient,
          baseUrl: "http://localhost",
        ),
      ),
    );
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(AdminConfigurationPage));
    final l10n = AppLocalizations.of(context)!;

    await tester.enterText(
      find.widgetWithText(TextField, l10n.smtpUserNameLabel),
      "mailer-admin",
    );
    await tester.enterText(
      find.byType(PasswordTextField),
      "TopSecretPassword!123",
    );

    final testButtonFinder = find.text(l10n.smtpTestConnectionButton);
    await tester.scrollUntilVisible(
      testButtonFinder,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(testButtonFinder);
    await tester.pumpAndSettle();

    expect(smtpTestPayload, isNotNull);
    expect(smtpTestPayload!["smtpHost"], "smtp.example.test");
    expect(smtpTestPayload!["smtpPort"], 465);
    expect(smtpTestPayload!["smtpSecurityMode"], 1);
    expect(smtpTestPayload!["smtpUserName"], "mailer-admin");
    expect(smtpTestPayload!["smtpPassword"], "TopSecretPassword!123");
    expect(smtpTestPayload!["smtpPasswordSecretName"], "Smtp:Password");
  });
}

class _AdminConfigurationHarness extends StatelessWidget {
  const _AdminConfigurationHarness({required this.apiClient});

  final AppApiClient apiClient;

  @override
  Widget build(BuildContext context) {
    final authCubit = AuthSessionCubit()
      ..signIn(
        userId: "admin-1",
        email: "admin@example.com",
        userName: "Admin",
        role: AppUserRole.admin,
        accessToken: "access-token",
        accessTokenExpiresAtUtc: DateTime.utc(2026, 3, 19, 12),
        tokenType: "Bearer",
      );

    final router = GoRouter(
      routes: [
        GoRoute(
          path: "/admin/configuration",
          builder: (context, state) =>
              AdminConfigurationPage(apiClient: apiClient),
        ),
      ],
      initialLocation: "/admin/configuration",
    );

    return BlocProvider.value(
      value: authCubit,
      child: MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );
  }
}
