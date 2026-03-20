class ManagedUser {
  const ManagedUser({
    required this.id,
    required this.email,
    required this.userName,
    required this.role,
    required this.pendingRoleApplication,
    required this.pendingRoleApplicationRequestedAtUtc,
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
      pendingRoleApplication: _readNullableInt(
        json,
        "pendingRoleApplication",
        "PendingRoleApplication",
      ),
      pendingRoleApplicationRequestedAtUtc: _readNullableDateTime(
        json,
        "pendingRoleApplicationRequestedAtUtc",
        "PendingRoleApplicationRequestedAtUtc",
      ),
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
  final int? pendingRoleApplication;
  final DateTime? pendingRoleApplicationRequestedAtUtc;
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
    required this.accessToken,
    required this.accessTokenExpiresAtUtc,
    required this.tokenType,
    required this.requiresMfa,
    required this.mfaSetupRequired,
    required this.mfaChallengeToken,
    required this.mfaChallengeExpiresAtUtc,
    required this.mfaManualEntryKey,
    required this.mfaProvisioningUri,
  });

  factory AuthResultModel.fromJson(Map<String, dynamic> json) {
    final retryAfterRaw = _readNullableString(
      json,
      "retryAfterUtc",
      "RetryAfterUtc",
    );
    final accessTokenExpiresAtRaw = _readNullableString(
      json,
      "accessTokenExpiresAtUtc",
      "AccessTokenExpiresAtUtc",
    );
    final mfaChallengeExpiresAtRaw = _readNullableString(
      json,
      "mfaChallengeExpiresAtUtc",
      "MfaChallengeExpiresAtUtc",
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
      accessToken: _readNullableString(json, "accessToken", "AccessToken"),
      accessTokenExpiresAtUtc: accessTokenExpiresAtRaw == null
          ? null
          : DateTime.tryParse(accessTokenExpiresAtRaw),
      tokenType: _readNullableString(json, "tokenType", "TokenType"),
      requiresMfa: _readBool(json, "requiresMfa", "RequiresMfa"),
      mfaSetupRequired: _readBool(json, "mfaSetupRequired", "MfaSetupRequired"),
      mfaChallengeToken: _readNullableString(
        json,
        "mfaChallengeToken",
        "MfaChallengeToken",
      ),
      mfaChallengeExpiresAtUtc: mfaChallengeExpiresAtRaw == null
          ? null
          : DateTime.tryParse(mfaChallengeExpiresAtRaw),
      mfaManualEntryKey: _readNullableString(
        json,
        "mfaManualEntryKey",
        "MfaManualEntryKey",
      ),
      mfaProvisioningUri: _readNullableString(
        json,
        "mfaProvisioningUri",
        "MfaProvisioningUri",
      ),
    );
  }

  final bool success;
  final String message;
  final String? userId;
  final int? role;
  final String? userName;
  final String? email;
  final DateTime? retryAfterUtc;
  final String? accessToken;
  final DateTime? accessTokenExpiresAtUtc;
  final String? tokenType;
  final bool requiresMfa;
  final bool mfaSetupRequired;
  final String? mfaChallengeToken;
  final DateTime? mfaChallengeExpiresAtUtc;
  final String? mfaManualEntryKey;
  final String? mfaProvisioningUri;
}

class ExternalProviderAuthStartModel {
  const ExternalProviderAuthStartModel({
    required this.authorizationUrl,
    required this.expiresAtUtc,
  });

  factory ExternalProviderAuthStartModel.fromJson(Map<String, dynamic> json) {
    final expiresAtRaw = _readNullableString(
      json,
      "expiresAtUtc",
      "ExpiresAtUtc",
    );
    return ExternalProviderAuthStartModel(
      authorizationUrl: _readString(
        json,
        "authorizationUrl",
        "AuthorizationUrl",
      ),
      expiresAtUtc: expiresAtRaw == null
          ? null
          : DateTime.tryParse(expiresAtRaw),
    );
  }

  final String authorizationUrl;
  final DateTime? expiresAtUtc;
}

class AuthProviderOptionModel {
  const AuthProviderOptionModel({
    required this.provider,
    required this.displayName,
  });

