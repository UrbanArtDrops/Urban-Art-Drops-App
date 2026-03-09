import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:urban_art_drops_app/l10n/app_localizations.dart";

import "../../../../shared/widgets/page_shell.dart";

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final links = <_HomeLink>[
      _HomeLink(l10n.navMap, "/hunter/map"),
      _HomeLink(l10n.navDrops, "/hunter/drops"),
      _HomeLink(l10n.navLeaderboard, "/hunter/leaderboard"),
      _HomeLink(l10n.navLogin, "/auth/login"),
      _HomeLink(l10n.navRegister, "/auth/register"),
      _HomeLink(l10n.navArtistArea, "/artist/art-pieces"),
      _HomeLink(l10n.navDropMakerArea, "/drop-maker/art-pieces"),
      _HomeLink(l10n.navModeration, "/moderation/reports"),
      _HomeLink(l10n.navAdminConfig, "/admin/configuration"),
      _HomeLink(l10n.navAdminUsers, "/admin/users"),
      _HomeLink(l10n.navAdminContent, "/admin/content"),
    ];

    return PageShell(
      title: l10n.appTitle,
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: links.length,
        itemBuilder: (context, index) {
          final item = links[index];
          return Card(
            child: ListTile(
              title: Text(item.title),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.go(item.path),
            ),
          );
        },
      ),
    );
  }
}

class _HomeLink {
  _HomeLink(this.title, this.path);

  final String title;
  final String path;
}
