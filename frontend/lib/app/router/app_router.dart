import "dart:async";

import "package:flutter/foundation.dart";
import "package:go_router/go_router.dart";

import "../../features/admin/presentation/pages/admin_configuration_page.dart";
import "../../features/admin/presentation/pages/admin_content_page.dart";
import "../../features/admin/presentation/pages/admin_user_management_page.dart";
import "../../features/artist_area/presentation/pages/artist_art_pieces_page.dart";
import "../../features/authentication/presentation/bloc/auth_session_cubit.dart";
import "../../features/authentication/presentation/pages/login_page.dart";
import "../../features/authentication/presentation/pages/profile_page.dart";
import "../../features/authentication/presentation/pages/register_page.dart";
import "../../features/discovery/presentation/pages/claim_page.dart";
import "../../features/discovery/presentation/pages/drop_detail_page.dart";
import "../../features/discovery/presentation/pages/drop_list_page.dart";
import "../../features/discovery/presentation/pages/leaderboard_page.dart";
import "../../features/discovery/presentation/pages/map_page.dart";
import "../../features/drop_maker/presentation/pages/drop_maker_page.dart";
import "../../features/drop_maker/presentation/pages/make_drop_wizard_page.dart";
import "../../features/drop_maker/presentation/pages/my_drops_page.dart";
import "../../features/moderation/presentation/pages/moderation_page.dart";

GoRouter createAppRouter(AuthSessionCubit authSessionCubit) {
  return GoRouter(
    initialLocation: "/",
    refreshListenable: _GoRouterRefreshStream(authSessionCubit.stream),
    redirect: (context, state) {
      final session = authSessionCubit.state;
      final path = state.uri.path;
      final routeAccess = _resolveRouteAccess(path);

      if (_isAuthRoute(path) && session.hasValidAccessToken) {
        final from = state.uri.queryParameters["from"];
        if (from != null && from.trim().isNotEmpty && from != path) {
          return from;
        }

        return "/";
      }

      if (routeAccess == _RouteAccess.publicRoute) {
        return null;
      }

      if (!session.isAuthenticated || !session.hasValidAccessToken) {
        final encodedTarget = Uri.encodeComponent(state.uri.toString());
        return "/auth/login?from=$encodedTarget";
      }

      final role = session.role;
      if (!_isAuthorizedForRoute(routeAccess, role)) {
        return "/";
      }

      return null;
    },
    routes: [
      GoRoute(
        path: "/",
        builder: (context, state) =>
            MapPage(focusDropId: state.uri.queryParameters["focusDropId"]),
      ),
      GoRoute(path: "/hunter/map", redirect: (context, state) => "/"),
      GoRoute(
        path: "/hunter/drops",
        builder: (context, state) => const DropListPage(),
      ),
      GoRoute(
        path: "/hunter/drops/:id",
        builder: (context, state) =>
            DropDetailPage(dropId: state.pathParameters["id"]!),
      ),
      GoRoute(
        path: "/hunter/claim",
        builder: (context, state) =>
            ClaimPage(initialToken: state.uri.queryParameters["token"]),
      ),
      GoRoute(
        path: "/hunter/leaderboard",
        builder: (context, state) => const LeaderboardPage(),
      ),
      GoRoute(
        path: "/auth/login",
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: "/auth/profile",
        builder: (context, state) => const ProfilePage(),
      ),
      GoRoute(
        path: "/auth/register",
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: "/artist/art-pieces",
        builder: (context, state) => const ArtistArtPiecesPage(),
      ),
      GoRoute(
        path: "/drop-maker/art-pieces",
        builder: (context, state) => const DropMakerPage(),
      ),
      GoRoute(
        path: "/drop-maker/drops",
        builder: (context, state) => const MyDropsPage(),
      ),
      GoRoute(
        path: "/drop-maker/make-drop-wizard",
        builder: (context, state) => MakeDropWizardPage(
          preselectedArtPieceId: state.uri.queryParameters["artPieceId"],
          resumeDropId: state.uri.queryParameters["dropId"],
        ),
      ),
      GoRoute(
        path: "/moderation/reports",
        builder: (context, state) => const ModerationPage(),
      ),
      GoRoute(
        path: "/admin/configuration",
        builder: (context, state) => const AdminConfigurationPage(),
      ),
      GoRoute(
        path: "/admin/users",
        builder: (context, state) => const AdminUserManagementPage(),
      ),
      GoRoute(
        path: "/admin/content",
        builder: (context, state) => const AdminContentPage(),
      ),
    ],
  );
}

bool _isAuthRoute(String path) =>
    path == "/auth/login" || path == "/auth/register";

_RouteAccess _resolveRouteAccess(String path) {
  if (path == "/auth/profile") {
    return _RouteAccess.authenticated;
  }

  if (path.startsWith("/admin/")) {
    return _RouteAccess.adminOnly;
  }

  if (path == "/artist/art-pieces") {
    return _RouteAccess.artistOnly;
  }

  if (path == "/drop-maker/art-pieces" ||
      path == "/drop-maker/drops" ||
      path == "/drop-maker/make-drop-wizard") {
    return _RouteAccess.dropCreatorOnly;
  }

  if (path == "/moderation/reports") {
    return _RouteAccess.moderationOnly;
  }

  return _RouteAccess.publicRoute;
}

bool _isAuthorizedForRoute(_RouteAccess access, AppUserRole? role) {
  switch (access) {
    case _RouteAccess.publicRoute:
      return true;
    case _RouteAccess.authenticated:
      return role != null;
    case _RouteAccess.artistOnly:
      return role == AppUserRole.artist || role == AppUserRole.admin;
    case _RouteAccess.dropCreatorOnly:
      return role == AppUserRole.artist ||
          role == AppUserRole.dropMaker ||
          role == AppUserRole.admin;
    case _RouteAccess.moderationOnly:
      return role == AppUserRole.artist ||
          role == AppUserRole.dropMaker ||
          role == AppUserRole.moderator ||
          role == AppUserRole.admin;
    case _RouteAccess.adminOnly:
      return role == AppUserRole.admin;
  }
}

enum _RouteAccess {
  publicRoute,
  authenticated,
  artistOnly,
  dropCreatorOnly,
  moderationOnly,
  adminOnly,
}

class _GoRouterRefreshStream extends ChangeNotifier {
  _GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