  factory AuthProviderOptionModel.fromJson(Map<String, dynamic> json) {
    return AuthProviderOptionModel(
      provider: _readString(json, "provider", "Provider"),
      displayName: _readString(json, "displayName", "DisplayName"),
    );
  }

  final String provider;
  final String displayName;
}

class AuthProviderConfigurationStatusModel {
  const AuthProviderConfigurationStatusModel({
    required this.provider,
    required this.displayName,
    required this.enabled,
    required this.visibleOnLogin,
    required this.hasClientId,
    required this.hasClientSecret,
    required this.usesPkce,
  });

  factory AuthProviderConfigurationStatusModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return AuthProviderConfigurationStatusModel(
      provider: _readString(json, "provider", "Provider"),
      displayName: _readString(json, "displayName", "DisplayName"),
      enabled: _readBool(json, "enabled", "Enabled"),
      visibleOnLogin: _readBool(json, "visibleOnLogin", "VisibleOnLogin"),
      hasClientId: _readBool(json, "hasClientId", "HasClientId"),
      hasClientSecret: _readBool(json, "hasClientSecret", "HasClientSecret"),
      usesPkce: _readBool(json, "usesPkce", "UsesPkce"),
    );
  }

  final String provider;
  final String displayName;
  final bool enabled;
  final bool visibleOnLogin;
  final bool hasClientId;
  final bool hasClientSecret;
  final bool usesPkce;
}

class CurrentUserProfileModel {
  const CurrentUserProfileModel({
    required this.userId,
    required this.email,
    required this.userName,
    required this.role,
    required this.pendingRoleApplication,
    required this.pendingRoleApplicationRequestedAtUtc,
    required this.isProviderAccount,
    required this.isMfaEnabled,
    required this.isMfaRequiredByPolicy,
    required this.profileImageUrl,
  });

  factory CurrentUserProfileModel.fromJson(Map<String, dynamic> json) {
    final profileImageEntry = _readNullableMap(
      json,
      "profileImage",
      "ProfileImage",
    );

    return CurrentUserProfileModel(
      userId: _readString(json, "userId", "UserId"),
      email: _readString(json, "email", "Email"),
      userName: _readString(json, "userName", "UserName"),
      role: _readInt(json, "role", "Role"),
      pendingRoleApplication: _readNullableInt(
        json,
        "pendingRoleApplication",
        "PendingRoleApplication",
      ),
      pendingRoleApplicationRequestedAtUtc: _readNullableDateTime(
        json,
        "pendingRoleApplicationRequestedAtUtc",
        "PendingRoleApplicationRequestedAtUtc",
      ),
      isProviderAccount: _readBool(
        json,
        "isProviderAccount",
        "IsProviderAccount",
      ),
      isMfaEnabled: _readBool(json, "isMfaEnabled", "IsMfaEnabled"),
      isMfaRequiredByPolicy: _readBool(
        json,
        "isMfaRequiredByPolicy",
        "IsMfaRequiredByPolicy",
      ),
      profileImageUrl: profileImageEntry == null
          ? null
          : _readNullableString(profileImageEntry, "url", "Url"),
    );
  }

  final String userId;
  final String email;
  final String userName;
  final int role;
  final int? pendingRoleApplication;
  final DateTime? pendingRoleApplicationRequestedAtUtc;
  final bool isProviderAccount;
  final bool isMfaEnabled;
  final bool isMfaRequiredByPolicy;
  final String? profileImageUrl;
}

class UserNotificationModel {
  const UserNotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.category,
    required this.isRead,
    required this.createdAtUtc,
    required this.relatedEntityId,
    required this.relatedEntityType,
  });

  factory UserNotificationModel.fromJson(Map<String, dynamic> json) {
    final createdAtRaw = _readNullableString(
      json,
      "createdAtUtc",
      "CreatedAtUtc",
    );

    return UserNotificationModel(
      id: _readString(json, "id", "Id"),
      title: _readString(json, "title", "Title"),
      message: _readString(json, "message", "Message"),
      category: _readString(json, "category", "Category"),
      isRead: _readBool(json, "isRead", "IsRead"),
      createdAtUtc: createdAtRaw == null
          ? null
          : DateTime.tryParse(createdAtRaw),
      relatedEntityId: _readNullableString(
        json,
        "relatedEntityId",
        "RelatedEntityId",
      ),
      relatedEntityType: _readNullableString(
        json,
        "relatedEntityType",
        "RelatedEntityType",
      ),
    );
  }

  final String id;
  final String title;
  final String message;
  final String category;
  final bool isRead;
  final DateTime? createdAtUtc;
  final String? relatedEntityId;
  final String? relatedEntityType;
}

