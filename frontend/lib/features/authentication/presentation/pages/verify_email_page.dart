import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:urban_art_drops_app/l10n/app_localizations.dart";

import "../../../../shared/services/app_api_client.dart";
import "../../../../shared/widgets/page_shell.dart";

class VerifyEmailPage extends StatefulWidget {
  const VerifyEmailPage({
    required this.userId,
    required this.token,
    super.key,
    this.apiClient,
  });

  final String? userId;
  final String? token;
  final AppApiClient? apiClient;

  @override
  State<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends State<VerifyEmailPage> {
  bool _isLoading = true;
  bool _isSuccessful = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _verifyEmail();
  }

  Future<void> _verifyEmail() async {
    final userId = widget.userId?.trim();
    final token = widget.token?.trim();
    if (userId == null || userId.isEmpty || token == null || token.isEmpty) {
      setState(() {
        _isLoading = false;
        _isSuccessful = false;
        _message = null;
      });
      return;
    }

    try {
      final result = await _apiClient.verifyEmail(userId: userId, token: token);
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _isSuccessful = result.success;
        _message = result.message;
      });
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _isSuccessful = false;
        _message = error.message;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _isSuccessful = false;
        _message = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final fallbackMessage = _isSuccessful
        ? l10n.authVerifyEmailSuccess
        : l10n.authVerifyEmailFailure;
    final hasParameters =
        (widget.userId?.trim().isNotEmpty ?? false) &&
        (widget.token?.trim().isNotEmpty ?? false);

    return PageShell(
      title: l10n.authVerifyEmailTitle,
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Card.outlined(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.authVerifyEmailTitle,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  if (_isLoading) ...[
                    const LinearProgressIndicator(),
                    const SizedBox(height: 12),
                    Text(l10n.authVerifyEmailInProgress),
                  ] else ...[
                    Icon(
                      _isSuccessful
                          ? Icons.verified_user_outlined
                          : Icons.error_outline,
                      color: _isSuccessful
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      hasParameters
                          ? (_message?.trim().isNotEmpty == true
                                ? _message!
                                : fallbackMessage)
                          : l10n.authVerifyEmailMissingParameters,
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () => context.go("/auth/login"),
                      child: Text(l10n.navLogin),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  AppApiClient get _apiClient {
    return widget.apiClient ?? AppApiClient();
  }
}
