import "package:flutter/material.dart";
import "package:urban_art_drops_app/l10n/app_localizations.dart";

import "../../../../shared/widgets/page_shell.dart";

class ModerationPage extends StatelessWidget {
  const ModerationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return PageShell(
      title: l10n.moderationTitle,
      body: ListView(
        children: [
          Card(
            child: ListTile(
              title: Text(l10n.reportedCommentTitle),
              subtitle: Text(l10n.reportedCommentSubtitle),
            ),
          ),
          Card(
            child: ListTile(
              title: Text(l10n.reportedArtPieceTitle),
              subtitle: Text(l10n.reportedArtPieceSubtitle),
            ),
          ),
        ],
      ),
    );
  }
}
