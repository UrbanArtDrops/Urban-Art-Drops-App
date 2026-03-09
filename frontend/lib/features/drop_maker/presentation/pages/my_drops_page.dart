import "package:flutter/material.dart";
import "package:urban_art_drops_app/l10n/app_localizations.dart";

import "../../../../shared/models/app_models.dart";
import "../../../../shared/services/app_api_client.dart";
import "../../../../shared/widgets/page_shell.dart";

class MyDropsPage extends StatefulWidget {
  const MyDropsPage({super.key});

  @override
  State<MyDropsPage> createState() => _MyDropsPageState();
}

class _MyDropsPageState extends State<MyDropsPage> {
  final AppApiClient _apiClient = AppApiClient();
  List<DropModel> _drops = const [];
  List<ArtPieceModel> _artPieces = const [];
  List<ManagedUser> _dropMakers = const [];
  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _apiClient.getDrops(),
        _apiClient.getArtPieces(),
        _apiClient.getUsers(),
      ]);
      if (!mounted) {
        return;
      }

      final users = (results[2] as List<ManagedUser>)
          .where((user) => user.role == 1 || user.role == 2)
          .toList(growable: false);

      setState(() {
        _drops = (results[0] as List<DropModel>);
        _artPieces = (results[1] as List<ArtPieceModel>);
        _dropMakers = users;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error = AppLocalizations.of(context)!.dropsLoadFailed;
        _isLoading = false;
      });
    }
  }

  Future<void> _openDropDialog([DropModel? existing]) async {
    final l10n = AppLocalizations.of(context)!;
    if (_artPieces.isEmpty || _dropMakers.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.dropDependenciesMissing)));
      return;
    }

    var selectedArtPieceId = existing?.artPieceId ?? _artPieces.first.id;
    var selectedDropMakerId = existing?.dropMakerId ?? _dropMakers.first.id;
    var isStationary = existing?.isStationary ?? true;
    final portableItemController = TextEditingController(
      text: existing?.portableItemCount?.toString() ?? "",
    );
    final latitudeController = TextEditingController(
      text: existing?.latitude?.toString() ?? "",
    );
    final longitudeController = TextEditingController(
      text: existing?.longitude?.toString() ?? "",
    );
    final locationPhotosController = TextEditingController(
      text: existing?.locationPhotoUrls.join(", ") ?? "",
    );
    final itemCountController = TextEditingController(
      text: existing?.itemCount.toString() ?? "1",
    );
    var published = existing?.isPublished ?? false;

    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          existing == null ? l10n.dropCreateTitle : l10n.dropEditTitle,
        ),
        content: StatefulBuilder(
          builder: (context, setDialogState) => SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: selectedArtPieceId,
                  decoration: InputDecoration(
                    labelText: l10n.dropArtPieceLabel,
                  ),
                  items: _artPieces
                      .map(
                        (artPiece) => DropdownMenuItem(
                          value: artPiece.id,
                          child: Text(artPiece.title),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => selectedArtPieceId = value);
                    }
                  },
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: selectedDropMakerId,
                  decoration: InputDecoration(
                    labelText: l10n.dropMakerUserLabel,
                  ),
                  items: _dropMakers
                      .map(
                        (user) => DropdownMenuItem(
                          value: user.id,
                          child: Text("${user.userName} (${user.email})"),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => selectedDropMakerId = value);
                    }
                  },
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: isStationary,
                  onChanged: (value) {
                    setDialogState(() => isStationary = value);
                  },
                  title: Text(l10n.dropStationaryLabel),
                ),
                if (!isStationary)
                  TextField(
                    controller: portableItemController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: l10n.dropPortableItemCountLabel,
                    ),
                  ),
                const SizedBox(height: 8),
                TextField(
                  controller: latitudeController,
                  keyboardType: const TextInputType.numberWithOptions(
                    signed: true,
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: l10n.dropLatitudeLabel,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: longitudeController,
                  keyboardType: const TextInputType.numberWithOptions(
                    signed: true,
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: l10n.dropLongitudeLabel,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: locationPhotosController,
                  decoration: InputDecoration(
                    labelText: l10n.dropLocationPhotosLabel,
                    hintText: l10n.commaSeparatedHint,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: itemCountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: l10n.dropItemCountLabel,
                  ),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: published,
                  onChanged: (value) => setDialogState(() => published = value),
                  title: Text(l10n.statusPublished),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancelAction),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.saveButton),
          ),
        ],
      ),
    );

    if (shouldSave != true) {
      return;
    }

    final input = CreateDropInput(
      artPieceId: selectedArtPieceId,
      dropMakerId: selectedDropMakerId,
      isStationary: isStationary,
      portableItemCount: isStationary
          ? null
          : int.tryParse(portableItemController.text.trim()),
      latitude: double.tryParse(latitudeController.text.trim()),
      longitude: double.tryParse(longitudeController.text.trim()),
      locationPhotoUrls: locationPhotosController.text
          .split(",")
          .map((entry) => entry.trim())
          .where((entry) => entry.isNotEmpty)
          .toList(growable: false),
      itemCount: int.tryParse(itemCountController.text.trim()) ?? 1,
    );

    await _withSaving(() async {
      String? changedDropId = existing?.id;
      if (existing == null) {
        await _apiClient.createDrop(input);
      } else {
        await _apiClient.updateDrop(existing.id, input);
      }
      await _loadData();

      if (changedDropId == null) {
        for (final drop in _drops) {
          if (drop.artPieceId == selectedArtPieceId &&
              drop.dropMakerId == selectedDropMakerId) {
            changedDropId = drop.id;
          }
        }
      }

      if (changedDropId != null) {
        await _apiClient.setDropPublished(changedDropId, published);
        await _loadData();
      }
    });
  }

  Future<void> _deleteDrop(DropModel drop) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.confirmDelete),
        content: Text(l10n.dropDeleteConfirm(drop.id)),
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
      await _apiClient.deleteDrop(drop.id);
      await _loadData();
    });
  }

  Future<void> _togglePublish(DropModel drop) async {
    await _withSaving(() async {
      await _apiClient.setDropPublished(drop.id, !drop.isPublished);
      await _loadData();
    });
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
    final artById = <String, ArtPieceModel>{
      for (final artPiece in _artPieces) artPiece.id: artPiece,
    };

    return PageShell(
      title: l10n.menuMyDrops,
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
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      FilledButton.icon(
                        onPressed: _isSaving ? null : () => _openDropDialog(),
                        icon: const Icon(Icons.add_location_alt_outlined),
                        label: Text(l10n.createAction),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: _isSaving ? null : _loadData,
                        icon: const Icon(Icons.refresh),
                        label: Text(l10n.refreshAction),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _drops.isEmpty
                      ? Center(child: Text(l10n.noDropsAvailable))
                      : RefreshIndicator(
                          onRefresh: _loadData,
                          child: ListView.builder(
                            itemCount: _drops.length,
                            itemBuilder: (context, index) {
                              final drop = _drops[index];
                              final art = artById[drop.artPieceId];
                              final title =
                                  art?.title ?? l10n.dropFallbackTitle(drop.id);
                              final subtitle = [
                                drop.isPublished
                                    ? l10n.statusPublished
                                    : l10n.statusUnpublished,
                                l10n.claimedItemsValue(
                                  "${drop.claimedItemCount}",
                                  "${drop.itemCount}",
                                ),
                              ].join(" · ");

                              return Card(
                                child: ListTile(
                                  title: Text(title),
                                  subtitle: Text(subtitle),
                                  trailing: PopupMenuButton<String>(
                                    onSelected: (value) {
                                      switch (value) {
                                        case "edit":
                                          _openDropDialog(drop);
                                          break;
                                        case "togglePublish":
                                          _togglePublish(drop);
                                          break;
                                        case "delete":
                                          _deleteDrop(drop);
                                          break;
                                      }
                                    },
                                    itemBuilder: (_) => [
                                      PopupMenuItem(
                                        value: "edit",
                                        child: Text(l10n.editAction),
                                      ),
                                      PopupMenuItem(
                                        value: "togglePublish",
                                        child: Text(
                                          drop.isPublished
                                              ? l10n.depublishAction
                                              : l10n.publishAction,
                                        ),
                                      ),
                                      PopupMenuItem(
                                        value: "delete",
                                        child: Text(l10n.deleteAction),
                                      ),
                                    ],
                                  ),
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
