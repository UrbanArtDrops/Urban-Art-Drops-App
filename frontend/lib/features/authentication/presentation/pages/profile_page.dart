import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:qr_flutter/qr_flutter.dart";
import "package:urban_art_drops_app/l10n/app_localizations.dart";

import "../../../../shared/models/app_models.dart";
import "../../../../shared/services/app_api_client.dart";
import "../../../../shared/services/local_photo_picker.dart";
import "../../../../shared/widgets/page_shell.dart";
import "../../../../shared/widgets/source_image.dart";
import "../bloc/auth_session_cubit.dart";

class ProfilePage extends StatefulWidget {
  const ProfilePage({
    super.key,
    AppApiClient? apiClient,
    LocalPhotoPicker? photoPicker,
  }) : _apiClient = apiClient,
       _photoPicker = photoPicker;

  final AppApiClient? _apiClient;
  final LocalPhotoPicker? _photoPicker;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late final AppApiClient _apiClient = widget._apiClient ?? AppApiClient();
  late final LocalPhotoPicker _photoPicker =
      widget._photoPicker ?? const FilePickerLocalPhotoPicker();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _userNameController = TextEditingController();
  final TextEditingController _mfaCodeController = TextEditingController();

  CurrentUserProfileModel? _profile;
  List<UserNotificationModel> _notifications = const [];
  bool _isLoading = true;
  bool _isSaving = false;
  String? _loadError;
  String? _profileImageSource;
  bool _profileImageDirty = false;
  String? _markingNotificationId;
  String? _mfaChallengeToken;
  bool _mfaSetupRequired = false;
  String? _mfaManualEntryKey;
  String? _mfaProvisioningUri;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _userNameController.dispose();
    _mfaCodeController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final results = await Future.wait<Object>([
        _apiClient.getCurrentUserProfile(),
        _apiClient.getCurrentUserNotifications(),
      ]);
      if (!mounted) {
        return;
      }

      final profile = results[0] as CurrentUserProfileModel;
      final notifications = results[1] as List<UserNotificationModel>;

