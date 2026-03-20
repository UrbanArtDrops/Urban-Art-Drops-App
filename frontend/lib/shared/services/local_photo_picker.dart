import "dart:convert";

import "package:file_picker/file_picker.dart";
import "package:image_picker/image_picker.dart";
import "package:mime/mime.dart";

class LocalPhotoSelection {
  const LocalPhotoSelection({required this.source, required this.label});

  final String source;
  final String label;
}

abstract interface class LocalPhotoPicker {
  Future<List<LocalPhotoSelection>> pickPhotos();

  Future<LocalPhotoSelection?> captureSelfie();
}

class FilePickerLocalPhotoPicker implements LocalPhotoPicker {
  const FilePickerLocalPhotoPicker({ImagePicker? imagePicker})
    : _imagePicker = imagePicker;

  final ImagePicker? _imagePicker;

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
        .map((file) => _toSelection(bytes: file.bytes!, fileName: file.name))
        .toList(growable: false);
  }

  @override
  Future<LocalPhotoSelection?> captureSelfie() async {
    final imageFile = await (_imagePicker ?? ImagePicker()).pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.front,
      imageQuality: 90,
    );
    if (imageFile == null) {
      return null;
    }

    final bytes = await imageFile.readAsBytes();
    if (bytes.isEmpty) {
      return null;
    }

    return _toSelection(bytes: bytes, fileName: imageFile.name);
  }

  LocalPhotoSelection _toSelection({
    required List<int> bytes,
    required String fileName,
  }) {
    final mimeType =
        lookupMimeType(fileName, headerBytes: bytes) ??
        "application/octet-stream";
    return LocalPhotoSelection(
      source: "data:$mimeType;base64,${base64Encode(bytes)}",
      label: fileName,
    );
  }
}
