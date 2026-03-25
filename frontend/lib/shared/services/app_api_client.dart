import "dart:convert";

import "package:http/http.dart" as http;

import "../models/app_models.dart";

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => "ApiException($statusCode): $message";
}

class AppApiClient {
  static String? Function()? _accessTokenProvider;

  static void configureAccessTokenProvider(String? Function() provider) {
    _accessTokenProvider = provider;
  }

  AppApiClient({http.Client? httpClient, String? baseUrl})
    : _httpClient = httpClient ?? http.Client(),
      _baseUrl =
          (baseUrl ??
                  const String.fromEnvironment(
                    "API_BASE_URL",
                    defaultValue: "http://localhost:5143",
                  ))
              .replaceAll(RegExp(r"/+$"), "");

  final http.Client _httpClient;
  final String _baseUrl;

  Future<AuthResultModel> registerLocal({
    required String email,
    required String userName,
    required String password,
  }) async {
    final response = await _httpClient.post(
      _uri("/api/auth/register-local"),
      headers: _jsonHeaders(includeAuthorization: false),
      body: jsonEncode({
        "email": email,
        "userName": userName,
        "password": password,
      }),
    );
    _ensureSuccess(response, "Failed to register account.");
    return AuthResultModel.fromJson(_decodeObjectResponse(response));
  }

  Future<AuthResultModel> registerProvider({
    required String provider,
    required String providerSubject,
    required String email,
    required String userName,
  }) async {
    final response = await _httpClient.post(
      _uri("/api/auth/register-provider"),
      headers: _jsonHeaders(includeAuthorization: false),
      body: jsonEncode({
        "provider": provider,
        "providerSubject": providerSubject,
        "email": email,
        "userName": userName,
      }),
    );
    _ensureSuccess(response, "Failed to register provider account.");
    return AuthResultModel.fromJson(_decodeObjectResponse(response));
  }

  Future<ExternalProviderAuthStartModel> beginProviderLogin({
    required String provider,
    required String callbackUrl,
  }) async {
    final response = await _httpClient.post(
      _uri("/api/auth/provider-login/begin"),
      headers: _jsonHeaders(includeAuthorization: false),
      body: jsonEncode({"provider": provider, "callbackUrl": callbackUrl}),
    );
    _ensureSuccess(response, "Failed to start provider login.");
    return ExternalProviderAuthStartModel.fromJson(
      _decodeObjectResponse(response),
    );
  }

  Future<ExternalProviderAuthStartModel> beginProviderRegistration({
    required String provider,
    required String callbackUrl,
    required String email,
    required String userName,
  }) async {
    final response = await _httpClient.post(
      _uri("/api/auth/provider-register/begin"),
      headers: _jsonHeaders(includeAuthorization: false),
      body: jsonEncode({
        "provider": provider,
        "callbackUrl": callbackUrl,
        "email": email,
        "userName": userName,
      }),
    );
    _ensureSuccess(response, "Failed to start provider registration.");
    return ExternalProviderAuthStartModel.fromJson(
      _decodeObjectResponse(response),
    );
  }

  Future<List<AuthProviderOptionModel>> getAvailableAuthProviders() async {
    final data = await _getList(
      "/api/auth/providers",
      includeAuthorization: false,
    );
    return data.map(AuthProviderOptionModel.fromJson).toList(growable: false);
  }

  Future<AuthResultModel> loginLocal({
    required String email,
    required String password,
  }) async {
    final response = await _httpClient.post(
      _uri("/api/auth/login-local"),
      headers: _jsonHeaders(includeAuthorization: false),
      body: jsonEncode({"email": email, "password": password}),
    );
    _ensureSuccess(response, "Failed to login.");
    return AuthResultModel.fromJson(_decodeObjectResponse(response));
  }

  Future<AuthResultModel> loginProvider({
    required String provider,
    required String providerSubject,
    required String email,
  }) async {
    final response = await _httpClient.post(
      _uri("/api/auth/login-provider"),
      headers: _jsonHeaders(includeAuthorization: false),
      body: jsonEncode({
        "provider": provider,
        "providerSubject": providerSubject,
        "email": email,
      }),
    );
    _ensureSuccess(response, "Failed to login with provider.");
    return AuthResultModel.fromJson(_decodeObjectResponse(response));
  }

