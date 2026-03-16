import "dart:convert";

import "package:file_picker/file_picker.dart";
import "package:mime/mime.dart";

class LocalPhotoSelection {
  const LocalPhotoSelection({required this.source, required this.label});

  final String source;
  final String label;
}

abstract interface class LocalPhotoPicker {
  Future<List<LocalPhotoSelection>> pickPhotos();
}

class FilePickerLocalPhotoPicker implements LocalPhotoPicker {
  const FilePickerLocalPhotoPicker();

  @override
  Future<List<LocalPhotoSelection>> pickPhotos() async {
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
          return LocalPhotoSelection(
            source: "data:$mimeType;base64,${base64Encode(bytes)}",
            label: file.name,
          );
        })
        .toList(growable: false);
  }
}
