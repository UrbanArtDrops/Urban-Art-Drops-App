import "package:flutter/material.dart";
import "package:flutter_map/flutter_map.dart";
import "package:flutter_test/flutter_test.dart";
import "package:urban_art_drops_app/l10n/app_localizations.dart";
import "package:urban_art_drops_app/shared/models/hunter_identity.dart";
import "package:urban_art_drops_app/shared/widgets/drop_overview_card.dart";
import "package:urban_art_drops_app/shared/widgets/user_avatar.dart";

void main() {
  testWidgets("renders an unclaimed radius in the mini map", (tester) async {
    await tester.pumpWidget(
      _buildHarness(isFullyClaimed: false, claimedItemCount: 0, itemCount: 3),
    );

    expect(find.byType(CircleLayer), findsOneWidget);
    expect(find.byType(MarkerLayer), findsNothing);
  });

  testWidgets("renders a marker for a fully claimed mini map", (tester) async {
    await tester.pumpWidget(
      _buildHarness(isFullyClaimed: true, claimedItemCount: 3, itemCount: 3),
    );

    expect(find.byType(MarkerLayer), findsOneWidget);
    expect(find.byType(CircleLayer), findsNothing);
  });

  testWidgets("renders a marker for the owner view of an unclaimed drop", (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildHarness(
        isFullyClaimed: false,
        claimedItemCount: 1,
        itemCount: 3,
        showPreciseLocationForUnclaimed: true,
      ),
    );

    expect(find.byType(CircleLayer), findsOneWidget);
    expect(find.byType(MarkerLayer), findsOneWidget);
  });

  testWidgets("renders side tabs for multi-image carousels", (tester) async {
    await tester.pumpWidget(
      _buildHarness(
        isFullyClaimed: true,
        claimedItemCount: 3,
        itemCount: 3,
        galleryUrls: const [
          "https://example.com/one.png",
          "https://example.com/two.png",
        ],
      ),
    );

    expect(find.byKey(const ValueKey("carousel-tab-previous")), findsOneWidget);
    expect(find.byKey(const ValueKey("carousel-tab-next")), findsOneWidget);
  });

  testWidgets("renders artist and drop-maker profile chips", (tester) async {
    await tester.pumpWidget(
      _buildHarness(isFullyClaimed: true, claimedItemCount: 3, itemCount: 3),
    );

    expect(find.byType(UserIdentityChip), findsNWidgets(2));
    expect(find.text("Artist: Artist"), findsOneWidget);
    expect(find.text("Drop-Maker: Drop-Maker"), findsOneWidget);
  });

  testWidgets("renders claimed hunters with profile avatars", (tester) async {
    await tester.pumpWidget(
      _buildHarness(
        isFullyClaimed: true,
        claimedItemCount: 2,
        itemCount: 3,
        claimedHunters: const [
          HunterIdentity(
            name: "Hunter One",
            imageUrl: "https://example.com/hunter-one.png",
          ),
          HunterIdentity(name: "Hunter Two"),
        ],
      ),
    );

    expect(find.text("Hunter One"), findsOneWidget);
    expect(find.text("Hunter Two"), findsOneWidget);
    expect(find.byType(UserAvatar), findsWidgets);
  });
}

Widget _buildHarness({
  required bool isFullyClaimed,
  required int claimedItemCount,
  required int itemCount,
  List<String> galleryUrls = const [],
  List<HunterIdentity> claimedHunters = const [],
  bool showPreciseLocationForUnclaimed = false,
}) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Builder(
      builder: (context) => Scaffold(
        body: SingleChildScrollView(
          child: DropOverviewCard(
            l10n: AppLocalizations.of(context)!,
            title: "Drop",
            subtitle: "Subtitle",
            artistName: "Artist",
            dropMakerName: "Drop-Maker",
            description: "Description",
            galleryUrls: galleryUrls,
            claimedHunters: claimedHunters,
            claimedItemCount: claimedItemCount,
            itemCount: itemCount,
            isFullyClaimed: isFullyClaimed,
            unclaimedDropRadiusKm: 3,
            showPreciseLocationForUnclaimed: showPreciseLocationForUnclaimed,
            latitude: 52.52,
            longitude: 13.405,
          ),
        ),
      ),
    ),
  );
}
