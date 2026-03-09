import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:go_router/go_router.dart";
import "package:urban_art_drops_app/l10n/app_localizations.dart";

import "../../../../shared/widgets/page_shell.dart";
import "../bloc/auth_session_cubit.dart";

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  AppUserRole _selectedRole = AppUserRole.hunter;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _login() {
    context.read<AuthSessionCubit>().signIn(
      role: _selectedRole,
      displayName: _emailController.text,
    );
    context.go("/");
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return PageShell(
      title: l10n.navLogin,
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          TextField(
            controller: _emailController,
            decoration: InputDecoration(labelText: l10n.emailLabel),
          ),
          const SizedBox(height: 8),
          TextField(
            obscureText: true,
            decoration: InputDecoration(labelText: l10n.passwordLabel),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<AppUserRole>(
            initialValue: _selectedRole,
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedRole = value);
              }
            },
            items: [
              DropdownMenuItem(
                value: AppUserRole.hunter,
                child: Text(l10n.roleHunter),
              ),
              DropdownMenuItem(
                value: AppUserRole.artist,
                child: Text(l10n.roleArtist),
              ),
              DropdownMenuItem(
                value: AppUserRole.dropMaker,
                child: Text(l10n.roleDropMaker),
              ),
              DropdownMenuItem(
                value: AppUserRole.admin,
                child: Text(l10n.menuSettings),
              ),
            ],
            decoration: InputDecoration(labelText: l10n.roleLabel),
          ),
          const SizedBox(height: 12),
          FilledButton(onPressed: _login, child: Text(l10n.navLogin)),
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
