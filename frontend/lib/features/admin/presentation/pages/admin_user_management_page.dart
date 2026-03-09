import "package:flutter/material.dart";
import "package:urban_art_drops_app/l10n/app_localizations.dart";

import "../../../../shared/widgets/page_shell.dart";

class AdminUserManagementPage extends StatelessWidget {
  const AdminUserManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return PageShell(
      title: l10n.navAdminUsers,
      body: ListView(
        children: [
          Card(
            child: ListTile(
              title: Text(
                l10n.userRow("artist.one@example.com", l10n.roleArtist),
              ),
              subtitle: Text(l10n.userRowActions),
            ),
          ),
          Card(
            child: ListTile(
              title: Text(
                l10n.userRow("maker.one@example.com", l10n.roleDropMaker),
              ),
              subtitle: Text(l10n.userRowActions),
            ),
          ),
        ],
      ),
    );
  }
}