      setState(() {
        _applyProfile(profile);
        _notifications = notifications;
        _isLoading = false;
      });
      _syncSessionProfile(profile);
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _loadError = error.message;
      });
    }
  }

  Future<void> _markNotificationRead(String notificationId) async {
    setState(() => _markingNotificationId = notificationId);
    try {
      final updatedNotification = await _apiClient
          .markCurrentUserNotificationRead(notificationId);
      if (!mounted) {
        return;
      }

      setState(() {
        _notifications = _notifications
            .map(
              (notification) => notification.id == updatedNotification.id
                  ? updatedNotification
                  : notification,
            )
            .toList(growable: false);
        _markingNotificationId = null;
      });
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() => _markingNotificationId = null);
      _showSnackBar(error.message);
    }
  }

  Future<void> _saveProfile() async {
    final l10n = AppLocalizations.of(context)!;
    final email = _emailController.text.trim();
    final userName = _userNameController.text.trim();
    if (email.isEmpty || userName.isEmpty) {
      _showSnackBar(l10n.authFillRegistrationHint);
      return;
    }

    setState(() => _isSaving = true);
    try {
      final updatedProfile = await _apiClient.updateCurrentUserProfile(
        email: email,
        userName: userName,
        profileImageSource: _profileImageDirty
            ? (_profileImageSource ?? "")
            : null,
      );
      if (!mounted) {
        return;
      }

      setState(() {
        _applyProfile(updatedProfile);
        _isSaving = false;
      });
      _syncSessionProfile(updatedProfile);
      _showSnackBar(l10n.profileSaveSuccess);
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() => _isSaving = false);
      _showSnackBar(error.message);
    }
  }

  Future<void> _pickProfileImage() async {
    try {
      final selections = await _photoPicker.pickPhotos();
      if (!mounted || selections.isEmpty) {
        return;
      }

      setState(() {
        _profileImageSource = selections.first.source;
        _profileImageDirty = true;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      _showSnackBar(AppLocalizations.of(context)!.profileImagePickerFailed);
    }
  }

  void _removeProfileImage() {
    setState(() {
      _profileImageSource = null;
      _profileImageDirty = true;
    });
  }

  Future<void> _beginMfaSetup() async {
    setState(() => _isSaving = true);
    try {
      final result = await _apiClient.beginCurrentUserMfaSetup();
      if (!mounted) {
        return;
      }

      setState(() {
        _isSaving = false;
        _mfaChallengeToken = result.mfaChallengeToken;
        _mfaSetupRequired = result.mfaSetupRequired;
        _mfaManualEntryKey = result.mfaManualEntryKey;
        _mfaProvisioningUri = result.mfaProvisioningUri;
        _mfaCodeController.clear();
      });
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() => _isSaving = false);
      _showSnackBar(error.message);
    }
  }

  Future<void> _completeMfaSetup() async {
    final l10n = AppLocalizations.of(context)!;
    final challengeToken = _mfaChallengeToken?.trim();
    final code = _mfaCodeController.text.trim();
    if (challengeToken == null || challengeToken.isEmpty || code.isEmpty) {
      _showSnackBar(l10n.profileMfaCodeRequired);
      return;
    }

    setState(() => _isSaving = true);
    try {
      final result = await _apiClient.completeMfaChallenge(
        challengeToken: challengeToken,
        code: code,
      );
      if (!mounted) {
        return;
      }

      _refreshAccessToken(result);
      await _loadProfile();
      if (!mounted) {
        return;
      }

      setState(() {
        _isSaving = false;
        _clearMfaState();
      });
      _showSnackBar(l10n.profileMfaSetupSuccess);
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() => _isSaving = false);
      _showSnackBar(error.message);
    }
  }

  Future<void> _disableMfa() async {
    final l10n = AppLocalizations.of(context)!;
    final code = _mfaCodeController.text.trim();
    if (code.isEmpty) {
      _showSnackBar(l10n.profileMfaCodeRequired);
      return;
    }

    setState(() => _isSaving = true);
    try {
      final updatedProfile = await _apiClient.disableCurrentUserMfa(code: code);
      if (!mounted) {
        return;
      }

      setState(() {
        _applyProfile(updatedProfile);
        _isSaving = false;
        _clearMfaState();
      });
      _syncSessionProfile(updatedProfile);
      _showSnackBar(l10n.profileMfaDisableSuccess);
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() => _isSaving = false);
      _showSnackBar(error.message);
    }
  }

  Future<void> _applyForRole(int role) async {
    setState(() => _isSaving = true);
    try {
      final updatedProfile = await _apiClient.applyForRole(role: role);
      if (!mounted) {
        return;
      }

      setState(() {
        _applyProfile(updatedProfile);
        _isSaving = false;
      });
      _syncSessionProfile(updatedProfile);
      _showSnackBar(
        AppLocalizations.of(context)!.profileRoleApplicationSubmitted,
      );
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() => _isSaving = false);
      _showSnackBar(error.message);
    }
  }

  void _applyProfile(CurrentUserProfileModel profile) {
    _profile = profile;
    _emailController.text = profile.email;
    _userNameController.text = profile.userName;
    _profileImageSource = profile.profileImageUrl;
    _profileImageDirty = false;
  }

  void _clearMfaState() {
    _mfaChallengeToken = null;
    _mfaSetupRequired = false;
    _mfaManualEntryKey = null;
    _mfaProvisioningUri = null;
    _mfaCodeController.clear();
  }

  void _syncSessionProfile(CurrentUserProfileModel profile) {
    context.read<AuthSessionCubit>().updateProfile(
      email: profile.email,
      userName: profile.userName,
      profileImageUrl: profile.profileImageUrl,
      role: appUserRoleFromApiValue(profile.role),
    );
  }

  void _refreshAccessToken(AuthResultModel result) {
    final state = context.read<AuthSessionCubit>().state;
    final role = state.role;
    final userId = state.userId;
    final accessToken = result.accessToken?.trim();
    if (!state.isAuthenticated ||
        role == null ||
        userId == null ||
        accessToken == null ||
        accessToken.isEmpty) {
      return;
    }

    context.read<AuthSessionCubit>().signIn(
      userId: userId,
      email: _profile?.email ?? state.email ?? "",
      userName: _profile?.userName ?? state.userName ?? "",
      profileImageUrl: _profile?.profileImageUrl ?? state.profileImageUrl,
      role: role,
      accessToken: accessToken,
      accessTokenExpiresAtUtc:
          result.accessTokenExpiresAtUtc ?? state.accessTokenExpiresAtUtc,
      tokenType: result.tokenType ?? state.tokenType ?? "Bearer",
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String? _formatNotificationTimestamp(
    BuildContext context,
    DateTime? createdAtUtc,
  ) {
    if (createdAtUtc == null) {
      return null;
    }

    final localTime = createdAtUtc.toLocal();
    final localizations = MaterialLocalizations.of(context);
    final dateLabel = localizations.formatShortDate(localTime);
    final timeLabel = localizations.formatTimeOfDay(
      TimeOfDay.fromDateTime(localTime),
      alwaysUse24HourFormat: true,
    );
    return "$dateLabel $timeLabel";
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return PageShell(
      title: l10n.menuProfile,
      body: BlocBuilder<AuthSessionCubit, AuthSessionState>(
        builder: (context, state) {
          if (!state.isAuthenticated || state.role == null) {
            return Center(child: Text(l10n.profileNotLoggedIn));
          }

          if (_isLoading && _profile == null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 12),
                  Text(l10n.loadingData),
                ],
              ),
            );
          }

          if (_loadError != null && _profile == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _loadError ?? l10n.profileLoadFailed,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _loadProfile,
                      child: Text(l10n.retryButton),
                    ),
                  ],
                ),
              ),
            );
          }

          final profile = _profile;
          if (profile == null) {
            return Center(child: Text(l10n.profileLoadFailed));
          }

          final pendingRole = profile.pendingRoleApplication;
          final hasPendingRoleApplication = pendingRole != null;
          final canApplyForRole =
              profile.role == AppUserRole.hunter.index &&
              !hasPendingRoleApplication;

          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              Card.outlined(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipOval(
                        child: SourceImage(
                          source: _profileImageSource,
                          fit: BoxFit.cover,
                          width: 88,
                          height: 88,
                          fallback: DecoratedBox(
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHighest,
                            ),
                            child: Icon(
                              Icons.person_outline,
                              size: 40,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              profile.userName,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 4),
                            Text(profile.email),
                            const SizedBox(height: 8),
                            Text(
                              l10n.profileRoleLabel(
                                _roleLabel(l10n, state.role!),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                Chip(
                                  label: Text(
                                    profile.isProviderAccount
                                        ? l10n.profileProviderAccountChip
                                        : l10n.profileLocalAccountChip,
                                  ),
                                ),
                                Chip(
                                  label: Text(
                                    profile.isMfaEnabled
                                        ? l10n.profileMfaEnabled
                                        : l10n.profileMfaDisabled,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
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
                        l10n.profileRoleApplicationSectionTitle,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      if (hasPendingRoleApplication) ...[
                        Text(
                          l10n.profileRoleApplicationPending(
                            _roleLabelForApiValue(l10n, pendingRole),
                          ),
                        ),
                        if (profile.pendingRoleApplicationRequestedAtUtc !=
                            null) ...[
                          const SizedBox(height: 8),
                          Text(
                            l10n.profileRoleApplicationRequestedAt(
                              _formatNotificationTimestamp(
                                    context,
                                    profile
                                        .pendingRoleApplicationRequestedAtUtc,
                                  ) ??
                                  "",
                            ),
                          ),
                        ],
                      ] else if (profile.role == AppUserRole.hunter.index) ...[
                        Text(l10n.profileRoleApplicationHint),
                      ] else ...[
                        Text(
                          l10n.profileRoleApplicationNotAvailableForCurrentRole,
                        ),
                      ],
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          OutlinedButton.icon(
                            onPressed: _isSaving || !canApplyForRole
                                ? null
                                : () => _applyForRole(AppUserRole.artist.index),
                            icon: const Icon(Icons.palette_outlined),
                            label: Text(l10n.profileApplyArtistAction),
                          ),
                          OutlinedButton.icon(
                            onPressed: _isSaving || !canApplyForRole
                                ? null
                                : () => _applyForRole(
                                    AppUserRole.dropMaker.index,
                                  ),
                            icon: const Icon(Icons.add_box_outlined),
                            label: Text(l10n.profileApplyDropMakerAction),
                          ),
                        ],
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
                        l10n.profileContactSectionTitle,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(labelText: l10n.emailLabel),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _userNameController,
                        decoration: InputDecoration(
                          labelText: l10n.profileDisplayNameLabel,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.profileImageSectionTitle,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(l10n.profileImageHint),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          OutlinedButton.icon(
                            onPressed: _isSaving ? null : _pickProfileImage,
                            icon: const Icon(Icons.upload_file_outlined),
                            label: Text(l10n.profileImageUploadAction),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            onPressed: _isSaving || _profileImageSource == null
                                ? null
                                : _removeProfileImage,
                            icon: const Icon(Icons.delete_outline),
                            label: Text(l10n.profileImageRemoveAction),
                          ),
                        ],
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
                        l10n.profileMfaSectionTitle,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        profile.isMfaEnabled
                            ? l10n.profileMfaEnabled
                            : l10n.profileMfaDisabled,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        profile.isMfaRequiredByPolicy
                            ? l10n.profileMfaRequiredByPolicy
                            : l10n.profileMfaOptionalHint,
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          FilledButton.icon(
                            onPressed: _isSaving ? null : _beginMfaSetup,
                            icon: const Icon(Icons.shield_outlined),
                            label: Text(
                              profile.isMfaEnabled
                                  ? l10n.profileMfaReconfigureAction
                                  : l10n.profileMfaSetupAction,
                            ),
                          ),
                          if (profile.isMfaEnabled)
                            OutlinedButton.icon(
                              onPressed: _isSaving ? null : _disableMfa,
                              icon: const Icon(Icons.shield_moon_outlined),
                              label: Text(l10n.profileMfaDisableAction),
                            ),
                        ],
                      ),
                      if (_mfaChallengeToken != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          _mfaSetupRequired
                              ? l10n.authMfaSetupHint
                              : l10n.authMfaRequired,
                        ),
                        if (_mfaProvisioningUri != null) ...[
                          const SizedBox(height: 12),
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
                              _completeMfaSetup();
                            }
                          },
                        ),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: _isSaving ? null : _completeMfaSetup,
                          child: Text(l10n.authMfaContinue),
                        ),
                      ] else if (profile.isMfaEnabled) ...[
                        const SizedBox(height: 16),
                        Text(l10n.profileMfaDisableHint),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _mfaCodeController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: l10n.authMfaCodeLabel,
                          ),
                        ),
                      ],
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
                        l10n.profileNotificationsSectionTitle,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      if (_notifications.isEmpty)
                        Text(l10n.profileNotificationsEmpty)
                      else
                        ..._notifications.map((notification) {
                          final isMarking =
                              _markingNotificationId == notification.id;
                          final timestampLabel = _formatNotificationTimestamp(
                            context,
                            notification.createdAtUtc,
                          );
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: notification.isRead
                                    ? Theme.of(
                                        context,
                                      ).colorScheme.surfaceContainerLow
                                    : Theme.of(
                                        context,
                                      ).colorScheme.secondaryContainer,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                notification.title,
                                                style: Theme.of(
                                                  context,
                                                ).textTheme.titleSmall,
                                              ),
                                              const SizedBox(height: 4),
                                              Text(notification.message),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Chip(
                                          label: Text(
                                            notification.isRead
                                                ? l10n.profileNotificationReadState
                                                : l10n.profileNotificationUnreadState,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (timestampLabel != null) ...[
                                      const SizedBox(height: 8),
                                      Text(
                                        timestampLabel,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodySmall,
                                      ),
                                    ],
                                    if (!notification.isRead) ...[
                                      const SizedBox(height: 8),
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: TextButton(
                                          onPressed: isMarking || _isSaving
                                              ? null
                                              : () => _markNotificationRead(
                                                  notification.id,
                                                ),
                                          child: isMarking
                                              ? const SizedBox(
                                                  width: 16,
                                                  height: 16,
                                                  child:
                                                      CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                      ),
                                                )
                                              : Text(
                                                  l10n.profileNotificationMarkReadAction,
                                                ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card.outlined(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilledButton(
                        onPressed: _isSaving ? null : _saveProfile,
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
                      OutlinedButton(
                        onPressed: _isSaving
                            ? null
                            : () => context.read<AuthSessionCubit>().signOut(),
                        child: Text(l10n.logoutButton),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

String _roleLabel(AppLocalizations l10n, AppUserRole role) {
  switch (role) {
    case AppUserRole.hunter:
      return l10n.roleHunter;
    case AppUserRole.artist:
      return l10n.roleArtist;
    case AppUserRole.dropMaker:
      return l10n.roleDropMaker;
    case AppUserRole.moderator:
      return l10n.navModeration;
    case AppUserRole.admin:
      return l10n.menuSettings;
  }
}

String _roleLabelForApiValue(AppLocalizations l10n, int? role) {
  final appRole = appUserRoleFromApiValue(role);
  if (appRole == null) {
    return l10n.roleHunter;
  }

  return _roleLabel(l10n, appRole);
}
