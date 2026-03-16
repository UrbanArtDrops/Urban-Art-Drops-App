import "package:flutter/material.dart";
import "package:urban_art_drops_app/l10n/app_localizations.dart";

import "../../../../shared/models/app_models.dart";
import "../../application/art_piece_asset_picker.dart";
import "../../application/art_piece_photo_picker.dart";
import "../../domain/art_piece_editor_draft.dart";
import "art_piece_source_image.dart";

Future<ArtPieceEditorDraft?> showArtPieceEditorDialog(
  BuildContext context, {
  required List<ManagedUser> artists,
  required ArtPieceEditorDraft initialDraft,
  required ArtPiecePhotoPicker photoPicker,
  required ArtPieceAssetPicker assetPicker,
}) {
  return showDialog<ArtPieceEditorDraft>(
    context: context,
    builder: (context) => _ArtPieceEditorDialog(
      artists: artists,
      initialDraft: initialDraft,
      photoPicker: photoPicker,
      assetPicker: assetPicker,
    ),
  );
}

class _ArtPieceEditorDialog extends StatefulWidget {
  const _ArtPieceEditorDialog({
    required this.artists,
    required this.initialDraft,
    required this.photoPicker,
    required this.assetPicker,
  });

  final List<ManagedUser> artists;
  final ArtPieceEditorDraft initialDraft;
  final ArtPiecePhotoPicker photoPicker;
  final ArtPieceAssetPicker assetPicker;

  @override
  State<_ArtPieceEditorDialog> createState() => _ArtPieceEditorDialogState();
}

