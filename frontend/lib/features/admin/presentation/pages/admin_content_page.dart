import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:urban_art_drops_app/l10n/app_localizations.dart";

import "../../../../shared/models/app_models.dart";
import "../../../../shared/services/app_api_client.dart";
import "../../../../shared/widgets/page_shell.dart";

class AdminContentPage extends StatefulWidget {
  const AdminContentPage({super.key, this.apiClient});

  final AppApiClient? apiClient;

  @override
  State<AdminContentPage> createState() => _AdminContentPageState();
}

class _AdminContentPageState extends State<AdminContentPage> {
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;
  List<ArtPieceModel> _artPieces = const [];
  List<DropModel> _drops = const [];

  AppApiClient get _apiClient => widget.apiClient ?? AppApiClient();

  @override
  void initState() {
    super.initState();
    _loadContent();
  }

  Future<void> _loadContent() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait<Object>([
        _apiClient.getManageableArtPieces(),
        _apiClient.getDrops(),
      ]);
      if (!mounted) {
        return;
      }

      setState(() {
        _artPieces = List<ArtPieceModel>.from(results[0] as List<ArtPieceModel>)
          ..sort((first, second) => first.title.compareTo(second.title));
        _drops = List<DropModel>.from(results[1] as List<DropModel>)
          ..sort((first, second) => first.id.compareTo(second.id));
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _errorMessage = AppLocalizations.of(context)!.configLoadError;
      });
    }
  }

  Future<void> _runAction(Future<void> Function() action) async {
    setState(() => _isSaving = true);
    try {
      await action();
      await _loadContent();
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.genericSaveError)),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return PageShell(
      title: l10n.navAdminContent,
      body: _isLoading
          ? Center(child: Text(l10n.loadingData))
          : _errorMessage != null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_errorMessage!, textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: _loadContent,
                    child: Text(l10n.retryButton),
                  ),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(12),
              children: [
                _SectionHeader(
                  title: l10n.globalArtPieceModerationTitle,
                  subtitle: l10n.globalArtPieceModerationSubtitle,
                  actionLabel: l10n.editAction,
                  onAction: () => context.go("/artist/art-pieces"),
                ),
                if (_artPieces.isEmpty)
                  Text(l10n.noArtPiecesAvailable)
                else
                  ..._artPieces.map(
                    (artPiece) => _ArtPieceAdminCard(
                      artPiece: artPiece,
                      isSaving: _isSaving,
                      onTogglePublished: () => _runAction(
                        () => _apiClient.setArtPiecePublished(
                          artPiece.id,
                          !artPiece.isPublished,
                        ),
                      ),
                      onDelete: () => _runAction(
                        () => _apiClient.deleteArtPiece(artPiece.id),
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
                _SectionHeader(
                  title: l10n.globalDropModerationTitle,
                  subtitle: l10n.globalDropModerationSubtitle,
                  actionLabel: l10n.editAction,
                  onAction: () => context.go("/drop-maker/drops"),
                ),
                if (_drops.isEmpty)
                  Text(l10n.dropListEmpty)
                else
                  ..._drops.map(
                    (drop) => _DropAdminCard(
                      drop: drop,
                      isSaving: _isSaving,
                      onTogglePublished: () => _runAction(
                        () => _apiClient.setDropPublished(
                          drop.id,
                          !drop.isPublished,
                        ),
                      ),
                      onDelete: () =>
                          _runAction(() => _apiClient.deleteDrop(drop.id)),
                    ),
                  ),
              ],
            ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Card.outlined(
      child: ListTile(
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: FilledButton.tonal(
          onPressed: onAction,
          child: Text(actionLabel),
        ),
      ),
    );
  }
}

class _ArtPieceAdminCard extends StatelessWidget {
  const _ArtPieceAdminCard({
    required this.artPiece,
    required this.isSaving,
    required this.onTogglePublished,
    required this.onDelete,
  });

  final ArtPieceModel artPiece;
  final bool isSaving;
  final VoidCallback onTogglePublished;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Card(
      child: ListTile(
        leading: Icon(
          artPiece.isPublished
              ? Icons.public_outlined
              : Icons.visibility_off_outlined,
        ),
        title: Text(artPiece.title),
        subtitle: Text(
          artPiece.isPublished ? l10n.statusPublished : l10n.statusUnpublished,
        ),
        trailing: Wrap(
          spacing: 8,
          children: [
            TextButton(
              onPressed: isSaving ? null : onTogglePublished,
              child: Text(
                artPiece.isPublished
                    ? l10n.depublishAction
                    : l10n.publishAction,
              ),
            ),
            IconButton(
              tooltip: l10n.deleteAction,
              onPressed: isSaving ? null : onDelete,
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ),
      ),
    );
  }
}

class _DropAdminCard extends StatelessWidget {
  const _DropAdminCard({
    required this.drop,
    required this.isSaving,
    required this.onTogglePublished,
    required this.onDelete,
  });

  final DropModel drop;
  final bool isSaving;
  final VoidCallback onTogglePublished;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Card(
      child: ListTile(
        leading: Icon(
          drop.isPublished ? Icons.public_outlined : Icons.inventory_outlined,
        ),
        title: Text(drop.id),
        subtitle: Text(
          drop.isPublished ? l10n.statusPublished : l10n.statusUnpublished,
        ),
        trailing: Wrap(
          spacing: 8,
          children: [
            TextButton(
              onPressed: isSaving ? null : onTogglePublished,
              child: Text(
                drop.isPublished ? l10n.depublishAction : l10n.publishAction,
              ),
            ),
            IconButton(
              tooltip: l10n.deleteAction,
              onPressed: isSaving ? null : onDelete,
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ),
      ),
    );
  }
}
