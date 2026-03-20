import "package:flutter_test/flutter_test.dart";
import "package:urban_art_drops_app/features/artist_area/domain/art_piece_editor_draft.dart";
import "package:urban_art_drops_app/shared/models/app_models.dart";

void main() {
  test("validate returns expected errors for incomplete art piece draft", () {
    final draft = ArtPieceEditorDraft.create(artistId: "").copyWith(
      title: "AB",
      description: "Too short",
      photos: const [],
      assetKind: 1,
    );

    final errors = draft.validate();

    expect(errors, contains(ArtPieceDraftValidationError.missingArtist));
    expect(errors, contains(ArtPieceDraftValidationError.titleTooShort));
    expect(errors, contains(ArtPieceDraftValidationError.descriptionTooShort));
    expect(errors, contains(ArtPieceDraftValidationError.missingPhotos));
    expect(errors, contains(ArtPieceDraftValidationError.missingModelAsset));
  });

  test("fromArtPiece keeps existing remote photos available for editing", () {
    const artPiece = ArtPieceModel(
      id: "art-1",
      artistId: "artist-1",
      createdByUserId: "artist-1",
      title: "Crystal Owl",
      subtitle: "Limited city edition",
      description: "This description is definitely long enough.",
      assetKind: 1,
      isPublished: true,
      isReported: false,
      reportReason: null,
      reportedAtUtc: null,
      photoUrls: ["http://localhost:5143/api/media/art-piece-photos/1"],
      assetFile: BinaryAssetModel(
        id: "asset-1",
        url: "http://localhost:5143/api/media/art-piece-assets/1",
        fileName: "owl.glb",
        contentType: "model/gltf-binary",
        sizeBytes: 4096,
      ),
    );

    final draft = ArtPieceEditorDraft.fromArtPiece(artPiece);

    expect(draft.id, artPiece.id);
    expect(draft.artistId, artPiece.artistId);
    expect(draft.subtitle, artPiece.subtitle);
    expect(draft.assetKind, artPiece.assetKind);
    expect(draft.isPublished, isTrue);
    expect(draft.photoSources, artPiece.photoUrls);
    expect(draft.assetFile?.source, artPiece.assetFile?.url);
    expect(draft.assetFile?.fileName, artPiece.assetFile?.fileName);
  });
}
