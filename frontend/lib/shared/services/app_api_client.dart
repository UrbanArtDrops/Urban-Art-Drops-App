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

  Future<List<ManagedUser>> getUsers() async {
    final data = await _getList("/api/admin/users");
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
      headers: _jsonHeaders,
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

  Future<void> updateUserName(String userId, String userName) async {
    final response = await _httpClient.patch(
      _uri("/api/admin/users/$userId/profile"),
      headers: _jsonHeaders,
      body: jsonEncode({"userName": userName}),
    );
    _ensureSuccess(response, "Failed to update user profile.");
  }

  Future<List<ArtPieceModel>> getArtPieces() async {
    final data = await _getList("/api/art-pieces");
    return data.map(ArtPieceModel.fromJson).toList(growable: false);
  }

  Future<ArtPieceModel> createArtPiece({
    required String artistId,
    required String title,
    required String description,
    required int assetKind,
    required List<String> photoUrls,
  }) async {
    final response = await _httpClient.post(
      _uri("/api/art-pieces"),
      headers: _jsonHeaders,
      body: jsonEncode({
        "artistId": artistId,
        "title": title,
        "description": description,
        "assetKind": assetKind,
        "photoUrls": photoUrls,
      }),
    );
    _ensureSuccess(response, "Failed to create art piece.");
    return ArtPieceModel.fromJson(_decodeObjectResponse(response));
  }

  Future<ArtPieceModel> updateArtPiece({
    required String id,
    required String artistId,
    required String title,
    required String description,
    required int assetKind,
    required List<String> photoUrls,
  }) async {
    final response = await _httpClient.put(
      _uri("/api/art-pieces/$id"),
      headers: _jsonHeaders,
      body: jsonEncode({
        "artistId": artistId,
        "title": title,
        "description": description,
        "assetKind": assetKind,
        "photoUrls": photoUrls,
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

  Future<List<DropModel>> getDrops() async {
    final data = await _getList("/api/drops");
    return data.map(DropModel.fromJson).toList(growable: false);
  }

  Future<DropModel> getDropById(String id) async {
    final data = await _getObject("/api/drops/$id");
    return DropModel.fromJson(data);
  }

  Future<void> createDrop(CreateDropInput input) async {
    final response = await _httpClient.post(
      _uri("/api/drops"),
      headers: _jsonHeaders,
      body: jsonEncode({
        "artPieceId": input.artPieceId,
        "dropMakerId": input.dropMakerId,
        "isStationary": input.isStationary,
        "portableItemCount": input.portableItemCount,
        "latitude": input.latitude,
        "longitude": input.longitude,
        "locationPhotoUrls": input.locationPhotoUrls,
        "itemCount": input.itemCount,
      }),
    );
    _ensureSuccess(response, "Failed to create drop.");
  }

  Future<void> updateDrop(String id, CreateDropInput input) async {
    final response = await _httpClient.put(
      _uri("/api/drops/$id"),
      headers: _jsonHeaders,
      body: jsonEncode({
        "artPieceId": input.artPieceId,
        "dropMakerId": input.dropMakerId,
        "isStationary": input.isStationary,
        "portableItemCount": input.portableItemCount,
        "latitude": input.latitude,
        "longitude": input.longitude,
        "locationPhotoUrls": input.locationPhotoUrls,
        "itemCount": input.itemCount,
      }),
    );
    _ensureSuccess(response, "Failed to update drop.");
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

  Future<AppConfigurationModel> getAppConfiguration() async {
    final data = await _getObject("/api/admin/configuration");
    return AppConfigurationModel.fromJson(data);
  }

  Future<List<Map<String, dynamic>>> _getList(String path) async {
    final response = await _httpClient.get(_uri(path));
    _ensureSuccess(response, "Failed to load data.");
    final payload = jsonDecode(response.body);
    if (payload is! List<dynamic>) {
      throw const ApiException("Unexpected API response format.");
    }

    return payload.whereType<Map<String, dynamic>>().toList(growable: false);
  }

  Future<Map<String, dynamic>> _getObject(String path) async {
    final response = await _httpClient.get(_uri(path));
    _ensureSuccess(response, "Failed to load data.");
    return _decodeObjectResponse(response);
  }

  Uri _uri(String path, [Map<String, String>? query]) {
    final uri = Uri.parse("$_baseUrl$path");
    if (query == null || query.isEmpty) {
      return uri;
    }

    return uri.replace(queryParameters: query);
  }

  void _ensureSuccess(http.Response response, String fallbackMessage) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    var message = fallbackMessage;
    if (response.body.isNotEmpty) {
      message = response.body;
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

const Map<String, String> _jsonHeaders = {
  "Content-Type": "application/json",
  "Accept": "application/json",
};
