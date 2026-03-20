import "dart:async";
import "dart:math" as math;

import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:flutter_map/flutter_map.dart";
import "package:latlong2/latlong.dart";
import "package:urban_art_drops_app/l10n/app_localizations.dart";

import "../../../../shared/models/app_models.dart";
import "../../../../shared/services/app_api_client.dart";
import "../../../../shared/widgets/carousel_navigation_tabs.dart";
import "../../../../shared/widgets/page_shell.dart";
import "../../../../shared/widgets/source_image.dart";
import "../../../../shared/widgets/user_avatar.dart";
import "../../../authentication/presentation/bloc/auth_session_cubit.dart";

class DropDetailPage extends StatefulWidget {
  const DropDetailPage({required this.dropId, this.apiClient, super.key});

  final String dropId;
  final AppApiClient? apiClient;

  @override
  State<DropDetailPage> createState() => _DropDetailPageState();
}

class _DropDetailPageState extends State<DropDetailPage> {
  late final AppApiClient _apiClient;

  DropModel? _drop;
  ArtPieceModel? _artPiece;
  AppConfigurationModel _appConfiguration = AppConfigurationModel.defaults;
  List<DropCommentModel> _comments = const [];
  Map<String, ManagedUser> _usersById = const {};
  bool _isLoading = true;
  bool _isSubmittingComment = false;
  bool _isSubmittingArtPieceReport = false;
  String? _pendingCommentReportId;
  String? _error;