  Future<AuthResultModel> completeProviderAuthentication({
    required String providerSessionId,
  }) async {
    final response = await _httpClient.post(
      _uri("/api/auth/provider/complete"),
      headers: _jsonHeaders(includeAuthorization: false),
      body: jsonEncode({"providerSessionId": providerSessionId}),
    );
    _ensureSuccess(response, "Failed to complete provider authentication.");
    return AuthResultModel.fromJson(_decodeObjectResponse(response));
  }

  Future<AuthResultModel> completeMfaChallenge({
    required String challengeToken,
    required String code,
  }) async {
    final response = await _httpClient.post(
      _uri("/api/auth/mfa/complete"),
      headers: _jsonHeaders(includeAuthorization: false),
      body: jsonEncode({"challengeToken": challengeToken, "code": code}),
    );
    _ensureSuccess(response, "Failed to complete MFA challenge.");
    return AuthResultModel.fromJson(_decodeObjectResponse(response));
  }

  Future<BootstrapStatusModel> getBootstrapStatus() async {
    final data = await _getObject(
      "/api/bootstrap/status",
      includeAuthorization: false,
    );
    return BootstrapStatusModel.fromJson(data);
  }

  Future<ManagedUser> bootstrapAdmin({
    required String email,
    required String userName,
    required String password,
  }) async {
    final response = await _httpClient.post(
      _uri("/api/bootstrap/admin"),
      headers: _jsonHeaders(includeAuthorization: false),
      body: jsonEncode({
        "email": email,
        "userName": userName,
        "password": password,
      }),
    );
    _ensureSuccess(response, "Failed to bootstrap admin.");
    return ManagedUser.fromJson(_decodeObjectResponse(response));
  }

  Future<void> verifyEmail(String userId) async {
    final response = await _httpClient.post(
      _uri("/api/auth/verify-email/$userId"),
      headers: _headers(includeAuthorization: false),
    );
    _ensureSuccess(response, "Failed to verify email.");
  }

  Future<CurrentUserProfileModel> getCurrentUserProfile() async {
    final data = await _getObject(
      "/api/profile",
      fallbackMessage: "Failed to load current profile.",
    );
    return CurrentUserProfileModel.fromJson(data);
  }

  Future<List<UserNotificationModel>> getCurrentUserNotifications() async {
    final data = await _getList(
      "/api/profile/notifications",
      fallbackMessage: "Failed to load notifications.",
    );
    return data.map(UserNotificationModel.fromJson).toList(growable: false);
  }

  Future<CurrentUserProfileModel> updateCurrentUserProfile({
    required String email,
    required String userName,
    String? profileImageSource,
  }) async {
    final response = await _httpClient.put(
      _uri("/api/profile"),
      headers: _jsonHeaders(),
      body: jsonEncode({
        "email": email,
        "userName": userName,
        "profileImageSource": profileImageSource,
      }),
    );
    _ensureSuccess(response, "Failed to update profile.");
    return CurrentUserProfileModel.fromJson(_decodeObjectResponse(response));
  }

  Future<AuthResultModel> beginCurrentUserMfaSetup() async {
    final response = await _httpClient.post(
      _uri("/api/profile/mfa/setup"),
      headers: _headers(),
    );
    _ensureSuccess(response, "Failed to start MFA setup.");
    return AuthResultModel.fromJson(_decodeObjectResponse(response));
  }

  Future<CurrentUserProfileModel> disableCurrentUserMfa({
    required String code,
  }) async {
    final response = await _httpClient.post(
      _uri("/api/profile/mfa/disable"),
      headers: _jsonHeaders(),
      body: jsonEncode({"code": code}),
    );
    _ensureSuccess(response, "Failed to disable MFA.");
    return CurrentUserProfileModel.fromJson(_decodeObjectResponse(response));
  }

  Future<CurrentUserProfileModel> applyForRole({required int role}) async {
    final response = await _httpClient.post(
      _uri("/api/profile/role-application"),
      headers: _jsonHeaders(),
      body: jsonEncode({"role": role}),
    );
    _ensureSuccess(response, "Failed to submit role application.");
    return CurrentUserProfileModel.fromJson(_decodeObjectResponse(response));
  }

  Future<UserNotificationModel> markCurrentUserNotificationRead(
    String notificationId,
  ) async {
    final response = await _httpClient.post(
      _uri("/api/profile/notifications/$notificationId/mark-read"),
      headers: _headers(),
    );
    _ensureSuccess(response, "Failed to mark notification as read.");
    return UserNotificationModel.fromJson(_decodeObjectResponse(response));
  }

