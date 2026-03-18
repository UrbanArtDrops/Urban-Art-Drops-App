import "dart:async";
import "dart:convert";

import "package:flutter_bloc/flutter_bloc.dart";

import "../../application/auth_session_storage.dart";
import "../../../../shared/services/app_api_client.dart";

enum AppUserRole { hunter, artist, dropMaker, moderator, admin }

class AuthSessionState {
  const AuthSessionState({
    required this.isAuthenticated,
    this.userId,
    this.email,
    this.userName,
    this.profileImageUrl,
    this.role,
    this.accessToken,
    this.accessTokenExpiresAtUtc,
    this.tokenType,
  });

  const AuthSessionState.anonymous()
    : isAuthenticated = false,
      userId = null,
      email = null,
      userName = null,
      profileImageUrl = null,
      role = null,
      accessToken = null,
      accessTokenExpiresAtUtc = null,
      tokenType = null;

  final bool isAuthenticated;
  final String? userId;
  final String? email;
  final String? userName;
  final String? profileImageUrl;
  final AppUserRole? role;
  final String? accessToken;
  final DateTime? accessTokenExpiresAtUtc;
  final String? tokenType;

  bool get hasValidAccessToken {
    final token = accessToken?.trim();
    if (token == null || token.isEmpty) {
      return false;
    }

    final expiresAtUtc = accessTokenExpiresAtUtc;
    if (expiresAtUtc == null) {
      return true;
    }

    return expiresAtUtc.isAfter(DateTime.now().toUtc());
  }

  String? get displayName {
    final trimmedUserName = userName?.trim();
    if (trimmedUserName != null && trimmedUserName.isNotEmpty) {
      return trimmedUserName;
    }

    final trimmedEmail = email?.trim();
    if (trimmedEmail != null && trimmedEmail.isNotEmpty) {
      return trimmedEmail;
    }

    return null;
  }

  AuthSessionState authenticated({
    required String userId,
    required String email,
    required String userName,
    String? profileImageUrl,
    required AppUserRole role,
    required String accessToken,
    required DateTime? accessTokenExpiresAtUtc,
    required String tokenType,
  }) => AuthSessionState(
    isAuthenticated: true,
    userId: userId.trim(),
    email: email.trim(),
    userName: userName.trim(),
    profileImageUrl: profileImageUrl?.trim(),
    role: role,
    accessToken: accessToken.trim(),
    accessTokenExpiresAtUtc: accessTokenExpiresAtUtc,
    tokenType: tokenType.trim(),
  );

  Map<String, dynamic> toStorageJson() => {
    "userId": userId,
    "email": email,
    "userName": userName,
    "profileImageUrl": profileImageUrl,
    "role": role?.index,
    "accessToken": accessToken,
    "accessTokenExpiresAtUtc": accessTokenExpiresAtUtc?.toIso8601String(),
    "tokenType": tokenType,
  };

  static AuthSessionState? fromStorageJson(Map<String, dynamic> json) {
    final userId = json["userId"]?.toString().trim();
    final email = json["email"]?.toString().trim();
    final userName = json["userName"]?.toString().trim();
    final profileImageUrl = json["profileImageUrl"]?.toString().trim();
    final accessToken = json["accessToken"]?.toString().trim();
    final tokenType = json["tokenType"]?.toString().trim();

    if (userId == null ||
        userId.isEmpty ||
        email == null ||
        email.isEmpty ||
        userName == null ||
        userName.isEmpty ||
        accessToken == null ||
        accessToken.isEmpty ||
        tokenType == null ||
        tokenType.isEmpty) {
      return null;
    }

    final role = appUserRoleFromApiValue(json["role"] as int?);
    if (role == null) {
      return null;
    }

    final expiresAtRaw = json["accessTokenExpiresAtUtc"]?.toString().trim();
    final expiresAtUtc = expiresAtRaw == null || expiresAtRaw.isEmpty
        ? null
        : DateTime.tryParse(expiresAtRaw)?.toUtc();

    return AuthSessionState(
      isAuthenticated: true,
      userId: userId,
      email: email,
      userName: userName,
      profileImageUrl: profileImageUrl == null || profileImageUrl.isEmpty
          ? null
          : profileImageUrl,
      role: role,
      accessToken: accessToken,
      accessTokenExpiresAtUtc: expiresAtUtc,
      tokenType: tokenType,
    );
  }
}

class AuthSessionCubit extends Cubit<AuthSessionState> {
  AuthSessionCubit({AuthSessionStorage? storage})
    : _storage = storage ?? InMemoryAuthSessionStorage(),
      super(const AuthSessionState.anonymous()) {
    AppApiClient.configureAccessTokenProvider(() {
      final session = state;
      if (!session.hasValidAccessToken) {
        return null;
      }

      return session.accessToken;
    });
  }

  final AuthSessionStorage _storage;

  Future<void> hydrate() async {
    final serializedSession = await _storage.read();
    if (serializedSession == null || serializedSession.trim().isEmpty) {
      return;
    }

    try {
      final decoded = jsonDecode(serializedSession);
      if (decoded is! Map<String, dynamic>) {
        await _storage.clear();
        return;
      }

      final hydratedState = AuthSessionState.fromStorageJson(decoded);
      if (hydratedState == null || !hydratedState.hasValidAccessToken) {
        await _storage.clear();
        return;
      }

      emit(hydratedState);
    } on FormatException {
      await _storage.clear();
    }
  }

  void signIn({
    required String userId,
    required String email,
    required String userName,
    String? profileImageUrl,
    required AppUserRole role,
    required String accessToken,
    required DateTime? accessTokenExpiresAtUtc,
    String tokenType = "Bearer",
  }) {
    final nextState = state.authenticated(
      userId: userId,
      email: email,
      userName: userName.trim().isEmpty ? email : userName,
      profileImageUrl: profileImageUrl,
      role: role,
      accessToken: accessToken,
      accessTokenExpiresAtUtc: accessTokenExpiresAtUtc,
      tokenType: tokenType,
    );
    emit(nextState);
    unawaited(_storage.write(jsonEncode(nextState.toStorageJson())));
  }

  void updateProfile({
    required String email,
    required String userName,
    String? profileImageUrl,
  }) {
    final currentState = state;
    if (!currentState.isAuthenticated ||
        currentState.userId == null ||
        currentState.role == null ||
        currentState.accessToken == null ||
        currentState.tokenType == null) {
      return;
    }

    final nextState = currentState.authenticated(
      userId: currentState.userId!,
      email: email,
      userName: userName,
      profileImageUrl: profileImageUrl,
      role: currentState.role!,
      accessToken: currentState.accessToken!,
      accessTokenExpiresAtUtc: currentState.accessTokenExpiresAtUtc,
      tokenType: currentState.tokenType!,
    );
    emit(nextState);
    unawaited(_storage.write(jsonEncode(nextState.toStorageJson())));
  }

  void signOut() {
    emit(const AuthSessionState.anonymous());
    unawaited(_storage.clear());
  }
}

AppUserRole? appUserRoleFromApiValue(int? value) {
  switch (value) {
    case 0:
      return AppUserRole.hunter;
    case 1:
      return AppUserRole.artist;
    case 2:
      return AppUserRole.dropMaker;
    case 3:
      return AppUserRole.moderator;
    case 4:
      return AppUserRole.admin;
    default:
      return null;
  }
}
