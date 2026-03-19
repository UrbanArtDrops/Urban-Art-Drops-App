import "dart:convert";

import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:flutter_test/flutter_test.dart";
import "package:go_router/go_router.dart";
import "package:http/http.dart" as http;
import "package:http/testing.dart";
import "package:urban_art_drops_app/features/authentication/presentation/bloc/auth_session_cubit.dart";
import "package:urban_art_drops_app/features/authentication/presentation/pages/login_page.dart";
import "package:urban_art_drops_app/l10n/app_localizations.dart";
import "package:urban_art_drops_app/shared/services/app_api_client.dart";
import "package:urban_art_drops_app/shared/services/external_provider_auth_launcher.dart";

void main() {
  testWidgets("shows only the MFA flow after an MFA setup challenge", (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final mockHttpClient = MockClient((request) async {
      if (request.url.path == "/api/bootstrap/status") {
        return http.Response(
          jsonEncode({"bootstrapRequired": false, "adminCount": 1}),
          200,
          headers: {"content-type": "application/json"},
        );
      }

      if (request.url.path == "/api/auth/login-local") {
        return http.Response(
          jsonEncode({
            "success": true,
            "message": "MFA required",
            "userId": "admin-1",
            "role": 4,
            "userName": "Admin",
            "email": "admin@example.com",
            "requiresMfa": true,
            "mfaSetupRequired": true,
            "mfaChallengeToken": "challenge-token",
            "mfaManualEntryKey": "MANUALKEY",
            "mfaProvisioningUri":
                "otpauth://totp/UrbanArtDrops:admin@example.com?secret=MANUALKEY",
          }),
          200,
          headers: {"content-type": "application/json"},
        );
      }

      return http.Response("Not Found", 404);
    });

    await tester.pumpWidget(
      _LoginHarness(
        apiClient: AppApiClient(
          httpClient: mockHttpClient,
          baseUrl: "http://localhost",
        ),
      ),
    );
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(LoginPage));
    final l10n = AppLocalizations.of(context)!;

    await tester.enterText(
      _findTextField(l10n.emailLabel).first,
      "admin@example.com",
    );
    await tester.enterText(
      _findTextField(l10n.passwordLabel),
      "PasswordWith16Chars!",
    );
    await tester.tap(find.widgetWithText(FilledButton, l10n.navLogin));
    await tester.pumpAndSettle();

    expect(find.text(l10n.authMfaTitle), findsOneWidget);
    expect(
      find.textContaining("${l10n.authMfaManualKeyLabel}:"),
      findsOneWidget,
    );
    expect(
      find.widgetWithText(FilledButton, l10n.authMfaContinue),
      findsOneWidget,
    );
    expect(find.byType(TextField), findsOneWidget);
    expect(_findTextField(l10n.passwordLabel), findsNothing);
    expect(_findTextField(l10n.authProviderSubjectLabel), findsNothing);
    expect(find.byType(ChoiceChip), findsNothing);
    expect(find.text(l10n.providerLoginTitle), findsNothing);
  });

  testWidgets("completes provider login through the external browser flow", (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final mockHttpClient = MockClient((request) async {
      if (request.url.path == "/api/bootstrap/status") {
        return http.Response(
          jsonEncode({
            "bootstrapRequired": false,
            "adminUserExists": true,
            "moderatorBootstrapAvailable": true,
          }),
          200,
          headers: {"content-type": "application/json"},
        );
      }

      if (request.url.path == "/api/auth/provider-login/begin") {
        return http.Response(
          jsonEncode({
            "authorizationUrl": "https://provider.test/oauth/authorize",
            "expiresAtUtc": "2026-03-18T12:00:00Z",
          }),
          200,
          headers: {"content-type": "application/json"},
        );
      }

      if (request.url.path == "/api/auth/provider/complete") {
        return http.Response(
          jsonEncode({
            "success": true,
            "message": "Login successful.",
            "userId": "hunter-1",
            "role": 0,
            "userName": "ProviderHunter",
            "email": "provider.hunter@example.com",
            "accessToken": "access-token",
            "accessTokenExpiresAtUtc": "2026-03-18T12:30:00Z",
            "tokenType": "Bearer",
            "requiresMfa": false,
            "mfaSetupRequired": false,
          }),
          200,
          headers: {"content-type": "application/json"},
        );
      }

      return http.Response("Not Found", 404);
    });
    final authSessionCubit = AuthSessionCubit();

    await tester.pumpWidget(
      _LoginHarness(
        apiClient: AppApiClient(
          httpClient: mockHttpClient,
          baseUrl: "http://localhost",
        ),
        providerAuthLauncher: const _FakeExternalProviderAuthLauncher(),
        authSessionCubit: authSessionCubit,
      ),
    );
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(LoginPage));
    final l10n = AppLocalizations.of(context)!;
    final providerLoginButton = find.widgetWithText(
      OutlinedButton,
      l10n.providerLoginTitle,
    );
    await tester.tap(providerLoginButton);
    await tester.pumpAndSettle();

    expect(authSessionCubit.state.isAuthenticated, isTrue);
    expect(authSessionCubit.state.userId, "hunter-1");
    expect(authSessionCubit.state.accessToken, "access-token");
  });
}

class _LoginHarness extends StatelessWidget {
  const _LoginHarness({
    required this.apiClient,
    this.providerAuthLauncher,
    this.authSessionCubit,
  });

  final AppApiClient apiClient;
  final ExternalProviderAuthLauncher? providerAuthLauncher;
  final AuthSessionCubit? authSessionCubit;

  @override
  Widget build(BuildContext context) {
    final resolvedCubit = authSessionCubit ?? AuthSessionCubit();
    final router = GoRouter(
      routes: [
        GoRoute(
          path: "/auth/login",
          builder: (context, state) => LoginPage(
            apiClient: apiClient,
            providerAuthLauncher: providerAuthLauncher,
          ),
        ),
        GoRoute(
          path: "/",
          builder: (context, state) => const SizedBox.shrink(),
        ),
      ],
      initialLocation: "/auth/login",
    );

    return BlocProvider.value(
      value: resolvedCubit,
      child: MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );
  }
}

Finder _findTextField(String labelText) {
  return find.byWidgetPredicate(
    (widget) =>
        widget is TextField && widget.decoration?.labelText == labelText,
  );
}

class _FakeExternalProviderAuthLauncher extends ExternalProviderAuthLauncher {
  const _FakeExternalProviderAuthLauncher();

  @override
  Uri buildCallbackUri() {
    return Uri.parse("urbanartdrops-auth://oauth/callback");
  }

  @override
  Future<Uri> authenticate({
    required String authorizationUrl,
    Uri? callbackUri,
  }) async {
    return Uri.parse(
      "${callbackUri ?? buildCallbackUri()}?provider_session=provider-session-1",
    );
  }
}
