import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:flutter_test/flutter_test.dart";
import "package:go_router/go_router.dart";
import "package:urban_art_drops_app/features/authentication/presentation/bloc/auth_session_cubit.dart";
import "package:urban_art_drops_app/features/drop_maker/presentation/pages/my_drops_page.dart";
import "package:urban_art_drops_app/l10n/app_localizations.dart";
import "package:urban_art_drops_app/shared/models/app_models.dart";
import "package:urban_art_drops_app/shared/services/app_api_client.dart";

void main() {
  testWidgets(
    "reloads the drop list when the edit dialog is closed without saving",
    (tester) async {
      tester.view.physicalSize = const Size(1440, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final apiClient = _FakeMyDropsApiClient();
      final authCubit = AuthSessionCubit()
        ..signIn(
          userId: "drop-maker-1",
          email: "dropmaker@example.com",
          userName: "Drop Maker",
          role: AppUserRole.dropMaker,
          accessToken: "access-token",
          accessTokenExpiresAtUtc: DateTime.utc(2099, 3, 20, 12),
          tokenType: "Bearer",
        );

      await tester.pumpWidget(
        _MyDropsHarness(authCubit: authCubit, apiClient: apiClient),
      );
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(MyDropsPage));
      final l10n = AppLocalizations.of(context)!;

      await tester.tap(find.byType(PopupMenuButton<String>).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.editAction));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.cancelAction).last);
      await tester.pumpAndSettle();

      expect(apiClient.getDropsCallCount, 2);
    },
  );
}

class _MyDropsHarness extends StatelessWidget {
  const _MyDropsHarness({required this.authCubit, required this.apiClient});

  final AuthSessionCubit authCubit;
  final AppApiClient apiClient;

  @override
  Widget build(BuildContext context) {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: "/drop-maker/drops",
          builder: (context, state) => MyDropsPage(apiClient: apiClient),
        ),
      ],
      initialLocation: "/drop-maker/drops",
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

class _FakeMyDropsApiClient extends AppApiClient {
  _FakeMyDropsApiClient() : super(baseUrl: "http://localhost");

  int getDropsCallCount = 0;

  @override
  Future<AppConfigurationModel> getAppConfiguration() async {
    return AppConfigurationModel.defaults;
  }

  @override
  Future<List<DropModel>> getDrops() async {
    getDropsCallCount += 1;
    return const [
      DropModel(
        id: "drop-1",
        artPieceId: "art-1",
        dropMakerId: "drop-maker-1",
        isStationary: true,
        portableItemCount: null,
        dropMakerComment: null,
        socialChannels: [],
        latitude: 52.52,
        longitude: 13.405,
        isPublished: false,
        locationPhotoUrls: [],
        itemCount: 1,
        claimedItemCount: 0,
        items: [
          DropItemModel(
            id: "item-1",
            qrToken: "token-1",
            claimUrl: "https://example.com/claim/token-1",
            isClaimed: false,
            claimedByUserId: null,
            claimedByAnonymousNickname: null,
            claimedAtUtc: null,
          ),
        ],
      ),
    ];
  }

  @override
  Future<List<ArtPieceModel>> getArtPieces() async {
    return const [
      ArtPieceModel(
        id: "art-1",
        artistId: "artist-1",
        createdByUserId: "artist-1",
        title: "Artwork One",
        subtitle: "Subtitle",
        description: "Description long enough for the card and dialog.",
        assetKind: 0,
        isPublished: false,
        isReported: false,
        reportReason: null,
        reportedAtUtc: null,
        photoUrls: [],
        assetFile: null,
      ),
    ];
  }

  @override
  Future<List<ManagedUser>> getUserDirectory() async {
    return const [
      ManagedUser(
        id: "artist-1",
        email: "artist@example.com",
        userName: "Artist One",
        role: 1,
        pendingRoleApplication: null,
        pendingRoleApplicationRequestedAtUtc: null,
        isApproved: true,
        isSuspended: false,
        isEmailVerified: true,
        isProviderAccount: false,
        profileImageUrl: null,
      ),
      ManagedUser(
        id: "drop-maker-1",
        email: "dropmaker@example.com",
        userName: "Drop Maker",
        role: 2,
        pendingRoleApplication: null,
        pendingRoleApplicationRequestedAtUtc: null,
        isApproved: true,
        isSuspended: false,
        isEmailVerified: true,
        isProviderAccount: false,
        profileImageUrl: null,
      ),
    ];
  }
}
