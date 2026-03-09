import "package:flutter/material.dart";
import "package:urban_art_drops_app/l10n/app_localizations.dart";

import "../../../../shared/widgets/page_shell.dart";

class LeaderboardPage extends StatelessWidget {
  const LeaderboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return PageShell(
      title: l10n.navLeaderboard,
      body: ListView(
        children: [
          Card(
            child: ListTile(
              title: Text(l10n.rankEntry("1", "HunterOne")),
              trailing: const Text("14"),
            ),
          ),
          Card(
            child: ListTile(
              title: Text(l10n.rankEntry("2", "HunterTwo")),
              trailing: const Text("9"),
            ),
          ),
        ],
      ),
    );
  }
}
