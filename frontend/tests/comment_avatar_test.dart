import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:flutter_test/flutter_test.dart";
import "package:go_router/go_router.dart";
import "package:urban_art_drops_app/features/authentication/application/auth_session_storage.dart";
import "package:urban_art_drops_app/features/authentication/presentation/bloc/auth_session_cubit.dart";
import "package:urban_art_drops_app/features/discovery/presentation/pages/drop_detail_page.dart";
import "package:urban_art_drops_app/features/moderation/presentation/pages/moderation_page.dart";
import "package:urban_art_drops_app/l10n/app_localizations.dart";
import "package:urban_art_drops_app/shared/models/app_models.dart";
import "package:urban_art_drops_app/shared/services/app_api_client.dart";
import "package:urban_art_drops_app/shared/widgets/user_avatar.dart";

void main() {
  testWidgets("drop detail comments render an author avatar", (tester) async {
    tester.view.physicalSize = const Size(1280, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final authSessionCubit = AuthSessionCubit(
      storage: InMemoryAuthSessionStorage(),
    );
    final apiClient = _FakeCommentApiClient();

    await tester.pumpWidget(
      _CommentTestHarness(
        authSessionCubit: authSessionCubit,
        child: DropDetailPage(dropId: "drop-1", apiClient: apiClient),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining("Comment Author"), findsOneWidget);
    expect(find.text("First comment body"), findsOneWidget);
    expect(find.byType(UserAvatar), findsNWidgets(3));
  });

  testWidgets("moderation comments render an author avatar", (tester) async {
    tester.view.physicalSize = const Size(1280, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final authSessionCubit = AuthSessionCubit(
      storage: InMemoryAuthSessionStorage(),
    );
    authSessionCubit.signIn(
      userId: "moderator-1",
      email: "moderator@example.com",
      userName: "moderator",
      role: AppUserRole.moderator,
      accessToken: "moderator-token",
      accessTokenExpiresAtUtc: DateTime.utc(2099, 3, 20, 18),
    );

    final apiClient = _FakeCommentApiClient();

    await tester.pumpWidget(
      _CommentTestHarness(
        authSessionCubit: authSessionCubit,
        child: ModerationPage(apiClient: apiClient),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining("Comment Author"), findsOneWidget);
    expect(find.text("Reported moderation comment"), findsOneWidget);
    expect(find.byType(UserAvatar), findsOneWidget);
  });
}

class _CommentTestHarness extends StatelessWidget {
  const _CommentTestHarness({
    required this.authSessionCubit,
    required this.child,
  });

  final AuthSessionCubit authSessionCubit;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final router = GoRouter(
      routes: [
        GoRoute(path: "/", builder: (context, state) => child),
        GoRoute(path: "/hunter/drops/:id", builder: (context, state) => child),
      ],
    );

    return BlocProvider.value(
      value: authSessionCubit,
      child: MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );
  }
}

class _FakeCommentApiClient extends AppApiClient {
  @override
  Future<AppConfigurationModel> getAppConfiguration() async {
    return AppConfigurationModel.defaults;
  }

  @override
  Future<DropModel> getDropById(String dropId) async {
    return const DropModel(
      id: "drop-1",
      artPieceId: "art-1",
      dropMakerId: "drop-maker-1",
      isStationary: true,
      portableItemCount: null,
      dropMakerComment: null,
      socialChannels: [],
      latitude: 52.52,
      longitude: 13.405,
      isPublished: true,
      locationPhotoUrls: [],
      itemCount: 1,
      claimedItemCount: 0,
      items: [
        DropItemModel(
          id: "item-1",
          qrToken: "qr-1",
          claimUrl: "https://example.com/claim/1",
          isClaimed: false,
          claimedByUserId: null,
          claimedByAnonymousNickname: null,
          claimedAtUtc: null,
        ),
      ],
    );
  }

  @override
  Future<List<ArtPieceModel>> getArtPieces() async {
    return const [
      ArtPieceModel(
        id: "art-1",
        artistId: "artist-1",
        createdByUserId: "artist-1",
        title: "Artwork",
        subtitle: "Subtitle",
        description: "Artwork description that is long enough for the page.",
        assetKind: 0,
        isPublished: true,
        isReported: false,
        reportReason: null,
        reportedAtUtc: null,
        photoUrls: [],
        assetFile: null,
      ),
    ];
  }

  @override
  Future<List<ManagedUser>> getUserDirectory() async {
    return const [
      ManagedUser(
        id: "artist-1",
        email: "artist@example.com",
        userName: "Artist One",
        role: 1,
        pendingRoleApplication: null,
        pendingRoleApplicationRequestedAtUtc: null,
        isApproved: true,
        isSuspended: false,
        isEmailVerified: true,
        isProviderAccount: false,
        profileImageUrl: "https://example.com/artist.png",
      ),
      ManagedUser(
        id: "drop-maker-1",
        email: "dropmaker@example.com",
        userName: "Drop Maker",
        role: 2,
        pendingRoleApplication: null,
        pendingRoleApplicationRequestedAtUtc: null,
        isApproved: true,
        isSuspended: false,
        isEmailVerified: true,
        isProviderAccount: false,
        profileImageUrl: "https://example.com/drop-maker.png",
      ),
      ManagedUser(
        id: "hunter-1",
        email: "hunter@example.com",
        userName: "Comment Author",
        role: 0,
        pendingRoleApplication: null,
        pendingRoleApplicationRequestedAtUtc: null,
        isApproved: true,
        isSuspended: false,
        isEmailVerified: true,
        isProviderAccount: false,
        profileImageUrl: "https://example.com/hunter.png",
      ),
    ];
  }

  @override
  Future<List<DropCommentModel>> getDropComments(String dropId) async {
    return const [
      DropCommentModel(
        id: "comment-1",
        dropId: "drop-1",
        authorUserId: "hunter-1",
        authorDisplayName: "Comment Author",
        anonymousNickname: null,
        content: "First comment body",
        isReported: false,
        isHidden: false,
        reportReason: null,
        createdAtUtc: null,
        reportedAtUtc: null,
      ),
    ];
  }

  @override
  Future<ModerationQueueModel> getModerationQueue({
    required String actingUserId,
  }) async {
    return const ModerationQueueModel(
      comments: [
        ReportedCommentModel(
          id: "reported-comment-1",
          dropId: "drop-1",
          dropTitle: "Reported drop",
          authorUserId: "hunter-1",
          authorDisplayName: "Comment Author",
          content: "Reported moderation comment",
          reportReason: "Inappropriate",
          createdAtUtc: null,
          reportedAtUtc: null,
        ),
      ],
      artPieces: [],
    );
  }
}
