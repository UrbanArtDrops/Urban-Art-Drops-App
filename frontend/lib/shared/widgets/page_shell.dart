import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:go_router/go_router.dart";
import "package:urban_art_drops_app/l10n/app_localizations.dart";

import "../../features/authentication/presentation/bloc/auth_session_cubit.dart";

class PageShell extends StatelessWidget {
  const PageShell({
    required this.title,
    required this.body,
    this.actions = const <Widget>[],
    this.expandBodyToViewport = false,
    super.key,
  });

  final String title;
  final Widget body;
  final List<Widget> actions;
  final bool expandBodyToViewport;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocBuilder<AuthSessionCubit, AuthSessionState>(
      builder: (context, authState) {
        final navigation = _buildNavigationEntries(l10n, authState);
        final path = GoRouterState.of(context).uri.path;
        final canNavigateBack = context.canPop();

        return Scaffold(
          appBar: AppBar(
            title: Text(title),
            actions: [
              IconButton(
                tooltip: l10n.backAction,
                onPressed: canNavigateBack ? () => context.pop() : null,
                icon: const Icon(Icons.arrow_back),
              ),
              ...actions,
            ],
          ),
          drawer: Drawer(
            child: SafeArea(
              child: ListView(
                children: navigation
                    .map(
                      (entry) => entry.isDivider
                          ? const Divider(height: 24)
                          : ListTile(
                              selected: path == entry.path,
                              leading: Icon(entry.icon),
                              title: Text(entry.title),
                              onTap: () {
                                Navigator.of(context).pop();
                                if (entry.path.isNotEmpty) {
                                  context.go(entry.path);
                                }
                              },
                            ),
                    )
                    .toList(growable: false),
              ),
            ),
          ),
          body: SafeArea(
            child: expandBodyToViewport
                ? SizedBox.expand(child: body)
                : Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1200),
                      child: SizedBox.expand(child: body),
                    ),
                  ),
          ),
        );
      },
    );
  }
}

List<_NavigationEntry> _buildNavigationEntries(
  AppLocalizations l10n,
  AuthSessionState authState,
) {
  final isAuthenticated = authState.isAuthenticated;
  final role = authState.role;
  final isArtist = role == AppUserRole.artist;
  final isDropMakerOrArtist =
      role == AppUserRole.dropMaker || role == AppUserRole.artist;
  final isAdmin = role == AppUserRole.admin;

  final entries = <_NavigationEntry>[
    if (isAuthenticated)
      _NavigationEntry("/auth/profile", l10n.menuProfile, Icons.person_outline),
    _NavigationEntry("/", l10n.navMap, Icons.map_outlined),
    _NavigationEntry(
      "/hunter/leaderboard",
      l10n.navLeaderboard,
      Icons.emoji_events_outlined,
    ),
    _NavigationEntry("/hunter/drops", l10n.navDrops, Icons.view_list_outlined),
    if (isArtist)
      _NavigationEntry(
        "/artist/art-pieces",
        l10n.menuMyArt,
        Icons.palette_outlined,
      ),
    if (isDropMakerOrArtist)
      _NavigationEntry(
        "/drop-maker/art-pieces",
        l10n.menuArtWorks,
        Icons.collections_bookmark_outlined,
      ),
    if (isDropMakerOrArtist)
      _NavigationEntry(
        "/drop-maker/drops",
        l10n.menuMyDrops,
        Icons.inventory_2_outlined,
      ),
    if (isDropMakerOrArtist)
      _NavigationEntry(
        "/moderation/reports",
        l10n.navModeration,
        Icons.gavel_outlined,
      ),
    if (isAdmin)
      _NavigationEntry(
        "/admin/configuration",
        l10n.menuSettings,
        Icons.settings_outlined,
      ),
    if (isAdmin)
      _NavigationEntry("/admin/users", l10n.menuUsers, Icons.groups_outlined),
    const _NavigationEntry.divider(),
    _NavigationEntry("/auth/login", l10n.navLogin, Icons.login_outlined),
    _NavigationEntry(
      "/auth/register",
      l10n.navRegister,
      Icons.person_add_outlined,
    ),
  ];

  return entries;
}

class _NavigationEntry {
  const _NavigationEntry(this.path, this.title, this.icon) : isDivider = false;

  const _NavigationEntry.divider()
    : path = "",
      title = "",
      icon = Icons.horizontal_rule,
      isDivider = true;

  final String path;
  final String title;
  final IconData icon;
  final bool isDivider;
}