  Future<List<ManagedUser>> getUsers() async {
    final data = await _getList("/api/admin/users");
    return data.map(ManagedUser.fromJson).toList(growable: false);
  }

  Future<List<ManagedUser>> getUserDirectory() async {
    final data = await _getList("/api/users/directory");
    return data.map(ManagedUser.fromJson).toList(growable: false);
  }

  Future<void> createManagedUser({
    required String email,
    required String userName,
    required int role,
    required bool isApproved,
    required bool isEmailVerified,
    required bool isProviderAccount,
    String? password,
    String? provider,
    String? providerSubject,
  }) async {
    final response = await _httpClient.post(
      _uri("/api/admin/users"),
      headers: _jsonHeaders(),
      body: jsonEncode({
        "email": email,
        "userName": userName,
        "role": role,
        "isApproved": isApproved,
        "isEmailVerified": isEmailVerified,
        "isProviderAccount": isProviderAccount,
        "password": password,
        "provider": provider,
        "providerSubject": providerSubject,
      }),
    );

    _ensureSuccess(response, "Failed to create user.");
  }

  Future<void> updateUserApproval(String userId, bool approved) async {
    final response = await _httpClient.patch(
      _uri("/api/admin/users/$userId/approval", {
        "approved": approved.toString(),
      }),
    );
    _ensureSuccess(response, "Failed to update user approval.");
  }

  Future<void> updateUserSuspension(String userId, bool suspended) async {
    final response = await _httpClient.patch(
      _uri("/api/admin/users/$userId/suspension", {
        "suspended": suspended.toString(),
      }),
    );
    _ensureSuccess(response, "Failed to update user suspension.");
  }

  Future<void> updateUserRole(String userId, int role) async {
    final response = await _httpClient.patch(
      _uri("/api/admin/users/$userId/role", {"role": role.toString()}),
    );
    _ensureSuccess(response, "Failed to update user role.");
  }

  Future<ManagedUser> approveUserRoleApplication(String userId) async {
    final response = await _httpClient.post(
      _uri("/api/admin/users/$userId/role-application/approve"),
      headers: _headers(),
    );
    _ensureSuccess(response, "Failed to approve role application.");
    return ManagedUser.fromJson(_decodeObjectResponse(response));
  }

  Future<ManagedUser> rejectUserRoleApplication(String userId) async {
    final response = await _httpClient.post(
      _uri("/api/admin/users/$userId/role-application/reject"),
      headers: _headers(),
    );
    _ensureSuccess(response, "Failed to reject role application.");
    return ManagedUser.fromJson(_decodeObjectResponse(response));
  }

  Future<void> updateUserProfile({
    required String userId,
    required String userName,
    required String email,
  }) async {
    final response = await _httpClient.patch(
      _uri("/api/admin/users/$userId/profile"),
      headers: _jsonHeaders(),
      body: jsonEncode({"userName": userName, "email": email}),
    );
    _ensureSuccess(response, "Failed to update user profile.");
  }

  Future<List<ArtPieceModel>> getArtPieces() async {
    final data = await _getList("/api/art-pieces");
    return data.map(ArtPieceModel.fromJson).toList(growable: false);
  }

  Future<List<ArtPieceModel>> getManageableArtPieces() async {
    final data = await _getList("/api/art-pieces/manageable");
    return data.map(ArtPieceModel.fromJson).toList(growable: false);
  }

  Future<ArtPieceModel> createArtPiece({
    required String artistId,
    required String title,
    required String subtitle,
    required String description,
    required int assetKind,
    required List<String> photoUrls,
    String? assetSource,
    String? assetFileName,
  }) async {
    final response = await _httpClient.post(
      _uri("/api/art-pieces"),
      headers: _jsonHeaders(),
      body: jsonEncode({
        "artistId": artistId,
        "title": title,
        "subtitle": subtitle,
        "description": description,
        "assetKind": assetKind,
        "photoUrls": photoUrls,
        "assetSource": assetSource,
        "assetFileName": assetFileName,
      }),
    );
    _ensureSuccess(response, "Failed to create art piece.");
    return ArtPieceModel.fromJson(_decodeObjectResponse(response));
  }

