import "package:flutter/material.dart";
import "package:urban_art_drops_app/l10n/app_localizations.dart";

import "../../../../shared/models/app_models.dart";
import "../../../../shared/services/app_api_client.dart";
import "../../../../shared/widgets/page_shell.dart";

class AdminUserManagementPage extends StatefulWidget {
  const AdminUserManagementPage({super.key});

  @override
  State<AdminUserManagementPage> createState() =>
      _AdminUserManagementPageState();
}

class _AdminUserManagementPageState extends State<AdminUserManagementPage> {
  final AppApiClient _apiClient = AppApiClient();
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
      await _loadUsers();
    });
  }

  Future<void> _editUserProfile(ManagedUser user) async {
    final l10n = AppLocalizations.of(context)!;
    final userNameController = TextEditingController(text: user.userName);
    final emailController = TextEditingController(text: user.email);
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
      await _loadUsers();
    });
  }

  Future<void> _changeRole(ManagedUser user) async {
    final l10n = AppLocalizations.of(context)!;
    var role = user.role;
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
      await _loadUsers();
    });
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

  Future<void> _withSaving(Future<void> Function() action) async {
    setState(() => _isSaving = true);
    try {
      await action();
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

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
                              final approvedLabel = user.isApproved
                                  ? l10n.userApproved
                                  : l10n.userNotApproved;
                              final suspendedLabel = user.isSuspended
                                  ? l10n.userSuspended
                                  : l10n.userActive;

                              return Card(
                                child: ListTile(
                                  title: Text(user.userName),
                                  subtitle: Text(
                                    "${user.email}\n${_roleLabel(l10n, user.role)} · $approvedLabel · $suspendedLabel",
                                  ),
                                  isThreeLine: true,
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
                                      }
                                    },
                                    itemBuilder: (_) => [
                                      PopupMenuItem(
                                        value: "approval",
                                        child: Text(
                                          user.isApproved
                                              ? l10n.userRevokeApprovalAction
                                              : l10n.userApproveAction,
                                        ),
                                      ),
                                      PopupMenuItem(
                                        value: "suspension",
                                        child: Text(
                                          user.isSuspended
                                              ? l10n.userUnsuspendAction
                                              : l10n.userSuspendAction,
                                        ),
                                      ),
                                      PopupMenuItem(
                                        value: "role",
                                        child: Text(l10n.userChangeRoleAction),
                                      ),
                                      PopupMenuItem(
                                        value: "username",
                                        child: Text(l10n.userEditProfileAction),
                                      ),
                                    ],
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
