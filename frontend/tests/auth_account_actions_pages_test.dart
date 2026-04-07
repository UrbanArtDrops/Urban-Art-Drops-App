import "dart:convert";

import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:flutter_test/flutter_test.dart";
import "package:go_router/go_router.dart";
import "package:http/http.dart" as http;
import "package:http/testing.dart";
import "package:urban_art_drops_app/features/authentication/presentation/bloc/auth_session_cubit.dart";
import "package:urban_art_drops_app/features/authentication/presentation/pages/forgot_password_page.dart";
import "package:urban_art_drops_app/features/authentication/presentation/pages/login_page.dart";
import "package:urban_art_drops_app/features/authentication/presentation/pages/reset_password_page.dart";
import "package:urban_art_drops_app/features/authentication/presentation/pages/verify_email_page.dart";
import "package:urban_art_drops_app/l10n/app_localizations.dart";
import "package:urban_art_drops_app/shared/services/app_api_client.dart";

void main() {
  testWidgets("verifies an email address with token parameters", (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    var verifyCalled = false;
    final apiClient = AppApiClient(
      httpClient: MockClient((request) async {
        if (request.url.path == "/api/auth/verify-email") {
          verifyCalled = true;
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body["userId"], "user-1");
          expect(body["token"], "email-token");
          return http.Response(
            jsonEncode({"success": true, "message": "Email verified."}),
            200,
            headers: {"content-type": "application/json"},
          );
        }

        return http.Response("Not Found", 404);
      }),
      baseUrl: "http://localhost",
    );

    await tester.pumpWidget(
      _AuthActionsHarness(
        apiClient: apiClient,
        initialLocation: "/auth/verify-email?userId=user-1&token=email-token",
      ),
    );
    await tester.pumpAndSettle();

    expect(verifyCalled, isTrue);
    expect(find.text("Email verified."), findsOneWidget);
  });

  testWidgets("requests a password reset link", (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    var requestCalled = false;
    final apiClient = AppApiClient(
      httpClient: MockClient((request) async {
        if (request.url.path == "/api/auth/password-reset/request") {
          requestCalled = true;
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body["email"], "hunter@example.com");
          return http.Response(
            jsonEncode({"success": true, "message": "Reset link sent."}),
            200,
            headers: {"content-type": "application/json"},
          );
        }

        return http.Response("Not Found", 404);
      }),
      baseUrl: "http://localhost",
    );

    await tester.pumpWidget(
      _AuthActionsHarness(
        apiClient: apiClient,
        initialLocation: "/auth/forgot-password",
      ),
    );
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(ForgotPasswordPage));
    final l10n = AppLocalizations.of(context)!;
    await tester.enterText(
      _findTextField(l10n.emailLabel),
      "hunter@example.com",
    );
    await tester.tap(
      find.widgetWithText(FilledButton, l10n.authForgotPasswordSubmit),
    );
    await tester.pumpAndSettle();

    expect(requestCalled, isTrue);
    expect(find.text("Reset link sent."), findsOneWidget);
  });

  testWidgets("sets a new password with token parameters", (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    var resetCalled = false;
    final apiClient = AppApiClient(
      httpClient: MockClient((request) async {
        if (request.url.path == "/api/auth/password-reset/complete") {
          resetCalled = true;
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body["userId"], "user-1");
          expect(body["token"], "reset-token");
          expect(body["newPassword"], "PasswordWith16Chars!");
          return http.Response(
            jsonEncode({"success": true, "message": "Password reset."}),
            200,
            headers: {"content-type": "application/json"},
          );
        }

        return http.Response("Not Found", 404);
      }),
      baseUrl: "http://localhost",
    );

    await tester.pumpWidget(
      _AuthActionsHarness(
        apiClient: apiClient,
        initialLocation: "/auth/reset-password?userId=user-1&token=reset-token",
      ),
    );
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(ResetPasswordPage));
    final l10n = AppLocalizations.of(context)!;
    await tester.enterText(
      _findTextField(l10n.authNewPasswordLabel),
      "PasswordWith16Chars!",
    );
    await tester.tap(
      find.widgetWithText(FilledButton, l10n.authResetPasswordSubmit),
    );
    await tester.pumpAndSettle();

    expect(resetCalled, isTrue);
    expect(find.text("Password reset."), findsOneWidget);
  });
}

class _AuthActionsHarness extends StatelessWidget {
  const _AuthActionsHarness({
    required this.apiClient,
    required this.initialLocation,
  });

  final AppApiClient apiClient;
  final String initialLocation;

  @override
  Widget build(BuildContext context) {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: "/auth/verify-email",
          builder: (context, state) => VerifyEmailPage(
            userId: state.uri.queryParameters["userId"],
            token: state.uri.queryParameters["token"],
            apiClient: apiClient,
          ),
        ),
        GoRoute(
          path: "/auth/forgot-password",
          builder: (context, state) => ForgotPasswordPage(apiClient: apiClient),
        ),
        GoRoute(
          path: "/auth/reset-password",
          builder: (context, state) => ResetPasswordPage(
            userId: state.uri.queryParameters["userId"],
            token: state.uri.queryParameters["token"],
            apiClient: apiClient,
          ),
        ),
        GoRoute(
          path: "/auth/login",
          builder: (context, state) => const LoginPage(),
        ),
      ],
      initialLocation: initialLocation,
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
