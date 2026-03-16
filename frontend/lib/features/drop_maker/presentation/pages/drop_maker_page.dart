import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:urban_art_drops_app/l10n/app_localizations.dart";

import "../../../../shared/models/app_models.dart";
import "../../../../shared/services/app_api_client.dart";
import "../../../../shared/widgets/page_shell.dart";
import "../../../../shared/widgets/source_image.dart";

class DropMakerPage extends StatefulWidget {
  const DropMakerPage({super.key});

  @override
  State<DropMakerPage> createState() => _DropMakerPageState();
}

class _DropMakerPageState extends State<DropMakerPage> {
  final AppApiClient _apiClient = AppApiClient();
  List<ArtPieceModel> _artPieces = const [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadArtPieces();
  }

  Future<void> _loadArtPieces() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final artPieces = await _apiClient.getArtPieces();
      if (!mounted) {
        return;
      }

      setState(() {
        _artPieces = artPieces.where((item) => item.isPublished).toList();
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return PageShell(
      title: l10n.menuArtWorks,
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
                    onPressed: _loadArtPieces,
                    child: Text(l10n.retryButton),
                  ),
                ],
              ),
            )
          : _artPieces.isEmpty
          ? Center(child: Text(l10n.noArtPiecesAvailable))
          : RefreshIndicator(
              onRefresh: _loadArtPieces,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                itemCount: _artPieces.length,
                itemBuilder: (context, index) {
                  final artPiece = _artPieces[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => context.go(
                        "/drop-maker/make-drop-wizard?artPieceId=${artPiece.id}",
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SourceImage(
                              source: artPiece.photoUrls.isEmpty
                                  ? null
                                  : artPiece.photoUrls.first,
                              fit: BoxFit.cover,
                              width: 112,
                              height: 112,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    artPiece.title,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    artPiece.description,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 12),
                                  FilledButton.icon(
                                    onPressed: () => context.go(
                                      "/drop-maker/make-drop-wizard?artPieceId=${artPiece.id}",
                                    ),
                                    icon: const Icon(Icons.auto_fix_high),
                                    label: Text(l10n.makeDropWizardFabLabel),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
