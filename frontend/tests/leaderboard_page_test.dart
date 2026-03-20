import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:go_router/go_router.dart";
import "package:urban_art_drops_app/features/authentication/presentation/bloc/auth_session_cubit.dart";
import "package:urban_art_drops_app/features/discovery/presentation/pages/leaderboard_page.dart";
import "package:urban_art_drops_app/l10n/app_localizations.dart";
import "package:urban_art_drops_app/shared/models/app_models.dart";
import "package:urban_art_drops_app/shared/services/app_api_client.dart";

void main() {
  testWidgets(
    "highlights the signed-in user, expands the own claims, and centers the entry",
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(640, 720));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final authCubit = AuthSessionCubit()
        ..signIn(
          userId: "user-15",
          email: "hunter15@example.com",
          userName: "Hunter 15",
          role: AppUserRole.hunter,
          accessToken: "hunter-token",
          accessTokenExpiresAtUtc: DateTime.utc(2099, 3, 20, 18),
        );

      await tester.pumpWidget(
        _LeaderboardHarness(
          authCubit: authCubit,
          apiClient: _FakeLeaderboardApiClient(
            users: _buildUsers(25),
            artPieces: _buildArtPieces(25),
            drops: _buildDrops(25),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final ownEntryKey = const ValueKey("leaderboard-entry-user:user-15");
      final ownDropTitle = "Ranked Drop 15";

      expect(find.byKey(ownEntryKey), findsOneWidget);
      expect(find.text(ownDropTitle), findsOneWidget);

      final ownEntryCard = tester.widget<Card>(find.byKey(ownEntryKey));
      final theme = ThemeData(useMaterial3: true);
      expect(ownEntryCard.color, theme.colorScheme.primaryContainer);

      final scrollable = tester.state<ScrollableState>(
        find.byType(Scrollable).first,
      );
      expect(scrollable.position.pixels, greaterThan(0));

      final ownEntryRect = tester.getRect(find.byKey(ownEntryKey));
      final screenCenter =
          tester.view.physicalSize.height / tester.view.devicePixelRatio / 2;
      expect((ownEntryRect.center.dy - screenCenter).abs(), lessThan(170));
    },
  );

  testWidgets(
    "renders gold, silver, and bronze medals for the configured ranks",
    (tester) async {
      await tester.pumpWidget(
        _LeaderboardHarness(
          authCubit: AuthSessionCubit(),
          apiClient: _FakeLeaderboardApiClient(
            users: _buildUsers(51),
            artPieces: _buildArtPieces(51),
            drops: _buildDrops(51, descendingClaims: true),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        tester
            .widget<CircleAvatar>(
              find.byKey(const ValueKey("leaderboard-rank-badge-1")),
            )
            .backgroundColor,
        const Color(0xFFD4AF37).withValues(alpha: 0.18),
      );
      expect(
        tester
            .widget<CircleAvatar>(
              find.byKey(const ValueKey("leaderboard-rank-badge-2")),
            )
            .backgroundColor,
        const Color(0xFFC0C0C0).withValues(alpha: 0.18),
      );

      await tester.scrollUntilVisible(
        find.byKey(const ValueKey("leaderboard-rank-badge-21")),
        400,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(
        tester
            .widget<CircleAvatar>(
              find.byKey(const ValueKey("leaderboard-rank-badge-21")),
            )
            .backgroundColor,
        const Color(0xFFCD7F32).withValues(alpha: 0.18),
      );

      await tester.scrollUntilVisible(
        find.byKey(const ValueKey("leaderboard-rank-badge-51")),
        400,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byKey(const ValueKey("leaderboard-rank-badge-51")),
          matching: find.text("51"),
        ),
        findsOneWidget,
      );
    },
  );
}

class _LeaderboardHarness extends StatelessWidget {
  const _LeaderboardHarness({required this.authCubit, required this.apiClient});

  final AuthSessionCubit authCubit;
  final AppApiClient apiClient;

  @override
  Widget build(BuildContext context) {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: "/hunter/leaderboard",
          builder: (context, state) => LeaderboardPage(apiClient: apiClient),
        ),
      ],
      initialLocation: "/hunter/leaderboard",
    );

    return BlocProvider.value(
      value: authCubit,
      child: MaterialApp.router(
        theme: ThemeData(useMaterial3: true),
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );
  }
}

class _FakeLeaderboardApiClient extends AppApiClient {
  _FakeLeaderboardApiClient({
    required List<ManagedUser> users,
    required List<ArtPieceModel> artPieces,
    required List<DropModel> drops,
  }) : _users = List<ManagedUser>.from(users),
       _artPieces = List<ArtPieceModel>.from(artPieces),
       _drops = List<DropModel>.from(drops),
       super(baseUrl: "http://localhost");

  final List<ManagedUser> _users;
  final List<ArtPieceModel> _artPieces;
  final List<DropModel> _drops;

  @override
  Future<List<ManagedUser>> getUserDirectory() async {
    return List<ManagedUser>.from(_users);
  }

  @override
  Future<List<ArtPieceModel>> getArtPieces() async {
    return List<ArtPieceModel>.from(_artPieces);
  }

  @override
  Future<List<DropModel>> getDrops() async {
    return List<DropModel>.from(_drops);
  }
}

List<ManagedUser> _buildUsers(int count) {
  return List<ManagedUser>.generate(count, (index) {
    final rank = index + 1;
    final label = rank.toString().padLeft(2, "0");
    return ManagedUser(
      id: "user-$rank",
      email: "hunter$rank@example.com",
      userName: "Hunter $label",
      role: AppUserRole.hunter.index,
      pendingRoleApplication: null,
      pendingRoleApplicationRequestedAtUtc: null,
      isApproved: true,
      isSuspended: false,
      isEmailVerified: true,
      isProviderAccount: false,
      profileImageUrl: null,
    );
  }, growable: false);
}

List<ArtPieceModel> _buildArtPieces(int count) {
  return List<ArtPieceModel>.generate(count, (index) {
    final rank = index + 1;
    return ArtPieceModel(
      id: "art-$rank",
      artistId: "artist-$rank",
      createdByUserId: "artist-$rank",
      title: "Ranked Drop $rank",
      subtitle: "Subtitle $rank",
      description: "Description for ranked drop $rank that is long enough.",
      assetKind: 0,
      isPublished: true,
      isReported: false,
      reportReason: null,
      reportedAtUtc: null,
      photoUrls: const [],
      assetFile: null,
    );
  }, growable: false);
}

List<DropModel> _buildDrops(int count, {bool descendingClaims = false}) {
  return List<DropModel>.generate(count, (index) {
    final rank = index + 1;
    final claimCount = descendingClaims ? count - index : 1;
    final items = List<DropItemModel>.generate(
      claimCount,
      (itemIndex) => DropItemModel(
        id: "drop-$rank-item-$itemIndex",
        qrToken: "qr-$rank-$itemIndex",
        claimUrl: "https://example.test/claim/$rank/$itemIndex",
        isClaimed: true,
        claimedByUserId: "user-$rank",
        claimedByAnonymousNickname: null,
        claimedAtUtc: DateTime.utc(2026, 3, 20, 12),
      ),
      growable: false,
    );

    return DropModel(
      id: "drop-$rank",
      artPieceId: "art-$rank",
      dropMakerId: "drop-maker-$rank",
      isStationary: true,
      portableItemCount: null,
      dropMakerComment: null,
      socialChannels: const [],
      latitude: 52.52,
      longitude: 13.405,
      isPublished: true,
      locationPhotoUrls: const [],
      itemCount: claimCount,
      claimedItemCount: claimCount,
      items: items,
    );
  }, growable: false);
}
