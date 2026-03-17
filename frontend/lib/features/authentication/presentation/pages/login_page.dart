import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:go_router/go_router.dart";
import "package:qr_flutter/qr_flutter.dart";
import "package:urban_art_drops_app/l10n/app_localizations.dart";

import "../../../../shared/models/app_models.dart";
import "../../../../shared/services/app_api_client.dart";
import "../../../../shared/widgets/page_shell.dart";
import "../bloc/auth_session_cubit.dart";

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  static const List<String> _providers = <String>[
    "google",
    "facebook",
    "instagram",
    "tiktok",
    "microsoft",
  ];

  final AppApiClient _apiClient = AppApiClient();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _providerEmailController =
      TextEditingController();
  final TextEditingController _providerSubjectController =
      TextEditingController();
  final TextEditingController _mfaCodeController = TextEditingController();

  bool _isSaving = false;
  String _selectedProvider = _providers.first;
  String? _mfaChallengeToken;
  bool _mfaSetupRequired = false;
  String? _mfaManualEntryKey;
  String? _mfaProvisioningUri;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _providerEmailController.dispose();
    _providerSubjectController.dispose();
    _mfaCodeController.dispose();
    super.dispose();
  }

  Future<void> _loginLocal() async {
    final l10n = AppLocalizations.of(context)!;
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      _showSnackBar(l10n.authFillCredentialsHint);
      return;
    }

    await _runAuthAction(
      () => _apiClient.loginLocal(email: email, password: password),
      fallbackEmail: email,
    );
  }

  Future<void> _loginProvider() async {
    final l10n = AppLocalizations.of(context)!;
    final email = _providerEmailController.text.trim();
    final providerSubject = _providerSubjectController.text.trim();
    if (email.isEmpty || providerSubject.isEmpty) {
      _showSnackBar(l10n.authFillCredentialsHint);
      return;
    }

    await _runAuthAction(
      () => _apiClient.loginProvider(
        provider: _selectedProvider,
        providerSubject: providerSubject,
        email: email,
      ),
      fallbackEmail: email,
    );
  }

  Future<void> _completeMfa() async {
    final l10n = AppLocalizations.of(context)!;
    final challengeToken = _mfaChallengeToken?.trim();
    final code = _mfaCodeController.text.trim();
    if (challengeToken == null || challengeToken.isEmpty) {
      _showSnackBar(l10n.authMfaRequired);
      return;
    }

    if (code.isEmpty) {
      _showSnackBar(l10n.authMfaRequired);
      return;
    }

    await _runAuthAction(
      () => _apiClient.completeMfaChallenge(
        challengeToken: challengeToken,
        code: code,
      ),
      fallbackEmail: _providerEmailController.text.trim().isNotEmpty
          ? _providerEmailController.text.trim()
          : _emailController.text.trim(),
      resetMfaState: false,
    );
  }

  Future<void> _runAuthAction(
    Future<AuthResultModel> Function() action, {
    required String fallbackEmail,
    bool resetMfaState = true,
  }) async {
    setState(() {
      _isSaving = true;
      if (resetMfaState) {
        _clearMfaState();
      }
    });

    try {
      final result = await action();
      if (!mounted) {
        return;
      }

      await _applyAuthResult(result, fallbackEmail: fallbackEmail);
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

  Future<void> _applyAuthResult(
    AuthResultModel result, {
    required String fallbackEmail,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    if (result.requiresMfa) {
      setState(() {
        _mfaChallengeToken = result.mfaChallengeToken;
        _mfaSetupRequired = result.mfaSetupRequired;
        _mfaManualEntryKey = result.mfaManualEntryKey;
        _mfaProvisioningUri = result.mfaProvisioningUri;
      });
      return;
    }

    final role = appUserRoleFromApiValue(result.role);
    final userId = result.userId?.trim();
    final accessToken = result.accessToken?.trim();
    final resolvedEmail = result.email?.trim() ?? fallbackEmail;
    final userName = result.userName?.trim() ?? resolvedEmail;
    if (!result.success ||
        role == null ||
        userId == null ||
        userId.isEmpty ||
        accessToken == null ||
        accessToken.isEmpty) {
      throw ApiException(
        result.message.isEmpty ? l10n.authFillCredentialsHint : result.message,
      );
    }

    context.read<AuthSessionCubit>().signIn(
      userId: userId,
      email: resolvedEmail,
      userName: userName,
      role: role,
      accessToken: accessToken,
      accessTokenExpiresAtUtc: result.accessTokenExpiresAtUtc,
      tokenType: result.tokenType ?? "Bearer",
    );
    _clearMfaState();
    final redirectTarget = GoRouterState.of(
      context,
    ).uri.queryParameters["from"];
    context.go(
      redirectTarget == null || redirectTarget.trim().isEmpty
          ? "/"
          : redirectTarget,
    );
  }

  void _clearMfaState() {
    _mfaChallengeToken = null;
    _mfaSetupRequired = false;
    _mfaManualEntryKey = null;
    _mfaProvisioningUri = null;
    _mfaCodeController.clear();
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
      title: l10n.navLogin,
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          if (_mfaChallengeToken != null) ...[
            Card.outlined(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.authMfaTitle,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _mfaSetupRequired
                          ? l10n.authMfaSetupHint
                          : l10n.authMfaRequired,
                    ),
                    if (_mfaProvisioningUri != null) ...[
                      const SizedBox(height: 16),
                      Center(
                        child: QrImageView(
                          data: _mfaProvisioningUri!,
                          size: 180,
                        ),
                      ),
                    ],
                    if ((_mfaManualEntryKey ?? "").isNotEmpty) ...[
                      const SizedBox(height: 12),
                      SelectableText(
                        "${l10n.authMfaManualKeyLabel}: ${_mfaManualEntryKey!}",
                      ),
                    ],
                    const SizedBox(height: 12),
                    TextField(
                      controller: _mfaCodeController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: l10n.authMfaCodeLabel,
                      ),
                      onSubmitted: (_) {
                        if (!_isSaving) {
                          _completeMfa();
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _isSaving ? null : _completeMfa,
                      child: _isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(l10n.authMfaContinue),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
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
                        _loginLocal();
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: _isSaving ? null : _loginLocal,
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
                  Text(l10n.authProviderLoginHint),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _providers
                        .map(
                          (provider) => ChoiceChip(
                            label: Text(_providerLabel(provider)),
                            selected: _selectedProvider == provider,
                            onSelected: _isSaving
                                ? null
                                : (selected) {
                                    if (selected) {
                                      setState(
                                        () => _selectedProvider = provider,
                                      );
                                    }
                                  },
                          ),
                        )
                        .toList(growable: false),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _providerEmailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(labelText: l10n.emailLabel),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _providerSubjectController,
                    decoration: InputDecoration(
                      labelText: l10n.authProviderSubjectLabel,
                    ),
                    onSubmitted: (_) {
                      if (!_isSaving) {
                        _loginProvider();
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: _isSaving ? null : _loginProvider,
                    child: Text(l10n.providerLoginTitle),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _providerLabel(String provider) {
    switch (provider) {
      case "google":
        return "Google";
      case "facebook":
        return "Facebook";
      case "instagram":
        return "Instagram";
      case "tiktok":
        return "TikTok";
      case "microsoft":
        return "Microsoft";
      default:
        return provider;
    }
  }
}