  @override
  void initState() {
    super.initState();
    _apiClient = widget.apiClient ?? AppApiClient();
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
        _apiClient.getDropById(widget.dropId),
        _apiClient.getArtPieces(),
        _apiClient.getUserDirectory(),
        _apiClient.getDropComments(widget.dropId),
      ]);

      if (!mounted) {
        return;
      }

      final drop = results[0] as DropModel;
      final artPieces = results[1] as List<ArtPieceModel>;
      final users = results[2] as List<ManagedUser>;
      final comments = results[3] as List<DropCommentModel>;
      ArtPieceModel? artPiece;
      for (final entry in artPieces) {
        if (entry.id == drop.artPieceId) {
          artPiece = entry;
          break;
        }
      }

      setState(() {
        _drop = drop;
        _artPiece = artPiece;
        _appConfiguration = appConfiguration;
        _comments = comments;
        _usersById = {for (final user in users) user.id: user};
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error = AppLocalizations.of(context)!.dropDetailLoadFailed;
        _isLoading = false;
      });
    }
  }

  Future<void> _handleCreateComment(String content) async {
    final authState = context.read<AuthSessionCubit>().state;
    if (!_canCreateComments(authState)) {
      return;
    }

    final drop = _drop;
    if (drop == null) {
      return;
    }

    setState(() => _isSubmittingComment = true);

    try {
      final created = await _apiClient.createComment(
        dropId: drop.id,
        content: content,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _comments = [created, ..._comments];
        _isSubmittingComment = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.dropDetailCommentCreated),
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() => _isSubmittingComment = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.dropDetailCommentCreateFailed,
          ),
        ),
      );
    }
  }

  Future<void> _handleReportComment(DropCommentModel comment) async {
    if (_pendingCommentReportId != null) {
      return;
    }

    final l10n = AppLocalizations.of(context)!;
    final reason = await _showReportReasonDialog(
      context,
      title: l10n.dropDetailReportCommentAction,
      description: l10n.dropDetailReportDialogDescription,
    );
    if (!mounted || reason == null) {
      return;
    }

    setState(() => _pendingCommentReportId = comment.id);

    try {
      await _apiClient.reportComment(comment.id, reason: reason);

      if (!mounted) {
        return;
      }

      setState(() {
        _comments = _comments
            .map(
              (entry) => entry.id == comment.id
                  ? DropCommentModel(
                      id: entry.id,
                      dropId: entry.dropId,
                      authorUserId: entry.authorUserId,
                      authorDisplayName: entry.authorDisplayName,
                      anonymousNickname: entry.anonymousNickname,
                      content: entry.content,
                      isReported: true,
                      isHidden: entry.isHidden,
                      reportReason: reason,
                      createdAtUtc: entry.createdAtUtc,
                      reportedAtUtc: DateTime.now().toUtc(),
                    )
                  : entry,
            )
            .toList(growable: false);
        _pendingCommentReportId = null;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.dropDetailReportSubmitted)));
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() => _pendingCommentReportId = null);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.dropDetailReportFailed)));
    }
  }

  Future<void> _handleReportArtPiece() async {
    final artPiece = _artPiece;
    if (artPiece == null ||
        artPiece.isReported ||
        _isSubmittingArtPieceReport) {
      return;
    }

    final l10n = AppLocalizations.of(context)!;
    final reason = await _showReportReasonDialog(
      context,
      title: l10n.dropDetailReportArtPieceAction,
      description: l10n.dropDetailReportDialogDescription,
    );
    if (!mounted || reason == null) {
      return;
    }

    setState(() => _isSubmittingArtPieceReport = true);

    try {
      await _apiClient.reportArtPiece(artPiece.id, reason: reason);

      if (!mounted) {
        return;
      }

      setState(() {
        _artPiece = ArtPieceModel(
          id: artPiece.id,
          artistId: artPiece.artistId,
          createdByUserId: artPiece.createdByUserId,
          title: artPiece.title,
          subtitle: artPiece.subtitle,
          description: artPiece.description,
          assetKind: artPiece.assetKind,
          isPublished: artPiece.isPublished,
          isReported: true,
          reportReason: reason,
          reportedAtUtc: DateTime.now().toUtc(),
          photoUrls: artPiece.photoUrls,
          assetFile: artPiece.assetFile,
        );
        _isSubmittingArtPieceReport = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.dropDetailReportSubmitted)));
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() => _isSubmittingArtPieceReport = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.dropDetailReportFailed)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final drop = _drop;
    final authState = context.watch<AuthSessionCubit>().state;

    return PageShell(
      title: l10n.dropDetailTitle,
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
          : drop == null
          ? Center(child: Text(l10n.dropDetailLoadFailed))
          : _DropDetailContent(
              l10n: l10n,
              drop: drop,
              artPiece: _artPiece,
              appConfiguration: _appConfiguration,
              usersById: _usersById,
              comments: _comments,
              authState: authState,
              isSubmittingComment: _isSubmittingComment,
              isSubmittingArtPieceReport: _isSubmittingArtPieceReport,
              pendingCommentReportId: _pendingCommentReportId,
              onCreateComment: _handleCreateComment,
              onReportComment: _handleReportComment,
              onReportArtPiece: _handleReportArtPiece,
            ),
    );
  }
}

class _DropDetailContent extends StatelessWidget {
  const _DropDetailContent({
    required this.l10n,
    required this.drop,
    required this.artPiece,
    required this.appConfiguration,
    required this.usersById,
    required this.comments,
    required this.authState,
    required this.isSubmittingComment,
    required this.isSubmittingArtPieceReport,
    required this.pendingCommentReportId,
    required this.onCreateComment,
    required this.onReportComment,
    required this.onReportArtPiece,
  });

  final AppLocalizations l10n;
  final DropModel drop;
  final ArtPieceModel? artPiece;
  final AppConfigurationModel appConfiguration;
  final Map<String, ManagedUser> usersById;
  final List<DropCommentModel> comments;
  final AuthSessionState authState;
  final bool isSubmittingComment;
  final bool isSubmittingArtPieceReport;
  final String? pendingCommentReportId;
  final Future<void> Function(String content) onCreateComment;
  final Future<void> Function(DropCommentModel comment) onReportComment;
  final Future<void> Function() onReportArtPiece;

