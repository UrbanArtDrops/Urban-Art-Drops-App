import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:flutter_test/flutter_test.dart";
import "package:go_router/go_router.dart";
import "package:urban_art_drops_app/features/authentication/application/auth_session_storage.dart";
import "package:urban_art_drops_app/features/authentication/presentation/bloc/auth_session_cubit.dart";
import "package:urban_art_drops_app/features/authentication/presentation/pages/profile_page.dart";
import "package:urban_art_drops_app/l10n/app_localizations.dart";
import "package:urban_art_drops_app/shared/models/app_models.dart";
import "package:urban_art_drops_app/shared/services/app_api_client.dart";
import "package:urban_art_drops_app/shared/services/local_photo_picker.dart";

void main() {
  testWidgets("loads and saves current profile data", (tester) async {
    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final apiClient = _FakeAppApiClient(
      profile: const CurrentUserProfileModel(
        userId: "user-1",
        email: "before@example.com",
        userName: "Before",
        role: 0,
        pendingRoleApplication: null,
        pendingRoleApplicationRequestedAtUtc: null,
        isProviderAccount: false,
        isMfaEnabled: false,
        isMfaRequiredByPolicy: false,
        profileImageUrl: null,
      ),
    );
    final authSessionCubit = AuthSessionCubit(
      storage: InMemoryAuthSessionStorage(),
    );
    authSessionCubit.signIn(
      userId: "user-1",
      email: "before@example.com",
      userName: "Before",
      role: AppUserRole.hunter,
      accessToken: "token",
      accessTokenExpiresAtUtc: DateTime.utc(2099, 3, 17, 18),
    );

    await tester.pumpWidget(
      _ProfileHarness(
        authSessionCubit: authSessionCubit,
        apiClient: apiClient,
        photoPicker: const _FakePhotoPicker([]),
      ),
    );
    await tester.pumpAndSettle();
    final l10n = AppLocalizations.of(tester.element(find.byType(ProfilePage)))!;

    expect(find.text("before@example.com"), findsWidgets);
    expect(find.text("Before"), findsWidgets);

    await tester.enterText(
      _findTextField(l10n.emailLabel),
      "after@example.com",
    );
    await tester.enterText(
      _findTextField(l10n.profileDisplayNameLabel),
      "After",
    );
    final saveButtonFinder = find.text(l10n.saveButton, skipOffstage: false);
    await tester.ensureVisible(saveButtonFinder.first);
    await tester.tap(saveButtonFinder.first);
    await tester.pumpAndSettle();

    expect(apiClient.lastUpdatedEmail, "after@example.com");
    expect(apiClient.lastUpdatedUserName, "After");
    expect(authSessionCubit.state.email, "after@example.com");
    expect(authSessionCubit.state.userName, "After");
  });

  testWidgets("shows MFA setup UI after starting setup", (tester) async {
    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final apiClient = _FakeAppApiClient(
      profile: const CurrentUserProfileModel(
        userId: "user-1",
        email: "before@example.com",
        userName: "Before",
        role: 0,
        pendingRoleApplication: null,
        pendingRoleApplicationRequestedAtUtc: null,
        isProviderAccount: false,
        isMfaEnabled: false,
        isMfaRequiredByPolicy: false,
        profileImageUrl: null,
      ),
    );
    final authSessionCubit = AuthSessionCubit(
      storage: InMemoryAuthSessionStorage(),
    );
    authSessionCubit.signIn(
      userId: "user-1",
      email: "before@example.com",
      userName: "Before",
      role: AppUserRole.hunter,
      accessToken: "token",
      accessTokenExpiresAtUtc: DateTime.utc(2099, 3, 17, 18),
    );

    await tester.pumpWidget(
      _ProfileHarness(
        authSessionCubit: authSessionCubit,
        apiClient: apiClient,
        photoPicker: const _FakePhotoPicker([]),
      ),
    );
    await tester.pumpAndSettle();
    final l10n = AppLocalizations.of(tester.element(find.byType(ProfilePage)))!;

    final mfaSetupFinder = find.text(
      l10n.profileMfaSetupAction,
      skipOffstage: false,
    );
    await tester.ensureVisible(mfaSetupFinder.first);
    await tester.tap(mfaSetupFinder.first);
    await tester.pumpAndSettle();

    expect(
      find.textContaining("${l10n.authMfaManualKeyLabel}:"),
      findsOneWidget,
    );
    expect(find.text(l10n.authMfaContinue), findsOneWidget);
  });

  testWidgets("shows notifications and marks them as read", (tester) async {
    tester.view.physicalSize = const Size(1200, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final apiClient = _FakeAppApiClient(
      profile: const CurrentUserProfileModel(
        userId: "user-1",
        email: "before@example.com",
        userName: "Before",
        role: 0,
        pendingRoleApplication: null,
        pendingRoleApplicationRequestedAtUtc: null,
        isProviderAccount: false,
        isMfaEnabled: false,
        isMfaRequiredByPolicy: false,
        profileImageUrl: null,
      ),
      notifications: const [
        UserNotificationModel(
          id: "notification-1",
          title: "Admin bearbeitet Kunstwerk",
          message: "Ein Administrator hat dein Kunstwerk bearbeitet.",
          category: "admin-art-piece",
          isRead: false,
          createdAtUtc: null,
          relatedEntityId: "art-piece-1",
          relatedEntityType: "ArtPiece",
        ),
      ],
    );
    final authSessionCubit = AuthSessionCubit(
      storage: InMemoryAuthSessionStorage(),
    );
    authSessionCubit.signIn(
      userId: "user-1",
      email: "before@example.com",
      userName: "Before",
      role: AppUserRole.artist,
      accessToken: "token",
      accessTokenExpiresAtUtc: DateTime.utc(2099, 3, 17, 18),
    );

    await tester.pumpWidget(
      _ProfileHarness(
        authSessionCubit: authSessionCubit,
        apiClient: apiClient,
        photoPicker: const _FakePhotoPicker([]),
      ),
    );
    await tester.pumpAndSettle();
    final l10n = AppLocalizations.of(tester.element(find.byType(ProfilePage)))!;

    expect(find.text(l10n.profileNotificationsSectionTitle), findsOneWidget);
    expect(find.text("Admin bearbeitet Kunstwerk"), findsOneWidget);

    final markReadButton = find.text(
      l10n.profileNotificationMarkReadAction,
      skipOffstage: false,
    );
    await tester.ensureVisible(markReadButton);
    await tester.tap(markReadButton);
    await tester.pumpAndSettle();

    expect(apiClient.lastMarkedNotificationId, "notification-1");
    expect(find.text(l10n.profileNotificationReadState), findsOneWidget);
  });

  testWidgets(
    "provider profile still loads when notifications cannot be loaded",
    (tester) async {
      tester.view.physicalSize = const Size(1200, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final apiClient = _FakeAppApiClient(
        profile: const CurrentUserProfileModel(
          userId: "provider-user-1",
          email: "provider@example.com",
          userName: "Provider Hunter",
          role: 0,
          pendingRoleApplication: null,
          pendingRoleApplicationRequestedAtUtc: null,
          isProviderAccount: true,
          isMfaEnabled: false,
          isMfaRequiredByPolicy: false,
          profileImageUrl: null,
        ),
        notificationsError: const ApiException("Failed to load notifications."),
      );
      final authSessionCubit = AuthSessionCubit(
        storage: InMemoryAuthSessionStorage(),
      );
      authSessionCubit.signIn(
        userId: "provider-user-1",
        email: "provider@example.com",
        userName: "Provider Hunter",
        role: AppUserRole.hunter,
        accessToken: "provider-token",
        accessTokenExpiresAtUtc: DateTime.utc(2099, 3, 17, 18),
      );

      await tester.pumpWidget(
        _ProfileHarness(
          authSessionCubit: authSessionCubit,
          apiClient: apiClient,
          photoPicker: const _FakePhotoPicker([]),
        ),
      );
      await tester.pumpAndSettle();
      final l10n = AppLocalizations.of(
        tester.element(find.byType(ProfilePage)),
      )!;

      expect(find.text("provider@example.com"), findsWidgets);
      expect(find.text("Provider Hunter"), findsWidgets);
      expect(find.text(l10n.profileProviderAccountChip), findsOneWidget);
      expect(find.text("Failed to load notifications."), findsOneWidget);
      expect(find.text(l10n.retryButton), findsWidgets);
    },
  );

  testWidgets("hunter can apply for artist role from profile", (tester) async {
    tester.view.physicalSize = const Size(1200, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final apiClient = _FakeAppApiClient(
      profile: const CurrentUserProfileModel(
        userId: "user-1",
        email: "before@example.com",
        userName: "Before",
        role: 0,
        pendingRoleApplication: null,
        pendingRoleApplicationRequestedAtUtc: null,
        isProviderAccount: false,
        isMfaEnabled: false,
        isMfaRequiredByPolicy: false,
        profileImageUrl: null,
      ),
    );
    final authSessionCubit = AuthSessionCubit(
      storage: InMemoryAuthSessionStorage(),
    );
    authSessionCubit.signIn(
      userId: "user-1",
      email: "before@example.com",
      userName: "Before",
      role: AppUserRole.hunter,
      accessToken: "token",
      accessTokenExpiresAtUtc: DateTime.utc(2099, 3, 17, 18),
    );

    await tester.pumpWidget(
      _ProfileHarness(
        authSessionCubit: authSessionCubit,
        apiClient: apiClient,
        photoPicker: const _FakePhotoPicker([]),
      ),
    );
    await tester.pumpAndSettle();
    final l10n = AppLocalizations.of(tester.element(find.byType(ProfilePage)))!;

    final applyArtistFinder = find.text(
      l10n.profileApplyArtistAction,
      skipOffstage: false,
    );
    await tester.ensureVisible(applyArtistFinder.first);
    await tester.tap(applyArtistFinder.first);
    await tester.pumpAndSettle();

    expect(apiClient.lastAppliedRole, 1);
    expect(
      find.text(l10n.profileRoleApplicationPending(l10n.roleArtist)),
      findsOneWidget,
    );
  });
}

class _ProfileHarness extends StatelessWidget {
  const _ProfileHarness({
    required this.authSessionCubit,
    required this.apiClient,
    required this.photoPicker,
  });

  final AuthSessionCubit authSessionCubit;
  final AppApiClient apiClient;
  final LocalPhotoPicker photoPicker;

  @override
  Widget build(BuildContext context) {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: "/auth/profile",
          builder: (context, state) =>
              ProfilePage(apiClient: apiClient, photoPicker: photoPicker),
        ),
      ],
      initialLocation: "/auth/profile",
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

Finder _findTextField(String labelText) {
  return find.byWidgetPredicate(
    (widget) =>
        widget is TextField && widget.decoration?.labelText == labelText,
  );
}

class _FakeAppApiClient extends AppApiClient {
  _FakeAppApiClient({
    required CurrentUserProfileModel profile,
    List<UserNotificationModel> notifications = const [],
    this.notificationsError,
  }) : _profile = profile,
       _notifications = List<UserNotificationModel>.from(notifications),
       super(baseUrl: "http://localhost");

  CurrentUserProfileModel _profile;
  List<UserNotificationModel> _notifications;
  final ApiException? notificationsError;
  String? lastUpdatedEmail;
  String? lastUpdatedUserName;
  String? lastMarkedNotificationId;
  int? lastAppliedRole;

  @override
  Future<CurrentUserProfileModel> getCurrentUserProfile() async => _profile;

  @override
  Future<List<UserNotificationModel>> getCurrentUserNotifications() async {
    if (notificationsError != null) {
      throw notificationsError!;
    }

    return List<UserNotificationModel>.from(_notifications);
  }

  @override
  Future<CurrentUserProfileModel> updateCurrentUserProfile({
    required String email,
    required String userName,
    String? profileImageSource,
  }) async {
    lastUpdatedEmail = email;
    lastUpdatedUserName = userName;
    _profile = CurrentUserProfileModel(
      userId: _profile.userId,
      email: email,
      userName: userName,
      role: _profile.role,
      pendingRoleApplication: _profile.pendingRoleApplication,
      pendingRoleApplicationRequestedAtUtc:
          _profile.pendingRoleApplicationRequestedAtUtc,
      isProviderAccount: _profile.isProviderAccount,
      isMfaEnabled: _profile.isMfaEnabled,
      isMfaRequiredByPolicy: _profile.isMfaRequiredByPolicy,
      profileImageUrl: profileImageSource == null || profileImageSource.isEmpty
          ? _profile.profileImageUrl
          : profileImageSource,
    );
    return _profile;
  }

  @override
  Future<AuthResultModel> beginCurrentUserMfaSetup() async {
    return const AuthResultModel(
      success: true,
      message: "setup",
      userId: "user-1",
      role: 0,
      userName: "Before",
      email: "before@example.com",
      retryAfterUtc: null,
      accessToken: null,
      accessTokenExpiresAtUtc: null,
      tokenType: null,
      requiresMfa: true,
      mfaSetupRequired: true,
      mfaChallengeToken: "challenge-token",
      mfaChallengeExpiresAtUtc: null,
      mfaManualEntryKey: "MANUALKEY",
      mfaProvisioningUri:
          "otpauth://totp/UrbanArtDrops:before@example.com?secret=MANUALKEY",
    );
  }

  @override
  Future<UserNotificationModel> markCurrentUserNotificationRead(
    String notificationId,
  ) async {
    lastMarkedNotificationId = notificationId;
    _notifications = _notifications
        .map(
          (notification) => notification.id == notificationId
              ? UserNotificationModel(
                  id: notification.id,
                  title: notification.title,
                  message: notification.message,
                  category: notification.category,
                  isRead: true,
                  createdAtUtc: notification.createdAtUtc,
                  relatedEntityId: notification.relatedEntityId,
                  relatedEntityType: notification.relatedEntityType,
                )
              : notification,
        )
        .toList(growable: false);
    return _notifications.firstWhere(
      (notification) => notification.id == notificationId,
    );
  }

  @override
  Future<CurrentUserProfileModel> applyForRole({required int role}) async {
    lastAppliedRole = role;
    _profile = CurrentUserProfileModel(
      userId: _profile.userId,
      email: _profile.email,
      userName: _profile.userName,
      role: _profile.role,
      pendingRoleApplication: role,
      pendingRoleApplicationRequestedAtUtc: DateTime.utc(2026, 3, 20, 9),
      isProviderAccount: _profile.isProviderAccount,
      isMfaEnabled: _profile.isMfaEnabled,
      isMfaRequiredByPolicy: _profile.isMfaRequiredByPolicy,
      profileImageUrl: _profile.profileImageUrl,
    );
    return _profile;
  }
}

class _FakePhotoPicker implements LocalPhotoPicker {
  const _FakePhotoPicker(this._result);

  final List<LocalPhotoSelection> _result;

  @override
  Future<List<LocalPhotoSelection>> pickPhotos() async => _result;
}
