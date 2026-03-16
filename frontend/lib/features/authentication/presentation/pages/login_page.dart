import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:go_router/go_router.dart";
import "package:urban_art_drops_app/l10n/app_localizations.dart";

import "../../../../shared/services/app_api_client.dart";
import "../../../../shared/widgets/page_shell.dart";
import "../bloc/auth_session_cubit.dart";

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final AppApiClient _apiClient = AppApiClient();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final l10n = AppLocalizations.of(context)!;
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.authFillCredentialsHint)));
      return;
    }

    setState(() => _isSaving = true);
    try {
      final result = await _apiClient.loginLocal(
        email: email,
        password: password,
      );
      if (!mounted) {
        return;
      }

      final role = appUserRoleFromApiValue(result.role);
      final userId = result.userId?.trim();
      final resolvedEmail = result.email?.trim() ?? email;
      final userName = result.userName?.trim() ?? resolvedEmail;
      if (!result.success || role == null || userId == null || userId.isEmpty) {
        throw const ApiException("The login response is incomplete.");
      }

      context.read<AuthSessionCubit>().signIn(
        userId: userId,
        email: resolvedEmail,
        userName: userName,
        role: role,
      );
      context.go("/");
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return PageShell(
      title: l10n.navLogin,
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
                    l10n.authRoleManagedAtRegistration,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
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
                    onSubmitted: (_) {
                      if (!_isSaving) {
                        _login();
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: _isSaving ? null : _login,
                    child: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(l10n.navLogin),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card.outlined(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.providerLoginTitle,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(l10n.authProviderLoginComingSoon),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: const [
                      OutlinedButton(onPressed: null, child: Text("Google")),
                      OutlinedButton(onPressed: null, child: Text("Facebook")),
                      OutlinedButton(onPressed: null, child: Text("Instagram")),
                      OutlinedButton(onPressed: null, child: Text("TikTok")),
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
}
