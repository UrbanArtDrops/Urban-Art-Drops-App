import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:flutter_test/flutter_test.dart";
import "package:go_router/go_router.dart";
import "package:urban_art_drops_app/features/artist_area/presentation/pages/artist_art_pieces_page.dart";
import "package:urban_art_drops_app/features/authentication/application/auth_session_storage.dart";
import "package:urban_art_drops_app/features/authentication/presentation/bloc/auth_session_cubit.dart";
import "package:urban_art_drops_app/l10n/app_localizations.dart";
import "package:urban_art_drops_app/shared/models/app_models.dart";
import "package:urban_art_drops_app/shared/services/app_api_client.dart";

void main() {
  testWidgets("artist area shows only the signed-in artist's art pieces", (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final authSessionCubit = AuthSessionCubit(
      storage: InMemoryAuthSessionStorage(),
    );
    authSessionCubit.signIn(
      userId: "artist-1",
      email: "artist1@example.com",
      userName: "artist-one",
      role: AppUserRole.artist,
      accessToken: "artist-token",
      accessTokenExpiresAtUtc: DateTime.utc(2099, 3, 17, 18),
    );

    final apiClient = _FakeArtistArtPiecesApiClient(
      artPieces: const [
        ArtPieceModel(
          id: "art-1",
          artistId: "artist-1",
          title: "Owned artwork",
          subtitle: "Primary",
          description: "Owned artwork description that is long enough.",
          assetKind: 0,
          isPublished: false,
          isReported: false,
          reportReason: null,
          reportedAtUtc: null,
          photoUrls: [],
          assetFile: null,
        ),
        ArtPieceModel(
          id: "art-2",
          artistId: "artist-2",
          title: "Foreign artwork",
          subtitle: "Secondary",
          description: "Foreign artwork description that is long enough.",
          assetKind: 0,
          isPublished: true,
          isReported: false,
          reportReason: null,
          reportedAtUtc: null,
          photoUrls: [],
          assetFile: null,
        ),
      ],
      artists: const [
        ManagedUser(
          id: "artist-1",
          email: "artist1@example.com",
          userName: "artist-one",
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
          id: "artist-2",
          email: "artist2@example.com",
          userName: "artist-two",
          role: 1,
          pendingRoleApplication: null,
          pendingRoleApplicationRequestedAtUtc: null,
          isApproved: true,
          isSuspended: false,
          isEmailVerified: true,
          isProviderAccount: false,
          profileImageUrl: null,
        ),
      ],
    );

    await tester.pumpWidget(
      _ArtistArtPiecesHarness(
        authSessionCubit: authSessionCubit,
        apiClient: apiClient,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text("Owned artwork"), findsAtLeastNWidgets(1));
    expect(find.text("Foreign artwork"), findsNothing);
    expect(apiClient.getManageableArtPiecesCallCount, 1);
  });
}

class _ArtistArtPiecesHarness extends StatelessWidget {
  const _ArtistArtPiecesHarness({
    required this.authSessionCubit,
    required this.apiClient,
  });

  final AuthSessionCubit authSessionCubit;
  final AppApiClient apiClient;

  @override
  Widget build(BuildContext context) {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: "/artist/art-pieces",
          builder: (context, state) =>
              ArtistArtPiecesPage(apiClient: apiClient),
        ),
      ],
      initialLocation: "/artist/art-pieces",
    );

    return BlocProvider.value(
      value: authSessionCubit,
      child: MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );
  }
}

class _FakeArtistArtPiecesApiClient extends AppApiClient {
  _FakeArtistArtPiecesApiClient({
    required List<ArtPieceModel> artPieces,
    required List<ManagedUser> artists,
  }) : _artPieces = List<ArtPieceModel>.from(artPieces),
       _artists = List<ManagedUser>.from(artists),
       super(baseUrl: "http://localhost");

  final List<ArtPieceModel> _artPieces;
  final List<ManagedUser> _artists;
  int getManageableArtPiecesCallCount = 0;

  @override
  Future<List<ArtPieceModel>> getManageableArtPieces() async {
    getManageableArtPiecesCallCount += 1;
    return List<ArtPieceModel>.from(_artPieces);
  }

  @override
  Future<List<ManagedUser>> getUserDirectory() async {
    return List<ManagedUser>.from(_artists);
  }
}
