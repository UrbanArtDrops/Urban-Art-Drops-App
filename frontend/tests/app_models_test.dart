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
      "title": "Crystal Owl",
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
  });
}
