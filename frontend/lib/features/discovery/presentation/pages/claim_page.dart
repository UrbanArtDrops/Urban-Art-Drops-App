import "package:flutter/material.dart";
import "package:urban_art_drops_app/l10n/app_localizations.dart";

import "../../../../shared/widgets/page_shell.dart";

class ClaimPage extends StatelessWidget {
  const ClaimPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final nicknameController = TextEditingController();

    return PageShell(
      title: l10n.claimTitle,
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Text(l10n.claimInstruction),
          const SizedBox(height: 12),
          TextField(
            controller: nicknameController,
            decoration: InputDecoration(labelText: l10n.nicknameLabel),
          ),
          const SizedBox(height: 12),
          FilledButton(onPressed: () {}, child: Text(l10n.claimButton)),
        ],
      ),
    );
  }
}
