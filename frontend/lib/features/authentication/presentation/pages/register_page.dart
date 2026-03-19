import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:urban_art_drops_app/l10n/app_localizations.dart";

import "../../../../shared/models/app_models.dart";
import "../../../../shared/services/app_api_client.dart";
import "../../../../shared/services/external_provider_auth_launcher.dart";
import "../../../../shared/widgets/page_shell.dart";

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key, this.apiClient, this.providerAuthLauncher});

  final AppApiClient? apiClient;
  final ExternalProviderAuthLauncher? providerAuthLauncher;

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _userNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _providerUserNameController =
      TextEditingController();
  final TextEditingController _providerEmailController =
      TextEditingController();
  int _selectedRole = 0;
  int _selectedProviderRole = 0;
  bool _isLoadingProviders = true;
  List<AuthProviderOptionModel> _availableProviders = const [];
  String? _selectedProvider;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadAvailableProviders();
  }

  @override
  void dispose() {
    _userNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _providerUserNameController.dispose();
    _providerEmailController.dispose();
    super.dispose();
  }

  Future<void> _loadAvailableProviders() async {
    try {
      final providers = await _apiClient.getAvailableAuthProviders();
      if (!mounted) {
        return;
      }

      setState(() {
        _availableProviders = providers;
        _selectedProvider =
            providers.any((provider) => provider.provider == _selectedProvider)
            ? _selectedProvider
            : providers.isEmpty
            ? null
            : providers.first.provider;
        _isLoadingProviders = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _availableProviders = const [];
        _selectedProvider = null;
        _isLoadingProviders = false;
      });
    }
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

      if (!mounted) {
        return;
      }

      if (!result.success) {
        throw ApiException(result.message);
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

  Future<void> _registerProvider() async {
    final l10n = AppLocalizations.of(context)!;
    final userName = _providerUserNameController.text.trim();
    final email = _providerEmailController.text.trim();
    final selectedProvider = _selectedProvider;
    if (userName.isEmpty || email.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.authFillRegistrationHint)));
      return;
    }
    if (selectedProvider == null || selectedProvider.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.authNoConfiguredProviders)));
      return;
    }

    setState(() => _isSaving = true);
    try {
      final callbackUri = _providerAuthLauncher.buildCallbackUri();
      final beginResult = await _apiClient.beginProviderRegistration(
        provider: selectedProvider,
        callbackUrl: callbackUri.toString(),
        email: email,
        userName: userName,
        role: _selectedProviderRole,
      );
      final completionUri = await _providerAuthLauncher.authenticate(
        authorizationUrl: beginResult.authorizationUrl,
        callbackUri: callbackUri,
      );
      final providerSessionId = _readProviderCallbackParameter(
        completionUri,
        "provider_session",
      );
      if (providerSessionId == null || providerSessionId.isEmpty) {
        final providerError = _readProviderCallbackParameter(
          completionUri,
          "provider_error",
        );
        throw ApiException(
          providerError?.isNotEmpty == true
              ? providerError!
              : l10n.authProviderMissingCompletionSession,
        );
      }

      final result = await _apiClient.completeProviderAuthentication(
        providerSessionId: providerSessionId,
      );

      if (!mounted) {
        return;
      }

      if (!result.success) {
        throw ApiException(result.message);
      }

      final successMessage = _selectedProviderRole == 0
          ? l10n.authHunterProviderRegistrationSuccess
          : l10n.authProviderApprovalRequestSubmitted;
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
    } catch (_) {
      if (!mounted) {
        return;
      }

      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.authProviderFlowCancelledOrFailed)),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  String _roleHint(AppLocalizations l10n, int role) {
    switch (role) {
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
                  Text(_roleHint(l10n, _selectedRole)),
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
          if (!_isLoadingProviders && _availableProviders.isNotEmpty) ...[
            const SizedBox(height: 12),
            Card.outlined(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.providerRegisterTitle,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(l10n.authProviderRegistrationHint),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _availableProviders
                          .map(
                            (provider) => ChoiceChip(
                              label: Text(provider.displayName),
                              selected: _selectedProvider == provider.provider,
                              onSelected: _isSaving
                                  ? null
                                  : (selected) {
                                      if (selected) {
                                        setState(
                                          () => _selectedProvider =
                                              provider.provider,
                                        );
                                      }
                                    },
                            ),
                          )
                          .toList(growable: false),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _providerUserNameController,
                      decoration: InputDecoration(
                        labelText: l10n.usernameLabel,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _providerEmailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(labelText: l10n.emailLabel),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int>(
                      initialValue: _selectedProviderRole,
                      items: [
                        DropdownMenuItem(
                          value: 0,
                          child: Text(l10n.roleHunter),
                        ),
                        DropdownMenuItem(
                          value: 1,
                          child: Text(l10n.roleArtist),
                        ),
                        DropdownMenuItem(
                          value: 2,
                          child: Text(l10n.roleDropMaker),
                        ),
                      ],
                      onChanged: _isSaving
                          ? null
                          : (value) {
                              if (value != null) {
                                setState(() => _selectedProviderRole = value);
                              }
                            },
                      decoration: InputDecoration(labelText: l10n.roleLabel),
                    ),
                    const SizedBox(height: 12),
                    Text(_roleHint(l10n, _selectedProviderRole)),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: _isSaving ? null : _registerProvider,
                      child: Text(l10n.providerRegisterTitle),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  AppApiClient get _apiClient {
    return widget.apiClient ?? AppApiClient();
  }

  ExternalProviderAuthLauncher get _providerAuthLauncher {
    return widget.providerAuthLauncher ?? const ExternalProviderAuthLauncher();
  }

  String? _readProviderCallbackParameter(Uri uri, String parameterName) {
    final queryValue = uri.queryParameters[parameterName]?.trim();
    if (queryValue != null && queryValue.isNotEmpty) {
      return queryValue;
    }

    final fragment = uri.fragment.trim();
    if (fragment.isEmpty) {
      return null;
    }

    final normalizedFragment = fragment.startsWith("?")
        ? fragment.substring(1)
        : fragment;
    if (normalizedFragment.isEmpty) {
      return null;
    }

    final fragmentParameters = Uri.splitQueryString(normalizedFragment);
    final fragmentValue = fragmentParameters[parameterName]?.trim();
    return fragmentValue == null || fragmentValue.isEmpty
        ? null
        : fragmentValue;
  }
}