  Widget _withUnifiedWidth(Widget child) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = artPiece?.title ?? l10n.dropFallbackTitle(drop.id);
    final description = artPiece?.description ?? "";
    final artistName = artPiece == null
        ? "-"
        : (usersById[artPiece!.artistId]?.userName ?? artPiece!.artistId);
    final artistProfileImageUrl = artPiece == null
        ? null
        : usersById[artPiece!.artistId]?.profileImageUrl;
    final dropMakerName =
        usersById[drop.dropMakerId]?.userName ?? drop.dropMakerId;
    final dropMakerProfileImageUrl =
        usersById[drop.dropMakerId]?.profileImageUrl;
    final subtitle = artPiece?.subtitle.trim().isNotEmpty == true
        ? artPiece!.subtitle
        : "${l10n.mapArtistLabel}: $artistName · ${l10n.mapDropMakerLabel}: $dropMakerName";
    final claimedHunters = _extractClaimedHunters(drop, usersById);
    final photos = _buildGalleryUrls(artPiece, drop);
    final canSeePreciseLocation = _canSeePreciseDropLocation(authState, drop);

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _withUnifiedWidth(
          Text(title, style: Theme.of(context).textTheme.headlineSmall),
        ),
        const SizedBox(height: 6),
        _withUnifiedWidth(
          Text(subtitle, style: Theme.of(context).textTheme.titleMedium),
        ),
        const SizedBox(height: 12),
        _withUnifiedWidth(
          _SectionCard(
            title: l10n.artPieceMetadataSection,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(
                  avatar: UserAvatar(
                    displayName: artistName,
                    imageUrl: artistProfileImageUrl,
                  ),
                  label: Text("${l10n.mapArtistLabel}: $artistName"),
                ),
                Chip(
                  avatar: UserAvatar(
                    displayName: dropMakerName,
                    imageUrl: dropMakerProfileImageUrl,
                  ),
                  label: Text("${l10n.mapDropMakerLabel}: $dropMakerName"),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        _withUnifiedWidth(_DropDetailGallery(imageUrls: photos)),
        const SizedBox(height: 12),
        _withUnifiedWidth(
          _SectionCard(
            title: l10n.dropDetailDescriptionSection,
            actions: [
              OutlinedButton.icon(
                onPressed:
                    artPiece == null ||
                        artPiece!.isReported ||
                        isSubmittingArtPieceReport
                    ? null
                    : onReportArtPiece,
                icon: isSubmittingArtPieceReport
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.flag_outlined),
                label: Text(
                  artPiece?.isReported == true
                      ? l10n.dropDetailAlreadyReported
                      : l10n.dropDetailReportArtPieceAction,
                ),
              ),
            ],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(description.isEmpty ? "-" : description),
                if (artPiece?.isReported == true) ...[
                  const SizedBox(height: 12),
                  _ReportMeta(
                    l10n: l10n,
                    reason: artPiece?.reportReason,
                    reportedAtUtc: artPiece?.reportedAtUtc,
                  ),
                ],
              ],
            ),
          ),
        ),
        if ((drop.dropMakerComment ?? "").trim().isNotEmpty) ...[
          const SizedBox(height: 12),
          _withUnifiedWidth(
            _SectionCard(
              title: l10n.dropMakerCommentLabel,
              child: Text(drop.dropMakerComment!.trim()),
            ),
          ),
        ],
        if (drop.socialChannels.isNotEmpty) ...[
          const SizedBox(height: 12),
          _withUnifiedWidth(
            _SectionCard(
              title: l10n.dropSocialChannelsLabel,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: drop.socialChannels
                    .map((channel) => Chip(label: Text(channel)))
                    .toList(growable: false),
              ),
            ),
          ),
        ],
        const SizedBox(height: 12),
        _withUnifiedWidth(
          _SectionCard(
            title: l10n.claimedHuntersTitle,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.claimedItemsValue(
                    "${drop.claimedItemCount}",
                    "${drop.itemCount}",
                  ),
                ),
                const SizedBox(height: 8),
                if (claimedHunters.isEmpty)
                  Text(l10n.mapUnclaimedLabel)
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: claimedHunters
                        .map((name) => Chip(label: Text(name)))
                        .toList(growable: false),
                  ),
              ],
            ),
          ),
        ),
        if (canSeePreciseLocation) ...[
          const SizedBox(height: 12),
          _withUnifiedWidth(
            _SectionCard(
              title: l10n.dropDetailItemStatusSection,
              child: _DropItemStatusList(
                l10n: l10n,
                drop: drop,
                usersById: usersById,
              ),
            ),
          ),
        ],
        const SizedBox(height: 12),
        _withUnifiedWidth(
          _SectionCard(
            title: l10n.dropDetailCommentsSection,
            child: _CommentsSection(
              l10n: l10n,
              comments: comments,
              authState: authState,
              isSubmittingComment: isSubmittingComment,
              pendingCommentReportId: pendingCommentReportId,
              onCreateComment: onCreateComment,
              onReportComment: onReportComment,
            ),
          ),
        ),
        const SizedBox(height: 12),
        _withUnifiedWidth(
          _SectionCard(
            title: l10n.dropDetailLocationSection,
            child: SizedBox(
              height: 220,
              child: _DropDetailMap(
                l10n: l10n,
                isFullyClaimed: drop.isFullyClaimed,
                unclaimedDropRadiusKm: appConfiguration.unclaimedDropRadiusKm,
                showPreciseLocationForUnclaimed: canSeePreciseLocation,
                latitude: drop.latitude,
                longitude: drop.longitude,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DropDetailGallery extends StatefulWidget {
  const _DropDetailGallery({required this.imageUrls});

  final List<String> imageUrls;

  @override
  State<_DropDetailGallery> createState() => _DropDetailGalleryState();
}

class _DropDetailGalleryState extends State<_DropDetailGallery> {
  static const Duration _autoAdvanceInterval = Duration(seconds: 5);

  late final PageController _controller;
  Timer? _autoAdvanceTimer;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
    _configureAutoAdvance();
  }

  @override
  void didUpdateWidget(covariant _DropDetailGallery oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (_index >= widget.imageUrls.length && widget.imageUrls.isNotEmpty) {
      _index = widget.imageUrls.length - 1;
      if (_controller.hasClients) {
        _controller.jumpToPage(_index);
      }
    }

    if (oldWidget.imageUrls.length != widget.imageUrls.length) {
      _configureAutoAdvance();
    }
  }

  @override
  void dispose() {
    _autoAdvanceTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _configureAutoAdvance() {
    _autoAdvanceTimer?.cancel();
    if (widget.imageUrls.length <= 1) {
      return;
    }

    _autoAdvanceTimer = Timer.periodic(_autoAdvanceInterval, (_) {
      if (!mounted || !_controller.hasClients) {
        return;
      }

      final imageCount = widget.imageUrls.length;
      if (imageCount <= 1) {
        return;
      }

      final nextIndex = (_index + 1) % imageCount;
      _goToPage(nextIndex);
    });
  }

  void _goToPage(int index) {
    _controller.animateToPage(
      index,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.imageUrls.isEmpty) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(child: Icon(Icons.image_not_supported_outlined)),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Stack(
          fit: StackFit.expand,
          children: [
            PageView.builder(
              controller: _controller,
              itemCount: widget.imageUrls.length,
              onPageChanged: (value) => setState(() => _index = value),
              itemBuilder: (context, index) => SourceImage(
                source: widget.imageUrls[index],
                fit: BoxFit.cover,
                fallback: const ColoredBox(
                  color: Color(0xFFE7ECEE),
                  child: Center(
                    child: Icon(Icons.image_not_supported_outlined),
                  ),
                ),
              ),
            ),
            if (widget.imageUrls.length > 1)
              CarouselNavigationTabs(
                canGoPrevious: _index > 0,
                canGoNext: _index < widget.imageUrls.length - 1,
                onPrevious: () => _goToPage(_index - 1),
                onNext: () => _goToPage(_index + 1),
              ),
            if (widget.imageUrls.length > 1)
              Positioned(
                left: 0,
                right: 0,
                bottom: 8,
                child: Center(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      child: Text(
                        "${_index + 1}/${widget.imageUrls.length}",
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DropDetailMap extends StatelessWidget {
  const _DropDetailMap({
    required this.l10n,
    required this.isFullyClaimed,
    required this.unclaimedDropRadiusKm,
    required this.showPreciseLocationForUnclaimed,
    required this.latitude,
    required this.longitude,
  });

  final AppLocalizations l10n;
  final bool isFullyClaimed;
  final int unclaimedDropRadiusKm;
  final bool showPreciseLocationForUnclaimed;
  final double? latitude;
  final double? longitude;

  double _zoomForRadiusKm(int radiusKm) {
    final safeRadiusKm = radiusKm < 1 ? 1 : radiusKm;
    final zoom = 14.0 - (math.log(safeRadiusKm) / math.ln2);
    return (zoom.clamp(10.5, 14.5) as num).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    if (latitude == null || longitude == null) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(child: Text(l10n.dropListLocationUnavailable)),
      );
    }

    final point = LatLng(latitude!, longitude!);
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: FlutterMap(
        options: MapOptions(
          initialCenter: point,
          initialZoom: isFullyClaimed || showPreciseLocationForUnclaimed
              ? 14.5
              : _zoomForRadiusKm(unclaimedDropRadiusKm),
          interactionOptions: const InteractionOptions(
            flags: InteractiveFlag.none,
          ),
        ),
        children: [
          TileLayer(
            urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
            userAgentPackageName: "urban.art.drops.app",
          ),
          if (!isFullyClaimed)
            CircleLayer(
              circles: [
                CircleMarker(
                  point: point,
                  radius: unclaimedDropRadiusKm * 1000,
                  useRadiusInMeter: true,
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.15),
                  borderColor: Theme.of(context).colorScheme.primary,
                  borderStrokeWidth: 2,
                ),
              ],
            ),
          if (isFullyClaimed || showPreciseLocationForUnclaimed)
            MarkerLayer(
              markers: [
                Marker(
                  point: point,
                  width: 44,
                  height: 44,
                  child: const Icon(
                    Icons.location_on,
                    color: Colors.redAccent,
                    size: 34,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _DropItemStatusList extends StatelessWidget {
  const _DropItemStatusList({
    required this.l10n,
    required this.drop,
    required this.usersById,
  });

  final AppLocalizations l10n;
  final DropModel drop;
  final Map<String, ManagedUser> usersById;

  @override
  Widget build(BuildContext context) {
    if (drop.items.isEmpty) {
      return const Text("-");
    }

    return Column(
      children: List<Widget>.generate(drop.items.length, (index) {
        final item = drop.items[index];
        final statusLabel = item.isClaimed
            ? l10n.dropDetailItemStatusClaimedBy(
                _resolveClaimDisplayName(
                  item: item,
                  usersById: usersById,
                  l10n: l10n,
                ),
              )
            : l10n.dropDetailItemStatusAvailable;

        return Column(
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                item.isClaimed
                    ? Icons.check_circle_outline
                    : Icons.radio_button_unchecked,
              ),
              title: Text(l10n.dropDetailItemStatusItemLabel("${index + 1}")),
              subtitle: Text(statusLabel),
            ),
            if (index < drop.items.length - 1) const Divider(height: 1),
          ],
        );
      }),
    );
  }
}

class _CommentsSection extends StatefulWidget {
  const _CommentsSection({
    required this.l10n,
    required this.comments,
    required this.authState,
    required this.isSubmittingComment,
    required this.pendingCommentReportId,
    required this.onCreateComment,
    required this.onReportComment,
  });

  final AppLocalizations l10n;
  final List<DropCommentModel> comments;
  final AuthSessionState authState;
  final bool isSubmittingComment;
  final String? pendingCommentReportId;
  final Future<void> Function(String content) onCreateComment;
  final Future<void> Function(DropCommentModel comment) onReportComment;

  @override
  State<_CommentsSection> createState() => _CommentsSectionState();
}

class _CommentsSectionState extends State<_CommentsSection> {
  late final TextEditingController _commentController;

  @override
  void initState() {
    super.initState();
    _commentController = TextEditingController();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty || widget.isSubmittingComment) {
      return;
    }

    await widget.onCreateComment(content);
    if (!mounted) {
      return;
    }

    _commentController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final canCreateComment = _canCreateComments(widget.authState);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (canCreateComment) ...[
          Text(
            widget.l10n.dropDetailCommentComposerTitle,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _commentController,
            minLines: 3,
            maxLines: 6,
            textInputAction: TextInputAction.newline,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              hintText: widget.l10n.dropDetailCommentPlaceholder,
            ),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: widget.isSubmittingComment ? null : _submitComment,
            icon: widget.isSubmittingComment
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send_outlined),
            label: Text(widget.l10n.dropDetailCommentSubmit),
          ),
          const SizedBox(height: 16),
        ] else
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(widget.l10n.dropDetailCommentLoginHint),
          ),
        if (widget.comments.isEmpty)
          Text(widget.l10n.dropDetailCommentsEmpty)
        else
          Column(
            children: widget.comments
                .map(
                  (comment) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _CommentCard(
                      l10n: widget.l10n,
                      comment: comment,
                      isSubmittingReport:
                          widget.pendingCommentReportId == comment.id,
                      onReport: () => widget.onReportComment(comment),
                    ),
                  ),
                )
                .toList(growable: false),
          ),
      ],
    );
  }
}

class _CommentCard extends StatelessWidget {
  const _CommentCard({
    required this.l10n,
    required this.comment,
    required this.isSubmittingReport,
    required this.onReport,
  });

  final AppLocalizations l10n;
  final DropCommentModel comment;
  final bool isSubmittingReport;
  final Future<void> Function() onReport;

  @override
  Widget build(BuildContext context) {
    final displayName = _commentDisplayName(comment, l10n);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDateTime(comment.createdAtUtc),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: comment.isReported || isSubmittingReport
                      ? null
                      : onReport,
                  icon: isSubmittingReport
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.flag_outlined),
                  label: Text(
                    comment.isReported
                        ? l10n.dropDetailAlreadyReported
                        : l10n.dropDetailReportCommentAction,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(comment.content),
            if (comment.isReported) ...[
              const SizedBox(height: 12),
              _ReportMeta(
                l10n: l10n,
                reason: comment.reportReason,
                reportedAtUtc: comment.reportedAtUtc,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ReportMeta extends StatelessWidget {
  const _ReportMeta({
    required this.l10n,
    required this.reason,
    required this.reportedAtUtc,
  });

  final AppLocalizations l10n;
  final String? reason;
  final DateTime? reportedAtUtc;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.errorContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.dropDetailAlreadyReported,
              style: Theme.of(context).textTheme.labelLarge,
            ),
            if (reason != null && reason!.trim().isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(l10n.dropDetailReportReason(reason!.trim())),
            ],
            if (reportedAtUtc != null) ...[
              const SizedBox(height: 4),
              Text(
                l10n.dropDetailReportedAt(_formatDateTime(reportedAtUtc)),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
    this.actions = const <Widget>[],
  });

  final String title;
  final Widget child;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (actions.isNotEmpty) ...actions,
              ],
            ),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}

List<String> _extractClaimedHunters(
  DropModel drop,
  Map<String, ManagedUser> usersById,
) {
  final hunters = <String>[];
  final seen = <String>{};
  for (final item in drop.claimedItems) {
    String candidate = "";
    if (item.claimedByUserId != null) {
      candidate =
          usersById[item.claimedByUserId!]?.userName ?? item.claimedByUserId!;
    } else if (item.claimedByAnonymousNickname != null) {
      candidate = item.claimedByAnonymousNickname!;
    }

    final normalized = candidate.trim().toLowerCase();
    if (normalized.isEmpty || !seen.add(normalized)) {
      continue;
    }
    hunters.add(candidate.trim());
  }

  return hunters;
}

List<String> _buildGalleryUrls(ArtPieceModel? artPiece, DropModel drop) {
  final combined = [...?artPiece?.photoUrls, ...drop.locationPhotoUrls];
  final seen = <String>{};
  final unique = <String>[];

  for (final url in combined) {
    final normalized = url.trim();
    if (normalized.isEmpty || !seen.add(normalized)) {
      continue;
    }
    unique.add(normalized);
  }

  return unique;
}

String _resolveClaimDisplayName({
  required DropItemModel item,
  required Map<String, ManagedUser> usersById,
  required AppLocalizations l10n,
}) {
  if (item.claimedByUserId != null && item.claimedByUserId!.trim().isNotEmpty) {
    return usersById[item.claimedByUserId!]?.userName ?? item.claimedByUserId!;
  }

  final anonymous = item.claimedByAnonymousNickname?.trim();
  if (anonymous != null && anonymous.isNotEmpty) {
    return anonymous;
  }

  return l10n.leaderboardAnonymousFallback;
}

bool _canSeePreciseDropLocation(AuthSessionState authState, DropModel drop) {
  final currentUserId = authState.userId?.trim();
  return currentUserId != null &&
      currentUserId.isNotEmpty &&
      currentUserId == drop.dropMakerId;
}

bool _canCreateComments(AuthSessionState authState) {
  if (!authState.isAuthenticated || authState.role == null) {
    return false;
  }

  switch (authState.role!) {
    case AppUserRole.hunter:
    case AppUserRole.artist:
    case AppUserRole.dropMaker:
    case AppUserRole.moderator:
    case AppUserRole.admin:
      return true;
  }
}

String _commentDisplayName(DropCommentModel comment, AppLocalizations l10n) {
  final author = comment.authorDisplayName?.trim();
  if (author != null && author.isNotEmpty) {
    return author;
  }

  final nickname = comment.anonymousNickname?.trim();
  if (nickname != null && nickname.isNotEmpty) {
    return nickname;
  }

  return l10n.leaderboardAnonymousFallback;
}

String _formatDateTime(DateTime? value) {
  if (value == null) {
    return "-";
  }

  final local = value.toLocal();
  final day = local.day.toString().padLeft(2, "0");
  final month = local.month.toString().padLeft(2, "0");
  final year = local.year.toString().padLeft(4, "0");
  final hour = local.hour.toString().padLeft(2, "0");
  final minute = local.minute.toString().padLeft(2, "0");
  return "$day.$month.$year $hour:$minute";
}

Future<String?> _showReportReasonDialog(
  BuildContext context, {
  required String title,
  required String description,
}) {
  final controller = TextEditingController();
  final l10n = AppLocalizations.of(context)!;

  return showDialog<String>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(description),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            maxLength: 400,
            minLines: 3,
            maxLines: 6,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              labelText: l10n.dropDetailReportReasonLabel,
              hintText: l10n.dropDetailReportReasonHint,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(null),
          child: Text(l10n.cancelAction),
        ),
        FilledButton(
          onPressed: () =>
              Navigator.of(dialogContext).pop(controller.text.trim()),
          child: Text(l10n.dropDetailSubmitReportAction),
        ),
      ],
    ),
  );
}
