import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:go_router/go_router.dart";
import "package:urban_art_drops_app/l10n/app_localizations.dart";

import "../../app/router/app_navigation_history.dart";
import "../../features/authentication/presentation/bloc/auth_session_cubit.dart";

class PageShell extends StatelessWidget {
  const PageShell({
    required this.title,
    required this.body,
    this.actions = const <Widget>[],
    this.expandBodyToViewport = false,
    this.drawerWidth,
    this.minDrawerWidth = 280,
    this.maxDrawerWidth = 420,
    this.floatingActionButton,
    super.key,
  });

  final String title;
  final Widget body;
  final List<Widget> actions;
  final bool expandBodyToViewport;
  final double? drawerWidth;
  final double minDrawerWidth;
  final double maxDrawerWidth;
  final Widget? floatingActionButton;

  double _resolveDrawerWidth(BuildContext context) {
    final viewportWidth = MediaQuery.sizeOf(context).width;
    final availableWidth = (viewportWidth - 16).clamp(0.0, double.infinity);

    if (drawerWidth != null) {
      return drawerWidth!.clamp(0.0, availableWidth).toDouble();
    }

    final normalizedMin = minDrawerWidth.clamp(0.0, availableWidth).toDouble();
    final normalizedMax = maxDrawerWidth
        .clamp(normalizedMin, availableWidth)
        .toDouble();
    final responsiveWidth = viewportWidth < 720 ? viewportWidth * 0.9 : 360.0;

    return responsiveWidth.clamp(normalizedMin, normalizedMax).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocBuilder<AuthSessionCubit, AuthSessionState>(
      builder: (context, authState) {
        final path = GoRouterState.of(context).uri.path;
        final currentLocation = GoRouterState.of(context).uri.toString();
        final router = GoRouter.of(context);
        final navigator = Navigator.of(context);
        final canNavigateBack =
            router.canPop() ||
            navigator.canPop() ||
            AppNavigationHistory.instance.canGoBack(currentLocation);

        return Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            leadingWidth: canNavigateBack ? 104 : 56,
            leading: _PageShellLeading(
              showBackButton: canNavigateBack,
              backTooltip: l10n.backAction,
              onBackPressed: () =>
                  _handleBackNavigation(context, currentLocation),
            ),
            title: Text(title),
            actions: [...actions],
          ),
          floatingActionButton: floatingActionButton,
          drawer: Drawer(
            width: _resolveDrawerWidth(context),
            child: SafeArea(
              child: ListView(
                children: _buildNavigationEntries(l10n, authState)
                    .map(
                      (entry) => entry.isDivider
                          ? const Divider(height: 24)
                          : ListTile(
                              selected: path == entry.path,
                              leading: Icon(entry.icon),
                              title: Text(entry.title),
                              onTap: () {
                                Navigator.of(context).pop();
                                if (entry.isSignOut) {
                                  context.read<AuthSessionCubit>().signOut();
                                  context.go("/");
                                  return;
                                }

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

void _handleBackNavigation(BuildContext context, String currentLocation) {
  final router = GoRouter.of(context);
  final navigator = Navigator.of(context);

  if (router.canPop()) {
    router.pop();
    return;
  }

  if (navigator.canPop()) {
    navigator.pop();
    return;
  }

  final targetLocation = AppNavigationHistory.instance.beginBackNavigation(
    currentLocation,
  );
  if (targetLocation != null && targetLocation != currentLocation) {
    context.go(targetLocation);
  }
}

class _PageShellLeading extends StatelessWidget {
  const _PageShellLeading({
    required this.showBackButton,
    required this.backTooltip,
    required this.onBackPressed,
  });

  final bool showBackButton;
  final String backTooltip;
  final VoidCallback onBackPressed;

  @override
  Widget build(BuildContext context) {
    final menuTooltip = MaterialLocalizations.of(context).openAppDrawerTooltip;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Builder(
          builder: (context) => IconButton(
            tooltip: menuTooltip,
            onPressed: Scaffold.of(context).openDrawer,
            icon: const Icon(Icons.menu),
          ),
        ),
        if (showBackButton)
          IconButton(
            tooltip: backTooltip,
            onPressed: onBackPressed,
            icon: const Icon(Icons.arrow_back),
          ),
      ],
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
  final isAdmin = role == AppUserRole.admin;
  final isModerator = role == AppUserRole.moderator;
  final isDropMakerOrArtistOrAdmin =
      role == AppUserRole.dropMaker ||
      role == AppUserRole.artist ||
      role == AppUserRole.admin;
  final canBrowsePublishedArtWorks =
      role == AppUserRole.dropMaker ||
      role == AppUserRole.artist ||
      role == AppUserRole.moderator ||
      role == AppUserRole.admin;
  final artWorksPath = isAdmin
      ? "/artist/art-pieces"
      : "/drop-maker/art-pieces";

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
    if (canBrowsePublishedArtWorks)
      _NavigationEntry(
        artWorksPath,
        l10n.menuArtWorks,
        Icons.collections_bookmark_outlined,
      ),
    if (isDropMakerOrArtistOrAdmin)
      _NavigationEntry(
        "/drop-maker/drops",
        l10n.menuMyDrops,
        Icons.inventory_2_outlined,
      ),
    if (isDropMakerOrArtistOrAdmin || isModerator)
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
    if (isAuthenticated)
      _NavigationEntry.signOut(l10n.logoutButton, Icons.logout_outlined),
    if (!isAuthenticated)
      _NavigationEntry("/auth/login", l10n.navLogin, Icons.login_outlined),
    if (!isAuthenticated)
      _NavigationEntry(
        "/auth/register",
        l10n.navRegister,
        Icons.person_add_outlined,
      ),
  ];

  return entries;
}

class _NavigationEntry {
  const _NavigationEntry(this.path, this.title, this.icon)
    : isDivider = false,
      isSignOut = false;

  const _NavigationEntry.signOut(this.title, this.icon)
    : path = "",
      isDivider = false,
      isSignOut = true;

  const _NavigationEntry.divider()
    : path = "",
      title = "",
      icon = Icons.horizontal_rule,
      isDivider = true,
      isSignOut = false;

  final String path;
  final String title;
  final IconData icon;
  final bool isDivider;
  final bool isSignOut;
}
