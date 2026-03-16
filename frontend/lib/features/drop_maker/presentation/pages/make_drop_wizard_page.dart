import "dart:async";

import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:geolocator/geolocator.dart";
import "package:go_router/go_router.dart";
import "package:qr_flutter/qr_flutter.dart";
import "package:urban_art_drops_app/l10n/app_localizations.dart";

import "../../../../shared/models/app_models.dart";
import "../../../../shared/services/app_api_client.dart";
import "../../../../shared/services/external_download_launcher.dart";
import "../../../../shared/services/local_photo_picker.dart";
import "../../../../shared/services/location_lookup_service.dart";
import "../../../../shared/widgets/page_shell.dart";
import "../../../../shared/widgets/source_image.dart";
import "../../../authentication/presentation/bloc/auth_session_cubit.dart";
import "../../domain/make_drop_wizard_draft.dart";

class MakeDropWizardPage extends StatefulWidget {
  const MakeDropWizardPage({
    this.preselectedArtPieceId,
    AppApiClient? apiClient,
    LocalPhotoPicker? photoPicker,
    LocationLookupService? locationLookupService,
    ExternalDownloadLauncher? downloadLauncher,
    super.key,
  }) : _apiClient = apiClient,
       _photoPicker = photoPicker,
       _locationLookupService = locationLookupService,
       _downloadLauncher = downloadLauncher;

  final String? preselectedArtPieceId;
  final AppApiClient? _apiClient;
  final LocalPhotoPicker? _photoPicker;
  final LocationLookupService? _locationLookupService;
  final ExternalDownloadLauncher? _downloadLauncher;

  @override
  State<MakeDropWizardPage> createState() => _MakeDropWizardPageState();
}

class _MakeDropWizardPageState extends State<MakeDropWizardPage> {
  late final AppApiClient _apiClient = widget._apiClient ?? AppApiClient();
  late final LocalPhotoPicker _photoPicker =
      widget._photoPicker ?? const FilePickerLocalPhotoPicker();
  late final LocationLookupService _locationLookupService =
      widget._locationLookupService ?? OpenStreetMapLocationLookupService();
  late final ExternalDownloadLauncher _downloadLauncher =
      widget._downloadLauncher ?? const UrlLauncherExternalDownloadLauncher();

  final TextEditingController _itemCountController = TextEditingController(
    text: "1",
  );
  final TextEditingController _portableItemCountController =
      TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final FocusNode _locationFocusNode = FocusNode();

