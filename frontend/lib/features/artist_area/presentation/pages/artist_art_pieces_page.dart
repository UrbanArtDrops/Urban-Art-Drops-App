import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:urban_art_drops_app/l10n/app_localizations.dart";

import "../../../../shared/models/app_models.dart";
import "../../../../shared/services/app_api_client.dart";
import "../../../../shared/widgets/page_shell.dart";
import "../../../authentication/presentation/bloc/auth_session_cubit.dart";
import "../../application/art_piece_photo_picker.dart";
import "../../domain/art_piece_editor_draft.dart";
import "../widgets/art_piece_detail_view.dart";
import "../widgets/art_piece_editor_dialog.dart";
import "../widgets/art_piece_source_image.dart";

class ArtistArtPiecesPage extends StatefulWidget {
  const ArtistArtPiecesPage({
    AppApiClient? apiClient,
    ArtPiecePhotoPicker? photoPicker,
    super.key,
  }) : _apiClient = apiClient,
       _photoPicker = photoPicker;

  final AppApiClient? _apiClient;
  final ArtPiecePhotoPicker? _photoPicker;

  @override
  State<ArtistArtPiecesPage> createState() => _ArtistArtPiecesPageState();
}

class _ArtistArtPiecesPageState extends State<ArtistArtPiecesPage> {
  late final AppApiClient _apiClient = widget._apiClient ?? AppApiClient();
  late final ArtPiecePhotoPicker _photoPicker =
      widget._photoPicker ?? const FilePickerArtPiecePhotoPicker();

  List<ArtPieceModel> _artPieces = const [];
  List<ManagedUser> _artists = const [];
  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;
  String? _selectedArtPieceId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  ArtPieceModel? get _selectedArtPiece {
    final selectedId = _selectedArtPieceId;
    if (selectedId == null) {
      return null;
    }

    for (final artPiece in _artPieces) {
      if (artPiece.id == selectedId) {
        return artPiece;
      }
    }

    return null;
  }

  Future<void> _loadData({String? selectArtPieceId}) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait<Object>([
        _apiClient.getArtPieces(),
        _apiClient.getUsers(),
      ]);
      if (!mounted) {
        return;
      }

      final artPieces = results[0] as List<ArtPieceModel>;
      final artists = (results[1] as List<ManagedUser>)
          .where((user) => user.role == 1)
          .toList(growable: false);

