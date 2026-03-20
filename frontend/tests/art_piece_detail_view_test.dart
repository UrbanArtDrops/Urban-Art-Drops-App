import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:urban_art_drops_app/features/artist_area/presentation/widgets/art_piece_detail_view.dart";
import "package:urban_art_drops_app/l10n/app_localizations.dart";
import "package:urban_art_drops_app/shared/models/app_models.dart";

void main() {
  testWidgets("renders side tabs for multi-image artwork galleries", (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: ArtPieceDetailView(
            artPiece: const ArtPieceModel(
              id: "art-1",
              artistId: "artist-1",
              createdByUserId: "artist-1",
              title: "Artwork",
              subtitle: "Subtitle",
              description: "Long enough description for widget testing.",
              assetKind: 0,
              isPublished: true,
              isReported: false,
              reportReason: null,
              reportedAtUtc: null,
              photoUrls: [
                "https://example.com/one.png",
                "https://example.com/two.png",
              ],
              assetFile: null,
            ),
            artistName: "Artist",
            onDownloadAsset: null,
            onEdit: null,
            onDelete: null,
            onTogglePublished: null,
          ),
        ),
      ),
    );

    expect(find.byKey(const ValueKey("carousel-tab-previous")), findsOneWidget);
    expect(find.byKey(const ValueKey("carousel-tab-next")), findsOneWidget);
  });
}
