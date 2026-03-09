import "package:flutter/material.dart";
import "package:urban_art_drops_app/l10n/app_localizations.dart";

import "../../../../shared/widgets/page_shell.dart";

class DropMakerPage extends StatelessWidget {
  const DropMakerPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return PageShell(
      title: l10n.dropMakerTitle,
      body: ListView(
        children: [
          Card(
            child: ListTile(
              title: Text(l10n.dropMakerArtPieceSelection),
              subtitle: Text(l10n.dropMakerCreateDrop),
            ),
          ),
          Card(
            child: ListTile(
              title: Text(l10n.dropMakerPublishTitle),
              subtitle: Text(l10n.dropMakerPublishSubtitle),
            ),
          ),
        ],
      ),
    );
  }
}
