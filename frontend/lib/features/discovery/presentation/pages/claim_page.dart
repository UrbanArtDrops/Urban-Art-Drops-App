import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:go_router/go_router.dart";
import "package:urban_art_drops_app/l10n/app_localizations.dart";

import "../../../authentication/presentation/bloc/auth_session_cubit.dart";
import "../../../../shared/models/app_models.dart";
import "../../../../shared/services/app_api_client.dart";
import "../../../../shared/widgets/page_shell.dart";

class ClaimPage extends StatefulWidget {
  const ClaimPage({super.key, this.initialToken});

  final String? initialToken;

  @override
  State<ClaimPage> createState() => _ClaimPageState();
}

class _ClaimPageState extends State<ClaimPage> {
  final AppApiClient _apiClient = AppApiClient();
  final TextEditingController _nicknameController = TextEditingController();

  ClaimPreviewModel? _preview;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  String get _qrToken => (widget.initialToken ?? "").trim();

  @override
  void initState() {
    super.initState();
    _loadPreview();
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _loadPreview() async {
    final l10n = AppLocalizations.of(context)!;
    if (_qrToken.isEmpty) {
      setState(() {
        _isLoading = false;
        _errorMessage = l10n.claimMissingToken;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final preview = await _apiClient.getClaimPreview(_qrToken);
      if (!mounted) {
        return;
      }

      setState(() {
        _preview = preview;
        _isLoading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _errorMessage = error.message.isEmpty
            ? l10n.claimLoadError
            : error.message;
      });
    }
  }

  Future<void> _claim() async {
    final l10n = AppLocalizations.of(context)!;
    final preview = _preview;
    if (preview == null) {
      _showSnackBar(l10n.claimMissingToken);
      return;
    }

    final session = context.read<AuthSessionCubit>().state;
    final nickname = _nicknameController.text.trim();
    final hunterUserId = session.isAuthenticated ? session.userId : null;
    if ((hunterUserId ?? "").isEmpty && nickname.isEmpty) {
      _showSnackBar(l10n.claimAnonymousHint);
      return;
    }

    setState(() => _isSaving = true);
    try {
      await _apiClient.claimByToken(
        qrToken: _qrToken,
        hunterUserId: hunterUserId,
        anonymousNickname: nickname.isEmpty ? null : nickname,
      );
      if (!mounted) {
        return;
      }

      _showSnackBar(l10n.claimSuccess);
      await _loadPreview();
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }

      _showSnackBar(error.message);
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final session = context.watch<AuthSessionCubit>().state;

    return PageShell(
      title: l10n.claimTitle,
      body: _isLoading
          ? Center(child: Text(l10n.loadingData))
          : _errorMessage != null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_errorMessage!, textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: _loadPreview,
                    child: Text(l10n.retryButton),
                  ),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(12),
              children: [
                Text(l10n.claimInstruction),
                const SizedBox(height: 12),
                if (_preview != null) ...[
                  Card.outlined(
                    child: ListTile(
                      title: Text(l10n.claimPreviewTitle),
                      subtitle: Text(_preview!.artPieceTitle),
                      trailing: IconButton(
                        onPressed: () =>
                            context.go("/hunter/drops/${_preview!.dropId}"),
                        icon: const Icon(Icons.open_in_new_outlined),
                      ),
                    ),
                  ),
                  Card.outlined(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("${l10n.claimTokenLabel}: $_qrToken"),
                          const SizedBox(height: 8),
                          Text(
                            "${l10n.claimPreviewItemLabel}: ${_preview!.dropItemId}",
                          ),
                          const SizedBox(height: 8),
                          if (_preview!.isClaimed)
                            Text(
                              _preview!.claimedByDisplayName == null ||
                                      _preview!.claimedByDisplayName!
                                          .trim()
                                          .isEmpty
                                  ? l10n.claimAlreadyClaimed
                                  : l10n.claimAlreadyClaimedBy(
                                      _preview!.claimedByDisplayName!,
                                    ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                if (session.isAuthenticated &&
                    (session.displayName ?? "").isNotEmpty)
                  Text(l10n.claimAuthenticatedAs(session.displayName!))
                else ...[
                  TextField(
                    controller: _nicknameController,
                    decoration: InputDecoration(labelText: l10n.nicknameLabel),
                  ),
                  const SizedBox(height: 8),
                  Text(l10n.claimAnonymousHint),
                ],
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: _isSaving || (_preview?.isClaimed ?? false)
                      ? null
                      : _claim,
                  child: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n.claimButton),
                ),
              ],
            ),
    );
  }
}