      setState(() {
        _artPieces = artPieces;
        _artists = artists;
        _selectedArtPieceId = _resolveSelectedArtPieceId(
          artPieces,
          selectArtPieceId,
        );
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error = AppLocalizations.of(context)!.artPiecesLoadFailed;
        _isLoading = false;
      });
    }
  }

  String? _resolveSelectedArtPieceId(
    List<ArtPieceModel> artPieces,
    String? preferredId,
  ) {
    if (artPieces.isEmpty) {
      return null;
    }

    final candidates = <String?>[preferredId, _selectedArtPieceId];
    for (final candidate in candidates) {
      if (candidate != null &&
          artPieces.any((artPiece) => artPiece.id == candidate)) {
        return candidate;
      }
    }

    return artPieces.first.id;
  }

  ManagedUser? _artistById(String artistId) {
    for (final artist in _artists) {
      if (artist.id == artistId) {
        return artist;
      }
    }

    return null;
  }

  String _artistLabel(String artistId) {
    final artist = _artistById(artistId);
    if (artist == null) {
      return artistId;
    }

    final name = artist.userName.trim();
    if (name.isNotEmpty) {
      return name;
    }

    return artist.email;
  }

  String _preferredArtistId(AuthSessionState authState) {
    final displayName = authState.displayName?.trim().toLowerCase();
    if (displayName != null && displayName.isNotEmpty) {
      for (final artist in _artists) {
        if (artist.userName.toLowerCase() == displayName ||
            artist.email.toLowerCase() == displayName) {
          return artist.id;
        }
      }
    }

    return _artists.first.id;
  }

  Future<void> _openArtPieceEditor(
    AuthSessionState authState, [
    ArtPieceModel? existing,
  ]) async {
    final l10n = AppLocalizations.of(context)!;
    if (_artists.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.noArtistsAvailable)));
      return;
    }

    final initialDraft = existing == null
        ? ArtPieceEditorDraft.create(artistId: _preferredArtistId(authState))
        : ArtPieceEditorDraft.fromArtPiece(existing);

    final draft = await showArtPieceEditorDialog(
      context,
      artists: _artists,
      initialDraft: initialDraft,
      photoPicker: _photoPicker,
    );
    if (draft == null) {
      return;
    }

    await _withSaving(() async {
      final savedArtPiece = existing == null
          ? await _apiClient.createArtPiece(
              artistId: draft.artistId,
              title: draft.title.trim(),
              description: draft.description.trim(),
              assetKind: draft.assetKind,
              photoUrls: draft.photoSources,
            )
          : await _apiClient.updateArtPiece(
              id: existing.id,
              artistId: draft.artistId,
              title: draft.title.trim(),
              description: draft.description.trim(),
              assetKind: draft.assetKind,
              photoUrls: draft.photoSources,
            );

      if (savedArtPiece.isPublished != draft.isPublished) {
        await _apiClient.setArtPiecePublished(
          savedArtPiece.id,
          draft.isPublished,
        );
      }

      await _loadData(selectArtPieceId: savedArtPiece.id);
    });
  }

  Future<void> _deleteArtPiece(ArtPieceModel artPiece) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.confirmDelete),
        content: Text(l10n.artPieceDeleteConfirm(artPiece.title)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancelAction),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.deleteAction),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    await _withSaving(() async {
      await _apiClient.deleteArtPiece(artPiece.id);
      await _loadData();
    });
  }

  Future<void> _togglePublish(ArtPieceModel artPiece) async {
    await _withSaving(() async {
      await _apiClient.setArtPiecePublished(artPiece.id, !artPiece.isPublished);
      await _loadData(selectArtPieceId: artPiece.id);
    });
  }

  Future<void> _openMobileDetail(
    ArtPieceModel artPiece,
    AuthSessionState authState,
  ) async {
    setState(() => _selectedArtPieceId = artPiece.id);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: FractionallySizedBox(
          heightFactor: 0.92,
          child: ArtPieceDetailView(
            artPiece: artPiece,
            artistName: _artistLabel(artPiece.artistId),
            compact: true,
            onEdit: () {
              Navigator.of(sheetContext).pop();
              _openArtPieceEditor(authState, artPiece);
            },
            onDelete: () {
              Navigator.of(sheetContext).pop();
              _deleteArtPiece(artPiece);
            },
            onTogglePublished: () {
              Navigator.of(sheetContext).pop();
              _togglePublish(artPiece);
            },
          ),
        ),
      ),
    );
  }

  Future<void> _withSaving(Future<void> Function() action) async {
    setState(() => _isSaving = true);
    try {
      await action();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.genericSaveError),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocBuilder<AuthSessionCubit, AuthSessionState>(
      builder: (context, authState) {
        return PageShell(
          title: l10n.menuMyArt,
          body: _isLoading
              ? Center(child: Text(l10n.loadingData))
              : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: _loadData,
                        child: Text(l10n.retryButton),
                      ),
                    ],
                  ),
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final isWideLayout = constraints.maxWidth >= 980;

                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              FilledButton.icon(
                                onPressed: _isSaving
                                    ? null
                                    : () => _openArtPieceEditor(authState),
                                icon: const Icon(Icons.add),
                                label: Text(l10n.createAction),
                              ),
                              OutlinedButton.icon(
                                onPressed: _isSaving ? null : _loadData,
                                icon: const Icon(Icons.refresh),
                                label: Text(l10n.refreshAction),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: _artPieces.isEmpty
                              ? _EmptyArtPiecesState(
                                  onCreate: _isSaving
                                      ? null
                                      : () => _openArtPieceEditor(authState),
                                )
                              : isWideLayout
                              ? Row(
                                  children: [
                                    SizedBox(
                                      width: 430,
                                      child: RefreshIndicator(
                                        onRefresh: _loadData,
                                        child: ListView.separated(
                                          padding: const EdgeInsets.fromLTRB(
                                            16,
                                            0,
                                            8,
                                            16,
                                          ),
                                          itemCount: _artPieces.length,
                                          separatorBuilder: (_, _) =>
                                              const SizedBox(height: 12),
                                          itemBuilder: (context, index) {
                                            final artPiece = _artPieces[index];
                                            return _ArtPieceListCard(
                                              artPiece: artPiece,
                                              artistName: _artistLabel(
                                                artPiece.artistId,
                                              ),
                                              isSelected:
                                                  artPiece.id ==
                                                  _selectedArtPieceId,
                                              onTap: () {
                                                setState(
                                                  () => _selectedArtPieceId =
                                                      artPiece.id,
                                                );
                                              },
                                              onEdit: _isSaving
                                                  ? null
                                                  : () => _openArtPieceEditor(
                                                      authState,
                                                      artPiece,
                                                    ),
                                              onDelete: _isSaving
                                                  ? null
                                                  : () => _deleteArtPiece(
                                                      artPiece,
                                                    ),
                                              onTogglePublished: _isSaving
                                                  ? null
                                                  : () => _togglePublish(
                                                      artPiece,
                                                    ),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                          8,
                                          0,
                                          16,
                                          16,
                                        ),
                                        child: Card.outlined(
                                          clipBehavior: Clip.antiAlias,
                                          child: _selectedArtPiece == null
                                              ? _EmptySelectionState()
                                              : ArtPieceDetailView(
                                                  artPiece: _selectedArtPiece!,
                                                  artistName: _artistLabel(
                                                    _selectedArtPiece!.artistId,
                                                  ),
                                                  onEdit: _isSaving
                                                      ? null
                                                      : () =>
                                                            _openArtPieceEditor(
                                                              authState,
                                                              _selectedArtPiece!,
                                                            ),
                                                  onDelete: _isSaving
                                                      ? null
                                                      : () => _deleteArtPiece(
                                                          _selectedArtPiece!,
                                                        ),
                                                  onTogglePublished: _isSaving
                                                      ? null
                                                      : () => _togglePublish(
                                                          _selectedArtPiece!,
                                                        ),
                                                ),
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : RefreshIndicator(
                                  onRefresh: _loadData,
                                  child: ListView.separated(
                                    padding: const EdgeInsets.fromLTRB(
                                      16,
                                      0,
                                      16,
                                      16,
                                    ),
                                    itemCount: _artPieces.length,
                                    separatorBuilder: (_, _) =>
                                        const SizedBox(height: 12),
                                    itemBuilder: (context, index) {
                                      final artPiece = _artPieces[index];
                                      return _ArtPieceListCard(
                                        artPiece: artPiece,
                                        artistName: _artistLabel(
                                          artPiece.artistId,
                                        ),
                                        isSelected: false,
                                        onTap: () => _openMobileDetail(
                                          artPiece,
                                          authState,
                                        ),
                                        onEdit: _isSaving
                                            ? null
                                            : () => _openArtPieceEditor(
                                                authState,
                                                artPiece,
                                              ),
                                        onDelete: _isSaving
                                            ? null
                                            : () => _deleteArtPiece(artPiece),
                                        onTogglePublished: _isSaving
                                            ? null
                                            : () => _togglePublish(artPiece),
                                      );
                                    },
                                  ),
                                ),
                        ),
                      ],
                    );
                  },
                ),
        );
      },
    );
  }
}

