import "package:flutter/material.dart";
import "package:urban_art_drops_app/l10n/app_localizations.dart";

import "../../../../shared/models/app_models.dart";
import "../../../../shared/services/app_api_client.dart";
import "../../../../shared/widgets/page_shell.dart";

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
                itemCount: _artPieces.length,
                itemBuilder: (context, index) {
                  final artPiece = _artPieces[index];
                  return Card(
                    child: ListTile(
                      title: Text(artPiece.title),
                      subtitle: Text(artPiece.description),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
