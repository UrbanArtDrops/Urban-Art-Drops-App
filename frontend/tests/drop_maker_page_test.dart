import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:go_router/go_router.dart";
import "package:urban_art_drops_app/features/authentication/presentation/bloc/auth_session_cubit.dart";
import "package:urban_art_drops_app/features/drop_maker/presentation/pages/drop_maker_page.dart";
import "package:urban_art_drops_app/l10n/app_localizations.dart";
import "package:urban_art_drops_app/shared/models/app_models.dart";
import "package:urban_art_drops_app/shared/services/app_api_client.dart";

void main() {
  testWidgets(
    "shows all published artworks for moderator and hides unpublished ones",
    (tester) async {
      final authCubit = AuthSessionCubit()
        ..signIn(
          userId: "moderator-1",
          email: "moderator@example.com",
          userName: "Moderator",
          role: AppUserRole.moderator,
          accessToken: "moderator-token",
          accessTokenExpiresAtUtc: DateTime.utc(2099, 3, 20, 12),
        );

      await tester.pumpWidget(
        _DropMakerPageHarness(
          authCubit: authCubit,
          apiClient: _FakeDropMakerPageApiClient(
            artPieces: const [
              ArtPieceModel(
                id: "art-1",
                artistId: "artist-1",
                createdByUserId: "artist-1",
                title: "Published artwork",
                subtitle: "Visible",
                description: "Published artwork description long enough.",
                assetKind: 0,
                isPublished: true,
                isReported: false,
                reportReason: null,
                reportedAtUtc: null,
                photoUrls: [],
                assetFile: null,
              ),
              ArtPieceModel(
                id: "art-2",
                artistId: "artist-2",
                createdByUserId: "artist-2",
                title: "Draft artwork",
                subtitle: "Hidden",
                description: "Draft artwork description long enough.",
                assetKind: 0,
                isPublished: false,
                isReported: false,
                reportReason: null,
                reportedAtUtc: null,
                photoUrls: [],
                assetFile: null,
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text("Published artwork"), findsOneWidget);
      expect(find.text("Draft artwork"), findsNothing);
    },
  );
}

class _DropMakerPageHarness extends StatelessWidget {
  const _DropMakerPageHarness({
    required this.authCubit,
    required this.apiClient,
  });

  final AuthSessionCubit authCubit;
  final AppApiClient apiClient;

  @override
  Widget build(BuildContext context) {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: "/drop-maker/art-pieces",
          builder: (context, state) => DropMakerPage(apiClient: apiClient),
        ),
      ],
      initialLocation: "/drop-maker/art-pieces",
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

class _FakeDropMakerPageApiClient extends AppApiClient {
  _FakeDropMakerPageApiClient({required List<ArtPieceModel> artPieces})
    : _artPieces = List<ArtPieceModel>.from(artPieces),
      super(baseUrl: "http://localhost");

  final List<ArtPieceModel> _artPieces;

  @override
  Future<List<ArtPieceModel>> getArtPieces() async {
    return List<ArtPieceModel>.from(_artPieces);
  }
}
