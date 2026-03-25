import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:urban_art_drops_app/l10n/app_localizations.dart";

import "../../../authentication/presentation/bloc/auth_session_cubit.dart";
import "../../../../shared/models/app_models.dart";
import "../../../../shared/services/app_api_client.dart";
import "../../../../shared/widgets/page_shell.dart";
import "../../../../shared/widgets/source_image.dart";

class AdminUserManagementPage extends StatefulWidget {
  const AdminUserManagementPage({super.key, AppApiClient? apiClient})
    : _apiClient = apiClient;

  final AppApiClient? _apiClient;

  @override
  State<AdminUserManagementPage> createState() =>
      _AdminUserManagementPageState();
}

class _AdminUserManagementPageState extends State<AdminUserManagementPage> {
  late final AppApiClient _apiClient = widget._apiClient ?? AppApiClient();
  List<ManagedUser> _users = const [];
  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final users = await _apiClient.getUsers();
      if (!mounted) {
        return;
      }

      setState(() {
        _users = users;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error = AppLocalizations.of(context)!.usersLoadFailed;
        _isLoading = false;
      });
    }
  }

  Future<void> _createUser() async {
    final l10n = AppLocalizations.of(context)!;
    final emailController = TextEditingController();
    final userNameController = TextEditingController();
    final passwordController = TextEditingController();
    var role = 0;

    try {
      final shouldSave = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(l10n.userCreateTitle),
          content: StatefulBuilder(
            builder: (context, setStateDialog) => SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: emailController,
                    decoration: InputDecoration(labelText: l10n.emailLabel),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: userNameController,
                    decoration: InputDecoration(labelText: l10n.usernameLabel),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: passwordController,
                    decoration: InputDecoration(labelText: l10n.passwordLabel),
                    obscureText: true,
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    initialValue: role,
                    decoration: InputDecoration(labelText: l10n.roleLabel),
                    items: _roleOptions(l10n),
                    onChanged: (value) {
                      if (value != null) {
                        setStateDialog(() => role = value);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.cancelAction),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l10n.saveButton),
            ),
          ],
        ),
      );

      if (shouldSave != true) {
        return;
      }

      await _withSaving(() async {
        await _apiClient.createManagedUser(
          email: emailController.text.trim(),
          userName: userNameController.text.trim(),
          role: role,
          isApproved: true,
          isEmailVerified: true,
          isProviderAccount: false,
          password: passwordController.text.trim(),
        );
      });
    } finally {
      emailController.dispose();
      userNameController.dispose();
      passwordController.dispose();
      if (mounted) {
        await _loadUsers();
      }
    }
  }

  Future<void> _editUserProfile(ManagedUser user) async {
    final l10n = AppLocalizations.of(context)!;
    final userNameController = TextEditingController(text: user.userName);
    final emailController = TextEditingController(text: user.email);
    try {
      final shouldSave = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(l10n.userEditProfileTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: userNameController,
                decoration: InputDecoration(labelText: l10n.usernameLabel),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(labelText: l10n.emailLabel),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.cancelAction),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l10n.saveButton),
            ),
          ],
        ),
      );

      if (shouldSave != true) {
        return;
      }

      await _withSaving(() async {
        await _apiClient.updateUserProfile(
          userId: user.id,
          userName: userNameController.text.trim(),
          email: emailController.text.trim(),
        );
      });
    } finally {
      userNameController.dispose();
      emailController.dispose();
      if (mounted) {
        await _loadUsers();
      }
    }
  }

  Future<void> _changeRole(ManagedUser user) async {
    final l10n = AppLocalizations.of(context)!;
    var role = user.role;
    try {
      final shouldSave = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(l10n.userChangeRoleAction),
          content: StatefulBuilder(
            builder: (context, setStateDialog) => DropdownButtonFormField<int>(
              initialValue: role,
              decoration: InputDecoration(labelText: l10n.roleLabel),
              items: _roleOptions(l10n),
              onChanged: (value) {
                if (value != null) {
                  setStateDialog(() => role = value);
                }
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.cancelAction),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l10n.saveButton),
            ),
          ],
        ),
      );

      if (shouldSave != true) {
        return;
      }

      await _withSaving(() async {
        await _apiClient.updateUserRole(user.id, role);
      });
    } finally {
      if (mounted) {
        await _loadUsers();
      }
    }
  }

  Future<void> _toggleApproval(ManagedUser user) async {
    await _withSaving(() async {
      await _apiClient.updateUserApproval(user.id, !user.isApproved);
      await _loadUsers();
    });
  }

  Future<void> _toggleSuspension(ManagedUser user) async {
    await _withSaving(() async {
      await _apiClient.updateUserSuspension(user.id, !user.isSuspended);
      await _loadUsers();
    });
  }

  Future<void> _approveRoleApplication(ManagedUser user) async {
    await _withSaving(() async {
      final updatedUser = await _apiClient.approveUserRoleApplication(user.id);
      if (!mounted) {
        return;
      }

      setState(() {
        _users = _users
            .map((entry) => entry.id == updatedUser.id ? updatedUser : entry)
            .toList(growable: false);
      });
    });
  }

  Future<void> _rejectRoleApplication(ManagedUser user) async {
    await _withSaving(() async {
      final updatedUser = await _apiClient.rejectUserRoleApplication(user.id);
      if (!mounted) {
        return;
      }

      setState(() {
        _users = _users
            .map((entry) => entry.id == updatedUser.id ? updatedUser : entry)
            .toList(growable: false);
      });
    });
  }

  Future<void> _withSaving(Future<void> Function() action) async {
    setState(() => _isSaving = true);
    try {
      await action();
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.genericSaveError),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  List<DropdownMenuItem<int>> _roleOptions(AppLocalizations l10n) => [
    DropdownMenuItem(value: 0, child: Text(l10n.roleHunter)),
    DropdownMenuItem(value: 1, child: Text(l10n.roleArtist)),
    DropdownMenuItem(value: 2, child: Text(l10n.roleDropMaker)),
    DropdownMenuItem(value: 3, child: Text(l10n.navModeration)),
    DropdownMenuItem(value: 4, child: Text(l10n.menuSettings)),
  ];

  String _roleLabel(AppLocalizations l10n, int role) {
    switch (role) {
      case 1:
        return l10n.roleArtist;
      case 2:
        return l10n.roleDropMaker;
      case 3:
        return l10n.navModeration;
      case 4:
        return l10n.menuSettings;
      default:
        return l10n.roleHunter;
    }
  }

  IconData _roleIcon(int role) {
    switch (role) {
      case 1:
        return Icons.palette_outlined;
      case 2:
        return Icons.add_box_outlined;
      case 3:
        return Icons.gavel_outlined;
      case 4:
        return Icons.admin_panel_settings_outlined;
      default:
        return Icons.explore_outlined;
    }
  }

  Color _roleIconColor(BuildContext context, int role) {
    switch (role) {
      case 1:
        return Theme.of(context).colorScheme.primary;
      case 2:
        return Theme.of(context).colorScheme.tertiary;
      case 3:
        return Theme.of(context).colorScheme.secondary;
      case 4:
        return Theme.of(context).colorScheme.error;
      default:
        return Theme.of(context).colorScheme.onSurfaceVariant;
    }
  }

  Widget _buildProfileAvatar(BuildContext context, ManagedUser user) {
    final colorScheme = Theme.of(context).colorScheme;
    return CircleAvatar(
      radius: 24,
      backgroundColor: colorScheme.surfaceContainerHighest,
      child: ClipOval(
        child: SourceImage(
          source: user.profileImageUrl,
          fit: BoxFit.cover,
          width: 48,
          height: 48,
          fallback: DecoratedBox(
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
            ),
            child: Icon(
              Icons.person_outline,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIcons(
    BuildContext context,
    AppLocalizations l10n,
    ManagedUser user,
  ) {
    final pendingRoleLabel = user.pendingRoleApplication == null
        ? null
        : _roleLabel(l10n, user.pendingRoleApplication!);

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        Tooltip(
          message: _roleLabel(l10n, user.role),
          child: Icon(
            _roleIcon(user.role),
            color: _roleIconColor(context, user.role),
          ),
        ),
        if (pendingRoleLabel != null)
          Tooltip(
            message: l10n.userRoleApplicationPending(pendingRoleLabel),
            child: Icon(
              Icons.notifications_active_outlined,
              color: Theme.of(context).colorScheme.error,
            ),
          ),
        Tooltip(
          message: user.isApproved ? l10n.userApproved : l10n.userNotApproved,
          child: Icon(
            user.isApproved ? Icons.verified_outlined : Icons.pending_outlined,
            color: user.isApproved
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.error,
          ),
        ),
        Tooltip(
          message: user.isSuspended ? l10n.userSuspended : l10n.userActive,
          child: Icon(
            user.isSuspended ? Icons.lock_outline : Icons.lock_open_outlined,
            color: user.isSuspended
                ? Theme.of(context).colorScheme.error
                : Theme.of(context).colorScheme.primary,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authState = context.watch<AuthSessionCubit>().state;

    return PageShell(
      title: l10n.menuUsers,
      body: _isLoading
          ? Center(child: Text(l10n.loadingData))
          : _error != null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_error!),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: _loadUsers,
                    child: Text(l10n.retryButton),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      FilledButton.icon(
                        onPressed: _isSaving ? null : _createUser,
                        icon: const Icon(Icons.person_add_alt_1_outlined),
                        label: Text(l10n.createAction),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: _isSaving ? null : _loadUsers,
                        icon: const Icon(Icons.refresh),
                        label: Text(l10n.refreshAction),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _users.isEmpty
                      ? Center(child: Text(l10n.noUsersAvailable))
                      : RefreshIndicator(
                          onRefresh: _loadUsers,
                          child: ListView.builder(
                            itemCount: _users.length,
                            itemBuilder: (context, index) {
                              final user = _users[index];
                              final isCurrentAdmin =
                                  authState.userId == user.id;
                              final approvedLabel = user.isApproved
                                  ? l10n.userApproved
                                  : l10n.userNotApproved;
                              final suspendedLabel = user.isSuspended
                                  ? l10n.userSuspended
                                  : l10n.userActive;
                              final pendingRoleLabel =
                                  user.pendingRoleApplication == null
                                  ? null
                                  : _roleLabel(
                                      l10n,
                                      user.pendingRoleApplication!,
                                    );
                              final subtitleLines = <String>[
                                user.email,
                                "${_roleLabel(l10n, user.role)} · $approvedLabel · $suspendedLabel",
                              ];
                              if (pendingRoleLabel != null) {
                                subtitleLines.add(
                                  l10n.userRoleApplicationPending(
                                    pendingRoleLabel,
                                  ),
                                );
                              }

                              return Card(
                                child: ListTile(
                                  leading: _buildProfileAvatar(context, user),
                                  title: Row(
                                    children: [
                                      Expanded(child: Text(user.userName)),
                                      _buildStatusIcons(context, l10n, user),
                                    ],
                                  ),
                                  subtitle: Text(subtitleLines.join("\n")),
                                  isThreeLine: pendingRoleLabel != null,
                                  trailing: PopupMenuButton<String>(
                                    onSelected: (value) {
                                      switch (value) {
                                        case "approval":
                                          _toggleApproval(user);
                                          break;
                                        case "suspension":
                                          _toggleSuspension(user);
                                          break;
                                        case "role":
                                          _changeRole(user);
                                          break;
                                        case "username":
                                          _editUserProfile(user);
                                          break;
                                        case "approveRoleApplication":
                                          _approveRoleApplication(user);
                                          break;
                                        case "rejectRoleApplication":
                                          _rejectRoleApplication(user);
                                          break;
                                      }
                                    },
                                    itemBuilder: (_) {
                                      final items = <PopupMenuEntry<String>>[
                                        PopupMenuItem(
                                          value: "role",
                                          child: Text(
                                            l10n.userChangeRoleAction,
                                          ),
                                        ),
                                        PopupMenuItem(
                                          value: "username",
                                          child: Text(
                                            l10n.userEditProfileAction,
                                          ),
                                        ),
                                      ];
                                      if (!isCurrentAdmin) {
                                        items.insert(
                                          0,
                                          PopupMenuItem(
                                            value: "approval",
                                            child: Text(
                                              user.isApproved
                                                  ? l10n.userRevokeApprovalAction
                                                  : l10n.userApproveAction,
                                            ),
                                          ),
                                        );
                                        items.insert(
                                          1,
                                          PopupMenuItem(
                                            value: "suspension",
                                            child: Text(
                                              user.isSuspended
                                                  ? l10n.userUnsuspendAction
                                                  : l10n.userSuspendAction,
                                            ),
                                          ),
                                        );
                                      }
                                      if (pendingRoleLabel != null) {
                                        items.add(
                                          PopupMenuItem(
                                            value: "approveRoleApplication",
                                            child: Text(
                                              l10n.userApproveRoleApplicationAction,
                                            ),
                                          ),
                                        );
                                        items.add(
                                          PopupMenuItem(
                                            value: "rejectRoleApplication",
                                            child: Text(
                                              l10n.userRejectRoleApplicationAction,
                                            ),
                                          ),
                                        );
                                      }

                                      return items;
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }
}
