import "dart:async";
import "dart:math" as math;

import "package:flutter/material.dart";
import "package:flutter_map/flutter_map.dart";
import "package:latlong2/latlong.dart";
import "package:urban_art_drops_app/l10n/app_localizations.dart";

import "../models/hunter_identity.dart";
import "app_panels.dart";
import "carousel_navigation_tabs.dart";
import "hunter_identity_list.dart";
import "user_avatar.dart";

class DropOverviewCard extends StatelessWidget {
  const DropOverviewCard({
    required this.l10n,
    required this.title,
    required this.subtitle,
    required this.artistName,
    required this.dropMakerName,
    required this.description,
    required this.galleryUrls,
    required this.claimedHunters,
    required this.claimedItemCount,
    required this.itemCount,
    required this.isFullyClaimed,
    required this.unclaimedDropRadiusKm,
    required this.latitude,
    required this.longitude,
    this.showPreciseLocationForUnclaimed = false,
    this.artistProfileImageUrl,
    this.dropMakerProfileImageUrl,
    this.distanceKm,
    this.onTap,
    this.onMiniMapTap,
    this.trailing,
    super.key,
  });

  final AppLocalizations l10n;
  final String title;
  final String subtitle;
  final String artistName;
  final String dropMakerName;
  final String description;
  final List<String> galleryUrls;
  final List<HunterIdentity> claimedHunters;
  final int claimedItemCount;
  final int itemCount;
  final bool isFullyClaimed;
  final int unclaimedDropRadiusKm;
  final double? latitude;
  final double? longitude;
  final bool showPreciseLocationForUnclaimed;
  final String? artistProfileImageUrl;
  final String? dropMakerProfileImageUrl;
  final double? distanceKm;
  final VoidCallback? onTap;
  final VoidCallback? onMiniMapTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.all(18),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 980;
          final centerContent = _DropOverviewMainContent(
            l10n: l10n,
            title: title,
            subtitle: subtitle,
            artistName: artistName,
            dropMakerName: dropMakerName,
            artistProfileImageUrl: artistProfileImageUrl,
            dropMakerProfileImageUrl: dropMakerProfileImageUrl,
            description: description,
            claimedHunters: claimedHunters,
            claimedItemCount: claimedItemCount,
            itemCount: itemCount,
            distanceKm: distanceKm,
            trailing: trailing,
          );
          final miniMap = _DropMiniMap(
            l10n: l10n,
            isFullyClaimed: isFullyClaimed,
            unclaimedDropRadiusKm: unclaimedDropRadiusKm,
            latitude: latitude,
            longitude: longitude,
            showPreciseLocationForUnclaimed: showPreciseLocationForUnclaimed,
            onTap: onMiniMapTap,
          );

          if (!isDesktop) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DropPhotoCarousel(
                  imageUrls: galleryUrls,
                  fallbackLabel: title,
                ),
                const SizedBox(height: 12),
                centerContent,
                const SizedBox(height: 12),
                SizedBox(height: 170, child: miniMap),
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 320,
                child: _DropPhotoCarousel(
                  imageUrls: galleryUrls,
                  fallbackLabel: title,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(child: centerContent),
              const SizedBox(width: 16),
              SizedBox(width: 260, height: 200, child: miniMap),
            ],
          );
        },
      ),
    );

    return AppSurfacePanel(
      withAmbientShadow: true,
      padding: EdgeInsets.zero,
      child: Material(
        color: Colors.transparent,
        child: onTap == null ? content : InkWell(onTap: onTap, child: content),
      ),
    );
  }
}

class _DropOverviewMainContent extends StatelessWidget {
  const _DropOverviewMainContent({
    required this.l10n,
    required this.title,
    required this.subtitle,
    required this.artistName,
    required this.dropMakerName,
    required this.artistProfileImageUrl,
    required this.dropMakerProfileImageUrl,
    required this.description,
    required this.claimedHunters,
    required this.claimedItemCount,
    required this.itemCount,
    required this.distanceKm,
    required this.trailing,
  });

  final AppLocalizations l10n;
  final String title;
  final String subtitle;
  final String artistName;
  final String dropMakerName;
  final String? artistProfileImageUrl;
  final String? dropMakerProfileImageUrl;
  final String description;
  final List<HunterIdentity> claimedHunters;
  final int claimedItemCount;
  final int itemCount;
  final double? distanceKm;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final claimsLabel = l10n.claimedItemsValue(
      "$claimedItemCount",
      "$itemCount",
    );