  Future<ArtPieceModel> updateArtPiece({
    required String id,
    required String artistId,
    required String title,
    required String subtitle,
    required String description,
    required int assetKind,
    required List<String> photoUrls,
    String? assetSource,
    String? assetFileName,
  }) async {
    final response = await _httpClient.put(
      _uri("/api/art-pieces/$id"),
      headers: _jsonHeaders(),
      body: jsonEncode({
        "artistId": artistId,
        "title": title,
        "subtitle": subtitle,
        "description": description,
        "assetKind": assetKind,
        "photoUrls": photoUrls,
        "assetSource": assetSource,
        "assetFileName": assetFileName,
      }),
    );
    _ensureSuccess(response, "Failed to update art piece.");
    return ArtPieceModel.fromJson(_decodeObjectResponse(response));
  }

  Future<void> deleteArtPiece(String id) async {
    final response = await _httpClient.delete(_uri("/api/art-pieces/$id"));
    _ensureSuccess(response, "Failed to delete art piece.");
  }

  Future<void> setArtPiecePublished(String id, bool publish) async {
    final action = publish ? "publish" : "depublish";
    final response = await _httpClient.post(
      _uri("/api/art-pieces/$id/$action"),
    );
    _ensureSuccess(response, "Failed to change art piece publish state.");
  }

  Future<void> reportArtPiece(String id, {String? reason}) async {
    final response = await _httpClient.post(
      _uri("/api/art-pieces/$id/report"),
      headers: _jsonHeaders(),
      body: jsonEncode({"reason": reason}),
    );
    _ensureSuccess(response, "Failed to report art piece.");
  }

  Future<List<DropModel>> getDrops() async {
    final data = await _getList("/api/drops");
    return data.map(DropModel.fromJson).toList(growable: false);
  }

  Future<DropModel> getDropById(String id) async {
    final data = await _getObject("/api/drops/$id");
    return DropModel.fromJson(data);
  }

  String get baseUrl => _baseUrl;

  Future<DropModel> createDrop(CreateDropInput input) async {
    final response = await _httpClient.post(
      _uri("/api/drops"),
      headers: _jsonHeaders(),
      body: jsonEncode({
        "artPieceId": input.artPieceId,
        "dropMakerId": input.dropMakerId,
        "isStationary": input.isStationary,
        "portableItemCount": input.portableItemCount,
        "dropMakerComment": input.dropMakerComment,
        "socialChannels": input.socialChannels,
        "latitude": input.latitude,
        "longitude": input.longitude,
        "locationPhotoUrls": input.locationPhotoUrls,
        "itemCount": input.itemCount,
      }),
    );
    _ensureSuccess(response, "Failed to create drop.");
    return DropModel.fromJson(_decodeObjectResponse(response));
  }

  Future<DropModel> updateDrop(String id, CreateDropInput input) async {
    final response = await _httpClient.put(
      _uri("/api/drops/$id"),
      headers: _jsonHeaders(),
      body: jsonEncode({
        "artPieceId": input.artPieceId,
        "dropMakerId": input.dropMakerId,
        "isStationary": input.isStationary,
        "portableItemCount": input.portableItemCount,
        "dropMakerComment": input.dropMakerComment,
        "socialChannels": input.socialChannels,
        "latitude": input.latitude,
        "longitude": input.longitude,
        "locationPhotoUrls": input.locationPhotoUrls,
        "itemCount": input.itemCount,
      }),
    );
    _ensureSuccess(response, "Failed to update drop.");
    return DropModel.fromJson(_decodeObjectResponse(response));
  }

  Future<void> deleteDrop(String id) async {
    final response = await _httpClient.delete(_uri("/api/drops/$id"));
    _ensureSuccess(response, "Failed to delete drop.");
  }

  Future<void> setDropPublished(String id, bool publish) async {
    final action = publish ? "publish" : "depublish";
    final response = await _httpClient.post(_uri("/api/drops/$id/$action"));
    _ensureSuccess(response, "Failed to change drop publish state.");
  }

  Future<List<LeaderboardEntry>> getLeaderboard() async {
    final data = await _getList("/api/discovery/leaderboard");
    return data.map(LeaderboardEntry.fromJson).toList(growable: false);
  }

  Future<List<DropCommentModel>> getDropComments(String dropId) async {
    final data = await _getList("/api/comments/drop/$dropId");
    return data.map(DropCommentModel.fromJson).toList(growable: false);
  }

