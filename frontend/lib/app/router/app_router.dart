import "package:go_router/go_router.dart";

import "../../features/admin/presentation/pages/admin_configuration_page.dart";
import "../../features/admin/presentation/pages/admin_content_page.dart";
import "../../features/admin/presentation/pages/admin_user_management_page.dart";
import "../../features/artist_area/presentation/pages/artist_art_pieces_page.dart";
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

final GoRouter appRouter = GoRouter(
  initialLocation: "/",
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
      builder: (context, state) => const ClaimPage(),
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
