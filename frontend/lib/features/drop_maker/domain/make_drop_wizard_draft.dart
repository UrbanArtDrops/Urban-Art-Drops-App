import "../../../../shared/models/app_models.dart";

enum MakeDropWizardDraftValidationError {
  missingArtPiece,
  missingDropMaker,
  invalidItemCount,
  invalidPortableItemCount,
  missingLocation,
  missingLocationPhotos,
}

class MakeDropWizardDraft {
  const MakeDropWizardDraft({
    required this.dropId,
    required this.artPieceId,
    required this.dropMakerId,
    required this.isStationary,
    required this.portableItemCount,
    required this.itemCount,
    required this.downloadConfirmed,
    required this.locationLabel,
    required this.latitude,
    required this.longitude,
    required this.locationPhotoSources,
    required this.locationPhotoLabels,
    required this.items,
    required this.publishAfterFinish,
  });

  factory MakeDropWizardDraft.initial({
    String artPieceId = "",
    String dropMakerId = "",
  }) {
    return MakeDropWizardDraft(
      dropId: null,
      artPieceId: artPieceId,
      dropMakerId: dropMakerId,
      isStationary: true,
      portableItemCount: null,
      itemCount: 1,
      downloadConfirmed: false,
      locationLabel: "",
      latitude: null,
      longitude: null,
      locationPhotoSources: const [],
      locationPhotoLabels: const [],
      items: const [],
      publishAfterFinish: false,
    );
  }

  factory MakeDropWizardDraft.fromPersistedDrop(DropModel drop) {
    return MakeDropWizardDraft(
      dropId: drop.id,
      artPieceId: drop.artPieceId,
      dropMakerId: drop.dropMakerId,
      isStationary: drop.isStationary,
      portableItemCount: drop.portableItemCount,
      itemCount: drop.itemCount,
      downloadConfirmed: true,
      locationLabel: _buildLocationLabel(drop),
      latitude: drop.latitude,
      longitude: drop.longitude,
      locationPhotoSources: drop.locationPhotoUrls,
      locationPhotoLabels: _buildLocationPhotoLabels(drop.locationPhotoUrls),
      items: drop.items,
      publishAfterFinish: drop.isPublished,
    );
  }

  final String? dropId;
  final String artPieceId;
  final String dropMakerId;
  final bool isStationary;
  final int? portableItemCount;
  final int itemCount;
  final bool downloadConfirmed;
  final String locationLabel;
  final double? latitude;
  final double? longitude;
  final List<String> locationPhotoSources;
  final List<String> locationPhotoLabels;
  final List<DropItemModel> items;
  final bool publishAfterFinish;

  bool get hasPersistedDrop => dropId != null && dropId!.trim().isNotEmpty;

  bool get hasPlacementData =>
      latitude != null && longitude != null && locationPhotoSources.isNotEmpty;

  int get resumeStepIndex => hasPlacementData ? 5 : 4;

  List<String> get qrTokens =>
      items.map((item) => item.qrToken).toList(growable: false);

  MakeDropWizardDraft copyWith({
    String? dropId,
    bool clearDropId = false,
    String? artPieceId,
    String? dropMakerId,
    bool? isStationary,
    int? portableItemCount,
    bool clearPortableItemCount = false,
    int? itemCount,
    bool? downloadConfirmed,
    String? locationLabel,
    double? latitude,
    double? longitude,
    bool clearLatitude = false,
    bool clearLongitude = false,
    List<String>? locationPhotoSources,
    List<String>? locationPhotoLabels,
    List<DropItemModel>? items,
    bool? publishAfterFinish,
  }) {
    return MakeDropWizardDraft(
      dropId: clearDropId ? null : dropId ?? this.dropId,
      artPieceId: artPieceId ?? this.artPieceId,
      dropMakerId: dropMakerId ?? this.dropMakerId,
      isStationary: isStationary ?? this.isStationary,
      portableItemCount: clearPortableItemCount
          ? null
          : portableItemCount ?? this.portableItemCount,
      itemCount: itemCount ?? this.itemCount,
      downloadConfirmed: downloadConfirmed ?? this.downloadConfirmed,
      locationLabel: locationLabel ?? this.locationLabel,
      latitude: clearLatitude ? null : latitude ?? this.latitude,
      longitude: clearLongitude ? null : longitude ?? this.longitude,
      locationPhotoSources: locationPhotoSources ?? this.locationPhotoSources,
      locationPhotoLabels: locationPhotoLabels ?? this.locationPhotoLabels,
      items: items ?? this.items,
      publishAfterFinish: publishAfterFinish ?? this.publishAfterFinish,
    );
  }

  MakeDropWizardDraft withPersistedDrop(DropModel drop) {
    return copyWith(dropId: drop.id, items: drop.items);
  }

  List<MakeDropWizardDraftValidationError> validateCreationStep() {
    final errors = <MakeDropWizardDraftValidationError>[];
    if (artPieceId.trim().isEmpty) {
      errors.add(MakeDropWizardDraftValidationError.missingArtPiece);
    }
    if (dropMakerId.trim().isEmpty) {
      errors.add(MakeDropWizardDraftValidationError.missingDropMaker);
    }
    if (itemCount < 1) {
      errors.add(MakeDropWizardDraftValidationError.invalidItemCount);
    }
    if (!isStationary) {
      final portableCount = portableItemCount;
      if (portableCount == null ||
          portableCount < 1 ||
          portableCount > itemCount) {
        errors.add(MakeDropWizardDraftValidationError.invalidPortableItemCount);
      }
    }
    return errors;
  }

  List<MakeDropWizardDraftValidationError> validatePlacementStep() {
    final errors = <MakeDropWizardDraftValidationError>[];
    if (latitude == null || longitude == null) {
      errors.add(MakeDropWizardDraftValidationError.missingLocation);
    }
    if (locationPhotoSources.isEmpty) {
      errors.add(MakeDropWizardDraftValidationError.missingLocationPhotos);
    }
    return errors;
  }

  CreateDropInput toCreateInput() {
    return CreateDropInput(
      artPieceId: artPieceId,
      dropMakerId: dropMakerId,
      isStationary: isStationary,
      portableItemCount: isStationary ? null : portableItemCount,
      latitude: latitude,
      longitude: longitude,
      locationPhotoUrls: locationPhotoSources,
      itemCount: itemCount,
    );
  }

  static String _buildLocationLabel(DropModel drop) {
    if (drop.latitude == null || drop.longitude == null) {
      return "";
    }

    return "${drop.latitude!.toStringAsFixed(5)}, ${drop.longitude!.toStringAsFixed(5)}";
  }

  static List<String> _buildLocationPhotoLabels(List<String> photoUrls) {
    return photoUrls
        .asMap()
        .entries
        .map((entry) => _labelForPhotoSource(entry.key, entry.value))
        .toList(growable: false);
  }

  static String _labelForPhotoSource(int index, String source) {
    final uri = Uri.tryParse(source);
    final fileName = uri?.pathSegments.isNotEmpty == true
        ? uri!.pathSegments.last
        : "";
    if (fileName.trim().isNotEmpty) {
      return fileName;
    }

    final trimmedSource = source.trim();
    if (trimmedSource.isNotEmpty) {
      return trimmedSource;
    }

    return "#${index + 1}";
  }
}
