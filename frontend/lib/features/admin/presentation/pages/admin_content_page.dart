import "package:flutter/material.dart";
import "package:urban_art_drops_app/l10n/app_localizations.dart";

import "../../../../shared/widgets/page_shell.dart";

class AdminContentPage extends StatelessWidget {
  const AdminContentPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return PageShell(
      title: l10n.navAdminContent,
      body: ListView(
        children: [
          Card(
            child: ListTile(
              title: Text(l10n.globalArtPieceModerationTitle),
              subtitle: Text(l10n.globalArtPieceModerationSubtitle),
            ),
          ),
          Card(
            child: ListTile(
              title: Text(l10n.globalDropModerationTitle),
              subtitle: Text(l10n.globalDropModerationSubtitle),
            ),
          ),
        ],
      ),
    );
  }
}
