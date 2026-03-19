import "dart:convert";

import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:flutter_test/flutter_test.dart";
import "package:go_router/go_router.dart";
import "package:http/http.dart" as http;
import "package:http/testing.dart";
import "package:urban_art_drops_app/features/authentication/presentation/bloc/auth_session_cubit.dart";
import "package:urban_art_drops_app/features/authentication/presentation/pages/login_page.dart";
import "package:urban_art_drops_app/features/authentication/presentation/pages/register_page.dart";
import "package:urban_art_drops_app/l10n/app_localizations.dart";
import "package:urban_art_drops_app/shared/services/app_api_client.dart";
import "package:urban_art_drops_app/shared/services/external_provider_auth_launcher.dart";

void main() {
  testWidgets(
    "completes provider registration through the external browser flow",
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      var beginCalled = false;
      var completeCalled = false;
      final mockHttpClient = MockClient((request) async {
        if (request.url.path == "/api/auth/provider-register/begin") {
          beginCalled = true;
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
          completeCalled = true;
          return http.Response(
            jsonEncode({
              "success": true,
              "message": "Provider account created.",
              "userId": "provider-user-1",
              "role": 0,
              "userName": "ProviderRegister",
              "email": "provider.register@example.com",
              "requiresMfa": false,
              "mfaSetupRequired": false,
            }),
            200,
            headers: {"content-type": "application/json"},
          );
        }

        return http.Response("Not Found", 404);
      });

      await tester.pumpWidget(
        _RegisterHarness(
          apiClient: AppApiClient(
            httpClient: mockHttpClient,
            baseUrl: "http://localhost",
          ),
          providerAuthLauncher: const _FakeExternalProviderAuthLauncher(),
        ),
      );
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(RegisterPage));
      final l10n = AppLocalizations.of(context)!;

      final userNameFields = _findTextField(l10n.usernameLabel);
      final emailFields = _findTextField(l10n.emailLabel);
      await tester.enterText(userNameFields.last, "ProviderRegister");
      await tester.enterText(emailFields.last, "provider.register@example.com");
      final providerRegisterButton = find.widgetWithText(
        OutlinedButton,
        l10n.providerRegisterTitle,
      );
      await tester.tap(providerRegisterButton);
      await tester.pumpAndSettle();

      expect(beginCalled, isTrue);
      expect(completeCalled, isTrue);
      expect(find.byType(LoginPage), findsOneWidget);
    },
  );
}

class _RegisterHarness extends StatelessWidget {
  const _RegisterHarness({
    required this.apiClient,
    required this.providerAuthLauncher,
  });

  final AppApiClient apiClient;
  final ExternalProviderAuthLauncher providerAuthLauncher;

  @override
  Widget build(BuildContext context) {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: "/auth/register",
          builder: (context, state) => RegisterPage(
            apiClient: apiClient,
            providerAuthLauncher: providerAuthLauncher,
          ),
        ),
        GoRoute(
          path: "/auth/login",
          builder: (context, state) => const LoginPage(),
        ),
      ],
      initialLocation: "/auth/register",
    );

    return BlocProvider(
      create: (_) => AuthSessionCubit(),
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
      "${callbackUri ?? buildCallbackUri()}?provider_session=provider-registration-session",
    );
  }
}
