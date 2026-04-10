import "dart:async";
import "dart:convert";

import "package:flutter/material.dart";
import "package:flutter_map/flutter_map.dart";
import "package:geolocator/geolocator.dart";
import "package:http/http.dart" as http;
import "package:latlong2/latlong.dart";
import "package:urban_art_drops_app/l10n/app_localizations.dart";

import "../../../../shared/models/app_models.dart";
import "../../../../shared/models/hunter_identity.dart";
import "../../../../shared/services/app_api_client.dart";
import "../../../../shared/widgets/app_panels.dart";
import "../../../../shared/widgets/hunter_identity_list.dart";
import "../../../../shared/widgets/page_shell.dart";
import "../../../../shared/widgets/user_avatar.dart";

class MapPage extends StatefulWidget {
  const MapPage({this.focusDropId, super.key});

  final String? focusDropId;

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final AppApiClient _apiClient = AppApiClient();
  final MapController _mapController = MapController();
  final TextEditingController _locationSearchController =
      TextEditingController();
  final FocusNode _locationSearchFocusNode = FocusNode();
  static const LatLng _defaultCenter = LatLng(52.5208, 13.4095);
  static const int _fallbackMainMapRadiusKm = 30;
  static const int _fallbackUnclaimedRadiusKm = 3;

