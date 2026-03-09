import "package:flutter/material.dart";
import "package:urban_art_drops_app/l10n/app_localizations.dart";

import "../../../../shared/widgets/page_shell.dart";

class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return PageShell(
      title: l10n.navRegister,
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          TextField(decoration: InputDecoration(labelText: l10n.usernameLabel)),
          const SizedBox(height: 8),
          TextField(decoration: InputDecoration(labelText: l10n.emailLabel)),
          const SizedBox(height: 8),
          TextField(
            obscureText: true,
            decoration: InputDecoration(labelText: l10n.passwordLabel),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            items: [
              DropdownMenuItem(value: "hunter", child: Text(l10n.roleHunter)),
              DropdownMenuItem(value: "artist", child: Text(l10n.roleArtist)),
              DropdownMenuItem(
                value: "dropmaker",
                child: Text(l10n.roleDropMaker),
              ),
            ],
            onChanged: (_) {},
            decoration: InputDecoration(labelText: l10n.roleLabel),
          ),
          const SizedBox(height: 12),
          FilledButton(onPressed: () {}, child: Text(l10n.registerButton)),
        ],
      ),
    );
  }
}
