import "dart:convert";

import "package:file_picker/file_picker.dart";
import "package:mime/mime.dart";

import "../domain/art_piece_editor_draft.dart";

abstract interface class ArtPiecePhotoPicker {
  Future<List<ArtPiecePhotoDraft>> pickPhotos();
}

class FilePickerArtPiecePhotoPicker implements ArtPiecePhotoPicker {
  const FilePickerArtPiecePhotoPicker();

  @override
  Future<List<ArtPiecePhotoDraft>> pickPhotos() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.image,
      withData: true,
    );

    if (result == null) {
      return const [];
    }

    return result.files
        .where((file) => file.bytes != null && file.bytes!.isNotEmpty)
        .map((file) {
          final bytes = file.bytes!;
          final mimeType =
              lookupMimeType(file.name, headerBytes: bytes) ??
              "application/octet-stream";

          return ArtPiecePhotoDraft(
            source: "data:$mimeType;base64,${base64Encode(bytes)}",
            label: file.name,
          );
        })
        .toList(growable: false);
  }
}
