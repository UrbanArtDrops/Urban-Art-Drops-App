import "package:flutter/material.dart";
import "package:flutter_map/flutter_map.dart";
import "package:flutter_test/flutter_test.dart";
import "package:urban_art_drops_app/l10n/app_localizations.dart";
import "package:urban_art_drops_app/shared/widgets/drop_overview_card.dart";

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
}

Widget _buildHarness({
  required bool isFullyClaimed,
  required int claimedItemCount,
  required int itemCount,
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
            description: "Description",
            galleryUrls: const [],
            claimedHunterNames: const [],
            claimedItemCount: claimedItemCount,
            itemCount: itemCount,
            isFullyClaimed: isFullyClaimed,
            unclaimedDropRadiusKm: 3,
            latitude: 52.52,
            longitude: 13.405,
          ),
        ),
      ),
    ),
  );
}
