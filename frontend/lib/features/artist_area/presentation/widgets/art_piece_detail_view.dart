import "package:flutter/material.dart";
import "package:urban_art_drops_app/l10n/app_localizations.dart";

import "../../../../shared/models/app_models.dart";
import "art_piece_source_image.dart";

class ArtPieceDetailView extends StatelessWidget {
  const ArtPieceDetailView({
    required this.artPiece,
    required this.artistName,
    required this.onDownloadAsset,
    required this.onEdit,
    required this.onDelete,
    required this.onTogglePublished,
    this.compact = false,
    super.key,
  });

  final ArtPieceModel artPiece;
  final String artistName;
  final VoidCallback? onDownloadAsset;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onTogglePublished;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: EdgeInsets.all(compact ? 20 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(artPiece.title, style: theme.textTheme.headlineSmall),
              FilledButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined),
                label: Text(l10n.editAction),
              ),
              if (artPiece.assetFile != null)
                OutlinedButton.icon(
                  onPressed: onDownloadAsset,
                  icon: const Icon(Icons.download_outlined),
                  label: Text(l10n.artPieceDownloadAssetAction),
                ),
              OutlinedButton.icon(
                onPressed: onTogglePublished,
                icon: Icon(
                  artPiece.isPublished
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
                label: Text(
                  artPiece.isPublished
                      ? l10n.depublishAction
                      : l10n.publishAction,
                ),
              ),
              OutlinedButton.icon(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline),
                label: Text(l10n.deleteAction),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _ArtPiecePhotoGallery(photoUrls: artPiece.photoUrls),
          if (artPiece.assetFile != null) ...[
            const SizedBox(height: 20),
            Text(
              l10n.artPieceAssetSectionTitle,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Card.outlined(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
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
                                artPiece.assetFile!.fileName,
                                style: theme.textTheme.titleSmall,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                l10n.artPieceAssetContentType(
                                  artPiece.assetFile!.contentType,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                l10n.artPieceAssetSize(
                                  _formatAssetSize(
                                    artPiece.assetFile!.sizeBytes,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        FilledButton.tonalIcon(
                          onPressed: onDownloadAsset,
                          icon: const Icon(Icons.download_outlined),
                          label: Text(l10n.artPieceDownloadAssetAction),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Chip(
                avatar: const Icon(Icons.person_outline),
                label: Text("${l10n.artPieceArtistLabel}: $artistName"),
              ),
              Chip(
                avatar: const Icon(Icons.category_outlined),
                label: Text(
                  "${l10n.artPieceAssetTypeLabel}: ${_assetKindLabel(l10n, artPiece.assetKind)}",
                ),
              ),
              Chip(
                avatar: Icon(
                  artPiece.isPublished
                      ? Icons.public_outlined
                      : Icons.drafts_outlined,
                ),
                label: Text(
                  artPiece.isPublished
                      ? l10n.statusPublished
                      : l10n.statusUnpublished,
                ),
              ),
              Chip(
                avatar: const Icon(Icons.photo_library_outlined),
                label: Text(l10n.artPiecePhotoCount(artPiece.photoUrls.length)),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            l10n.artPieceMetadataSection,
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          Card.outlined(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _MetadataRow(
                    label: l10n.artPieceArtistLabel,
                    value: artistName,
                  ),
                  _MetadataRow(
                    label: l10n.artPieceAssetTypeLabel,
                    value: _assetKindLabel(l10n, artPiece.assetKind),
                  ),
                  _MetadataRow(
                    label: l10n.artPiecePhotosLabel,
                    value: l10n.artPiecePhotoCount(artPiece.photoUrls.length),
                    isLast: true,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            l10n.artPieceDescriptionLabel,
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          Card.outlined(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(artPiece.description),
            ),
          ),
        ],
      ),
    );
  }
}

class _ArtPiecePhotoGallery extends StatefulWidget {
  const _ArtPiecePhotoGallery({required this.photoUrls});

  final List<String> photoUrls;

  @override
  State<_ArtPiecePhotoGallery> createState() => _ArtPiecePhotoGalleryState();
}

class _ArtPiecePhotoGalleryState extends State<_ArtPiecePhotoGallery> {
  int _selectedIndex = 0;

  @override
  void didUpdateWidget(covariant _ArtPiecePhotoGallery oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_selectedIndex >= widget.photoUrls.length) {
      _selectedIndex = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.photoUrls.isEmpty) {
      return const AspectRatio(
        aspectRatio: 16 / 9,
        child: ArtPieceSourceImage(
          source: null,
          fit: BoxFit.cover,
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
      );
    }

    final selectedPhoto = widget.photoUrls[_selectedIndex];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AspectRatio(
          aspectRatio: 16 / 9,
          child: ArtPieceSourceImage(
            source: selectedPhoto,
            fit: BoxFit.cover,
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 84,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: widget.photoUrls.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final photoUrl = widget.photoUrls[index];
              final isSelected = index == _selectedIndex;

              return InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => setState(() => _selectedIndex = index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  width: 112,
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.outlineVariant,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: ArtPieceSourceImage(
                    source: photoUrl,
                    fit: BoxFit.cover,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _MetadataRow extends StatelessWidget {
  const _MetadataRow({
    required this.label,
    required this.value,
    this.isLast = false,
  });

  final String label;
  final String value;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final row = Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.labelLarge),
          ),
          const SizedBox(width: 16),
          Expanded(child: Text(value, textAlign: TextAlign.end)),
        ],
      ),
    );

    if (isLast) {
      return row;
    }

    return Column(children: [row, const Divider(height: 1)]);
  }
}

String _assetKindLabel(AppLocalizations l10n, int assetKind) {
  return assetKind == 1 ? l10n.artPieceAssetModel3d : l10n.artPieceAssetImage;
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
