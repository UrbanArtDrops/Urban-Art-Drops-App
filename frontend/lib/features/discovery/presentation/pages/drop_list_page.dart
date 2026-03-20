import "dart:async";
import "dart:convert";

import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:geolocator/geolocator.dart";
import "package:go_router/go_router.dart";
import "package:http/http.dart" as http;
import "package:latlong2/latlong.dart";
import "package:urban_art_drops_app/l10n/app_localizations.dart";

import "../../../authentication/presentation/bloc/auth_session_cubit.dart";
import "../../../../shared/models/app_models.dart";
import "../../../../shared/models/hunter_identity.dart";
import "../../../../shared/services/app_api_client.dart";
import "../../../../shared/widgets/drop_overview_card.dart";
import "../../../../shared/widgets/page_shell.dart";

class DropListPage extends StatefulWidget {
  const DropListPage({super.key});

  @override
  State<DropListPage> createState() => _DropListPageState();
}

class _DropListPageState extends State<DropListPage> {
  final AppApiClient _apiClient = AppApiClient();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final FocusNode _locationFocusNode = FocusNode();

  List<DropModel> _drops = const [];
  Map<String, ArtPieceModel> _artPiecesById = const {};
  Map<String, ManagedUser> _usersById = const {};
  AppConfigurationModel _appConfiguration = AppConfigurationModel.defaults;
  LatLng? _referenceLocation;
  String? _referenceLocationLabel;
  List<_LocationSuggestion> _locationSuggestions = const [];
  Timer? _locationSearchDebounce;
  String _lastLocationQuery = "";
  bool _isResolvingUserLocation = false;
  bool _isSearchingLocations = false;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _locationFocusNode.addListener(() {
      if (!_locationFocusNode.hasFocus && mounted) {
        setState(() => _locationSuggestions = const []);
      }
    });
    _loadDrops();
  }

  @override
  void dispose() {
    _locationSearchDebounce?.cancel();
    _searchController.dispose();
    _locationController.dispose();
    _locationFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadDrops() async {
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

      final drops = (results[0] as List<DropModel>)
          .where((drop) => drop.isPublished)
          .toList(growable: false);
      final artById = <String, ArtPieceModel>{
        for (final art in (results[1] as List<ArtPieceModel>)) art.id: art,
      };
      final usersById = <String, ManagedUser>{
        for (final user in (results[2] as List<ManagedUser>)) user.id: user,
      };

      setState(() {
        _drops = drops;
        _artPiecesById = artById;
        _usersById = usersById;
        _appConfiguration = appConfiguration;
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

  Future<void> _resolveUserLocation(AppLocalizations l10n) async {
    setState(() => _isResolvingUserLocation = true);

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
      final resolvedLocationLabel = await _resolveLocationLabelFromCoordinates(
        latitude: position.latitude,
        longitude: position.longitude,
      );
      if (!mounted) {
        return;
      }

      final locationLabel = resolvedLocationLabel ?? l10n.centerOnMyLocation;
      setState(() {
        _referenceLocation = LatLng(position.latitude, position.longitude);
        _referenceLocationLabel = locationLabel;
        _locationController.text = locationLabel;
        _lastLocationQuery = locationLabel;
        _locationSuggestions = const [];
      });
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
        setState(() => _isResolvingUserLocation = false);
      }
    }
  }

  Future<String?> _resolveLocationLabelFromCoordinates({
    required double latitude,
    required double longitude,
  }) async {
    final localeTag = Localizations.localeOf(context).toLanguageTag();
    final uri = Uri.https("nominatim.openstreetmap.org", "/reverse", {
      "lat": latitude.toString(),
      "lon": longitude.toString(),
      "format": "jsonv2",
      "addressdetails": "1",
      "accept-language": localeTag,
    });

    try {
      final response = await http.get(
        uri,
        headers: const {
          "Accept": "application/json",
          "User-Agent": "UrbanArtDropsApp/1.0 (drop-list-reverse)",
        },
      );

      if (response.statusCode != 200) {
        return null;
      }

      final payload = jsonDecode(response.body);
      if (payload is! Map<dynamic, dynamic>) {
        return null;
      }

      final address = payload["address"];
      final displayName = payload["display_name"]?.toString().trim() ?? "";
      if (address is! Map<dynamic, dynamic>) {
        return displayName.isEmpty ? null : displayName;
      }

      final localityCandidates = [
        address["city"],
        address["town"],
        address["village"],
        address["hamlet"],
        address["municipality"],
        address["county"],
      ];
      final locality = localityCandidates
          .map((value) => value?.toString().trim() ?? "")
          .firstWhere((value) => value.isNotEmpty, orElse: () => "");
      final postcode = address["postcode"]?.toString().trim() ?? "";

      if (locality.isNotEmpty && postcode.isNotEmpty) {
        return "$locality ($postcode)";
      }
      if (locality.isNotEmpty) {
        return locality;
      }
      if (postcode.isNotEmpty) {
        return postcode;
      }
      if (displayName.isNotEmpty) {
        return displayName;
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  void _clearReferenceLocation() {
    setState(() {
      _referenceLocation = null;
      _referenceLocationLabel = null;
      _locationController.clear();
      _locationSuggestions = const [];
      _lastLocationQuery = "";
    });
  }

  void _onLocationQueryChanged(String rawQuery) {
    final query = rawQuery.trim();
    _locationSearchDebounce?.cancel();
    setState(() => _lastLocationQuery = query);

    if (query.length < 2) {
      setState(() {
        _locationSuggestions = const [];
        _isSearchingLocations = false;
      });
      return;
    }

    _locationSearchDebounce = Timer(
      const Duration(milliseconds: 350),
      () => _searchLocations(query),
    );
  }

  Future<void> _searchLocations(String query) async {
    setState(() => _isSearchingLocations = true);

    final localeTag = Localizations.localeOf(context).toLanguageTag();
    final uri = Uri.https("nominatim.openstreetmap.org", "/search", {
      "q": query,
      "format": "jsonv2",
      "limit": "6",
      "addressdetails": "1",
      "accept-language": localeTag,
    });

    try {
      final response = await http.get(
        uri,
        headers: const {
          "Accept": "application/json",
          "User-Agent": "UrbanArtDropsApp/1.0 (drop-list)",
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
          .map((entry) {
            final displayName = entry["display_name"]?.toString() ?? "";
            final lat = double.tryParse(entry["lat"]?.toString() ?? "");
            final lon = double.tryParse(entry["lon"]?.toString() ?? "");
            if (displayName.isEmpty || lat == null || lon == null) {
              return null;
            }

            final address = entry["address"];
            final postcode = address is Map<dynamic, dynamic>
                ? address["postcode"]?.toString()
                : null;
            final label = (postcode != null && postcode.trim().isNotEmpty)
                ? "$displayName ($postcode)"
                : displayName;

            return _LocationSuggestion(
              label: label,
              latitude: lat,
              longitude: lon,
            );
          })
          .whereType<_LocationSuggestion>()
          .toList(growable: false);

      if (_locationController.text.trim() != query) {
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

  void _selectLocation(_LocationSuggestion suggestion) {
    _locationFocusNode.unfocus();
    setState(() {
      _referenceLocation = LatLng(suggestion.latitude, suggestion.longitude);
      _referenceLocationLabel = suggestion.label;
      _locationController.text = suggestion.label;
      _locationSuggestions = const [];
      _lastLocationQuery = suggestion.label;
    });
  }

  void _openDropOnMap(String dropId) {
    final route = Uri(
      path: "/",
      queryParameters: {"focusDropId": dropId},
    ).toString();
    context.go(route);
  }

  List<_DropListViewModel> _buildViewModels(AppLocalizations l10n) {
    final query = _searchController.text.trim().toLowerCase();

    final entries = _drops
        .where((drop) {
          if (query.isEmpty) {
            return true;
          }

          final art = _artPiecesById[drop.artPieceId];
          final title = (art?.title ?? "").toLowerCase();
          final description = (art?.description ?? "").toLowerCase();
          final dropId = drop.id.toLowerCase();
          return title.contains(query) ||
              description.contains(query) ||
              dropId.contains(query);
        })
        .map((drop) {
          final art = _artPiecesById[drop.artPieceId];
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

          final distanceKm =
              _referenceLocation != null &&
                  drop.latitude != null &&
                  drop.longitude != null
              ? const Distance().as(
                  LengthUnit.Kilometer,
                  _referenceLocation!,
                  LatLng(drop.latitude!, drop.longitude!),
                )
              : null;

          return _DropListViewModel(
            id: drop.id,
            title: art?.title ?? l10n.dropFallbackTitle(drop.id),
            subtitle: art?.subtitle.trim().isNotEmpty == true
                ? art!.subtitle
                : "${l10n.mapArtistLabel}: $artistName · ${l10n.mapDropMakerLabel}: $dropMakerName",
            artistName: artistName,
            artistProfileImageUrl: artistProfileImageUrl,
            dropMakerName: dropMakerName,
            dropMakerProfileImageUrl: dropMakerProfileImageUrl,
            description: _buildDropListDescription(
              artDescription: art?.description ?? "",
              dropMakerComment: drop.dropMakerComment,
              socialChannels: drop.socialChannels,
              l10n: l10n,
            ),
            artPhotoUrls: art?.photoUrls ?? const [],
            locationPhotoUrls: drop.locationPhotoUrls,
            claimedHunters: claimedHunters,
            latitude: drop.latitude,
            longitude: drop.longitude,
            claimedItemCount: drop.claimedItemCount,
            itemCount: drop.itemCount,
            isFullyClaimed: drop.isFullyClaimed,
            unclaimedDropRadiusKm: _appConfiguration.unclaimedDropRadiusKm,
            distanceKm: distanceKm,
          );
        })
        .toList(growable: false);

    entries.sort((a, b) {
      if (_referenceLocation != null) {
        final firstDistance = a.distanceKm;
        final secondDistance = b.distanceKm;
        if (firstDistance != null && secondDistance != null) {
          final distanceCompare = firstDistance.compareTo(secondDistance);
          if (distanceCompare != 0) {
            return distanceCompare;
          }
        } else if (firstDistance != null) {
          return -1;
        } else if (secondDistance != null) {
          return 1;
        }
      }

      return a.title.toLowerCase().compareTo(b.title.toLowerCase());
    });

    return entries;
  }

  Widget _buildLocationSuggestions(AppLocalizations l10n) {
    final showNoResults =
        !_isSearchingLocations &&
        _locationFocusNode.hasFocus &&
        _locationController.text.trim().length >= 2 &&
        _locationSuggestions.isEmpty &&
        _lastLocationQuery == _locationController.text.trim();

    if (_locationSuggestions.isEmpty && !showNoResults) {
      return const SizedBox.shrink();
    }

    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        children: [
          if (_locationSuggestions.isNotEmpty)
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 220),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _locationSuggestions.length,
                separatorBuilder: (context, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final suggestion = _locationSuggestions[index];
                  return ListTile(
                    dense: true,
                    leading: const Icon(Icons.location_on_outlined),
                    title: Text(
                      suggestion.label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () => _selectLocation(suggestion),
                  );
                },
              ),
            ),
          if (showNoResults)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authState = context.watch<AuthSessionCubit>().state;
    final canOpenWizard =
        authState.isAuthenticated &&
        (authState.role == AppUserRole.artist ||
            authState.role == AppUserRole.dropMaker);
    final viewModels = _buildViewModels(l10n);

    return PageShell(
      title: l10n.navDrops,
      floatingActionButton: canOpenWizard
          ? FloatingActionButton.extended(
              heroTag: "make-drop-wizard-fab",
              onPressed: () => context.go("/drop-maker/make-drop-wizard"),
              icon: const Icon(Icons.auto_fix_high_outlined),
              label: Text(l10n.makeDropWizardFabLabel),
            )
          : null,
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
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                  child: Column(
                    children: [
                      TextField(
                        controller: _searchController,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          labelText: l10n.searchDropsHint,
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _searchController.text.isEmpty
                              ? null
                              : IconButton(
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {});
                                  },
                                  icon: const Icon(Icons.clear),
                                ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _locationController,
                              focusNode: _locationFocusNode,
                              onChanged: _onLocationQueryChanged,
                              decoration: InputDecoration(
                                hintText: l10n.dropListLocationHint,
                                prefixIcon: const Icon(Icons.place_outlined),
                                suffixIcon: _isSearchingLocations
                                    ? const Padding(
                                        padding: EdgeInsets.all(12),
                                        child: SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        ),
                                      )
                                    : null,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton.filledTonal(
                            tooltip: l10n.centerOnMyLocation,
                            onPressed: _isResolvingUserLocation
                                ? null
                                : () => _resolveUserLocation(l10n),
                            icon: _isResolvingUserLocation
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.my_location_outlined),
                          ),
                          if (_referenceLocation != null) ...[
                            const SizedBox(width: 8),
                            IconButton(
                              tooltip: l10n.cancelAction,
                              onPressed: _clearReferenceLocation,
                              icon: const Icon(Icons.close),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      _buildLocationSuggestions(l10n),
                      if (_referenceLocation != null &&
                          _referenceLocationLabel != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              l10n.dropListSortingByDistance(
                                _referenceLocationLabel!,
                              ),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: viewModels.isEmpty
                      ? Center(child: Text(l10n.dropListEmpty))
                      : RefreshIndicator(
                          onRefresh: _loadDrops,
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                            itemCount: viewModels.length,
                            separatorBuilder: (context, _) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final viewModel = viewModels[index];
                              return DropOverviewCard(
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
                                latitude: viewModel.latitude,
                                longitude: viewModel.longitude,
                                distanceKm: viewModel.distanceKm,
                                onTap: () =>
                                    context.go("/hunter/drops/${viewModel.id}"),
                                onMiniMapTap:
                                    viewModel.latitude != null &&
                                        viewModel.longitude != null
                                    ? () => _openDropOnMap(viewModel.id)
                                    : null,
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

class _DropListViewModel {
  const _DropListViewModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.artistName,
    required this.artistProfileImageUrl,
    required this.dropMakerName,
    required this.dropMakerProfileImageUrl,
    required this.description,
    required this.artPhotoUrls,
    required this.locationPhotoUrls,
    required this.claimedHunters,
    required this.latitude,
    required this.longitude,
    required this.claimedItemCount,
    required this.itemCount,
    required this.isFullyClaimed,
    required this.unclaimedDropRadiusKm,
    required this.distanceKm,
  });

  final String id;
  final String title;
  final String subtitle;
  final String artistName;
  final String? artistProfileImageUrl;
  final String dropMakerName;
  final String? dropMakerProfileImageUrl;
  final String description;
  final List<String> artPhotoUrls;
  final List<String> locationPhotoUrls;
  final List<HunterIdentity> claimedHunters;
  final double? latitude;
  final double? longitude;
  final int claimedItemCount;
  final int itemCount;
  final bool isFullyClaimed;
  final int unclaimedDropRadiusKm;
  final double? distanceKm;

  List<String> get galleryUrls => [...artPhotoUrls, ...locationPhotoUrls];
}

class _LocationSuggestion {
  const _LocationSuggestion({
    required this.label,
    required this.latitude,
    required this.longitude,
  });

  final String label;
  final double latitude;
  final double longitude;
}

String _buildDropListDescription({
  required String artDescription,
  required String? dropMakerComment,
  required List<String> socialChannels,
  required AppLocalizations l10n,
}) {
  final sections = <String>[];
  final trimmedDescription = artDescription.trim();
  if (trimmedDescription.isNotEmpty) {
    sections.add(trimmedDescription);
  }

  final trimmedComment = dropMakerComment?.trim();
  if (trimmedComment != null && trimmedComment.isNotEmpty) {
    sections.add("${l10n.dropMakerCommentLabel}: $trimmedComment");
  }

  if (socialChannels.isNotEmpty) {
    sections.add(
      "${l10n.dropSocialChannelsLabel}: ${socialChannels.join(", ")}",
    );
  }

  return sections.join("\n\n");
}
