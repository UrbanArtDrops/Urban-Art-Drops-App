import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:urban_art_drops_app/l10n/app_localizations.dart";

import "../../../../shared/models/app_models.dart";
import "../../../../shared/services/app_api_client.dart";
import "../../../../shared/widgets/page_shell.dart";

class DropListPage extends StatefulWidget {
  const DropListPage({super.key});

  @override
  State<DropListPage> createState() => _DropListPageState();
}

class _DropListPageState extends State<DropListPage> {
  final AppApiClient _apiClient = AppApiClient();
  final TextEditingController _searchController = TextEditingController();
  List<DropModel> _drops = const [];
  Map<String, ArtPieceModel> _artPiecesById = const {};
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDrops();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadDrops() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _apiClient.getDrops(),
        _apiClient.getArtPieces(),
      ]);

      if (!mounted) {
        return;
      }

      final drops = (results[0] as List<DropModel>)
          .where((drop) => drop.isPublished)
          .toList(growable: false);
      final artPieces = (results[1] as List<ArtPieceModel>);
      final artById = <String, ArtPieceModel>{
        for (final art in artPieces) art.id: art,
      };

      setState(() {
        _drops = drops;
        _artPiecesById = artById;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error = AppLocalizations.of(context)!.dropListLoadFailed;
        _isLoading = false;
      });
    }
  }

  List<DropModel> get _filteredDrops {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      return _drops;
    }

    return _drops
        .where((drop) {
          final art = _artPiecesById[drop.artPieceId];
          final title = (art?.title ?? "").toLowerCase();
          return title.contains(query) || drop.id.toLowerCase().contains(query);
        })
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return PageShell(
      title: l10n.navDrops,
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
                    onPressed: _loadDrops,
                    child: Text(l10n.retryButton),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: l10n.searchDropsHint,
                      suffixIcon: IconButton(
                        onPressed: () => _searchController.clear(),
                        icon: const Icon(Icons.clear),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: _filteredDrops.isEmpty
                      ? Center(child: Text(l10n.dropListEmpty))
                      : RefreshIndicator(
                          onRefresh: _loadDrops,
                          child: ListView.builder(
                            itemCount: _filteredDrops.length,
                            itemBuilder: (context, index) {
                              final drop = _filteredDrops[index];
                              final artPiece = _artPiecesById[drop.artPieceId];
                              final title = artPiece?.title ?? drop.id;
                              final subtitle = l10n.claimedItemsValue(
                                "${drop.claimedItemCount}",
                                "${drop.itemCount}",
                              );

                              return Card(
                                child: ListTile(
                                  title: Text(title),
                                  subtitle: Text(subtitle),
                                  trailing: const Icon(Icons.chevron_right),
                                  onTap: () =>
                                      context.go("/hunter/drops/${drop.id}"),
                                ),
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }
}