  LatLng _center = _defaultCenter;
  List<_MapDropViewModel> _drops = const [];
  _MapDropViewModel? _latestDrop;
  _MapDropViewModel? _selectedDrop;
  int _mainMapRadiusKm = _fallbackMainMapRadiusKm;
  int _unclaimedDropRadiusKm = _fallbackUnclaimedRadiusKm;
  Timer? _searchDebounceTimer;
  List<_LocationSuggestion> _locationSuggestions = const [];
  String _lastSearchQuery = "";
  bool _isCenteringOnUser = false;
  bool _isSearchingLocations = false;
  bool _isLoadingDrops = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _locationSearchFocusNode.addListener(() {
      if (!_locationSearchFocusNode.hasFocus && mounted) {
        setState(() => _locationSuggestions = const []);
      }
    });
    _loadMapData();
  }

  @override
  void dispose() {
    _searchDebounceTimer?.cancel();
    _locationSearchController.dispose();
    _locationSearchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadMapData() async {
    setState(() {
      _isLoadingDrops = true;
      _loadError = null;
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

      final drops = (results[0] as List<DropModel>)
          .where((drop) => drop.latitude != null && drop.longitude != null)
          .toList(growable: false);
      final artById = <String, ArtPieceModel>{
        for (final art in (results[1] as List<ArtPieceModel>)) art.id: art,
      };
      final usersById = <String, ManagedUser>{
        for (final user in (results[2] as List<ManagedUser>)) user.id: user,
      };

      final mappedDrops = drops
          .map((drop) {
            final artPiece = artById[drop.artPieceId];
            final artistName = artPiece != null
                ? (usersById[artPiece.artistId]?.userName ?? artPiece.artistId)
                : "";
            final artistProfileImageUrl = artPiece == null
                ? null
                : usersById[artPiece.artistId]?.profileImageUrl;
            final dropMakerName =
                usersById[drop.dropMakerId]?.userName ?? drop.dropMakerId;
            final dropMakerProfileImageUrl =
                usersById[drop.dropMakerId]?.profileImageUrl;
            final claimedHunters = buildClaimedHunterIdentities(
              items: drop.claimedItems,
              usersById: usersById,
            );
            final subtitle = "$artistName · $dropMakerName";

            return _MapDropViewModel(
              id: drop.id,
              title: artPiece?.title ?? drop.id,
              subtitle: subtitle,
              latitude: drop.latitude ?? _defaultCenter.latitude,
              longitude: drop.longitude ?? _defaultCenter.longitude,
              artistName: artistName,
              artistProfileImageUrl: artistProfileImageUrl,
              dropMakerName: dropMakerName,
              dropMakerProfileImageUrl: dropMakerProfileImageUrl,
              description: artPiece?.description ?? "",
              previewImageUrl: artPiece != null && artPiece.photoUrls.isNotEmpty
                  ? artPiece.photoUrls.first
                  : "",
              claimedItemCount: drop.claimedItemCount,
              itemCount: drop.itemCount,
              isFullyClaimed: drop.isFullyClaimed,
              claimedHunters: claimedHunters,
            );
          })
          .toList(growable: false);

      if (!mounted) {
        return;
      }

      final latestDrop = mappedDrops.isNotEmpty ? mappedDrops.last : null;
      final requestedDropId = widget.focusDropId?.trim();
      _MapDropViewModel? focusedDrop;
      if (requestedDropId != null && requestedDropId.isNotEmpty) {
        for (final drop in mappedDrops) {
          if (drop.id == requestedDropId) {
            focusedDrop = drop;
            break;
          }
        }
      }

      final selectedId = focusedDrop?.id ?? _selectedDrop?.id;
      _MapDropViewModel? selected;
      if (selectedId != null) {
        for (final drop in mappedDrops) {
          if (drop.id == selectedId) {
            selected = drop;
            break;
          }
        }
      }

      setState(() {
        _drops = mappedDrops;
        _latestDrop = latestDrop;
        _selectedDrop = selected;
        _center =
            focusedDrop?.position ??
            selected?.position ??
            latestDrop?.position ??
            _defaultCenter;
        _mainMapRadiusKm = appConfiguration.mainMapRadiusKm;
        _unclaimedDropRadiusKm = appConfiguration.unclaimedDropRadiusKm;
        _isLoadingDrops = false;
      });

      final target = focusedDrop?.position ?? selected?.position;
      if (target != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) {
            return;
          }

          _mapController.move(target, 14.5);
        });
      }
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _drops = const [];
        _latestDrop = null;
        _selectedDrop = null;
        _center = _defaultCenter;
        _mainMapRadiusKm = _fallbackMainMapRadiusKm;
        _unclaimedDropRadiusKm = _fallbackUnclaimedRadiusKm;
        _isLoadingDrops = false;
        _loadError = AppLocalizations.of(context)!.mapDataLoadFailed;
      });
    }
  }

  Future<void> _centerOnUserLocation(AppLocalizations l10n) async {
    setState(() => _isCenteringOnUser = true);

    try {
      final isServiceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!isServiceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.locationServiceDisabled)));
        }
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.locationPermissionDenied)),
          );
        }
        return;
      }

      final position = await Geolocator.getCurrentPosition();
      final userCenter = LatLng(position.latitude, position.longitude);

      if (!mounted) {
        return;
      }

      setState(() => _center = userCenter);
      _mapController.move(userCenter, 15);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.mapCenteredOnUser)));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.locationError)));
      }
    } finally {
      if (mounted) {
        setState(() => _isCenteringOnUser = false);
      }
    }
  }

  void _onDropTap(_MapDropViewModel drop) {
    setState(() => _selectedDrop = drop);
    _mapController.move(drop.position, 14.5);
  }

  void _closeDropDetails() => setState(() => _selectedDrop = null);

  void _onLocationSearchChanged(String rawQuery) {
    final query = rawQuery.trim();
    _searchDebounceTimer?.cancel();
    setState(() => _lastSearchQuery = query);

    if (query.length < 2) {
      setState(() {
        _locationSuggestions = const [];
        _isSearchingLocations = false;
      });
      return;
    }

    _searchDebounceTimer = Timer(
      const Duration(milliseconds: 350),
      () => _searchLocationSuggestions(query),
    );
  }

  Future<void> _searchLocationSuggestions(String query) async {
    setState(() => _isSearchingLocations = true);

    final localeTag = Localizations.localeOf(context).toLanguageTag();
    final uri = Uri.https("nominatim.openstreetmap.org", "/search", {
      "q": query,
      "format": "jsonv2",
      "limit": "6",
      "addressdetails": "0",
      "accept-language": localeTag,
    });

    try {
      final response = await http.get(
        uri,
        headers: const {
          "Accept": "application/json",
          "User-Agent": "UrbanArtDropsApp/1.0 (dev)",
        },
      );

      if (!mounted) {
        return;
      }

      if (response.statusCode != 200) {
        setState(() {
          _locationSuggestions = const [];
          _isSearchingLocations = false;
        });
        return;
      }

      final payload = jsonDecode(response.body);
      if (payload is! List<dynamic>) {
        setState(() {
          _locationSuggestions = const [];
          _isSearchingLocations = false;
        });
        return;
      }

      final suggestions = payload
          .whereType<Map<dynamic, dynamic>>()
          .map((item) {
            final displayName = item["display_name"]?.toString() ?? "";
            final lat = double.tryParse(item["lat"]?.toString() ?? "");
            final lon = double.tryParse(item["lon"]?.toString() ?? "");
            if (displayName.isEmpty || lat == null || lon == null) {
              return null;
            }

            return _LocationSuggestion(
              displayName: displayName,
              latitude: lat,
              longitude: lon,
            );
          })
          .whereType<_LocationSuggestion>()
          .toList(growable: false);

      if (_locationSearchController.text.trim() != query) {
        return;
      }

      setState(() {
        _locationSuggestions = suggestions;
        _isSearchingLocations = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _locationSuggestions = const [];
        _isSearchingLocations = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.mapSearchError)),
      );
    }
  }

  void _selectLocationSuggestion(_LocationSuggestion suggestion) {
    final target = LatLng(suggestion.latitude, suggestion.longitude);
    _locationSearchController.text = suggestion.displayName;
    _locationSearchFocusNode.unfocus();

    setState(() {
      _center = target;
      _locationSuggestions = const [];
      _lastSearchQuery = suggestion.displayName;
    });
    _mapController.move(target, 14.5);
  }

  Widget _buildMapPane(bool isDesktop, AppLocalizations l10n) {
    final showNoResults =
        !_isSearchingLocations &&
        _locationSearchFocusNode.hasFocus &&
        _locationSearchController.text.trim().length >= 2 &&
        _locationSuggestions.isEmpty &&
        _lastSearchQuery == _locationSearchController.text.trim();
    final unclaimedFillColor = Theme.of(
      context,
    ).colorScheme.primary.withValues(alpha: 0.14);
    final unclaimedBorderColor = Theme.of(
      context,
    ).colorScheme.primary.withValues(alpha: 0.72);

    return Stack(
      children: [
        Positioned.fill(
          child: FlutterMap(
            mapController: _mapController,
            options: MapOptions(initialCenter: _center, initialZoom: 13.5),
            children: [
              TileLayer(
                urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                userAgentPackageName: "urban.art.drops.app",
              ),
              CircleLayer(
                circles: _drops
                    .where((drop) => !drop.isFullyClaimed)
                    .map(
                      (drop) => CircleMarker(
                        point: drop.position,
                        radius: _unclaimedDropRadiusKm * 1000,
                        useRadiusInMeter: true,
                        color: unclaimedFillColor,
                        borderColor: unclaimedBorderColor,
                        borderStrokeWidth: 2,
                      ),
                    )
                    .toList(growable: false),
              ),
              MarkerLayer(
                markers: _drops
                    .where((drop) => drop.isFullyClaimed)
                    .map(
                      (drop) => Marker(
                        point: drop.position,
                        width: 120,
                        height: 136,
                        child: GestureDetector(
                          onTap: () => _onDropTap(drop),
                          child: Tooltip(
                            message: drop.title,
                            child: _DropPin(
                              imageUrl: drop.previewImageUrl,
                              isSelected: _selectedDrop?.id == drop.id,
                              isFullyClaimed: drop.isFullyClaimed,
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(growable: false),
              ),
            ],
          ),
        ),
        Positioned(
          top: 12,
          left: 12,
          right: 12,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: AppGlassPanel(
                radius: 28,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _locationSearchController,
                            focusNode: _locationSearchFocusNode,
                            onChanged: _onLocationSearchChanged,
                            decoration: InputDecoration(
                              hintText: l10n.mapSearchLocationHint,
                              prefixIcon: const Icon(Icons.search),
                              suffixIcon: _isSearchingLocations
                                  ? const Padding(
                                      padding: EdgeInsets.all(12),
                                      child: SizedBox(
                                        height: 16,
                                        width: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    )
                                  : _locationSearchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.close),
                                      onPressed: () {
                                        _locationSearchController.clear();
                                        _onLocationSearchChanged("");
                                      },
                                    )
                                  : null,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filledTonal(
                          tooltip: l10n.centerOnMyLocation,
                          onPressed: _isCenteringOnUser
                              ? null
                              : () => _centerOnUserLocation(l10n),
                          icon: _isCenteringOnUser
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.my_location_outlined),
                        ),
                        IconButton.filledTonal(
                          tooltip: l10n.refreshAction,
                          onPressed: _isLoadingDrops ? null : _loadMapData,
                          icon: const Icon(Icons.refresh),
                        ),
                      ],
                    ),
                    if (_locationSuggestions.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 220),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: _locationSuggestions.length,
                          itemBuilder: (context, index) {
                            final suggestion = _locationSuggestions[index];
                            return ListTile(
                              dense: true,
                              leading: const Icon(Icons.place_outlined),
                              title: Text(
                                suggestion.displayName,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              onTap: () =>
                                  _selectLocationSuggestion(suggestion),
                            );
                          },
                        ),
                      ),
                    ],
                    if (showNoResults)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            l10n.mapSearchNoResults,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (!isDesktop && _selectedDrop == null)
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: AppGlassPanel(
              radius: 22,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Text(l10n.mapShowDropDetailsHint),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final header = _latestDrop != null
        ? l10n.mapCenteredOnLatestDrop(_latestDrop!.title)
        : l10n.mapNoDrops;

    return PageShell(
      title: l10n.navMap,
      expandBodyToViewport: true,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 980;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                child: AppGlassPanel(
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          header,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      if (_isLoadingDrops)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Text(
                            l10n.loadingData,
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              if (_loadError != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _loadError!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                ),
              Expanded(
                child: isDesktop
                    ? Row(
                        children: [
                          Expanded(child: _buildMapPane(true, l10n)),
                          if (_selectedDrop != null)
                            SizedBox(
                              width: 360,
                              child: _DropDetailsPanel(
                                l10n: l10n,
                                drop: _selectedDrop!,
                                onClose: _closeDropDetails,
                                compact: false,
                              ),
                            ),
                        ],
                      )
                    : Stack(
                        children: [
                          Positioned.fill(child: _buildMapPane(false, l10n)),
                          if (_selectedDrop != null)
                            Align(
                              alignment: Alignment.bottomCenter,
                              child: Padding(
                                padding: const EdgeInsets.all(8),
                                child: _DropDetailsPanel(
                                  l10n: l10n,
                                  drop: _selectedDrop!,
                                  onClose: _closeDropDetails,
                                  compact: true,
                                ),
                              ),
                            ),
                        ],
                      ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.mapRadiusLabel(_mainMapRadiusKm),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.mapUnclaimedRadiusLabel(_unclaimedDropRadiusKm),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DropPin extends StatelessWidget {
  const _DropPin({
    required this.imageUrl,
    required this.isSelected,
    required this.isFullyClaimed,
  });

  final String imageUrl;
  final bool isSelected;
  final bool isFullyClaimed;

  @override
  Widget build(BuildContext context) {
    final borderColor = isFullyClaimed
        ? Colors.grey.shade400
        : isSelected
        ? Theme.of(context).colorScheme.primary
        : Colors.white;
    final pinColor = isFullyClaimed
        ? Colors.grey.shade600
        : isSelected
        ? Theme.of(context).colorScheme.primary
        : Colors.redAccent;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: borderColor, width: 2.5),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 5,
                offset: Offset(0, 2),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              imageUrl.isEmpty
                  ? const ColoredBox(
                      color: Color(0xFFE7ECEE),
                      child: Icon(Icons.image_not_supported_outlined, size: 20),
                    )
                  : SizedBox.expand(
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        alignment: Alignment.center,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) {
                            return child;
                          }

                          return const ColoredBox(color: Color(0xFFE7ECEE));
                        },
                        errorBuilder: (context, error, stackTrace) =>
                            const ColoredBox(
                              color: Color(0xFFE7ECEE),
                              child: Icon(
                                Icons.image_not_supported_outlined,
                                size: 20,
                              ),
                            ),
                      ),
                    ),
              if (isFullyClaimed)
                ColoredBox(color: Colors.grey.shade500.withValues(alpha: 0.4)),
            ],
          ),
        ),
        Icon(Icons.location_on, color: pinColor, size: 44),
      ],
    );
  }
}

class _DropDetailsPanel extends StatelessWidget {
  const _DropDetailsPanel({
    required this.l10n,
    required this.drop,
    required this.onClose,
    required this.compact,
  });

  final AppLocalizations l10n;
  final _MapDropViewModel drop;
  final VoidCallback onClose;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final panel = Material(
      color: Theme.of(context).colorScheme.surface,
      elevation: compact ? 10 : 0,
      borderRadius: compact
          ? const BorderRadius.vertical(top: Radius.circular(18))
          : BorderRadius.zero,
      child: Column(
        children: [
          ListTile(
            title: Text(l10n.mapDropDetails),
            trailing: IconButton(
              tooltip: l10n.mapCloseDetails,
              onPressed: onClose,
              icon: const Icon(Icons.close),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: drop.previewImageUrl.isEmpty
                        ? const ColoredBox(
                            color: Color(0xFFE7ECEE),
                            child: Icon(Icons.image_not_supported_outlined),
                          )
                        : Image.network(
                            drop.previewImageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const ColoredBox(
                                  color: Color(0xFFE7ECEE),
                                  child: Icon(
                                    Icons.image_not_supported_outlined,
                                  ),
                                ),
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  drop.title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  drop.subtitle,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    UserIdentityChip(
                      label: l10n.mapArtistLabel,
                      displayName: drop.artistName,
                      imageUrl: drop.artistProfileImageUrl,
                    ),
                    UserIdentityChip(
                      label: l10n.mapDropMakerLabel,
                      displayName: drop.dropMakerName,
                      imageUrl: drop.dropMakerProfileImageUrl,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.mapDescriptionLabel,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 4),
                Text(drop.description.isEmpty ? "-" : drop.description),
                const SizedBox(height: 12),
                Text(
                  "${l10n.mapClaimedByLabel}: ${l10n.claimedItemsValue("${drop.claimedItemCount}", "${drop.itemCount}")}",
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.claimedHuntersTitle,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 6),
                HunterIdentityList(
                  hunters: drop.claimedHunters,
                  emptyLabel: l10n.mapUnclaimedLabel,
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (!compact) {
      return panel;
    }

    return SizedBox(height: 300, child: panel);
  }
}

class _MapDropViewModel {
  const _MapDropViewModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.latitude,
    required this.longitude,
    required this.artistName,
    required this.artistProfileImageUrl,
    required this.dropMakerName,
    required this.dropMakerProfileImageUrl,
    required this.description,
    required this.previewImageUrl,
    required this.claimedItemCount,
    required this.itemCount,
    required this.isFullyClaimed,
    required this.claimedHunters,
  });

  final String id;
  final String title;
  final String subtitle;
  final double latitude;
  final double longitude;
  final String artistName;
  final String? artistProfileImageUrl;
  final String dropMakerName;
  final String? dropMakerProfileImageUrl;
  final String description;
  final String previewImageUrl;
  final int claimedItemCount;
  final int itemCount;
  final bool isFullyClaimed;
  final List<HunterIdentity> claimedHunters;

  LatLng get position => LatLng(latitude, longitude);
}

class _LocationSuggestion {
  const _LocationSuggestion({
    required this.displayName,
    required this.latitude,
    required this.longitude,
  });

  final String displayName;
  final double latitude;
  final double longitude;
}
