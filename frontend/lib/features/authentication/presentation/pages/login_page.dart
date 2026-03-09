import "package:flutter/material.dart";
import "package:urban_art_drops_app/l10n/app_localizations.dart";

import "../../../../shared/widgets/page_shell.dart";

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return PageShell(
      title: l10n.navLogin,
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          TextField(decoration: InputDecoration(labelText: l10n.emailLabel)),
          const SizedBox(height: 8),
          TextField(
            obscureText: true,
            decoration: InputDecoration(labelText: l10n.passwordLabel),
          ),
          const SizedBox(height: 12),
          FilledButton(onPressed: () {}, child: Text(l10n.navLogin)),
          const SizedBox(height: 12),
          Text(l10n.providerLoginTitle),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton(onPressed: () {}, child: const Text("Google")),
              OutlinedButton(onPressed: () {}, child: const Text("Facebook")),
              OutlinedButton(onPressed: () {}, child: const Text("Instagram")),
              OutlinedButton(onPressed: () {}, child: const Text("TikTok")),
            ],
          ),
        ],
      ),
    );
  }
}