class BootstrapStatusModel {
  const BootstrapStatusModel({
    required this.bootstrapRequired,
    required this.adminUserExists,
    required this.moderatorBootstrapAvailable,
  });

  factory BootstrapStatusModel.fromJson(Map<String, dynamic> json) {
    return BootstrapStatusModel(
      bootstrapRequired: _readBool(
        json,
        "bootstrapRequired",
        "BootstrapRequired",
      ),
      adminUserExists: _readBool(json, "adminUserExists", "AdminUserExists"),
      moderatorBootstrapAvailable: _readBool(
        json,
        "moderatorBootstrapAvailable",
        "ModeratorBootstrapAvailable",
      ),
    );
  }

  final bool bootstrapRequired;
  final bool adminUserExists;
  final bool moderatorBootstrapAvailable;
}

class ArtPieceModel {
  const ArtPieceModel({
    required this.id,
    required this.artistId,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.assetKind,
    required this.isPublished,
    required this.isReported,
    required this.reportReason,
    required this.reportedAtUtc,
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
    final reportedAtRaw = _readNullableString(
      json,
      "reportedAtUtc",
      "ReportedAtUtc",
    );

    return ArtPieceModel(
      id: _readString(json, "id", "Id"),
      artistId: _readString(json, "artistId", "ArtistId"),
      title: _readString(json, "title", "Title"),
      subtitle: _readString(json, "subtitle", "Subtitle"),
      description: _readString(json, "description", "Description"),
      assetKind: _readInt(json, "assetKind", "AssetKind"),
      isPublished: _readBool(json, "isPublished", "IsPublished"),
      isReported: _readBool(json, "isReported", "IsReported"),
      reportReason: _readNullableString(json, "reportReason", "ReportReason"),
      reportedAtUtc: reportedAtRaw == null
          ? null
          : DateTime.tryParse(reportedAtRaw),
      photoUrls: urls,
      assetFile: assetEntry == null
          ? null
          : BinaryAssetModel.fromJson(assetEntry),
    );
  }

  final String id;
  final String artistId;
  final String title;
  final String subtitle;
  final String description;
  final int assetKind;
  final bool isPublished;
  final bool isReported;
  final String? reportReason;
  final DateTime? reportedAtUtc;
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
    required this.claimUrl,
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
      claimUrl: _readString(json, "claimUrl", "ClaimUrl"),
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
  final String claimUrl;
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
    required this.dropMakerComment,
    required this.socialChannels,
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
    final socialChannels = _readList(json, "socialChannels", "SocialChannels");
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
      dropMakerComment: _readNullableString(
        json,
        "dropMakerComment",
        "DropMakerComment",
      ),
      socialChannels: socialChannels
          .map((entry) => entry.toString().trim())
          .where((entry) => entry.isNotEmpty)
          .toList(growable: false),
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
  final String? dropMakerComment;
  final List<String> socialChannels;
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

class DropCommentModel {
  const DropCommentModel({
    required this.id,
    required this.dropId,
    required this.authorUserId,
    required this.authorDisplayName,
    required this.anonymousNickname,
    required this.content,
    required this.isReported,
    required this.isHidden,
    required this.reportReason,
    required this.createdAtUtc,
    required this.reportedAtUtc,
  });

  factory DropCommentModel.fromJson(Map<String, dynamic> json) {
    final createdAtRaw = _readNullableString(
      json,
      "createdAtUtc",
      "CreatedAtUtc",
    );
    final reportedAtRaw = _readNullableString(
      json,
      "reportedAtUtc",
      "ReportedAtUtc",
    );

    return DropCommentModel(
      id: _readString(json, "id", "Id"),
      dropId: _readString(json, "dropId", "DropId"),
      authorUserId: _readNullableString(json, "authorUserId", "AuthorUserId"),
      authorDisplayName: _readNullableString(
        json,
        "authorDisplayName",
        "AuthorDisplayName",
      ),
      anonymousNickname: _readNullableString(
        json,
        "anonymousNickname",
        "AnonymousNickname",
      ),
      content: _readString(json, "content", "Content"),
      isReported: _readBool(json, "isReported", "IsReported"),
      isHidden: _readBool(json, "isHidden", "IsHidden"),
      reportReason: _readNullableString(json, "reportReason", "ReportReason"),
      createdAtUtc: createdAtRaw == null
          ? null
          : DateTime.tryParse(createdAtRaw),
      reportedAtUtc: reportedAtRaw == null
          ? null
          : DateTime.tryParse(reportedAtRaw),
    );
  }

  final String id;
  final String dropId;
  final String? authorUserId;
  final String? authorDisplayName;
  final String? anonymousNickname;
  final String content;
  final bool isReported;
  final bool isHidden;
  final String? reportReason;
  final DateTime? createdAtUtc;
  final DateTime? reportedAtUtc;

  String get displayName {
    final preferred = authorDisplayName?.trim();
    if (preferred != null && preferred.isNotEmpty) {
      return preferred;
    }

    final nickname = anonymousNickname?.trim();
    if (nickname != null && nickname.isNotEmpty) {
      return nickname;
    }

    return "Anonym";
  }
}

class ModerationQueueModel {
  const ModerationQueueModel({required this.comments, required this.artPieces});

  factory ModerationQueueModel.fromJson(Map<String, dynamic> json) {
    final commentEntries = _readList(json, "comments", "Comments");
    final artPieceEntries = _readList(json, "artPieces", "ArtPieces");

    return ModerationQueueModel(
      comments: commentEntries
          .whereType<Map<String, dynamic>>()
          .map(ReportedCommentModel.fromJson)
          .toList(growable: false),
      artPieces: artPieceEntries
          .whereType<Map<String, dynamic>>()
          .map(ReportedArtPieceModel.fromJson)
          .toList(growable: false),
    );
  }

  final List<ReportedCommentModel> comments;
  final List<ReportedArtPieceModel> artPieces;
}

class ReportedCommentModel {
  const ReportedCommentModel({
    required this.id,
    required this.dropId,
    required this.dropTitle,
    required this.authorUserId,
    required this.authorDisplayName,
    required this.content,
    required this.reportReason,
    required this.createdAtUtc,
    required this.reportedAtUtc,
  });

  factory ReportedCommentModel.fromJson(Map<String, dynamic> json) {
    final createdAtRaw = _readNullableString(
      json,
      "createdAtUtc",
      "CreatedAtUtc",
    );
    final reportedAtRaw = _readNullableString(
      json,
      "reportedAtUtc",
      "ReportedAtUtc",
    );

    return ReportedCommentModel(
      id: _readString(json, "id", "Id"),
      dropId: _readString(json, "dropId", "DropId"),
      dropTitle: _readString(json, "dropTitle", "DropTitle"),
      authorUserId: _readNullableString(json, "authorUserId", "AuthorUserId"),
      authorDisplayName: _readString(
        json,
        "authorDisplayName",
        "AuthorDisplayName",
      ),
      content: _readString(json, "content", "Content"),
      reportReason: _readNullableString(json, "reportReason", "ReportReason"),
      createdAtUtc: createdAtRaw == null
          ? null
          : DateTime.tryParse(createdAtRaw),
      reportedAtUtc: reportedAtRaw == null
          ? null
          : DateTime.tryParse(reportedAtRaw),
    );
  }

  final String id;
  final String dropId;
  final String dropTitle;
  final String? authorUserId;
  final String authorDisplayName;
  final String content;
  final String? reportReason;
  final DateTime? createdAtUtc;
  final DateTime? reportedAtUtc;
}

class ReportedArtPieceModel {
  const ReportedArtPieceModel({
    required this.id,
    required this.artistId,
    required this.title,
    required this.artistDisplayName,
    required this.isPublished,
    required this.reportReason,
    required this.reportedAtUtc,
    required this.previewImageUrl,
  });

  factory ReportedArtPieceModel.fromJson(Map<String, dynamic> json) {
    final reportedAtRaw = _readNullableString(
      json,
      "reportedAtUtc",
      "ReportedAtUtc",
    );

    return ReportedArtPieceModel(
      id: _readString(json, "id", "Id"),
      artistId: _readString(json, "artistId", "ArtistId"),
      title: _readString(json, "title", "Title"),
      artistDisplayName: _readString(
        json,
        "artistDisplayName",
        "ArtistDisplayName",
      ),
      isPublished: _readBool(json, "isPublished", "IsPublished"),
      reportReason: _readNullableString(json, "reportReason", "ReportReason"),
      reportedAtUtc: reportedAtRaw == null
          ? null
          : DateTime.tryParse(reportedAtRaw),
      previewImageUrl: _readNullableString(
        json,
        "previewImageUrl",
        "PreviewImageUrl",
      ),
    );
  }

  final String id;
  final String artistId;
  final String title;
  final String artistDisplayName;
  final bool isPublished;
  final String? reportReason;
  final DateTime? reportedAtUtc;
  final String? previewImageUrl;
}

class AppConfigurationModel {
  const AppConfigurationModel({
    required this.smtpHost,
    required this.publicAppBaseUrl,
    required this.mainMapRadiusKm,
    required this.miniMapRadiusKm,
    required this.unclaimedDropRadiusKm,
    required this.showExactPositionWhenFullyClaimed,
    required this.authProviders,
  });

  factory AppConfigurationModel.fromJson(Map<String, dynamic> json) {
    final providerEntries = _readList(json, "authProviders", "AuthProviders");
    return AppConfigurationModel(
      smtpHost: _readString(json, "smtpHost", "SmtpHost"),
      publicAppBaseUrl: _readString(
        json,
        "publicAppBaseUrl",
        "PublicAppBaseUrl",
      ),
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
      authProviders: providerEntries
          .whereType<Map<String, dynamic>>()
          .map(AuthProviderConfigurationStatusModel.fromJson)
          .toList(growable: false),
    );
  }

  static const AppConfigurationModel defaults = AppConfigurationModel(
    smtpHost: "",
    publicAppBaseUrl: "",
    mainMapRadiusKm: 30,
    miniMapRadiusKm: 5,
    unclaimedDropRadiusKm: 3,
    showExactPositionWhenFullyClaimed: true,
    authProviders: [],
  );

  final String smtpHost;
  final String publicAppBaseUrl;
  final int mainMapRadiusKm;
  final int miniMapRadiusKm;
  final int unclaimedDropRadiusKm;
  final bool showExactPositionWhenFullyClaimed;
  final List<AuthProviderConfigurationStatusModel> authProviders;
}

class ClaimPreviewModel {
  const ClaimPreviewModel({
    required this.dropId,
    required this.dropItemId,
    required this.artPieceId,
    required this.artPieceTitle,
    required this.isClaimed,
    required this.claimedByDisplayName,
  });

  factory ClaimPreviewModel.fromJson(Map<String, dynamic> json) {
    return ClaimPreviewModel(
      dropId: _readString(json, "dropId", "DropId"),
      dropItemId: _readString(json, "dropItemId", "DropItemId"),
      artPieceId: _readString(json, "artPieceId", "ArtPieceId"),
      artPieceTitle: _readString(json, "artPieceTitle", "ArtPieceTitle"),
      isClaimed: _readBool(json, "isClaimed", "IsClaimed"),
      claimedByDisplayName: _readNullableString(
        json,
        "claimedByDisplayName",
        "ClaimedByDisplayName",
      ),
    );
  }

  final String dropId;
  final String dropItemId;
  final String artPieceId;
  final String artPieceTitle;
  final bool isClaimed;
  final String? claimedByDisplayName;
}

class CreateDropInput {
  const CreateDropInput({
    required this.artPieceId,
    required this.dropMakerId,
    required this.isStationary,
    required this.portableItemCount,
    required this.dropMakerComment,
    required this.socialChannels,
    required this.latitude,
    required this.longitude,
    required this.locationPhotoUrls,
    required this.itemCount,
  });

  final String artPieceId;
  final String dropMakerId;
  final bool isStationary;
  final int? portableItemCount;
  final String? dropMakerComment;
  final List<String> socialChannels;
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

DateTime? _readNullableDateTime(
  Map<String, dynamic> json,
  String key,
  String fallbackKey,
) {
  final raw = _readNullableString(json, key, fallbackKey);
  if (raw == null) {
    return null;
  }

  return DateTime.tryParse(raw);
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
