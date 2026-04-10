import "package:flutter/material.dart";
import "package:urban_art_drops_app/l10n/app_localizations.dart";

import "../../../../shared/models/app_models.dart";
import "../../../../shared/services/app_api_client.dart";
import "../../../../shared/widgets/app_panels.dart";
import "../../../../shared/widgets/page_shell.dart";
import "../../../../shared/widgets/password_text_field.dart";

class AdminConfigurationPage extends StatefulWidget {
  const AdminConfigurationPage({super.key, this.apiClient});

  final AppApiClient? apiClient;

  @override
  State<AdminConfigurationPage> createState() => _AdminConfigurationPageState();
}

class _AdminConfigurationPageState extends State<AdminConfigurationPage> {
  final TextEditingController _smtpHostController = TextEditingController();
  final TextEditingController _smtpPortController = TextEditingController();
  final TextEditingController _smtpUserNameController = TextEditingController();
  final TextEditingController _smtpUserEmailController =
      TextEditingController();
  final TextEditingController _smtpPasswordSecretNameController =
      TextEditingController();
  final TextEditingController _smtpPasswordController = TextEditingController();
  final TextEditingController _publicAppBaseUrlController =
      TextEditingController();
  final TextEditingController _mainMapRadiusController =
      TextEditingController();
  final TextEditingController _miniMapRadiusController =
      TextEditingController();
  final TextEditingController _unclaimedRadiusController =
      TextEditingController();

