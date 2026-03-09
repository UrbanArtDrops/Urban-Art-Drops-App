import "dart:async";

import "package:flutter/material.dart";
import "package:flutter_map/flutter_map.dart";
import "package:latlong2/latlong.dart";
import "package:urban_art_drops_app/l10n/app_localizations.dart";

import "../../../../shared/models/app_models.dart";
import "../../../../shared/services/app_api_client.dart";
import "../../../../shared/widgets/page_shell.dart";

class DropDetailPage extends StatefulWidget {
  const DropDetailPage({required this.dropId, super.key});

  final String dropId;

  @override
  State<DropDetailPage> createState() => _DropDetailPageState();
}

class _DropDetailPageState extends State<DropDetailPage> {
  final AppApiClient _apiClient = AppApiClient();

  DropModel? _drop;
  ArtPieceModel? _artPiece;
  Map<String, ManagedUser> _usersById = const {};
  bool _isLoading = true;
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
        _apiClient.getDropById(widget.dropId),
        _apiClient.getArtPieces(),
        _apiClient.getUsers(),
      ]);

      if (!mounted) {
        return;
      }

      final drop = results[0] as DropModel;
      final artPieces = results[1] as List<ArtPieceModel>;
      final users = results[2] as List<ManagedUser>;
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final drop = _drop;

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
              usersById: _usersById,
            ),
    );
  }
}

class _DropDetailContent extends StatelessWidget {
  const _DropDetailContent({
    required this.l10n,
    required this.drop,
    required this.artPiece,
    required this.usersById,
  });

  final AppLocalizations l10n;
  final DropModel drop;
  final ArtPieceModel? artPiece;
  final Map<String, ManagedUser> usersById;

  @override
  Widget build(BuildContext context) {
    final title = artPiece?.title ?? l10n.dropFallbackTitle(drop.id);
    final description = artPiece?.description ?? "";
    final artistName = artPiece == null
        ? "-"
        : (usersById[artPiece!.artistId]?.userName ?? artPiece!.artistId);
    final dropMakerName =
        usersById[drop.dropMakerId]?.userName ?? drop.dropMakerId;
    final subtitle =
        "${l10n.mapArtistLabel}: $artistName · ${l10n.mapDropMakerLabel}: $dropMakerName";
    final claimedHunters = _extractClaimedHunters(drop, usersById);
    final photos = _buildGalleryUrls(artPiece, drop);

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Text(title, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 6),
        Text(subtitle, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        _DropDetailGallery(imageUrls: photos),
        const SizedBox(height: 12),
        _SectionCard(
          title: l10n.dropDetailDescriptionSection,
          child: Text(description.isEmpty ? "-" : description),
        ),
        const SizedBox(height: 12),
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
        const SizedBox(height: 12),
        _SectionCard(
          title: l10n.dropDetailLocationSection,
          child: SizedBox(
            height: 220,
            child: _DropDetailMap(
              l10n: l10n,
              latitude: drop.latitude,
              longitude: drop.longitude,
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
      _controller.animateToPage(
        nextIndex,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
      );
    });
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
              itemBuilder: (context, index) => Image.network(
                widget.imageUrls[index],
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const ColoredBox(
                  color: Color(0xFFE7ECEE),
                  child: Center(
                    child: Icon(Icons.image_not_supported_outlined),
                  ),
                ),
              ),
            ),
            if (widget.imageUrls.length > 1)
              Positioned(
                right: 8,
                bottom: 8,
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
          ],
        ),
      ),
    );
  }
}

class _DropDetailMap extends StatelessWidget {
  const _DropDetailMap({
    required this.l10n,
    required this.latitude,
    required this.longitude,
  });

  final AppLocalizations l10n;
  final double? latitude;
  final double? longitude;

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
          initialZoom: 14.5,
          interactionOptions: const InteractionOptions(
            flags: InteractiveFlag.none,
          ),
        ),
        children: [
          TileLayer(
            urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
            userAgentPackageName: "urban.art.drops.app",
          ),
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

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
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
