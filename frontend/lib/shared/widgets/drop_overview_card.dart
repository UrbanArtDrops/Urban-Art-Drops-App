import "dart:async";

import "package:flutter/material.dart";
import "package:flutter_map/flutter_map.dart";
import "package:latlong2/latlong.dart";
import "package:urban_art_drops_app/l10n/app_localizations.dart";

class DropOverviewCard extends StatelessWidget {
  const DropOverviewCard({
    required this.l10n,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.galleryUrls,
    required this.claimedHunterNames,
    required this.claimedItemCount,
    required this.itemCount,
    required this.latitude,
    required this.longitude,
    this.distanceKm,
    this.onTap,
    this.trailing,
    super.key,
  });

  final AppLocalizations l10n;
  final String title;
  final String subtitle;
  final String description;
  final List<String> galleryUrls;
  final List<String> claimedHunterNames;
  final int claimedItemCount;
  final int itemCount;
  final double? latitude;
  final double? longitude;
  final double? distanceKm;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.all(12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 980;
          final centerContent = _DropOverviewMainContent(
            l10n: l10n,
            title: title,
            subtitle: subtitle,
            description: description,
            claimedHunterNames: claimedHunterNames,
            claimedItemCount: claimedItemCount,
            itemCount: itemCount,
            distanceKm: distanceKm,
            trailing: trailing,
          );
          final miniMap = _DropMiniMap(
            l10n: l10n,
            latitude: latitude,
            longitude: longitude,
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

    return Card(
      clipBehavior: Clip.antiAlias,
      child: onTap == null ? content : InkWell(onTap: onTap, child: content),
    );
  }
}

class _DropOverviewMainContent extends StatelessWidget {
  const _DropOverviewMainContent({
    required this.l10n,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.claimedHunterNames,
    required this.claimedItemCount,
    required this.itemCount,
    required this.distanceKm,
    required this.trailing,
  });

  final AppLocalizations l10n;
  final String title;
  final String subtitle;
  final String description;
  final List<String> claimedHunterNames;
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
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleLarge,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: 8), trailing!],
          ],
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodySmall,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 10),
        Text(
          description.isEmpty ? "-" : description,
          maxLines: 4,
          overflow: TextOverflow.ellipsis,
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
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 6),
        if (claimedHunterNames.isEmpty)
          Text(l10n.mapUnclaimedLabel)
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: claimedHunterNames
                .map((name) => Chip(label: Text(name)))
                .toList(growable: false),
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
                  color: Color(0xFFE7ECEE),
                  child: Center(
                    child: Icon(Icons.image_not_supported_outlined),
                  ),
                ),
              ),
            ),
            if (photos.length > 1)
              Positioned(
                left: 8,
                right: 8,
                bottom: 8,
                child: Row(
                  children: [
                    _CarouselButton(
                      icon: Icons.chevron_left,
                      onPressed: _activeIndex > 0
                          ? () => _goToPage(_activeIndex - 1)
                          : null,
                    ),
                    const Spacer(),
                    DecoratedBox(
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
                          "${_activeIndex + 1}/${photos.length}",
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                    const Spacer(),
                    _CarouselButton(
                      icon: Icons.chevron_right,
                      onPressed: _activeIndex < photos.length - 1
                          ? () => _goToPage(_activeIndex + 1)
                          : null,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CarouselButton extends StatelessWidget {
  const _CarouselButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black54,
      shape: const CircleBorder(),
      child: IconButton(
        visualDensity: VisualDensity.compact,
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white),
      ),
    );
  }
}

class _DropMiniMap extends StatelessWidget {
  const _DropMiniMap({
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