class _ArtPieceListCard extends StatelessWidget {
  const _ArtPieceListCard({
    required this.artPiece,
    required this.artistName,
    required this.isSelected,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onTogglePublished,
  });

  final ArtPieceModel artPiece;
  final String artistName;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onTogglePublished;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: isSelected ? 3 : 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.outlineVariant,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ArtPieceSourceImage(
                source: artPiece.photoUrls.isEmpty
                    ? null
                    : artPiece.photoUrls.first,
                fit: BoxFit.cover,
                width: 116,
                height: 116,
                borderRadius: BorderRadius.circular(18),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            artPiece.title,
                            style: theme.textTheme.titleMedium,
                          ),
                        ),
                        PopupMenuButton<String>(
                          onSelected: (value) {
                            switch (value) {
                              case "edit":
                                onEdit?.call();
                                break;
                              case "publish":
                                onTogglePublished?.call();
                                break;
                              case "delete":
                                onDelete?.call();
                                break;
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: "edit",
                              enabled: onEdit != null,
                              child: Text(l10n.editAction),
                            ),
                            PopupMenuItem(
                              value: "publish",
                              enabled: onTogglePublished != null,
                              child: Text(
                                artPiece.isPublished
                                    ? l10n.depublishAction
                                    : l10n.publishAction,
                              ),
                            ),
                            PopupMenuItem(
                              value: "delete",
                              enabled: onDelete != null,
                              child: Text(l10n.deleteAction),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      artPiece.description,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Chip(
                          avatar: const Icon(Icons.person_outline),
                          label: Text(artistName),
                        ),
                        Chip(
                          avatar: const Icon(Icons.category_outlined),
                          label: Text(
                            artPiece.assetKind == 1
                                ? l10n.artPieceAssetModel3d
                                : l10n.artPieceAssetImage,
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
                          label: Text(
                            l10n.artPiecePhotoCount(artPiece.photoUrls.length),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyArtPiecesState extends StatelessWidget {
  const _EmptyArtPiecesState({required this.onCreate});

  final VoidCallback? onCreate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.palette_outlined, size: 56),
            const SizedBox(height: 16),
            Text(
              l10n.noArtPiecesAvailable,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add),
              label: Text(l10n.createAction),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptySelectionState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.touch_app_outlined, size: 56),
            const SizedBox(height: 16),
            Text(
              l10n.artPieceNoSelectionTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(l10n.artPieceNoSelectionSubtitle, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