class _ArtPieceEditorDialogState extends State<_ArtPieceEditorDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late ArtPieceEditorDraft _draft;
  List<ArtPieceDraftValidationError> _validationErrors = const [];
  bool _isPickingAsset = false;
  bool _isPickingPhotos = false;

  @override
  void initState() {
    super.initState();
    _draft = widget.initialDraft;
    _titleController = TextEditingController(text: _draft.title);
    _descriptionController = TextEditingController(text: _draft.description);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickPhotos() async {
    setState(() => _isPickingPhotos = true);

    try {
      final photos = await widget.photoPicker.pickPhotos();
      if (!mounted || photos.isEmpty) {
        return;
      }

      setState(() {
        _draft = _draft.copyWith(photos: [..._draft.photos, ...photos]);
        _validationErrors = const [];
      });
    } finally {
      if (mounted) {
        setState(() => _isPickingPhotos = false);
      }
    }
  }

  Future<void> _pickAsset() async {
    setState(() => _isPickingAsset = true);

    try {
      final asset = await widget.assetPicker.pickAsset();
      if (!mounted || asset == null) {
        return;
      }

      setState(() {
        _draft = _draft.copyWith(assetFile: asset);
        _validationErrors = const [];
      });
    } finally {
      if (mounted) {
        setState(() => _isPickingAsset = false);
      }
    }
  }

  void _removePhoto(ArtPiecePhotoDraft photo) {
    setState(() {
      _draft = _draft.copyWith(
        photos: _draft.photos
            .where((candidate) => candidate != photo)
            .toList(growable: false),
      );
    });
  }

  void _removeAsset() {
    setState(() {
      _draft = _draft.copyWith(clearAssetFile: true);
    });
  }

  void _save() {
    final nextDraft = _draft.copyWith(
      title: _titleController.text,
      description: _descriptionController.text,
    );
    final validationErrors = nextDraft.validate();

    if (validationErrors.isNotEmpty) {
      setState(() {
        _draft = nextDraft;
        _validationErrors = validationErrors;
      });
      return;
    }

    Navigator.of(context).pop(nextDraft);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 860),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _draft.isEditMode
                    ? l10n.artPieceEditTitle
                    : l10n.artPieceCreateTitle,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              if (_validationErrors.isNotEmpty) ...[
                _ValidationSummary(errors: _validationErrors),
                const SizedBox(height: 16),
              ],
              SizedBox(
                height: MediaQuery.sizeOf(context).height * 0.6,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isCompact = constraints.maxWidth < 640;
                          final formChildren = [
                            _buildPrimaryFields(l10n),
                            _buildMediaSection(l10n),
                          ];

                          if (isCompact) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children:
                                  formChildren
                                      .expand(
                                        (child) => [
                                          child,
                                          const SizedBox(height: 20),
                                        ],
                                      )
                                      .toList(growable: false)
                                    ..removeLast(),
                            );
                          }

                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 4, child: formChildren[0]),
                              const SizedBox(width: 20),
                              Expanded(flex: 5, child: formChildren[1]),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(l10n.cancelAction),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(onPressed: _save, child: Text(l10n.saveButton)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPrimaryFields(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _titleController,
          decoration: InputDecoration(labelText: l10n.artPieceTitleLabel),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: _draft.artistId,
          decoration: InputDecoration(labelText: l10n.artPieceArtistLabel),
          items: widget.artists
              .map(
                (artist) => DropdownMenuItem(
                  value: artist.id,
                  child: Text("${artist.userName} (${artist.email})"),
                ),
              )
              .toList(growable: false),
          onChanged: (value) {
            if (value == null) {
              return;
            }

            setState(() => _draft = _draft.copyWith(artistId: value));
          },
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<int>(
          initialValue: _draft.assetKind,
          decoration: InputDecoration(labelText: l10n.artPieceAssetTypeLabel),
          items: [
            DropdownMenuItem(value: 0, child: Text(l10n.artPieceAssetImage)),
            DropdownMenuItem(value: 1, child: Text(l10n.artPieceAssetModel3d)),
          ],
          onChanged: (value) {
            if (value == null) {
              return;
            }

            setState(() => _draft = _draft.copyWith(assetKind: value));
          },
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _descriptionController,
          minLines: 6,
          maxLines: 10,
          decoration: InputDecoration(
            labelText: l10n.artPieceDescriptionLabel,
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 12),
        SwitchListTile(
          value: _draft.isPublished,
          contentPadding: EdgeInsets.zero,
          onChanged: (value) {
            setState(() => _draft = _draft.copyWith(isPublished: value));
          },
          title: Text(
            _draft.isPublished ? l10n.statusPublished : l10n.statusUnpublished,
          ),
        ),
      ],
    );
  }

  Widget _buildMediaSection(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_draft.assetKind == 1) ...[
          _buildAssetSection(l10n),
          const SizedBox(height: 24),
        ],
        _buildPhotoSection(l10n),
      ],
    );
  }

  Widget _buildAssetSection(AppLocalizations l10n) {
    final asset = _draft.assetFile;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.artPieceAssetSectionTitle,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            FilledButton.icon(
              onPressed: _isPickingAsset ? null : _pickAsset,
              icon: _isPickingAsset
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.precision_manufacturing_outlined),
              label: Text(l10n.artPieceUploadAssetAction),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          l10n.artPieceAssetHelp,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        if (asset == null)
          Card.outlined(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(l10n.artPieceAssetEmptyState),
            ),
          )
        else
          Card.outlined(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(Icons.view_in_ar_outlined),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          asset.fileName,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(l10n.artPieceAssetContentType(asset.contentType)),
                        const SizedBox(height: 4),
                        Text(
                          l10n.artPieceAssetSize(
                            _formatAssetSize(asset.sizeBytes),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.deleteAction,
                    onPressed: _removeAsset,
                    icon: const Icon(Icons.delete_outline),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPhotoSection(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.artPiecePhotosLabel,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            FilledButton.icon(
              onPressed: _isPickingPhotos ? null : _pickPhotos,
              icon: _isPickingPhotos
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.upload_file_outlined),
              label: Text(l10n.artPieceUploadPhotosAction),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          l10n.artPiecePhotosHelp,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        if (_draft.photos.isEmpty)
          Card.outlined(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(l10n.artPiecePhotosEmptyState),
            ),
          )
        else
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _draft.photos
                .map(
                  (photo) => SizedBox(
                    width: 148,
                    child: Card.outlined(
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(
                            height: 112,
                            child: ArtPieceSourceImage(
                              source: photo.source,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                            child: Text(
                              photo.label,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: IconButton(
                              tooltip: l10n.deleteAction,
                              onPressed: () => _removePhoto(photo),
                              icon: const Icon(Icons.delete_outline),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
                .toList(growable: false),
          ),
      ],
    );
  }
}

class _ValidationSummary extends StatelessWidget {
  const _ValidationSummary({required this.errors});

  final List<ArtPieceDraftValidationError> errors;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final messages = errors
        .map((error) => _validationMessage(l10n, error))
        .toSet()
        .toList(growable: false);

    return Material(
      color: Theme.of(context).colorScheme.errorContainer,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: messages
              .map(
                (message) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(message),
                ),
              )
              .toList(growable: false),
        ),
      ),
    );
  }
}

String _validationMessage(
  AppLocalizations l10n,
  ArtPieceDraftValidationError error,
) {
  switch (error) {
    case ArtPieceDraftValidationError.missingArtist:
      return l10n.artPieceArtistRequiredError;
    case ArtPieceDraftValidationError.titleTooShort:
      return l10n.artPieceTitleTooShortError;
    case ArtPieceDraftValidationError.descriptionTooShort:
      return l10n.artPieceDescriptionTooShortError;
    case ArtPieceDraftValidationError.descriptionTooLong:
      return l10n.artPieceDescriptionTooLongError;
    case ArtPieceDraftValidationError.missingPhotos:
      return l10n.artPiecePhotosRequiredError;
    case ArtPieceDraftValidationError.missingModelAsset:
      return l10n.artPieceModelAssetRequiredError;
  }
}

String _formatAssetSize(int sizeBytes) {
  if (sizeBytes < 1024) {
    return "$sizeBytes B";
  }
  if (sizeBytes < 1024 * 1024) {
    return "${(sizeBytes / 1024).toStringAsFixed(1)} KB";
  }

  return "${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB";
}