  Future<DropCommentModel> createComment({
    required String dropId,
    required String content,
  }) async {
    final response = await _httpClient.post(
      _uri("/api/comments"),
      headers: _jsonHeaders(),
      body: jsonEncode({"dropId": dropId, "content": content}),
    );
    _ensureSuccess(response, "Failed to create comment.");
    return DropCommentModel.fromJson(_decodeObjectResponse(response));
  }

  Future<void> reportComment(String id, {String? reason}) async {
    final response = await _httpClient.post(
      _uri("/api/comments/$id/report"),
      headers: _jsonHeaders(),
      body: jsonEncode({"reason": reason}),
    );
    _ensureSuccess(response, "Failed to report comment.");
  }

  Future<void> hideComment(String id, {required String actingUserId}) async {
    final response = await _httpClient.post(
      _uri("/api/comments/$id/hide"),
      headers: _headers(),
    );
    _ensureSuccess(response, "Failed to hide comment.");
  }

  Future<void> dismissCommentReport(
    String id, {
    required String actingUserId,
  }) async {
    final response = await _httpClient.post(
      _uri("/api/comments/$id/dismiss-report"),
      headers: _headers(),
    );
    _ensureSuccess(response, "Failed to dismiss comment report.");
  }

  Future<ModerationQueueModel> getModerationQueue({
    required String actingUserId,
  }) async {
    final response = await _httpClient.get(
      _uri("/api/moderation/reports"),
      headers: _headers(),
    );
    _ensureSuccess(response, "Failed to load moderation queue.");
    final data = _decodeObjectResponse(response);
    return ModerationQueueModel.fromJson(data);
  }

  Future<void> hideReportedComment(
    String id, {
    required String actingUserId,
  }) async {
    final response = await _httpClient.post(
      _uri("/api/moderation/comments/$id/hide"),
      headers: _headers(),
    );
    _ensureSuccess(response, "Failed to hide reported comment.");
  }

  Future<void> dismissReportedComment(
    String id, {
    required String actingUserId,
  }) async {
    final response = await _httpClient.post(
      _uri("/api/moderation/comments/$id/dismiss-report"),
      headers: _headers(),
    );
    _ensureSuccess(response, "Failed to dismiss reported comment.");
  }

  Future<void> depublishReportedArtPiece(
    String id, {
    required String actingUserId,
  }) async {
    final response = await _httpClient.post(
      _uri("/api/moderation/art-pieces/$id/depublish"),
      headers: _headers(),
    );
    _ensureSuccess(response, "Failed to depublish reported art piece.");
  }

  Future<void> dismissReportedArtPiece(
    String id, {
    required String actingUserId,
  }) async {
    final response = await _httpClient.post(
      _uri("/api/moderation/art-pieces/$id/dismiss-report"),
      headers: _headers(),
    );
    _ensureSuccess(response, "Failed to dismiss art piece report.");
  }

  Future<AppConfigurationModel> getAppConfiguration() async {
    final data = await _getObject("/api/admin/configuration");
    return AppConfigurationModel.fromJson(data);
  }

  Future<AppConfigurationModel> updateAppConfiguration({
    required String smtpHost,
    required int smtpPort,
    required SmtpSecurityModeModel smtpSecurityMode,
    required String smtpUserName,
    required String smtpUserEmail,
    required String publicAppBaseUrl,
    required int mainMapRadiusKm,
    required int miniMapRadiusKm,
    required int unclaimedDropRadiusKm,
    required bool showExactPositionWhenFullyClaimed,
  }) async {
    final response = await _httpClient.put(
      _uri("/api/admin/configuration"),
      headers: _jsonHeaders(),
      body: jsonEncode({
        "smtpHost": smtpHost,
        "smtpPort": smtpPort,
        "smtpSecurityMode": smtpSecurityMode.wireValue,
        "smtpUserName": smtpUserName,
        "smtpUserEmail": smtpUserEmail,
        "publicAppBaseUrl": publicAppBaseUrl,
        "mainMapRadiusKm": mainMapRadiusKm,
        "miniMapRadiusKm": miniMapRadiusKm,
        "unclaimedDropRadiusKm": unclaimedDropRadiusKm,
        "showExactPositionWhenFullyClaimed": showExactPositionWhenFullyClaimed,
      }),
    );
    _ensureSuccess(response, "Failed to update configuration.");
    return AppConfigurationModel.fromJson(_decodeObjectResponse(response));
  }

