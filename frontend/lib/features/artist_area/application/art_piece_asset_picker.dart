import "dart:convert";

import "package:file_picker/file_picker.dart";
import "package:mime/mime.dart";

import "../domain/art_piece_editor_draft.dart";

abstract interface class ArtPieceAssetPicker {
  Future<ArtPieceAssetDraft?> pickAsset();
}

class FilePickerArtPieceAssetPicker implements ArtPieceAssetPicker {
  const FilePickerArtPieceAssetPicker();

  @override
  Future<ArtPieceAssetDraft?> pickAsset() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.custom,
      allowedExtensions: const ["glb", "gltf", "obj", "stl", "fbx", "usdz"],
      withData: true,
    );

    final file = result == null || result.files.isEmpty
        ? null
        : result.files.first;
    if (file == null || file.bytes == null || file.bytes!.isEmpty) {
      return null;
    }

    final bytes = file.bytes!;
    final mimeType =
        lookupMimeType(file.name, headerBytes: bytes) ??
        "application/octet-stream";

    return ArtPieceAssetDraft(
      source: "data:$mimeType;base64,${base64Encode(bytes)}",
      fileName: file.name,
      contentType: mimeType,
      sizeBytes: bytes.length,
    );
  }
}
