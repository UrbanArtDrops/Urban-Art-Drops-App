import "package:flutter_test/flutter_test.dart";
import "package:urban_art_drops_app/shared/models/app_models.dart";

void main() {
  test("parses moderation queue responses", () {
    final queue = ModerationQueueModel.fromJson({
      "comments": [
        {
          "id": "comment-1",
          "dropId": "drop-1",
          "dropTitle": "Neon Fox",
          "authorUserId": "user-1",
          "authorDisplayName": "HunterOne",
          "content": "Bitte prüfen.",
          "reportReason": "Spam",
          "createdAtUtc": "2026-03-17T10:00:00Z",
          "reportedAtUtc": "2026-03-17T11:00:00Z",
        },
      ],
      "artPieces": [
        {
          "id": "art-1",
          "artistId": "artist-1",
          "title": "Crystal Owl",
          "artistDisplayName": "ArtistOne",
          "isPublished": true,
          "reportReason": "Unangemessen",
          "reportedAtUtc": "2026-03-17T12:00:00Z",
          "previewImageUrl": "https://example.com/preview.png",
        },
      ],
    });

    expect(queue.comments, hasLength(1));
    expect(queue.artPieces, hasLength(1));
    expect(queue.comments.single.authorDisplayName, "HunterOne");
    expect(queue.artPieces.single.previewImageUrl, isNotNull);
  });

  test("parses reported art piece flags on art pieces", () {
    final artPiece = ArtPieceModel.fromJson({
      "id": "art-1",
      "artistId": "artist-1",
      "createdByUserId": "creator-1",
      "title": "Crystal Owl",
      "subtitle": "Night shift",
      "description": "Ein ausfuehrlicher Beschreibungstext fuer das Kunstwerk.",
      "assetKind": 1,
      "isPublished": false,
      "isReported": true,
      "reportReason": "Bitte moderieren",
      "reportedAtUtc": "2026-03-17T09:30:00Z",
      "photos": [
        {"url": "https://example.com/photo.png"},
      ],
      "assetFile": null,
    });

    expect(artPiece.isReported, isTrue);
    expect(artPiece.reportReason, "Bitte moderieren");
    expect(artPiece.reportedAtUtc, isNotNull);
    expect(artPiece.createdByUserId, "creator-1");
  });

  test("parses auth provider status entries on app configuration", () {
    final configuration = AppConfigurationModel.fromJson({
      "smtpHost": "smtp.example.test",
      "smtpPort": 2525,
      "smtpSecurityMode": 1,
      "smtpUserName": "mailer-user",
      "smtpUserEmail": "mailer@example.test",
      "publicAppBaseUrl": "https://app.example.test",
      "mainMapRadiusKm": 30,
      "miniMapRadiusKm": 5,
      "unclaimedDropRadiusKm": 3,
      "showExactPositionWhenFullyClaimed": true,
      "authProviders": [
        {
          "provider": "google",
          "displayName": "Google",
          "enabled": true,
          "visibleOnLogin": true,
          "hasClientId": true,
          "hasClientSecret": true,
          "usesPkce": true,
        },
        {
          "provider": "facebook",
          "displayName": "Facebook",
          "enabled": false,
          "visibleOnLogin": false,
          "hasClientId": false,
          "hasClientSecret": false,
          "usesPkce": false,
        },
      ],
    });

    expect(configuration.authProviders, hasLength(2));
    expect(configuration.smtpPort, 2525);
    expect(configuration.smtpSecurityMode, SmtpSecurityModeModel.tls);
    expect(configuration.smtpUserName, "mailer-user");
    expect(configuration.smtpUserEmail, "mailer@example.test");
    expect(configuration.authProviders.first.provider, "google");
    expect(configuration.authProviders.first.visibleOnLogin, isTrue);
    expect(configuration.authProviders.last.provider, "facebook");
    expect(configuration.authProviders.last.enabled, isFalse);
  });

  test("parses managed user profile image references", () {
    final managedUser = ManagedUser.fromJson({
      "id": "user-1",
      "email": "artist@example.com",
      "userName": "Artist One",
      "role": 1,
      "pendingRoleApplication": null,
      "pendingRoleApplicationRequestedAtUtc": null,
      "isApproved": true,
      "isSuspended": false,
      "isEmailVerified": true,
      "isProviderAccount": false,
      "profileImage": {
        "id": "profile-image-1",
        "url": "https://example.com/user-profile.png",
      },
    });

    expect(managedUser.profileImageUrl, "https://example.com/user-profile.png");
  });
}
