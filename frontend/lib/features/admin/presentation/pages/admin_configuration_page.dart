import "package:flutter/material.dart";
import "package:urban_art_drops_app/l10n/app_localizations.dart";

import "../../../../shared/widgets/page_shell.dart";

class AdminConfigurationPage extends StatelessWidget {
  const AdminConfigurationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return PageShell(
      title: l10n.navAdminConfig,
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          TextField(decoration: InputDecoration(labelText: l10n.smtpLabel)),
          const SizedBox(height: 8),
          TextField(
            decoration: InputDecoration(labelText: l10n.mainMapRadiusSetting),
          ),
          const SizedBox(height: 8),
          TextField(
            decoration: InputDecoration(labelText: l10n.miniMapRadiusSetting),
          ),
          const SizedBox(height: 8),
          TextField(
            decoration: InputDecoration(labelText: l10n.unclaimedRadiusSetting),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            value: true,
            onChanged: (_) {},
            title: Text(l10n.showExactPositionSetting),
          ),
          FilledButton(onPressed: () {}, child: Text(l10n.saveButton)),
        ],
      ),
    );
  }
}
