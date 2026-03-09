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

class ArtPieceModel {
  const ArtPieceModel({
    required this.id,
    required this.artistId,
    required this.title,
    required this.description,
    required this.assetKind,
    required this.isPublished,
    required this.photoUrls,
  });

  factory ArtPieceModel.fromJson(Map<String, dynamic> json) {
    final photoEntries = _readList(json, "photos", "Photos");
    final urls = photoEntries
        .whereType<Map<String, dynamic>>()
        .map((entry) => _readString(entry, "url", "Url"))
        .where((url) => url.isNotEmpty)
        .toList(growable: false);

    return ArtPieceModel(
      id: _readString(json, "id", "Id"),
      artistId: _readString(json, "artistId", "ArtistId"),
      title: _readString(json, "title", "Title"),
      description: _readString(json, "description", "Description"),
      assetKind: _readInt(json, "assetKind", "AssetKind"),
      isPublished: _readBool(json, "isPublished", "IsPublished"),
      photoUrls: urls,
    );
  }

  final String id;
  final String artistId;
  final String title;
  final String description;
  final int assetKind;
  final bool isPublished;
  final List<String> photoUrls;
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
  });

  factory DropModel.fromJson(Map<String, dynamic> json) {
    final itemEntries = _readList(json, "items", "Items");
    final locationEntries = _readList(json, "locationPhotos", "LocationPhotos");
    final claimed = itemEntries
        .whereType<Map<String, dynamic>>()
        .where((entry) => _readBool(entry, "isClaimed", "IsClaimed"))
        .length;

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
      itemCount: itemEntries.length,
      claimedItemCount: claimed,
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

  bool get isFullyClaimed => itemCount > 0 && claimedItemCount == itemCount;
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
