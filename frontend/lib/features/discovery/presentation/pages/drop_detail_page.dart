import "package:flutter/material.dart";
import "package:urban_art_drops_app/l10n/app_localizations.dart";

import "../../../../shared/widgets/page_shell.dart";

class DropDetailPage extends StatelessWidget {
  const DropDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return PageShell(
      title: l10n.dropDetailTitle,
      body: ListView(
        children: [
          Card(
            child: ListTile(
              title: Text(l10n.sampleDropTitle),
              subtitle: Text(l10n.dropDetailDescription),
            ),
          ),
          Card(
            child: ListTile(
              title: Text(l10n.claimedHuntersTitle),
              subtitle: Text(l10n.claimedHuntersValue),
            ),
          ),
        ],
      ),
    );
  }
}
