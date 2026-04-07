import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:urban_art_drops_app/l10n/app_localizations.dart";

import "../../../../shared/services/app_api_client.dart";
import "../../../../shared/widgets/page_shell.dart";
import "../../../../shared/widgets/password_text_field.dart";

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({
    required this.userId,
    required this.token,
    super.key,
    this.apiClient,
  });

  final String? userId;
  final String? token;
  final AppApiClient? apiClient;

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final TextEditingController _passwordController = TextEditingController();
  bool _isSaving = false;
  bool _isSuccessful = false;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    final l10n = AppLocalizations.of(context)!;
    final userId = widget.userId?.trim();
    final token = widget.token?.trim();
    final newPassword = _passwordController.text;
    if (userId == null || userId.isEmpty || token == null || token.isEmpty) {
      _showSnackBar(l10n.authResetPasswordMissingParameters);
      return;
    }

    if (newPassword.isEmpty) {
      _showSnackBar(l10n.authResetPasswordPasswordRequired);
      return;
    }

    setState(() => _isSaving = true);
    try {
      final result = await _apiClient.completePasswordReset(
        userId: userId,
        token: token,
        newPassword: newPassword,
      );
      if (!mounted) {
        return;
      }

      setState(() => _isSuccessful = result.success);
      _showSnackBar(
        result.message.trim().isEmpty
            ? l10n.authResetPasswordSuccess
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
    final hasParameters =
        (widget.userId?.trim().isNotEmpty ?? false) &&
        (widget.token?.trim().isNotEmpty ?? false);

    return PageShell(
      title: l10n.authResetPasswordTitle,
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
                    l10n.authResetPasswordTitle,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    hasParameters
                        ? l10n.authResetPasswordHint
                        : l10n.authResetPasswordMissingParameters,
                  ),
                  const SizedBox(height: 16),
                  PasswordTextField(
                    controller: _passwordController,
                    enabled: hasParameters && !_isSuccessful,
                    decoration: InputDecoration(
                      labelText: l10n.authNewPasswordLabel,
                    ),
                    onSubmitted: (_) {
                      if (!_isSaving && !_isSuccessful) {
                        _resetPassword();
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilledButton(
                        onPressed: !hasParameters || _isSaving || _isSuccessful
                            ? null
                            : _resetPassword,
                        child: _isSaving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(l10n.authResetPasswordSubmit),
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
