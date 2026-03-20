import "dart:convert";

import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:flutter_test/flutter_test.dart";
import "package:go_router/go_router.dart";
import "package:http/http.dart" as http;
import "package:http/testing.dart";
import "package:urban_art_drops_app/features/admin/presentation/pages/admin_user_management_page.dart";
import "package:urban_art_drops_app/features/authentication/presentation/bloc/auth_session_cubit.dart";
import "package:urban_art_drops_app/l10n/app_localizations.dart";
import "package:urban_art_drops_app/shared/services/app_api_client.dart";

void main() {
  testWidgets("shows role, profile, approval and suspension icons", (
    tester,
  ) async {
    final mockHttpClient = MockClient((request) async {
      if (request.url.path == "/api/admin/users") {
        return http.Response(
          jsonEncode([
            {
              "id": "user-1",
              "email": "artist@example.com",
              "userName": "Artist One",
              "role": 1,
              "pendingRoleApplication": null,
              "pendingRoleApplicationRequestedAtUtc": null,
              "isApproved": true,
              "isSuspended": false,
              "isEmailVerified": true,
              "isProviderAccount": false,
              "profileImage": {
                "id": "profile-image-1",
                "url": "data:image/png;base64,aGVsbG8=",
              },
            },
          ]),
          200,
          headers: {"content-type": "application/json"},
        );
      }

      return http.Response("Not Found", 404);
    });

    await tester.pumpWidget(
      _AdminUserManagementHarness(
        apiClient: AppApiClient(
          httpClient: mockHttpClient,
          baseUrl: "http://localhost",
        ),
      ),
    );
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(AdminUserManagementPage));
    final l10n = AppLocalizations.of(context)!;

    expect(find.text("Artist One"), findsOneWidget);
    expect(find.textContaining("artist@example.com"), findsOneWidget);
    expect(find.byType(CircleAvatar), findsOneWidget);
    expect(find.byIcon(Icons.palette_outlined), findsOneWidget);
    expect(find.byIcon(Icons.verified_outlined), findsOneWidget);
    expect(find.byIcon(Icons.lock_open_outlined), findsOneWidget);
    expect(find.byTooltip(l10n.roleArtist), findsOneWidget);
    expect(find.byTooltip(l10n.userApproved), findsOneWidget);
    expect(find.byTooltip(l10n.userActive), findsOneWidget);
  });
}

class _AdminUserManagementHarness extends StatelessWidget {
  const _AdminUserManagementHarness({required this.apiClient});

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
        accessTokenExpiresAtUtc: DateTime.utc(2026, 3, 20, 12),
        tokenType: "Bearer",
      );

    final router = GoRouter(
      routes: [
        GoRoute(
          path: "/admin/users",
          builder: (context, state) =>
              AdminUserManagementPage(apiClient: apiClient),
        ),
      ],
      initialLocation: "/admin/users",
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
