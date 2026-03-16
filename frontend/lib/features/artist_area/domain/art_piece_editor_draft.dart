import "../../../../shared/models/app_models.dart";

class ArtPiecePhotoDraft {
  const ArtPiecePhotoDraft({required this.source, required this.label});

  factory ArtPiecePhotoDraft.fromRemoteUrl(String url) {
    final uri = Uri.tryParse(url);
    final lastSegment = uri?.pathSegments.isNotEmpty == true
        ? uri!.pathSegments.last
        : "";

    return ArtPiecePhotoDraft(
      source: url,
      label: lastSegment.isEmpty ? "photo" : lastSegment,
    );
  }

  final String source;
  final String label;
}

enum ArtPieceDraftValidationError {
  missingArtist,
  titleTooShort,
  descriptionTooShort,
  descriptionTooLong,
  missingPhotos,
}

class ArtPieceEditorDraft {
  const ArtPieceEditorDraft({
    required this.id,
    required this.artistId,
    required this.title,
    required this.description,
    required this.assetKind,
    required this.isPublished,
    required this.photos,
  });

  factory ArtPieceEditorDraft.create({required String artistId}) {
    return ArtPieceEditorDraft(
      id: null,
      artistId: artistId,
      title: "",
      description: "",
      assetKind: 0,
      isPublished: false,
      photos: const [],
    );
  }

  factory ArtPieceEditorDraft.fromArtPiece(ArtPieceModel artPiece) {
    return ArtPieceEditorDraft(
      id: artPiece.id,
      artistId: artPiece.artistId,
      title: artPiece.title,
      description: artPiece.description,
      assetKind: artPiece.assetKind,
      isPublished: artPiece.isPublished,
      photos: artPiece.photoUrls
          .map(ArtPiecePhotoDraft.fromRemoteUrl)
          .toList(growable: false),
    );
  }

  final String? id;
  final String artistId;
  final String title;
  final String description;
  final int assetKind;
  final bool isPublished;
  final List<ArtPiecePhotoDraft> photos;

  bool get isEditMode => id != null;

  List<String> get photoSources =>
      photos.map((photo) => photo.source).toList(growable: false);

  ArtPieceEditorDraft copyWith({
    String? id,
    String? artistId,
    String? title,
    String? description,
    int? assetKind,
    bool? isPublished,
    List<ArtPiecePhotoDraft>? photos,
  }) {
    return ArtPieceEditorDraft(
      id: id ?? this.id,
      artistId: artistId ?? this.artistId,
      title: title ?? this.title,
      description: description ?? this.description,
      assetKind: assetKind ?? this.assetKind,
      isPublished: isPublished ?? this.isPublished,
      photos: photos ?? this.photos,
    );
  }

  List<ArtPieceDraftValidationError> validate() {
    final errors = <ArtPieceDraftValidationError>[];

    if (artistId.trim().isEmpty) {
      errors.add(ArtPieceDraftValidationError.missingArtist);
    }

    if (title.trim().length < 3) {
      errors.add(ArtPieceDraftValidationError.titleTooShort);
    }

    final normalizedDescription = description.trim();
    if (normalizedDescription.length < 20) {
      errors.add(ArtPieceDraftValidationError.descriptionTooShort);
    }

    if (normalizedDescription.length > 3000) {
      errors.add(ArtPieceDraftValidationError.descriptionTooLong);
    }

    if (photos.isEmpty) {
      errors.add(ArtPieceDraftValidationError.missingPhotos);
    }

    return errors;
  }
}
