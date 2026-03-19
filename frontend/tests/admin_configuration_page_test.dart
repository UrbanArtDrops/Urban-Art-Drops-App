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

void main() {
  testWidgets("shows auth provider configuration status", (tester) async {
    final mockHttpClient = MockClient((request) async {
      if (request.url.path == "/api/admin/configuration") {
        return http.Response(
          jsonEncode({
            "smtpHost": "smtp.example.test",
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

    expect(find.text(l10n.authProviderStatusSectionTitle), findsOneWidget);
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
