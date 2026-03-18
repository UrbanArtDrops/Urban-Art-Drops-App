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

class ArtPieceAssetDraft {
  const ArtPieceAssetDraft({
    required this.source,
    required this.fileName,
    required this.contentType,
    required this.sizeBytes,
  });

  factory ArtPieceAssetDraft.fromRemoteAsset(BinaryAssetModel asset) {
    return ArtPieceAssetDraft(
      source: asset.url,
      fileName: asset.fileName,
      contentType: asset.contentType,
      sizeBytes: asset.sizeBytes,
    );
  }

  final String source;
  final String fileName;
  final String contentType;
  final int sizeBytes;
}

enum ArtPieceDraftValidationError {
  missingArtist,
  titleTooShort,
  subtitleTooLong,
  descriptionTooShort,
  descriptionTooLong,
  missingPhotos,
  missingModelAsset,
}

class ArtPieceEditorDraft {
  const ArtPieceEditorDraft({
    required this.id,
    required this.artistId,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.assetKind,
    required this.isPublished,
    required this.photos,
    required this.assetFile,
  });

  factory ArtPieceEditorDraft.create({required String artistId}) {
    return ArtPieceEditorDraft(
      id: null,
      artistId: artistId,
      title: "",
      subtitle: "",
      description: "",
      assetKind: 0,
      isPublished: false,
      photos: const [],
      assetFile: null,
    );
  }

  factory ArtPieceEditorDraft.fromArtPiece(ArtPieceModel artPiece) {
    return ArtPieceEditorDraft(
      id: artPiece.id,
      artistId: artPiece.artistId,
      title: artPiece.title,
      subtitle: artPiece.subtitle,
      description: artPiece.description,
      assetKind: artPiece.assetKind,
      isPublished: artPiece.isPublished,
      photos: artPiece.photoUrls
          .map(ArtPiecePhotoDraft.fromRemoteUrl)
          .toList(growable: false),
      assetFile: artPiece.assetFile == null
          ? null
          : ArtPieceAssetDraft.fromRemoteAsset(artPiece.assetFile!),
    );
  }

  final String? id;
  final String artistId;
  final String title;
  final String subtitle;
  final String description;
  final int assetKind;
  final bool isPublished;
  final List<ArtPiecePhotoDraft> photos;
  final ArtPieceAssetDraft? assetFile;

  bool get isEditMode => id != null;

  List<String> get photoSources =>
      photos.map((photo) => photo.source).toList(growable: false);

  String? get assetSource => assetFile?.source;
  String? get assetFileName => assetFile?.fileName;

  ArtPieceEditorDraft copyWith({
    String? id,
    String? artistId,
    String? title,
    String? subtitle,
    String? description,
    int? assetKind,
    bool? isPublished,
    List<ArtPiecePhotoDraft>? photos,
    ArtPieceAssetDraft? assetFile,
    bool clearAssetFile = false,
  }) {
    return ArtPieceEditorDraft(
      id: id ?? this.id,
      artistId: artistId ?? this.artistId,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      description: description ?? this.description,
      assetKind: assetKind ?? this.assetKind,
      isPublished: isPublished ?? this.isPublished,
      photos: photos ?? this.photos,
      assetFile: clearAssetFile ? null : assetFile ?? this.assetFile,
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

    if (subtitle.trim().length > 200) {
      errors.add(ArtPieceDraftValidationError.subtitleTooLong);
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

    if (assetKind == 1 && assetFile == null) {
      errors.add(ArtPieceDraftValidationError.missingModelAsset);
    }

    return errors;
  }
}
