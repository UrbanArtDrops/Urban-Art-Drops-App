import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:urban_art_drops_app/l10n/app_localizations.dart";

import "../../../../shared/services/app_api_client.dart";
import "../../../../shared/widgets/page_shell.dart";

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final AppApiClient _apiClient = AppApiClient();
  final TextEditingController _userNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  int _selectedRole = 0;
  bool _isSaving = false;

  @override
  void dispose() {
    _userNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final l10n = AppLocalizations.of(context)!;
    final userName = _userNameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (userName.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.authFillRegistrationHint)));
      return;
    }

    setState(() => _isSaving = true);
    try {
      final result = await _apiClient.registerLocal(
        email: email,
        userName: userName,
        password: password,
        role: _selectedRole,
      );

      if (result.userId != null && result.userId!.trim().isNotEmpty) {
        await _apiClient.verifyEmail(result.userId!);
      }

      if (!mounted) {
        return;
      }

      final successMessage = _selectedRole == 0
          ? l10n.authHunterRegistrationSuccess
          : l10n.authApprovalRequestSubmitted;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(successMessage)));
      context.go("/auth/login");
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  String _roleHint(AppLocalizations l10n) {
    switch (_selectedRole) {
      case 1:
        return l10n.authArtistApprovalHint;
      case 2:
        return l10n.authDropMakerApprovalHint;
      default:
        return l10n.authHunterSelfServiceHint;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return PageShell(
      title: l10n.navRegister,
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Card.outlined(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.authAdminRegistrationManaged),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _userNameController,
                    decoration: InputDecoration(labelText: l10n.usernameLabel),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(labelText: l10n.emailLabel),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(labelText: l10n.passwordLabel),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    initialValue: _selectedRole,
                    items: [
                      DropdownMenuItem(value: 0, child: Text(l10n.roleHunter)),
                      DropdownMenuItem(value: 1, child: Text(l10n.roleArtist)),
                      DropdownMenuItem(
                        value: 2,
                        child: Text(l10n.roleDropMaker),
                      ),
                    ],
                    onChanged: _isSaving
                        ? null
                        : (value) {
                            if (value != null) {
                              setState(() => _selectedRole = value);
                            }
                          },
                    decoration: InputDecoration(labelText: l10n.roleLabel),
                  ),
                  const SizedBox(height: 12),
                  Text(_roleHint(l10n)),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: _isSaving ? null : _register,
                    child: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(l10n.registerButton),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
