import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:urban_art_drops_app/l10n/app_localizations.dart";

import "../../../../shared/services/app_api_client.dart";
import "../../../../shared/widgets/page_shell.dart";

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key, this.apiClient});

  final AppApiClient? apiClient;

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final TextEditingController _emailController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _requestReset() async {
    final l10n = AppLocalizations.of(context)!;
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showSnackBar(l10n.authForgotPasswordEmailRequired);
      return;
    }

    setState(() => _isSaving = true);
    try {
      final result = await _apiClient.requestPasswordReset(email: email);
      if (!mounted) {
        return;
      }

      _showSnackBar(
        result.message.trim().isEmpty
            ? l10n.authForgotPasswordSubmitted
            : result.message,
      );
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

    return PageShell(
      title: l10n.authForgotPasswordTitle,
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
                    l10n.authForgotPasswordTitle,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(l10n.authForgotPasswordHint),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(labelText: l10n.emailLabel),
                    onSubmitted: (_) {
                      if (!_isSaving) {
                        _requestReset();
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilledButton(
                        onPressed: _isSaving ? null : _requestReset,
                        child: _isSaving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(l10n.authForgotPasswordSubmit),
                      ),
                      TextButton(
                        onPressed: () => context.go("/auth/login"),
                        child: Text(l10n.navLogin),
                      ),
                    ],
                  ),
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
