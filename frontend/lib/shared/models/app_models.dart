class ManagedUser {
  const ManagedUser({
    required this.id,
    required this.email,
    required this.userName,
    required this.role,
    required this.isApproved,
    required this.isSuspended,
    required this.isEmailVerified,
    required this.isProviderAccount,
  });

  factory ManagedUser.fromJson(Map<String, dynamic> json) {
    return ManagedUser(
      id: _readString(json, "id", "Id"),
      email: _readString(json, "email", "Email"),
      userName: _readString(json, "userName", "UserName"),
      role: _readInt(json, "role", "Role"),
      isApproved: _readBool(json, "isApproved", "IsApproved"),
      isSuspended: _readBool(json, "isSuspended", "IsSuspended"),
      isEmailVerified: _readBool(json, "isEmailVerified", "IsEmailVerified"),
      isProviderAccount: _readBool(
        json,
        "isProviderAccount",
        "IsProviderAccount",
      ),
    );
  }

  final String id;
  final String email;
  final String userName;
  final int role;
  final bool isApproved;
  final bool isSuspended;
  final bool isEmailVerified;
  final bool isProviderAccount;
}

class AuthResultModel {
  const AuthResultModel({
    required this.success,
    required this.message,
    required this.userId,
    required this.role,
    required this.userName,
    required this.email,
    required this.retryAfterUtc,
  });

  factory AuthResultModel.fromJson(Map<String, dynamic> json) {
    final retryAfterRaw = _readNullableString(
      json,
      "retryAfterUtc",
      "RetryAfterUtc",
    );

    return AuthResultModel(
      success: _readBool(json, "success", "Success"),
      message: _readString(json, "message", "Message"),
      userId: _readNullableString(json, "userId", "UserId"),
      role: _readNullableInt(json, "role", "Role"),
      userName: _readNullableString(json, "userName", "UserName"),
      email: _readNullableString(json, "email", "Email"),
      retryAfterUtc: retryAfterRaw == null
          ? null
          : DateTime.tryParse(retryAfterRaw),
    );
  }

  final bool success;
  final String message;
  final String? userId;
  final int? role;
  final String? userName;
  final String? email;
  final DateTime? retryAfterUtc;
}

class ArtPieceModel {
  const ArtPieceModel({
    required this.id,
    required this.artistId,
    required this.title,
    required this.description,
    required this.assetKind,
    required this.isPublished,
    required this.photoUrls,
    required this.assetFile,
  });

  factory ArtPieceModel.fromJson(Map<String, dynamic> json) {
    final photoEntries = _readList(json, "photos", "Photos");
    final urls = photoEntries
        .whereType<Map<String, dynamic>>()
        .map((entry) => _readString(entry, "url", "Url"))
        .where((url) => url.isNotEmpty)
        .toList(growable: false);
    final assetEntry = _readNullableMap(json, "assetFile", "AssetFile");

    return ArtPieceModel(
      id: _readString(json, "id", "Id"),
      artistId: _readString(json, "artistId", "ArtistId"),
      title: _readString(json, "title", "Title"),
      description: _readString(json, "description", "Description"),
      assetKind: _readInt(json, "assetKind", "AssetKind"),
      isPublished: _readBool(json, "isPublished", "IsPublished"),
      photoUrls: urls,
      assetFile: assetEntry == null
          ? null
          : BinaryAssetModel.fromJson(assetEntry),
    );
  }

  final String id;
  final String artistId;
  final String title;
  final String description;
  final int assetKind;
  final bool isPublished;
  final List<String> photoUrls;
  final BinaryAssetModel? assetFile;
}

class BinaryAssetModel {
  const BinaryAssetModel({
    required this.id,
    required this.url,
    required this.fileName,
    required this.contentType,
    required this.sizeBytes,
  });

  factory BinaryAssetModel.fromJson(Map<String, dynamic> json) {
    return BinaryAssetModel(
      id: _readString(json, "id", "Id"),
      url: _readString(json, "url", "Url"),
      fileName: _readString(json, "fileName", "FileName"),
      contentType: _readString(json, "contentType", "ContentType"),
      sizeBytes: _readInt(json, "sizeBytes", "SizeBytes"),
    );
  }

  final String id;
  final String url;
  final String fileName;
  final String contentType;
  final int sizeBytes;
}

