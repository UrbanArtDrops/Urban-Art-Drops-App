import "package:flutter/material.dart";
import "package:urban_art_drops_app/l10n/app_localizations.dart";

import "../../../../shared/models/app_models.dart";
import "../../../../shared/services/app_api_client.dart";
import "../../../../shared/widgets/page_shell.dart";

class MakeDropWizardPage extends StatefulWidget {
  const MakeDropWizardPage({super.key});

  @override
  State<MakeDropWizardPage> createState() => _MakeDropWizardPageState();
}

class _MakeDropWizardPageState extends State<MakeDropWizardPage> {
  final AppApiClient _apiClient = AppApiClient();
  final TextEditingController _itemCountController = TextEditingController(
    text: "1",
  );
  final TextEditingController _locationController = TextEditingController();

  List<ArtPieceModel> _artPieces = const [];
  ArtPieceModel? _selectedArtPiece;
  List<String> _generatedQrTokens = const [];
  bool _downloadConfirmed = false;
  bool _isLoadingArtPieces = true;
  String? _loadError;
  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    _loadArtPieces();
  }

  @override
  void dispose() {
    _itemCountController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _loadArtPieces() async {
    setState(() {
      _isLoadingArtPieces = true;
      _loadError = null;
    });

    try {
      final artPieces = await _apiClient.getArtPieces();
      if (!mounted) {
        return;
      }

      setState(() {
        _artPieces = artPieces..sort((a, b) => a.title.compareTo(b.title));
        _isLoadingArtPieces = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loadError = AppLocalizations.of(context)!.artPiecesLoadFailed;
        _isLoadingArtPieces = false;
      });
    }
  }

  void _selectArtPiece(ArtPieceModel artPiece) {
    setState(() {
      _selectedArtPiece = artPiece;
      _downloadConfirmed = false;
      _generatedQrTokens = const [];
    });
  }

  void _confirmDownload() {
    setState(() {
      _downloadConfirmed = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.makeDropDownloadSet),
      ),
    );
  }

  void _generateQrTokens() {
    final selected = _selectedArtPiece;
    final count = int.tryParse(_itemCountController.text.trim()) ?? 0;
    if (selected == null || count < 1) {
      return;
    }

    final prefix = selected.id.replaceAll("-", "").substring(0, 8);
    final tokens = List<String>.generate(
      count,
      (index) => "drop-$prefix-item-${(index + 1).toString().padLeft(2, "0")}",
      growable: false,
    );

    setState(() {
      _generatedQrTokens = tokens;
    });
  }

  void _goToNextStep() {
    final l10n = AppLocalizations.of(context)!;
    switch (_currentStep) {
      case 0:
        setState(() => _currentStep += 1);
        return;
      case 1:
        if (_selectedArtPiece == null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.makeDropSelectArtFirst)));
          return;
        }
        setState(() => _currentStep += 1);
        return;
      case 2:
        if (!_downloadConfirmed) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.makeDropConfirmDownloadFirst)),
          );
          return;
        }
        setState(() => _currentStep += 1);
        return;
      case 3:
        final count = int.tryParse(_itemCountController.text.trim()) ?? 0;
        if (count < 1) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.makeDropItemCountInvalid)),
          );
          return;
        }
        setState(() => _currentStep += 1);
        return;
      case 4:
        if (_generatedQrTokens.isEmpty) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.makeDropGenerateQrFirst)));
          return;
        }
        setState(() => _currentStep += 1);
        return;
      case 5:
        if (_locationController.text.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.makeDropLocationRequired)),
          );
          return;
        }
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.makeDropWizardFinished)));
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

  Widget _buildArtPieceList({required bool selectable}) {
    final l10n = AppLocalizations.of(context)!;
    if (_isLoadingArtPieces) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(l10n.loadingData),
      );
    }
    if (_loadError != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_loadError!),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _loadArtPieces,
            icon: const Icon(Icons.refresh),
            label: Text(l10n.retryButton),
          ),
        ],
      );
    }
    if (_artPieces.isEmpty) {
      return Text(l10n.noArtPiecesAvailable);
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 300),
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: _artPieces.length,
        separatorBuilder: (context, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final artPiece = _artPieces[index];
          final isSelected = _selectedArtPiece?.id == artPiece.id;
          final previewUrl = artPiece.photoUrls.isNotEmpty
              ? artPiece.photoUrls.first
              : "";

          return Card(
            margin: EdgeInsets.zero,
            child: ListTile(
              leading: previewUrl.isEmpty
                  ? const Icon(Icons.image_not_supported_outlined)
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.network(
                        previewUrl,
                        width: 52,
                        height: 52,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.image_not_supported_outlined),
                      ),
                    ),
              title: Text(artPiece.title),
              subtitle: Text(
                artPiece.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: selectable
                  ? Icon(
                      isSelected
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                    )
                  : null,
              selected: isSelected,
              onTap: selectable ? () => _selectArtPiece(artPiece) : null,
            ),
          );
        },
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
            const SizedBox(height: 10),
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
            const SizedBox(height: 10),
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
            const SizedBox(height: 10),
            if (_selectedArtPiece == null)
              Text(l10n.makeDropSelectArtFirst)
            else
              Text(_selectedArtPiece!.title),
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: _selectedArtPiece == null ? null : _confirmDownload,
              icon: const Icon(Icons.download_outlined),
              label: Text(l10n.makeDropDownloadAction),
            ),
            if (_downloadConfirmed)
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
            const SizedBox(height: 10),
            TextField(
              controller: _itemCountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: l10n.makeDropItemCountLabel,
              ),
            ),
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
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: _selectedArtPiece == null ? null : _generateQrTokens,
              icon: const Icon(Icons.qr_code_2_outlined),
              label: Text(l10n.makeDropGenerateQrAction),
            ),
            if (_generatedQrTokens.isNotEmpty) ...[
              const SizedBox(height: 10),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 220),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _generatedQrTokens.length,
                  itemBuilder: (context, index) => ListTile(
                    dense: true,
                    leading: const Icon(Icons.qr_code_outlined),
                    title: Text(_generatedQrTokens[index]),
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
            const SizedBox(height: 10),
            TextField(
              controller: _locationController,
              decoration: InputDecoration(
                labelText: l10n.makeDropLocationLabel,
              ),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 20),
        child: Stepper(
          currentStep: _currentStep,
          onStepContinue: _goToNextStep,
          onStepCancel: _goToPreviousStep,
          onStepTapped: (index) => setState(() => _currentStep = index),
          controlsBuilder: (context, details) {
            final isLastStep = _currentStep == 5;
            return Row(
              children: [
                FilledButton(
                  onPressed: details.onStepContinue,
                  child: Text(
                    isLastStep
                        ? l10n.makeDropFinishAction
                        : l10n.makeDropNextAction,
                  ),
                ),
                const SizedBox(width: 8),
                if (_currentStep > 0)
                  TextButton(
                    onPressed: details.onStepCancel,
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
