import "../domain/art_piece_editor_draft.dart";
import "../../../shared/services/local_photo_picker.dart";

abstract interface class ArtPiecePhotoPicker {
  Future<List<ArtPiecePhotoDraft>> pickPhotos();
}

class FilePickerArtPiecePhotoPicker implements ArtPiecePhotoPicker {
  const FilePickerArtPiecePhotoPicker({LocalPhotoPicker? photoPicker})
    : _photoPicker = photoPicker;

  final LocalPhotoPicker? _photoPicker;

  @override
  Future<List<ArtPiecePhotoDraft>> pickPhotos() async {
    final photos = await (_photoPicker ?? const FilePickerLocalPhotoPicker())
        .pickPhotos();

    return photos
        .map(
          (photo) =>
              ArtPiecePhotoDraft(source: photo.source, label: photo.label),
        )
        .toList(growable: false);
  }
}
