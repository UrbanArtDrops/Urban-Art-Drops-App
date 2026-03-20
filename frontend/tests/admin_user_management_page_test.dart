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

  testWidgets(
    "hides self approval and suspension actions for the signed-in admin",
    (tester) async {
      final mockHttpClient = MockClient((request) async {
        if (request.url.path == "/api/admin/users") {
          return http.Response(
            jsonEncode([
              {
                "id": "admin-1",
                "email": "admin@example.com",
                "userName": "Admin",
                "role": 4,
                "pendingRoleApplication": null,
                "pendingRoleApplicationRequestedAtUtc": null,
                "isApproved": true,
                "isSuspended": false,
                "isEmailVerified": true,
                "isProviderAccount": false,
                "profileImage": null,
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

      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();

      expect(find.text(l10n.userRevokeApprovalAction), findsNothing);
      expect(find.text(l10n.userSuspendAction), findsNothing);
      expect(find.text(l10n.userEditProfileAction), findsOneWidget);
      expect(find.text(l10n.userChangeRoleAction), findsOneWidget);
    },
  );

  testWidgets(
    "approves a pending role application without requiring a full user reload",
    (tester) async {
      var getUsersCalls = 0;
      var approveCalls = 0;
      final mockHttpClient = MockClient((request) async {
        if (request.url.path == "/api/admin/users") {
          getUsersCalls += 1;
          return http.Response(
            jsonEncode([
              {
                "id": "user-1",
                "email": "hunter@example.com",
                "userName": "Hunter Artist",
                "role": 0,
                "pendingRoleApplication": 1,
                "pendingRoleApplicationRequestedAtUtc": "2026-03-20T10:15:00Z",
                "isApproved": true,
                "isSuspended": false,
                "isEmailVerified": true,
                "isProviderAccount": false,
                "profileImage": null,
              },
            ]),
            200,
            headers: {"content-type": "application/json"},
          );
        }

        if (request.url.path ==
            "/api/admin/users/user-1/role-application/approve") {
          approveCalls += 1;
          return http.Response(
            jsonEncode({
              "id": "user-1",
              "email": "hunter@example.com",
              "userName": "Hunter Artist",
              "role": 1,
              "pendingRoleApplication": null,
              "pendingRoleApplicationRequestedAtUtc": null,
              "isApproved": true,
              "isSuspended": false,
              "isEmailVerified": true,
              "isProviderAccount": false,
              "profileImage": null,
            }),
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

      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.userApproveRoleApplicationAction));
      await tester.pumpAndSettle();

      expect(approveCalls, 1);
      expect(getUsersCalls, 1);

      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();

      expect(find.text(l10n.userApproveRoleApplicationAction), findsNothing);
    },
  );

  testWidgets(
    "reloads the user list when the profile dialog is closed without saving",
    (tester) async {
      var getUsersCalls = 0;
      final mockHttpClient = MockClient((request) async {
        if (request.url.path == "/api/admin/users") {
          getUsersCalls += 1;
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
                "profileImage": null,
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

      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.userEditProfileAction));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.cancelAction).last);
      await tester.pumpAndSettle();

      expect(getUsersCalls, 2);
    },
  );
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
