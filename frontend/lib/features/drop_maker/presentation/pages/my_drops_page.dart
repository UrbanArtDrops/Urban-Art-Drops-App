import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:go_router/go_router.dart";
import "package:urban_art_drops_app/l10n/app_localizations.dart";

import "../../../authentication/presentation/bloc/auth_session_cubit.dart";
import "../../../../shared/models/app_models.dart";
import "../../../../shared/models/hunter_identity.dart";
import "../../../../shared/services/app_api_client.dart";
import "../../../../shared/widgets/drop_overview_card.dart";
import "../../../../shared/widgets/page_shell.dart";

class MyDropsPage extends StatefulWidget {
  const MyDropsPage({super.key, AppApiClient? apiClient})
    : _apiClient = apiClient;

  final AppApiClient? _apiClient;

  @override
  State<MyDropsPage> createState() => _MyDropsPageState();
}

class _MyDropsPageState extends State<MyDropsPage> {
  static const List<String> _commonSocialChannels = <String>[
    "Facebook",
    "Instagram",
    "TikTok",
  ];

  late final AppApiClient _apiClient = widget._apiClient ?? AppApiClient();
  List<DropModel> _drops = const [];
  List<ArtPieceModel> _artPieces = const [];
  List<ManagedUser> _dropMakers = const [];
  Map<String, ManagedUser> _usersById = const {};
  AppConfigurationModel _appConfiguration = AppConfigurationModel.defaults;
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
      var appConfiguration = AppConfigurationModel.defaults;
      try {
        appConfiguration = await _apiClient.getAppConfiguration();
      } catch (_) {
        appConfiguration = AppConfigurationModel.defaults;
      }

      final results = await Future.wait([
        _apiClient.getDrops(),
        _apiClient.getArtPieces(),
        _apiClient.getUserDirectory(),
      ]);
      if (!mounted) {
        return;
      }

      final users = (results[2] as List<ManagedUser>)
          .where((user) => user.role == 1 || user.role == 2)
          .toList(growable: false);
      final allUsers = (results[2] as List<ManagedUser>);
      final authState = context.read<AuthSessionCubit>().state;
      final currentUserId = authState.userId?.trim();
      final isAdmin = authState.role == AppUserRole.admin;
      final visibleDrops = isAdmin
          ? (results[0] as List<DropModel>)
          : currentUserId == null || currentUserId.isEmpty
          ? const <DropModel>[]
          : (results[0] as List<DropModel>)
                .where((drop) => drop.dropMakerId == currentUserId)
                .toList(growable: false);

