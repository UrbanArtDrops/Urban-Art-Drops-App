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
  _FakeAppApiClient({required CurrentUserProfileModel profile})
    : _profile = profile,
      super(baseUrl: "http://localhost");

  CurrentUserProfileModel _profile;
  String? lastUpdatedEmail;
  String? lastUpdatedUserName;

  @override
  Future<CurrentUserProfileModel> getCurrentUserProfile() async => _profile;

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
}

class _FakePhotoPicker implements LocalPhotoPicker {
  const _FakePhotoPicker(this._result);

  final List<LocalPhotoSelection> _result;

  @override
  Future<List<LocalPhotoSelection>> pickPhotos() async => _result;
}
