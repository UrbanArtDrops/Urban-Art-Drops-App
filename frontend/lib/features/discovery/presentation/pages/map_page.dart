import "package:flutter/material.dart";
import "package:urban_art_drops_app/l10n/app_localizations.dart";

import "../../../../shared/widgets/page_shell.dart";

class MapPage extends StatelessWidget {
  const MapPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return PageShell(
      title: l10n.navMap,
      body: ListView(
        children: [
          Card(
            child: ListTile(
              title: Text(l10n.mapRadiusLabel(l10n.defaultMainRadiusKm)),
              subtitle: Text(
                l10n.mapUnclaimedRadiusLabel(l10n.defaultUnclaimedRadiusKm),
              ),
            ),
          ),
          Card(
            child: SizedBox(
              height: 260,
              child: Center(child: Text(l10n.mapPlaceholder)),
            ),
          ),
        ],
      ),
    );
  }
}