    return Column(
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
                    title,
                    style: Theme.of(context).textTheme.headlineMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: 8), trailing!],
          ],
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.labelMedium,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            UserIdentityChip(
              label: l10n.mapArtistLabel,
              displayName: artistName,
              imageUrl: artistProfileImageUrl,
            ),
            UserIdentityChip(
              label: l10n.mapDropMakerLabel,
              displayName: dropMakerName,
              imageUrl: dropMakerProfileImageUrl,
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          description.isEmpty ? "-" : description,
          maxLines: 4,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            Chip(
              avatar: const Icon(Icons.qr_code_2_outlined, size: 18),
              label: Text(claimsLabel),
            ),
            if (distanceKm != null)
              Chip(
                avatar: const Icon(Icons.near_me_outlined, size: 18),
                label: Text(l10n.distanceValue(distanceKm!.toStringAsFixed(1))),
              ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          l10n.claimedHuntersTitle,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 6),
        HunterIdentityList(
          hunters: claimedHunters,
          emptyLabel: l10n.mapUnclaimedLabel,
        ),
      ],
    );
  }
}

class _DropPhotoCarousel extends StatefulWidget {
  const _DropPhotoCarousel({
    required this.imageUrls,
    required this.fallbackLabel,
  });

  final List<String> imageUrls;
  final String fallbackLabel;

  @override
  State<_DropPhotoCarousel> createState() => _DropPhotoCarouselState();
}

class _DropPhotoCarouselState extends State<_DropPhotoCarousel> {
  static const Duration _autoAdvanceInterval = Duration(seconds: 5);

  late final PageController _controller;
  Timer? _autoAdvanceTimer;
  int _activeIndex = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
    _configureAutoAdvance();
  }

  @override
  void didUpdateWidget(covariant _DropPhotoCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (_activeIndex >= widget.imageUrls.length &&
        widget.imageUrls.isNotEmpty) {
      _activeIndex = widget.imageUrls.length - 1;
      if (_controller.hasClients) {
        _controller.jumpToPage(_activeIndex);
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

      final nextIndex = (_activeIndex + 1) % imageCount;
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
    final photos = widget.imageUrls;
    if (photos.isEmpty) {
      return AspectRatio(
        aspectRatio: 4 / 3,
        child: AppSurfacePanel(
          radius: 18,
          padding: EdgeInsets.zero,
          backgroundColor: Theme.of(
            context,
          ).colorScheme.surfaceContainerHighest,
          child: const Center(child: Icon(Icons.image_not_supported_outlined)),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: AspectRatio(
        aspectRatio: 4 / 3,
        child: Stack(
          fit: StackFit.expand,
          children: [
            PageView.builder(
              controller: _controller,
              itemCount: photos.length,
              onPageChanged: (value) => setState(() => _activeIndex = value),
              itemBuilder: (context, index) => Image.network(
                photos[index],
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const ColoredBox(
                  color: Color(0xFF151515),
                  child: Center(
                    child: Icon(Icons.image_not_supported_outlined),
                  ),
                ),
              ),
            ),
            if (photos.length > 1)
              CarouselNavigationTabs(
                canGoPrevious: _activeIndex > 0,
                canGoNext: _activeIndex < photos.length - 1,
                onPrevious: () => _goToPage(_activeIndex - 1),
                onNext: () => _goToPage(_activeIndex + 1),
              ),
            if (photos.length > 1)
              Positioned(
                left: 0,
                right: 0,
                bottom: 8,
                child: Center(
                  child: AppGlassPanel(
                    radius: 999,
                    opacity: 0.66,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    child: DefaultTextStyle(
                      style: const TextStyle(color: Colors.white),
                      child: Text("${_activeIndex + 1}/${photos.length}"),
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

class _DropMiniMap extends StatelessWidget {
  const _DropMiniMap({
    required this.l10n,
    required this.isFullyClaimed,
    required this.unclaimedDropRadiusKm,
    required this.latitude,
    required this.longitude,
    required this.showPreciseLocationForUnclaimed,
    required this.onTap,
  });

  final AppLocalizations l10n;
  final bool isFullyClaimed;
  final int unclaimedDropRadiusKm;
  final double? latitude;
  final double? longitude;
  final bool showPreciseLocationForUnclaimed;
  final VoidCallback? onTap;

  double _zoomForRadiusKm(int radiusKm) {
    final safeRadiusKm = math.max(1, radiusKm);
    final zoom = 14.0 - math.log(safeRadiusKm) / math.ln2;
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
    final unclaimedFillColor = Theme.of(
      context,
    ).colorScheme.primary.withValues(alpha: 0.14);
    final unclaimedBorderColor = Theme.of(
      context,
    ).colorScheme.primary.withValues(alpha: 0.72);
    final map = ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: FlutterMap(
        options: MapOptions(
          initialCenter: point,
          initialZoom: isFullyClaimed
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
                  color: unclaimedFillColor,
                  borderColor: unclaimedBorderColor,
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

    if (onTap == null) {
      return map;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: IgnorePointer(child: map),
      ),
    );
  }
}