      setState(() {
        _drops = visibleDrops;
        _artPieces = (results[1] as List<ArtPieceModel>);
        _dropMakers = users;
        _usersById = {for (final user in allUsers) user.id: user};
        _appConfiguration = appConfiguration;
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
    final dropMakerCommentController = TextEditingController(
      text: existing?.dropMakerComment ?? "",
    );
    final itemCountController = TextEditingController(
      text: existing?.itemCount.toString() ?? "1",
    );
    final selectedSocialChannels =
        (existing?.socialChannels ?? const <String>[]).toSet();
    var published = existing?.isPublished ?? false;

    try {
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
                    controller: dropMakerCommentController,
                    minLines: 3,
                    maxLines: 5,
                    maxLength: 1000,
                    decoration: InputDecoration(
                      labelText: l10n.dropMakerCommentLabel,
                      hintText: l10n.dropMakerCommentHint,
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      l10n.dropSocialChannelsLabel,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children:
                        {..._commonSocialChannels, ...selectedSocialChannels}
                            .map((channel) {
                              return FilterChip(
                                label: Text(channel),
                                selected: selectedSocialChannels.contains(
                                  channel,
                                ),
                                onSelected: (selected) {
                                  setDialogState(() {
                                    if (selected) {
                                      selectedSocialChannels.add(channel);
                                    } else {
                                      selectedSocialChannels.remove(channel);
                                    }
                                  });
                                },
                              );
                            })
                            .toList(growable: false),
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
                    onChanged: (value) =>
                        setDialogState(() => published = value),
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
        dropMakerComment: dropMakerCommentController.text.trim(),
        socialChannels: selectedSocialChannels.toList(growable: false),
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
        final savedDrop = existing == null
            ? await _apiClient.createDrop(input)
            : await _apiClient.updateDrop(existing.id, input);

        if (savedDrop.isPublished != published) {
          await _apiClient.setDropPublished(savedDrop.id, published);
        }
      });
    } finally {
      portableItemController.dispose();
      latitudeController.dispose();
      longitudeController.dispose();
      locationPhotosController.dispose();
      dropMakerCommentController.dispose();
      itemCountController.dispose();

      if (mounted) {
        await _loadData();
      }
    }
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

  void _resumeDropWizard(DropModel drop) {
    context.go("/drop-maker/make-drop-wizard?dropId=${drop.id}");
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

  List<_MyDropViewModel> _buildViewModels(AppLocalizations l10n) {
    final currentUserId = context.read<AuthSessionCubit>().state.userId?.trim();
    final artById = <String, ArtPieceModel>{
      for (final artPiece in _artPieces) artPiece.id: artPiece,
    };

    return _drops
        .map((drop) {
          final art = artById[drop.artPieceId];
          final artistName =
              _usersById[art?.artistId]?.userName ?? (art?.artistId ?? "-");
          final artistProfileImageUrl = art == null
              ? null
              : _usersById[art.artistId]?.profileImageUrl;
          final dropMakerName =
              _usersById[drop.dropMakerId]?.userName ?? drop.dropMakerId;
          final dropMakerProfileImageUrl =
              _usersById[drop.dropMakerId]?.profileImageUrl;
          final claimedHunters = buildClaimedHunterIdentities(
            items: drop.claimedItems,
            usersById: _usersById,
          );

          return _MyDropViewModel(
            drop: drop,
            id: drop.id,
            title: art?.title ?? l10n.dropFallbackTitle(drop.id),
            subtitle: art?.subtitle.trim().isNotEmpty == true
                ? art!.subtitle
                : "${l10n.mapArtistLabel}: $artistName · ${l10n.mapDropMakerLabel}: $dropMakerName",
            artistName: artistName,
            artistProfileImageUrl: artistProfileImageUrl,
            dropMakerName: dropMakerName,
            dropMakerProfileImageUrl: dropMakerProfileImageUrl,
            description: _buildDropDescription(
              artDescription: art?.description ?? "",
              dropMakerComment: drop.dropMakerComment,
              socialChannels: drop.socialChannels,
              socialPublishStatuses: drop.socialPublishStatuses,
              l10n: l10n,
            ),
            galleryUrls: [...?art?.photoUrls, ...drop.locationPhotoUrls],
            claimedHunters: claimedHunters,
            latitude: drop.latitude,
            longitude: drop.longitude,
            claimedItemCount: drop.claimedItemCount,
            itemCount: drop.itemCount,
            isFullyClaimed: drop.isFullyClaimed,
            unclaimedDropRadiusKm: _appConfiguration.unclaimedDropRadiusKm,
            showPreciseLocationForUnclaimed:
                currentUserId != null &&
                currentUserId.isNotEmpty &&
                currentUserId == drop.dropMakerId,
            isPublished: drop.isPublished,
            canResumeWizard: drop.canResumeWizard,
          );
        })
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authState = context.watch<AuthSessionCubit>().state;
    final pageTitle = authState.role == AppUserRole.admin
        ? l10n.navDrops
        : l10n.menuMyDrops;
    final viewModels = _buildViewModels(l10n);

    return PageShell(
      title: pageTitle,
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
                        onPressed: _isSaving
                            ? null
                            : () => context.go("/drop-maker/make-drop-wizard"),
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
                  child: viewModels.isEmpty
                      ? Center(child: Text(l10n.noDropsAvailable))
                      : RefreshIndicator(
                          onRefresh: _loadData,
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                            itemCount: viewModels.length,
                            itemBuilder: (context, index) {
                              final viewModel = viewModels[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: DropOverviewCard(
                                  l10n: l10n,
                                  title: viewModel.title,
                                  subtitle: viewModel.subtitle,
                                  artistName: viewModel.artistName,
                                  artistProfileImageUrl:
                                      viewModel.artistProfileImageUrl,
                                  dropMakerName: viewModel.dropMakerName,
                                  dropMakerProfileImageUrl:
                                      viewModel.dropMakerProfileImageUrl,
                                  description: viewModel.description,
                                  galleryUrls: viewModel.galleryUrls,
                                  claimedHunters: viewModel.claimedHunters,
                                  claimedItemCount: viewModel.claimedItemCount,
                                  itemCount: viewModel.itemCount,
                                  isFullyClaimed: viewModel.isFullyClaimed,
                                  unclaimedDropRadiusKm:
                                      viewModel.unclaimedDropRadiusKm,
                                  showPreciseLocationForUnclaimed:
                                      viewModel.showPreciseLocationForUnclaimed,
                                  latitude: viewModel.latitude,
                                  longitude: viewModel.longitude,
                                  onTap: () => context.go(
                                    "/hunter/drops/${viewModel.id}",
                                  ),
                                  trailing: PopupMenuButton<String>(
                                    onSelected: (value) {
                                      switch (value) {
                                        case "resume":
                                          _resumeDropWizard(viewModel.drop);
                                          break;
                                        case "edit":
                                          _openDropDialog(viewModel.drop);
                                          break;
                                        case "togglePublish":
                                          _togglePublish(viewModel.drop);
                                          break;
                                        case "delete":
                                          _deleteDrop(viewModel.drop);
                                          break;
                                      }
                                    },
                                    itemBuilder: (_) => [
                                      if (viewModel.canResumeWizard)
                                        PopupMenuItem(
                                          value: "resume",
                                          child: Text(
                                            l10n.makeDropResumeAction,
                                          ),
                                        ),
                                      PopupMenuItem(
                                        value: "edit",
                                        child: Text(l10n.editAction),
                                      ),
                                      PopupMenuItem(
                                        value: "togglePublish",
                                        child: Text(
                                          viewModel.isPublished
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

String _buildDropDescription({
  required String artDescription,
  required String? dropMakerComment,
  required List<String> socialChannels,
  required List<DropSocialPublishStatusModel> socialPublishStatuses,
  required AppLocalizations l10n,
}) {
  final segments = <String>[];
  final trimmedDescription = artDescription.trim();
  if (trimmedDescription.isNotEmpty) {
    segments.add(trimmedDescription);
  }

  final trimmedComment = dropMakerComment?.trim();
  if (trimmedComment != null && trimmedComment.isNotEmpty) {
    segments.add("${l10n.dropMakerCommentLabel}: $trimmedComment");
  }

  if (socialChannels.isNotEmpty) {
    segments.add(
      "${l10n.dropSocialChannelsLabel}: ${socialChannels.join(", ")}",
    );
  }

  if (socialPublishStatuses.isNotEmpty) {
    segments.add(
      "${l10n.dropSocialPublishStatusLabel}: ${socialPublishStatuses.map((status) => "${status.channel} ${status.status}").join(", ")}",
    );
  }

  return segments.join("\n\n");
}

class _MyDropViewModel {
  const _MyDropViewModel({
    required this.drop,
    required this.id,
    required this.title,
    required this.subtitle,
    required this.artistName,
    required this.artistProfileImageUrl,
    required this.dropMakerName,
    required this.dropMakerProfileImageUrl,
    required this.description,
    required this.galleryUrls,
    required this.claimedHunters,
    required this.latitude,
    required this.longitude,
    required this.claimedItemCount,
    required this.itemCount,
    required this.isFullyClaimed,
    required this.unclaimedDropRadiusKm,
    required this.showPreciseLocationForUnclaimed,
    required this.isPublished,
    required this.canResumeWizard,
  });

  final DropModel drop;
  final String id;
  final String title;
  final String subtitle;
  final String artistName;
  final String? artistProfileImageUrl;
  final String dropMakerName;
  final String? dropMakerProfileImageUrl;
  final String description;
  final List<String> galleryUrls;
  final List<HunterIdentity> claimedHunters;
  final double? latitude;
  final double? longitude;
  final int claimedItemCount;
  final int itemCount;
  final bool isFullyClaimed;
  final int unclaimedDropRadiusKm;
  final bool showPreciseLocationForUnclaimed;
  final bool isPublished;
  final bool canResumeWizard;
}