class DropItemModel {
  const DropItemModel({
    required this.id,
    required this.qrToken,
    required this.isClaimed,
    required this.claimedByUserId,
    required this.claimedByAnonymousNickname,
    required this.claimedAtUtc,
  });

  factory DropItemModel.fromJson(Map<String, dynamic> json) {
    final claimedAtRaw = _readNullableString(
      json,
      "claimedAtUtc",
      "ClaimedAtUtc",
    );

    return DropItemModel(
      id: _readString(json, "id", "Id"),
      qrToken: _readString(json, "qrToken", "QrToken"),
      isClaimed: _readBool(json, "isClaimed", "IsClaimed"),
      claimedByUserId: _readNullableString(
        json,
        "claimedByUserId",
        "ClaimedByUserId",
      ),
      claimedByAnonymousNickname: _readNullableString(
        json,
        "claimedByAnonymousNickname",
        "ClaimedByAnonymousNickname",
      ),
      claimedAtUtc: claimedAtRaw == null
          ? null
          : DateTime.tryParse(claimedAtRaw),
    );
  }

  final String id;
  final String qrToken;
  final bool isClaimed;
  final String? claimedByUserId;
  final String? claimedByAnonymousNickname;
  final DateTime? claimedAtUtc;
}

class DropModel {
  const DropModel({
    required this.id,
    required this.artPieceId,
    required this.dropMakerId,
    required this.isStationary,
    required this.portableItemCount,
    required this.latitude,
    required this.longitude,
    required this.isPublished,
    required this.locationPhotoUrls,
    required this.itemCount,
    required this.claimedItemCount,
    required this.items,
  });

  factory DropModel.fromJson(Map<String, dynamic> json) {
    final itemEntries = _readList(
      json,
      "items",
      "Items",
    ).whereType<Map<String, dynamic>>().toList(growable: false);
    final itemModels = itemEntries
        .map(DropItemModel.fromJson)
        .toList(growable: false);
    final locationEntries = _readList(json, "locationPhotos", "LocationPhotos");
    final claimed = itemModels.where((entry) => entry.isClaimed).length;

    return DropModel(
      id: _readString(json, "id", "Id"),
      artPieceId: _readString(json, "artPieceId", "ArtPieceId"),
      dropMakerId: _readString(json, "dropMakerId", "DropMakerId"),
      isStationary: _readBool(json, "isStationary", "IsStationary"),
      portableItemCount: _readNullableInt(
        json,
        "portableItemCount",
        "PortableItemCount",
      ),
      latitude: _readNullableDouble(json, "latitude", "Latitude"),
      longitude: _readNullableDouble(json, "longitude", "Longitude"),
      isPublished: _readBool(json, "isPublished", "IsPublished"),
      locationPhotoUrls: locationEntries
          .whereType<Map<String, dynamic>>()
          .map((entry) => _readString(entry, "url", "Url"))
          .where((url) => url.isNotEmpty)
          .toList(growable: false),
      itemCount: itemModels.length,
      claimedItemCount: claimed,
      items: itemModels,
    );
  }

  final String id;
  final String artPieceId;
  final String dropMakerId;
  final bool isStationary;
  final int? portableItemCount;
  final double? latitude;
  final double? longitude;
  final bool isPublished;
  final List<String> locationPhotoUrls;
  final int itemCount;
  final int claimedItemCount;
  final List<DropItemModel> items;

  bool get isFullyClaimed => itemCount > 0 && claimedItemCount == itemCount;

  List<DropItemModel> get claimedItems =>
      items.where((item) => item.isClaimed).toList(growable: false);

  bool get hasLocation => latitude != null && longitude != null;

  bool get hasLocationPhotos => locationPhotoUrls.isNotEmpty;

  bool get canResumeWizard =>
      itemCount > 0 && !isPublished && (!hasLocation || !hasLocationPhotos);
}

class LeaderboardEntry {
  const LeaderboardEntry({required this.hunter, required this.claims});

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      hunter: _readString(json, "hunter", "Hunter"),
      claims: _readInt(json, "claims", "Claims"),
    );
  }

  final String hunter;
  final int claims;
}

class AppConfigurationModel {
  const AppConfigurationModel({
    required this.smtpHost,
    required this.mainMapRadiusKm,
    required this.miniMapRadiusKm,
    required this.unclaimedDropRadiusKm,
    required this.showExactPositionWhenFullyClaimed,
  });

