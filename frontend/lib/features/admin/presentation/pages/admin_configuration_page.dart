import "package:flutter/material.dart";
import "package:urban_art_drops_app/l10n/app_localizations.dart";

import "../../../../shared/models/app_models.dart";
import "../../../../shared/services/app_api_client.dart";
import "../../../../shared/widgets/page_shell.dart";

class AdminConfigurationPage extends StatefulWidget {
  const AdminConfigurationPage({super.key});

  @override
  State<AdminConfigurationPage> createState() => _AdminConfigurationPageState();
}

class _AdminConfigurationPageState extends State<AdminConfigurationPage> {
  final AppApiClient _apiClient = AppApiClient();
  final TextEditingController _smtpHostController = TextEditingController();
  final TextEditingController _publicAppBaseUrlController =
      TextEditingController();
  final TextEditingController _mainMapRadiusController =
      TextEditingController();
  final TextEditingController _miniMapRadiusController =
      TextEditingController();
  final TextEditingController _unclaimedRadiusController =
      TextEditingController();

  bool _showExactPositionWhenFullyClaimed = true;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadConfiguration();
  }

  @override
  void dispose() {
    _smtpHostController.dispose();
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
    _smtpHostController.text = configuration.smtpHost;
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
    final mainMapRadiusKm = int.tryParse(_mainMapRadiusController.text.trim());
    final miniMapRadiusKm = int.tryParse(_miniMapRadiusController.text.trim());
    final unclaimedDropRadiusKm = int.tryParse(
      _unclaimedRadiusController.text.trim(),
    );
    if (mainMapRadiusKm == null ||
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
              padding: const EdgeInsets.all(12),
              children: [
                TextField(
                  controller: _smtpHostController,
                  decoration: InputDecoration(labelText: l10n.smtpLabel),
                ),
                const SizedBox(height: 8),
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
                            () => _showExactPositionWhenFullyClaimed = value,
                          );
                        },
                  title: Text(l10n.showExactPositionSetting),
                ),
                FilledButton(
                  onPressed: _isSaving ? null : _saveConfiguration,
                  child: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n.saveButton),
                ),
              ],
            ),
    );
  }
}
