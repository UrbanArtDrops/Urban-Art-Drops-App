import "package:flutter/material.dart";
import "package:urban_art_drops_app/l10n/app_localizations.dart";

import "../../../../shared/widgets/page_shell.dart";

class ArtistArtPiecesPage extends StatelessWidget {
  const ArtistArtPiecesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return PageShell(
      title: l10n.artistArtPiecesTitle,
      body: ListView(
        children: [
          Card(
            child: ListTile(
              title: Text(l10n.sampleArtPieceTitle),
              subtitle: Text(l10n.sampleArtPieceSubtitle),
            ),
          ),
          Card(
            child: ListTile(
              title: Text(l10n.artistDropManagerTitle),
              subtitle: Text(l10n.artistDropManagerSubtitle),
            ),
          ),
        ],
      ),
    );
  }
}
