import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:urban_art_drops_app/l10n/app_localizations.dart";

import "../../../../shared/widgets/page_shell.dart";
import "../bloc/auth_session_cubit.dart";

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return PageShell(
      title: l10n.menuProfile,
      body: BlocBuilder<AuthSessionCubit, AuthSessionState>(
        builder: (context, state) {
          if (!state.isAuthenticated || state.role == null) {
            return Center(child: Text(l10n.profileNotLoggedIn));
          }

          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              Card(
                child: ListTile(
                  title: Text(state.displayName ?? "User"),
                  subtitle: Text(
                    l10n.profileRoleLabel(_roleLabel(l10n, state.role!)),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: () => context.read<AuthSessionCubit>().signOut(),
                child: Text(l10n.logoutButton),
              ),
            ],
          );
        },
      ),
    );
  }
}

String _roleLabel(AppLocalizations l10n, AppUserRole role) {
  switch (role) {
    case AppUserRole.hunter:
      return l10n.roleHunter;
    case AppUserRole.artist:
      return l10n.roleArtist;
    case AppUserRole.dropMaker:
      return l10n.roleDropMaker;
    case AppUserRole.moderator:
      return l10n.navModeration;
    case AppUserRole.admin:
      return l10n.menuSettings;
  }
}