  AppConfigurationModel _configuration = AppConfigurationModel.defaults;
  SmtpSecurityModeModel _smtpSecurityMode = SmtpSecurityModeModel.tls;
  bool _showExactPositionWhenFullyClaimed = true;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isTestingConnection = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadConfiguration();
  }

  @override
  void dispose() {
    _smtpHostController.dispose();
    _smtpPortController.dispose();
    _smtpUserNameController.dispose();
    _smtpUserEmailController.dispose();
    _smtpPasswordSecretNameController.dispose();
    _smtpPasswordController.dispose();
    _publicAppBaseUrlController.dispose();
    _mainMapRadiusController.dispose();
    _miniMapRadiusController.dispose();
    _unclaimedRadiusController.dispose();
    super.dispose();
  }

  Future<void> _loadConfiguration() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final configuration = await _apiClient.getAppConfiguration();
      if (!mounted) {
        return;
      }

      _applyConfiguration(configuration);
      setState(() => _isLoading = false);
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }

      final l10n = AppLocalizations.of(context)!;

      setState(() {
        _isLoading = false;
        _errorMessage = error.message.isEmpty
            ? l10n.configLoadError
            : error.message;
      });
    }
  }

  void _applyConfiguration(AppConfigurationModel configuration) {
    _configuration = configuration;
    _smtpHostController.text = configuration.smtpHost;
    _smtpPortController.text = configuration.smtpPort.toString();
    _smtpSecurityMode = configuration.smtpSecurityMode;
    _smtpUserNameController.text = configuration.smtpUserName;
    _smtpUserEmailController.text = configuration.smtpUserEmail;
    _smtpPasswordSecretNameController.text =
        configuration.smtpPasswordSecretName;
    _smtpPasswordController.clear();
    _publicAppBaseUrlController.text = configuration.publicAppBaseUrl;
    _mainMapRadiusController.text = configuration.mainMapRadiusKm.toString();
    _miniMapRadiusController.text = configuration.miniMapRadiusKm.toString();
    _unclaimedRadiusController.text = configuration.unclaimedDropRadiusKm
        .toString();
    _showExactPositionWhenFullyClaimed =
        configuration.showExactPositionWhenFullyClaimed;
  }

  Future<void> _saveConfiguration() async {
    final l10n = AppLocalizations.of(context)!;
    final smtpPort = _parseSmtpPort();
    final mainMapRadiusKm = int.tryParse(_mainMapRadiusController.text.trim());
    final miniMapRadiusKm = int.tryParse(_miniMapRadiusController.text.trim());
    final unclaimedDropRadiusKm = int.tryParse(
      _unclaimedRadiusController.text.trim(),
    );
    if (smtpPort == null ||
        smtpPort < 1 ||
        smtpPort > 65535 ||
        mainMapRadiusKm == null ||
        miniMapRadiusKm == null ||
        unclaimedDropRadiusKm == null ||
        mainMapRadiusKm < 1 ||
        miniMapRadiusKm < 1 ||
        unclaimedDropRadiusKm < 1) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.configLoadError)));
      return;
    }

    setState(() => _isSaving = true);
    try {
      final updated = await _apiClient.updateAppConfiguration(
        smtpHost: _smtpHostController.text.trim(),
        smtpPort: smtpPort,
        smtpSecurityMode: _smtpSecurityMode,
        smtpUserName: _smtpUserNameController.text.trim(),
        smtpUserEmail: _smtpUserEmailController.text.trim(),
        smtpPasswordSecretName: _smtpPasswordSecretNameController.text.trim(),
        publicAppBaseUrl: _publicAppBaseUrlController.text.trim(),
        mainMapRadiusKm: mainMapRadiusKm,
        miniMapRadiusKm: miniMapRadiusKm,
        unclaimedDropRadiusKm: unclaimedDropRadiusKm,
        showExactPositionWhenFullyClaimed: _showExactPositionWhenFullyClaimed,
      );
      if (!mounted) {
        return;
      }

      _applyConfiguration(updated);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.configSaveSuccess)));
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

  int? _parseSmtpPort() => int.tryParse(_smtpPortController.text.trim());

  Future<void> _testSmtpConnection() async {
    final l10n = AppLocalizations.of(context)!;
    final smtpHost = _smtpHostController.text.trim();
    final smtpPort = _parseSmtpPort();
    final smtpUserName = _smtpUserNameController.text.trim();
    final smtpPassword = _smtpPasswordController.text;
    final smtpPasswordSecretName = _smtpPasswordSecretNameController.text
        .trim();

    if (smtpHost.isEmpty) {
      _showSnackBar(l10n.smtpTestConnectionHostRequired);
      return;
    }

    if (smtpPort == null || smtpPort < 1 || smtpPort > 65535) {
      _showSnackBar(l10n.smtpTestConnectionPortInvalid);
      return;
    }

    final hasUserName = smtpUserName.isNotEmpty;
    final hasPassword =
        smtpPassword.isNotEmpty || smtpPasswordSecretName.isNotEmpty;
    if (hasUserName != hasPassword) {
      _showSnackBar(l10n.smtpTestConnectionCredentialsRequired);
      return;
    }

    setState(() => _isTestingConnection = true);
    try {
      final result = await _apiClient.testSmtpConnection(
        smtpHost: smtpHost,
        smtpPort: smtpPort,
        smtpSecurityMode: _smtpSecurityMode,
        smtpUserName: smtpUserName,
        smtpPassword: smtpPassword,
        smtpPasswordSecretName: smtpPasswordSecretName,
      );
      if (!mounted) {
        return;
      }

      _showSnackBar(result.message);
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }

      _showSnackBar(error.message);
    } finally {
      if (mounted) {
        setState(() => _isTestingConnection = false);
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
      title: l10n.navAdminConfig,
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
                    onPressed: _loadConfiguration,
                    child: Text(l10n.retryButton),
                  ),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              children: [
                AppSurfacePanel(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppSectionHeading(title: l10n.smtpLabel),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _smtpHostController,
                        decoration: InputDecoration(labelText: l10n.smtpLabel),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _smtpPortController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: l10n.smtpPortLabel,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<SmtpSecurityModeModel>(
                        initialValue: _smtpSecurityMode,
                        decoration: InputDecoration(
                          labelText: l10n.smtpSecurityModeLabel,
                        ),
                        items: [
                          DropdownMenuItem(
                            value: SmtpSecurityModeModel.startTls,
                            child: Text(l10n.smtpSecurityModeStartTls),
                          ),
                          DropdownMenuItem(
                            value: SmtpSecurityModeModel.tls,
                            child: Text(l10n.smtpSecurityModeTls),
                          ),
                        ],
                        onChanged: _isSaving || _isTestingConnection
                            ? null
                            : (value) {
                                if (value == null) {
                                  return;
                                }

                                setState(() => _smtpSecurityMode = value);
                              },
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _smtpUserNameController,
                        decoration: InputDecoration(
                          labelText: l10n.smtpUserNameLabel,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _smtpUserEmailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: l10n.smtpUserEmailLabel,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _smtpPasswordSecretNameController,
                        decoration: InputDecoration(
                          labelText: l10n.smtpPasswordSecretNameLabel,
                          helperText: _configuration.smtpPasswordConfigured
                              ? l10n.smtpPasswordConfiguredHint
                              : l10n.smtpPasswordMissingHint,
                        ),
                      ),
                      const SizedBox(height: 8),
                      PasswordTextField(
                        controller: _smtpPasswordController,
                        enabled: !_isSaving && !_isTestingConnection,
                        decoration: InputDecoration(
                          labelText: l10n.smtpPasswordLabel,
                          helperText: l10n.smtpPasswordTransientHint,
                        ),
                      ),
                    ],
                  ),
                ),
                AppSurfacePanel(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppSectionHeading(title: l10n.menuSettings),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _publicAppBaseUrlController,
                        decoration: InputDecoration(
                          labelText: l10n.publicAppBaseUrlLabel,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _mainMapRadiusController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: l10n.mainMapRadiusSetting,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _miniMapRadiusController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: l10n.miniMapRadiusSetting,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _unclaimedRadiusController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: l10n.unclaimedRadiusSetting,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        value: _showExactPositionWhenFullyClaimed,
                        onChanged: _isSaving
                            ? null
                            : (value) {
                                setState(
                                  () => _showExactPositionWhenFullyClaimed =
                                      value,
                                );
                              },
                        title: Text(l10n.showExactPositionSetting),
                      ),
                    ],
                  ),
                ),
                AppSurfacePanel(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppSectionHeading(
                        title: l10n.authProviderStatusSectionTitle,
                      ),
                      const SizedBox(height: 12),
                      if (_configuration.authProviders.isEmpty)
                        Text(l10n.authProviderStatusEmpty)
                      else
                        ..._configuration.authProviders.map(
                          (provider) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: AppSurfacePanel(
                              padding: const EdgeInsets.all(16),
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHighest,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    provider.displayName,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleLarge,
                                  ),
                                  const SizedBox(height: 10),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      _StatusChip(
                                        label: provider.enabled
                                            ? l10n.authProviderStatusEnabled
                                            : l10n.authProviderStatusDisabled,
                                        color: provider.enabled
                                            ? Colors.green
                                            : Colors.grey,
                                      ),
                                      _StatusChip(
                                        label: provider.visibleOnLogin
                                            ? l10n.authProviderStatusVisibleOnLogin
                                            : l10n.authProviderStatusHiddenOnLogin,
                                        color: provider.visibleOnLogin
                                            ? Colors.blue
                                            : Colors.orange,
                                      ),
                                      _StatusChip(
                                        label: provider.hasClientId
                                            ? l10n.authProviderStatusClientIdPresent
                                            : l10n.authProviderStatusClientIdMissing,
                                        color: provider.hasClientId
                                            ? Colors.green
                                            : Colors.red,
                                      ),
                                      _StatusChip(
                                        label: provider.hasClientSecret
                                            ? l10n.authProviderStatusClientSecretPresent
                                            : l10n.authProviderStatusClientSecretMissing,
                                        color: provider.hasClientSecret
                                            ? Colors.green
                                            : Colors.red,
                                      ),
                                      _StatusChip(
                                        label: provider.usesPkce
                                            ? l10n.authProviderStatusPkceEnabled
                                            : l10n.authProviderStatusPkceDisabled,
                                        color: provider.usesPkce
                                            ? Colors.teal
                                            : Colors.blueGrey,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                AppGlassPanel(
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      FilledButton(
                        onPressed: _isSaving || _isTestingConnection
                            ? null
                            : _saveConfiguration,
                        child: _isSaving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(l10n.saveButton),
                      ),
                      FilledButton.tonalIcon(
                        onPressed: _isSaving || _isTestingConnection
                            ? null
                            : _testSmtpConnection,
                        icon: _isTestingConnection
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.network_check_outlined),
                        label: Text(l10n.smtpTestConnectionButton),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  AppApiClient get _apiClient => widget.apiClient ?? AppApiClient();
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      side: BorderSide(color: color.withValues(alpha: 0.4)),
      backgroundColor: color.withValues(alpha: 0.12),
    );
  }
}