  factory AppConfigurationModel.fromJson(Map<String, dynamic> json) {
    return AppConfigurationModel(
      smtpHost: _readString(json, "smtpHost", "SmtpHost"),
      mainMapRadiusKm: _readInt(json, "mainMapRadiusKm", "MainMapRadiusKm"),
      miniMapRadiusKm: _readInt(json, "miniMapRadiusKm", "MiniMapRadiusKm"),
      unclaimedDropRadiusKm: _readInt(
        json,
        "unclaimedDropRadiusKm",
        "UnclaimedDropRadiusKm",
      ),
      showExactPositionWhenFullyClaimed: _readBool(
        json,
        "showExactPositionWhenFullyClaimed",
        "ShowExactPositionWhenFullyClaimed",
      ),
    );
  }

  static const AppConfigurationModel defaults = AppConfigurationModel(
    smtpHost: "",
    mainMapRadiusKm: 30,
    miniMapRadiusKm: 5,
    unclaimedDropRadiusKm: 3,
    showExactPositionWhenFullyClaimed: true,
  );

  final String smtpHost;
  final int mainMapRadiusKm;
  final int miniMapRadiusKm;
  final int unclaimedDropRadiusKm;
  final bool showExactPositionWhenFullyClaimed;
}

class CreateDropInput {
  const CreateDropInput({
    required this.artPieceId,
    required this.dropMakerId,
    required this.isStationary,
    required this.portableItemCount,
    required this.latitude,
    required this.longitude,
    required this.locationPhotoUrls,
    required this.itemCount,
  });

  final String artPieceId;
  final String dropMakerId;
  final bool isStationary;
  final int? portableItemCount;
  final double? latitude;
  final double? longitude;
  final List<String> locationPhotoUrls;
  final int itemCount;
}

String _readString(Map<String, dynamic> json, String key, String fallbackKey) {
  final raw = json[key] ?? json[fallbackKey];
  if (raw == null) {
    return "";
  }

  return raw.toString();
}

String? _readNullableString(
  Map<String, dynamic> json,
  String key,
  String fallbackKey,
) {
  final raw = json[key] ?? json[fallbackKey];
  if (raw == null) {
    return null;
  }

  final value = raw.toString().trim();
  if (value.isEmpty || value.toLowerCase() == "null") {
    return null;
  }

  return value;
}

int _readInt(Map<String, dynamic> json, String key, String fallbackKey) {
  final raw = json[key] ?? json[fallbackKey];
  if (raw is int) {
    return raw;
  }
  if (raw is num) {
    return raw.toInt();
  }
  if (raw is String) {
    return int.tryParse(raw) ?? 0;
  }

  return 0;
}

int? _readNullableInt(
  Map<String, dynamic> json,
  String key,
  String fallbackKey,
) {
  final raw = json[key] ?? json[fallbackKey];
  if (raw == null) {
    return null;
  }
  if (raw is int) {
    return raw;
  }
  if (raw is num) {
    return raw.toInt();
  }
  if (raw is String) {
    return int.tryParse(raw);
  }

  return null;
}

double? _readNullableDouble(
  Map<String, dynamic> json,
  String key,
  String fallbackKey,
) {
  final raw = json[key] ?? json[fallbackKey];
  if (raw == null) {
    return null;
  }
  if (raw is double) {
    return raw;
  }
  if (raw is num) {
    return raw.toDouble();
  }
  if (raw is String) {
    return double.tryParse(raw);
  }

  return null;
}

bool _readBool(Map<String, dynamic> json, String key, String fallbackKey) {
  final raw = json[key] ?? json[fallbackKey];
  if (raw is bool) {
    return raw;
  }
  if (raw is String) {
    return raw.toLowerCase() == "true";
  }
  if (raw is num) {
    return raw != 0;
  }

  return false;
}

List<dynamic> _readList(
  Map<String, dynamic> json,
  String key,
  String fallbackKey,
) {
  final raw = json[key] ?? json[fallbackKey];
  if (raw is List<dynamic>) {
    return raw;
  }

  return const [];
}

Map<String, dynamic>? _readNullableMap(
  Map<String, dynamic> json,
  String key,
  String fallbackKey,
) {
  final raw = json[key] ?? json[fallbackKey];
  if (raw is Map<String, dynamic>) {
    return raw;
  }

  return null;
}