  List<ArtPieceModel> _artPieces = const [];
  MakeDropWizardDraft _draft = MakeDropWizardDraft.initial();
  List<LocationLookupSuggestion> _locationSuggestions = const [];
  Timer? _locationSearchDebounce;
  String _lastLocationQuery = "";
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isSearchingLocations = false;
  bool _isResolvingUserLocation = false;
  String? _loadError;
  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    _locationFocusNode.addListener(() {
      if (!_locationFocusNode.hasFocus && mounted) {
        setState(() => _locationSuggestions = const []);
      }
    });
    _loadDependencies();
  }

  @override
  void dispose() {
    _locationSearchDebounce?.cancel();
    _itemCountController.dispose();
    _portableItemCountController.dispose();
    _locationController.dispose();
    _locationFocusNode.dispose();
    super.dispose();
  }

  ArtPieceModel? get _selectedArtPiece {
    final artPieceId = _draft.artPieceId;
    for (final artPiece in _artPieces) {
      if (artPiece.id == artPieceId) {
        return artPiece;
      }
    }

    return null;
  }

  Future<void> _loadDependencies() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    final authState = context.read<AuthSessionCubit>().state;
    if (!authState.isAuthenticated) {
      setState(() {
        _loadError = AppLocalizations.of(context)!.makeDropMissingCurrentUser;
        _isLoading = false;
      });
      return;
    }

    try {
      final results = await Future.wait<Object>([
        _apiClient.getArtPieces(),
        _apiClient.getUsers(),
      ]);
      if (!mounted) {
        return;
      }

      final users = (results[1] as List<ManagedUser>).toList(growable: false);
      final currentUser = _resolveCurrentUser(authState, users);
      if (currentUser == null) {
        setState(() {
          _loadError = AppLocalizations.of(context)!.makeDropMissingCurrentUser;
          _isLoading = false;
        });
        return;
      }

      final visibleArtPieces = _resolveVisibleArtPieces(
        authState: authState,
        currentUserId: currentUser.id,
        artPieces: (results[0] as List<ArtPieceModel>),
      );
      final selectedArtPieceId = _resolveSelectedArtPieceId(
        visibleArtPieces,
        widget.preselectedArtPieceId,
        _draft.artPieceId,
      );

      final nextDraft = _draft.copyWith(
        artPieceId: selectedArtPieceId ?? "",
        dropMakerId: currentUser.id,
      );

      _itemCountController.text = nextDraft.itemCount.toString();
      _portableItemCountController.text =
          nextDraft.portableItemCount?.toString() ?? "";
      _locationController.text = nextDraft.locationLabel;

      setState(() {
        _artPieces = visibleArtPieces;
        _draft = nextDraft;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loadError = AppLocalizations.of(context)!.artPiecesLoadFailed;
        _isLoading = false;
      });
    }
  }

  ManagedUser? _resolveCurrentUser(
    AuthSessionState authState,
    List<ManagedUser> users,
  ) {
    final displayName = authState.displayName?.trim().toLowerCase();
    if (displayName == null || displayName.isEmpty) {
      return null;
    }

    for (final user in users) {
      if (user.userName.toLowerCase() == displayName ||
          user.email.toLowerCase() == displayName) {
        return user;
      }
    }

    return null;
  }

  List<ArtPieceModel> _resolveVisibleArtPieces({
    required AuthSessionState authState,
    required String currentUserId,
    required List<ArtPieceModel> artPieces,
  }) {
    final visible = artPieces
        .where((artPiece) {
          if (artPiece.isPublished) {
            return true;
          }

          return authState.role == AppUserRole.artist &&
              artPiece.artistId == currentUserId;
        })
        .toList(growable: false);
    visible.sort((first, second) => first.title.compareTo(second.title));
    return visible;
  }

  String? _resolveSelectedArtPieceId(
    List<ArtPieceModel> artPieces,
    String? preferredId,
    String? currentId,
  ) {
    if (artPieces.isEmpty) {
      return null;
    }

    for (final candidate in [preferredId, currentId]) {
      if (candidate != null &&
          artPieces.any((artPiece) => artPiece.id == candidate)) {
        return candidate;
      }
    }

    return artPieces.first.id;
  }

  void _selectArtPiece(ArtPieceModel artPiece) {
    if (_draft.artPieceId == artPiece.id) {
      return;
    }

    _locationController.clear();
    setState(() {
      _draft = _draft.copyWith(
        artPieceId: artPiece.id,
        clearDropId: true,
        items: const [],
        downloadConfirmed: false,
        locationLabel: "",
        clearLatitude: true,
        clearLongitude: true,
        locationPhotoSources: const [],
        locationPhotoLabels: const [],
        publishAfterFinish: false,
      );
      _locationSuggestions = const [];
      _lastLocationQuery = "";
      _currentStep = _currentStep > 1 ? 1 : _currentStep;
    });
  }

  Future<void> _downloadProductionReference() async {
    final selectedArtPiece = _selectedArtPiece;
    final l10n = AppLocalizations.of(context)!;
    if (selectedArtPiece == null) {
      return;
    }

    final downloadUrl =
        selectedArtPiece.assetFile?.url ??
        (selectedArtPiece.photoUrls.isEmpty
            ? null
            : selectedArtPiece.photoUrls.first);
    if (downloadUrl == null || downloadUrl.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.makeDropDownloadUnavailable)));
      return;
    }

    final started = await _downloadLauncher.launchDownload(downloadUrl);
    if (!mounted) {
      return;
    }

    if (!started) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.makeDropDownloadFailed)));
      return;
    }

    setState(() {
      _draft = _draft.copyWith(downloadConfirmed: true);
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.makeDropDownloadSet)));
  }

  void _syncCreationInputsIntoDraft() {
    final parsedItemCount = int.tryParse(_itemCountController.text.trim()) ?? 0;
    final isStationary = _draft.isStationary;
    final parsedPortableCount = isStationary
        ? null
        : int.tryParse(_portableItemCountController.text.trim());

    _draft = _draft.copyWith(
      itemCount: parsedItemCount,
      portableItemCount: parsedPortableCount,
      clearPortableItemCount: isStationary,
    );
  }

  Future<void> _persistDraft() async {
    _syncCreationInputsIntoDraft();
    final savedDrop = _draft.hasPersistedDrop
        ? await _apiClient.updateDrop(_draft.dropId!, _draft.toCreateInput())
        : await _apiClient.createDrop(_draft.toCreateInput());

    if (!mounted) {
      return;
    }

    setState(() {
      _draft = _draft.withPersistedDrop(savedDrop);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppLocalizations.of(
            context,
          )!.makeDropDraftSaved(savedDrop.items.length),
        ),
      ),
    );
  }

  Future<void> _finishWizard() async {
    _syncCreationInputsIntoDraft();
    final savedDrop = await _apiClient.updateDrop(
      _draft.dropId!,
      _draft.toCreateInput(),
    );
    if (_draft.publishAfterFinish != savedDrop.isPublished) {
      await _apiClient.setDropPublished(
        savedDrop.id,
        _draft.publishAfterFinish,
      );
    }

    if (!mounted) {
      return;
    }

    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _draft.publishAfterFinish
              ? l10n.makeDropFinishedPublished
              : l10n.makeDropWizardFinished,
        ),
      ),
    );
    context.go("/drop-maker/drops");
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

  void _goToNextStep() {
    final l10n = AppLocalizations.of(context)!;

    switch (_currentStep) {
      case 0:
        setState(() => _currentStep = 1);
        return;
      case 1:
        if (_selectedArtPiece == null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.makeDropSelectArtFirst)));
          return;
        }
        setState(() => _currentStep = 2);
        return;
      case 2:
        if (!_draft.downloadConfirmed) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.makeDropConfirmDownloadFirst)),
          );
          return;
        }
        setState(() => _currentStep = 3);
        return;
      case 3:
        _syncCreationInputsIntoDraft();
        final errors = _draft.validateCreationStep();
        if (errors.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_creationErrorMessage(l10n, errors.first))),
          );
          return;
        }
        _withSaving(() async {
          await _persistDraft();
          if (mounted) {
            setState(() => _currentStep = 4);
          }
        });
        return;
      case 4:
        if (_draft.items.isEmpty) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.makeDropGenerateQrFirst)));
          return;
        }
        setState(() => _currentStep = 5);
        return;
      case 5:
        final errors = _draft.validatePlacementStep();
        if (errors.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_placementErrorMessage(l10n, errors.first))),
          );
          return;
        }
        _withSaving(_finishWizard);
        return;
      default:
        return;
    }
  }

  void _goToPreviousStep() {
    if (_currentStep == 0) {
      return;
    }

    setState(() => _currentStep -= 1);
  }

  String _creationErrorMessage(
    AppLocalizations l10n,
    MakeDropWizardDraftValidationError error,
  ) {
    switch (error) {
      case MakeDropWizardDraftValidationError.missingArtPiece:
        return l10n.makeDropSelectArtFirst;
      case MakeDropWizardDraftValidationError.missingDropMaker:
        return l10n.makeDropMissingCurrentUser;
      case MakeDropWizardDraftValidationError.invalidItemCount:
        return l10n.makeDropItemCountInvalid;
      case MakeDropWizardDraftValidationError.invalidPortableItemCount:
        return l10n.makeDropPortableItemCountInvalid;
      case MakeDropWizardDraftValidationError.missingLocation:
      case MakeDropWizardDraftValidationError.missingLocationPhotos:
        return l10n.genericSaveError;
    }
  }

  String _placementErrorMessage(
    AppLocalizations l10n,
    MakeDropWizardDraftValidationError error,
  ) {
    switch (error) {
      case MakeDropWizardDraftValidationError.missingLocation:
        return l10n.makeDropLocationRequired;
      case MakeDropWizardDraftValidationError.missingLocationPhotos:
        return l10n.makeDropLocationPhotosRequired;
      case MakeDropWizardDraftValidationError.missingArtPiece:
      case MakeDropWizardDraftValidationError.missingDropMaker:
      case MakeDropWizardDraftValidationError.invalidItemCount:
      case MakeDropWizardDraftValidationError.invalidPortableItemCount:
        return l10n.genericSaveError;
    }
  }

  void _onLocationQueryChanged(String rawQuery) {
    final query = rawQuery.trim();
    _locationSearchDebounce?.cancel();
    setState(() {
      _lastLocationQuery = query;
      _draft = _draft.copyWith(
        locationLabel: query,
        clearLatitude: true,
        clearLongitude: true,
      );
    });

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

    try {
      final suggestions = await _locationLookupService.searchLocations(
        query: query,
        localeTag: Localizations.localeOf(context).toLanguageTag(),
      );

      if (!mounted || _locationController.text.trim() != query) {
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

  void _selectLocation(LocationLookupSuggestion suggestion) {
    _locationFocusNode.unfocus();
    _locationController.text = suggestion.label;
    setState(() {
      _locationSuggestions = const [];
      _lastLocationQuery = suggestion.label;
      _draft = _draft.copyWith(
        locationLabel: suggestion.label,
        latitude: suggestion.latitude,
        longitude: suggestion.longitude,
      );
    });
  }

  Future<void> _resolveUserLocation() async {
    final l10n = AppLocalizations.of(context)!;
    final localeTag = Localizations.localeOf(context).toLanguageTag();
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
      final label = await _locationLookupService.reverseLookupLabel(
        latitude: position.latitude,
        longitude: position.longitude,
        localeTag: localeTag,
      );

      if (!mounted) {
        return;
      }

      final resolvedLabel = label ?? l10n.centerOnMyLocation;
      _locationController.text = resolvedLabel;
      setState(() {
        _locationSuggestions = const [];
        _lastLocationQuery = resolvedLabel;
        _draft = _draft.copyWith(
          locationLabel: resolvedLabel,
          latitude: position.latitude,
          longitude: position.longitude,
        );
      });
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

  Future<void> _pickLocationPhotos() async {
    final selections = await _photoPicker.pickPhotos();
    if (selections.isEmpty || !mounted) {
      return;
    }

    setState(() {
      _draft = _draft.copyWith(
        locationPhotoSources: [
          ..._draft.locationPhotoSources,
          ...selections.map((photo) => photo.source),
        ],
        locationPhotoLabels: [
          ..._draft.locationPhotoLabels,
          ...selections.map((photo) => photo.label),
        ],
      );
    });
  }

  void _removeLocationPhoto(int index) {
    final sources = [..._draft.locationPhotoSources];
    final labels = [..._draft.locationPhotoLabels];
    if (index < 0 || index >= sources.length || index >= labels.length) {
      return;
    }

    sources.removeAt(index);
    labels.removeAt(index);

    setState(() {
      _draft = _draft.copyWith(
        locationPhotoSources: sources,
        locationPhotoLabels: labels,
      );
    });
  }

  Widget _buildArtPieceList({required bool selectable}) {
    final l10n = AppLocalizations.of(context)!;
    if (_artPieces.isEmpty) {
      return Text(l10n.noArtPiecesAvailable);
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 360),
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: _artPieces.length,
        separatorBuilder: (context, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final artPiece = _artPieces[index];
          final isSelected = _draft.artPieceId == artPiece.id;

          return Card(
            margin: EdgeInsets.zero,
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            child: InkWell(
              onTap: selectable ? () => _selectArtPiece(artPiece) : null,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SourceImage(
                      source: artPiece.photoUrls.isEmpty
                          ? null
                          : artPiece.photoUrls.first,
                      fit: BoxFit.cover,
                      width: 88,
                      height: 88,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  artPiece.title,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                              ),
                              if (selectable)
                                Icon(
                                  isSelected
                                      ? Icons.check_circle
                                      : Icons.radio_button_unchecked,
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            artPiece.description,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
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

  List<Step> _buildSteps(AppLocalizations l10n) {
    return [
      Step(
        title: Text(l10n.makeDropStepBrowseTitle),
        isActive: _currentStep >= 0,
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.makeDropStepBrowseDescription),
            const SizedBox(height: 12),
            _buildArtPieceList(selectable: false),
          ],
        ),
      ),
      Step(
        title: Text(l10n.makeDropStepSelectTitle),
        isActive: _currentStep >= 1,
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.makeDropStepSelectDescription),
            const SizedBox(height: 12),
            _buildArtPieceList(selectable: true),
          ],
        ),
      ),
      Step(
        title: Text(l10n.makeDropStepDownloadTitle),
        isActive: _currentStep >= 2,
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.makeDropStepDownloadDescription),
            const SizedBox(height: 12),
            if (_selectedArtPiece == null)
              Text(l10n.makeDropSelectArtFirst)
            else ...[
              SourceImage(
                source: _selectedArtPiece!.photoUrls.isEmpty
                    ? null
                    : _selectedArtPiece!.photoUrls.first,
                fit: BoxFit.cover,
                width: double.infinity,
                height: 180,
                borderRadius: BorderRadius.circular(18),
              ),
              const SizedBox(height: 12),
              Text(
                _selectedArtPiece!.title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              if (_selectedArtPiece!.assetFile != null)
                Card.outlined(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        const Icon(Icons.view_in_ar_outlined),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _selectedArtPiece!.assetFile!.fileName,
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                l10n.artPieceAssetContentType(
                                  _selectedArtPiece!.assetFile!.contentType,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (_selectedArtPiece!.assetFile != null)
                const SizedBox(height: 12),
              Text(l10n.makeDropSourceMediaHint),
            ],
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed:
                  _selectedArtPiece == null ||
                      _isSaving ||
                      ((_selectedArtPiece!.assetFile == null) &&
                          _selectedArtPiece!.photoUrls.isEmpty)
                  ? null
                  : () => _downloadProductionReference(),
              icon: const Icon(Icons.download_outlined),
              label: Text(l10n.makeDropDownloadAction),
            ),
            if (_draft.downloadConfirmed)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(l10n.makeDropDownloadDone),
              ),
          ],
        ),
      ),
      Step(
        title: Text(l10n.makeDropStepPrintTitle),
        isActive: _currentStep >= 3,
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.makeDropStepPrintDescription),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.dropStationaryLabel),
              value: _draft.isStationary,
              onChanged: _isSaving
                  ? null
                  : (value) {
                      setState(() {
                        _draft = _draft.copyWith(
                          isStationary: value,
                          clearPortableItemCount: value,
                        );
                        if (value) {
                          _portableItemCountController.clear();
                        }
                      });
                    },
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _itemCountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: l10n.makeDropItemCountLabel,
              ),
            ),
            if (!_draft.isStationary) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _portableItemCountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: l10n.dropPortableItemCountLabel,
                ),
              ),
            ],
            if (_draft.hasPersistedDrop) ...[
              const SizedBox(height: 12),
              Text(
                l10n.makeDropReadyWithId(_draft.dropId!),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
      Step(
        title: Text(l10n.makeDropStepQrTitle),
        isActive: _currentStep >= 4,
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.makeDropStepQrDescription),
            const SizedBox(height: 12),
            if (_draft.items.isEmpty)
              Text(l10n.makeDropGenerateQrFirst)
            else ...[
              Text(
                l10n.makeDropReadyWithId(_draft.dropId!),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 420),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _draft.items.length,
                  separatorBuilder: (context, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) => _QrCodeCard(
                    title: l10n.makeDropQrCodeLabel(index + 1),
                    qrValue: _draft.items[index].qrToken,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      Step(
        title: Text(l10n.makeDropStepPlaceTitle),
        isActive: _currentStep >= 5,
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.makeDropStepPlaceDescription),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    controller: _locationController,
                    focusNode: _locationFocusNode,
                    onChanged: _onLocationQueryChanged,
                    decoration: InputDecoration(
                      labelText: l10n.makeDropLocationLabel,
                      hintText: l10n.mapSearchLocationHint,
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
                  onPressed: _isResolvingUserLocation || _isSaving
                      ? null
                      : _resolveUserLocation,
                  icon: _isResolvingUserLocation
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.my_location_outlined),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildLocationSuggestions(l10n),
            const SizedBox(height: 12),
            if (_draft.latitude != null && _draft.longitude != null)
              Text(
                l10n.makeDropCoordinatesLabel(
                  _draft.latitude!.toStringAsFixed(5),
                  _draft.longitude!.toStringAsFixed(5),
                ),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                FilledButton.icon(
                  onPressed: _isSaving ? null : _pickLocationPhotos,
                  icon: const Icon(Icons.add_a_photo_outlined),
                  label: Text(l10n.makeDropAddLocationPhotos),
                ),
                const SizedBox(width: 12),
                Text(
                  l10n.makeDropPhotosSelected(
                    _draft.locationPhotoSources.length,
                  ),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_draft.locationPhotoSources.isEmpty)
              Text(l10n.makeDropNoLocationPhotos)
            else
              SizedBox(
                height: 140,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _draft.locationPhotoSources.length,
                  separatorBuilder: (context, _) => const SizedBox(width: 12),
                  itemBuilder: (context, index) => SizedBox(
                    width: 132,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: SourceImage(
                            source: _draft.locationPhotoSources[index],
                            fit: BoxFit.cover,
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        Positioned(
                          top: 6,
                          right: 6,
                          child: IconButton.filledTonal(
                            onPressed: _isSaving
                                ? null
                                : () => _removeLocationPhoto(index),
                            icon: const Icon(Icons.delete_outline),
                            iconSize: 18,
                          ),
                        ),
                        Positioned(
                          left: 8,
                          right: 8,
                          bottom: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _draft.locationPhotoLabels[index],
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.makeDropPublishAfterFinish),
              value: _draft.publishAfterFinish,
              onChanged: _isSaving
                  ? null
                  : (value) {
                      setState(() {
                        _draft = _draft.copyWith(publishAfterFinish: value);
                      });
                    },
            ),
          ],
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return PageShell(
      title: l10n.makeDropWizardTitle,
      body: _isLoading
          ? Center(child: Text(l10n.loadingData))
          : _loadError != null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_loadError!, textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: _loadDependencies,
                    child: Text(l10n.retryButton),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 20),
              child: Stepper(
                currentStep: _currentStep,
                onStepContinue: _isSaving ? null : _goToNextStep,
                onStepCancel: _isSaving ? null : _goToPreviousStep,
                onStepTapped: (index) {
                  if (_isSaving || index > _currentStep) {
                    return;
                  }

                  setState(() => _currentStep = index);
                },
                controlsBuilder: (context, details) {
                  final isLastStep = _currentStep == 5;
                  return Row(
                    children: [
                      FilledButton(
                        onPressed: _isSaving ? null : details.onStepContinue,
                        child: _isSaving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                isLastStep
                                    ? l10n.makeDropFinishAction
                                    : l10n.makeDropNextAction,
                              ),
                      ),
                      const SizedBox(width: 8),
                      if (_currentStep > 0)
                        TextButton(
                          onPressed: _isSaving ? null : details.onStepCancel,
                          child: Text(l10n.makeDropBackAction),
                        ),
                    ],
                  );
                },
                steps: _buildSteps(l10n),
              ),
            ),
    );
  }
}

class _QrCodeCard extends StatelessWidget {
  const _QrCodeCard({required this.title, required this.qrValue});

  final String title;
  final String qrValue;

  @override
  Widget build(BuildContext context) {
    return Card.outlined(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            QrImageView(data: qrValue, size: 124),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  SelectableText(qrValue),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
