import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:flutter_test/flutter_test.dart";
import "package:go_router/go_router.dart";
import "package:urban_art_drops_app/features/admin/presentation/pages/admin_content_page.dart";
import "package:urban_art_drops_app/features/authentication/presentation/bloc/auth_session_cubit.dart";
import "package:urban_art_drops_app/l10n/app_localizations.dart";
import "package:urban_art_drops_app/shared/models/app_models.dart";
import "package:urban_art_drops_app/shared/services/app_api_client.dart";

void main() {
  testWidgets("shows global content actions for art pieces and drops", (
    tester,
  ) async {
    final apiClient = _FakeAdminContentApiClient();

    await tester.pumpWidget(_AdminContentHarness(apiClient: apiClient));
    await tester.pumpAndSettle();

    expect(find.text("Admin Art"), findsOneWidget);
    expect(find.text("drop-1"), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, "Publish").first);
    await tester.pumpAndSettle();

    expect(apiClient.publishedArtPieceIds, ["art-1:true"]);
  });
}

class _AdminContentHarness extends StatelessWidget {
  const _AdminContentHarness({required this.apiClient});

  final AppApiClient apiClient;

  @override
  Widget build(BuildContext context) {
    final authCubit = AuthSessionCubit()
      ..signIn(
        userId: "admin-1",
        email: "admin@example.test",
        userName: "Admin",
        role: AppUserRole.admin,
        accessToken: "access-token",
        accessTokenExpiresAtUtc: DateTime.utc(2099, 1, 1),
      );

    final router = GoRouter(
      routes: [
        GoRoute(
          path: "/admin/content",
          builder: (context, state) => AdminContentPage(apiClient: apiClient),
        ),
        GoRoute(
          path: "/artist/art-pieces",
          builder: (context, state) => const SizedBox(),
        ),
        GoRoute(
          path: "/drop-maker/drops",
          builder: (context, state) => const SizedBox(),
        ),
      ],
      initialLocation: "/admin/content",
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

class _FakeAdminContentApiClient extends AppApiClient {
  _FakeAdminContentApiClient() : super(baseUrl: "http://localhost");

  final List<String> publishedArtPieceIds = [];

  @override
  Future<List<ArtPieceModel>> getManageableArtPieces() async {
    return const [
      ArtPieceModel(
        id: "art-1",
        artistId: "artist-1",
        createdByUserId: "artist-1",
        title: "Admin Art",
        subtitle: "Subtitle",
        description: "Description long enough.",
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
  Future<List<DropModel>> getDrops() async {
    return const [
      DropModel(
        id: "drop-1",
        artPieceId: "art-1",
        dropMakerId: "drop-maker-1",
        isStationary: true,
        portableItemCount: null,
        dropMakerComment: null,
        socialChannels: [],
        productionPrinted: true,
        placementConfirmed: true,
        latitude: 52.52,
        longitude: 13.405,
        isPublished: true,
        locationPhotoUrls: [],
        itemCount: 1,
        claimedItemCount: 0,
        items: [],
      ),
    ];
  }

  @override
  Future<void> setArtPiecePublished(String id, bool publish) async {
    publishedArtPieceIds.add("$id:$publish");
  }
}