  Future<SmtpConnectionTestResultModel> testSmtpConnection({
    required String smtpHost,
    required int smtpPort,
    required SmtpSecurityModeModel smtpSecurityMode,
    required String smtpUserName,
    required String smtpPassword,
  }) async {
    final response = await _httpClient.post(
      _uri("/api/admin/configuration/smtp/test"),
      headers: _jsonHeaders(),
      body: jsonEncode({
        "smtpHost": smtpHost,
        "smtpPort": smtpPort,
        "smtpSecurityMode": smtpSecurityMode.wireValue,
        "smtpUserName": smtpUserName,
        "smtpPassword": smtpPassword,
      }),
    );
    _ensureSuccess(response, "Failed to test SMTP connection.");
    return SmtpConnectionTestResultModel.fromJson(
      _decodeObjectResponse(response),
    );
  }

  Future<ClaimPreviewModel> getClaimPreview(String qrToken) async {
    final data = await _getObject("/api/claims/by-token/$qrToken");
    return ClaimPreviewModel.fromJson(data);
  }

  Future<void> claimByToken({
    required String qrToken,
    String? hunterUserId,
    String? anonymousNickname,
  }) async {
    final response = await _httpClient.post(
      _uri("/api/claims/by-token"),
      headers: _jsonHeaders(),
      body: jsonEncode({
        "qrToken": qrToken,
        "hunterUserId": hunterUserId,
        "anonymousNickname": anonymousNickname,
      }),
    );
    _ensureSuccess(response, "Failed to claim drop item.");
  }

  Future<List<Map<String, dynamic>>> _getList(
    String path, {
    bool includeAuthorization = true,
    String fallbackMessage = "Failed to load data.",
  }) async {
    final response = await _httpClient.get(
      _uri(path),
      headers: _headers(includeAuthorization: includeAuthorization),
    );
    _ensureSuccess(response, fallbackMessage);
    final payload = jsonDecode(response.body);
    if (payload is! List<dynamic>) {
      throw const ApiException("Unexpected API response format.");
    }

    return payload.whereType<Map<String, dynamic>>().toList(growable: false);
  }

  Future<Map<String, dynamic>> _getObject(
    String path, {
    bool includeAuthorization = true,
    String fallbackMessage = "Failed to load data.",
  }) async {
    final response = await _httpClient.get(
      _uri(path),
      headers: _headers(includeAuthorization: includeAuthorization),
    );
    _ensureSuccess(response, fallbackMessage);
    return _decodeObjectResponse(response);
  }

  Uri _uri(String path, [Map<String, String>? query]) {
    final uri = Uri.parse("$_baseUrl$path");
    if (query == null || query.isEmpty) {
      return uri;
    }

    return uri.replace(queryParameters: query);
  }

  Map<String, String> _headers({bool includeAuthorization = true}) {
    final headers = <String, String>{"Accept": "application/json"};
    final accessToken = includeAuthorization
        ? _accessTokenProvider?.call()
        : null;
    if (accessToken != null && accessToken.trim().isNotEmpty) {
      headers["Authorization"] = "Bearer ${accessToken.trim()}";
    }

    return headers;
  }

  Map<String, String> _jsonHeaders({bool includeAuthorization = true}) {
    return {
      ..._headers(includeAuthorization: includeAuthorization),
      "Content-Type": "application/json",
    };
  }

  void _ensureSuccess(http.Response response, String fallbackMessage) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    var message = fallbackMessage;
    if (response.body.isNotEmpty) {
      try {
        final payload = jsonDecode(response.body);
        if (payload is Map<String, dynamic>) {
          final structuredMessage =
              payload["message"]?.toString() ?? payload["error"]?.toString();
          if (structuredMessage != null &&
              structuredMessage.trim().isNotEmpty) {
            message = structuredMessage.trim();
          } else {
            message = response.body;
          }
        } else {
          message = response.body;
        }
      } on FormatException {
        message = response.body;
      }
    }

    throw ApiException(message, statusCode: response.statusCode);
  }

  Map<String, dynamic> _decodeObjectResponse(http.Response response) {
    final payload = jsonDecode(response.body);
    if (payload is! Map<String, dynamic>) {
      throw const ApiException("Unexpected API response format.");
    }

    return payload;
  }
}
