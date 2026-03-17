import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:go_router/go_router.dart";
import "package:urban_art_drops_app/l10n/app_localizations.dart";

import "../../../../shared/models/app_models.dart";
import "../../../../shared/services/app_api_client.dart";
import "../../../../shared/widgets/page_shell.dart";
import "../../../../shared/widgets/source_image.dart";
import "../../../authentication/presentation/bloc/auth_session_cubit.dart";

class ModerationPage extends StatefulWidget {
  const ModerationPage({this.apiClient, super.key});

  final AppApiClient? apiClient;

  @override
  State<ModerationPage> createState() => _ModerationPageState();
}

class _ModerationPageState extends State<ModerationPage> {
  late final AppApiClient _apiClient;

  ModerationQueueModel? _queue;
  bool _isLoading = false;
  String? _error;
  String? _pendingActionKey;
  String? _loadedModerationActorId;

  @override
  void initState() {
    super.initState();
    _apiClient = widget.apiClient ?? AppApiClient();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _ensureModerationQueueLoaded();
  }

  bool _canModerate(AuthSessionState authState) =>
      authState.isAuthenticated &&
      authState.userId != null &&
      (authState.role == AppUserRole.artist ||
          authState.role == AppUserRole.moderator ||
          authState.role == AppUserRole.admin);

  String? _moderationActorId(AuthSessionState authState) =>
      _canModerate(authState) ? authState.userId : null;

  void _ensureModerationQueueLoaded() {
    final authState = context.read<AuthSessionCubit>().state;
    final actorId = _moderationActorId(authState);

    if (actorId == null) {
      if (_loadedModerationActorId != null ||
          _queue != null ||
          _error != null ||
          _isLoading ||
          _pendingActionKey != null) {
        setState(() {
          _loadedModerationActorId = null;
          _queue = null;
          _error = null;
          _isLoading = false;
          _pendingActionKey = null;
        });
      }
      return;
    }

    if (_loadedModerationActorId == actorId) {
      return;
    }

    _loadedModerationActorId = actorId;
    _loadQueue(actorId);
  }

  Future<void> _loadQueue(String actingUserId) async {
    setState(() {
      _isLoading = true;
      _error = null;
      _pendingActionKey = null;
    });

    try {
      final queue = await _apiClient.getModerationQueue(
        actingUserId: actingUserId,
      );
      if (!mounted || _loadedModerationActorId != actingUserId) {
        return;
      }

      setState(() {
        _queue = queue;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted || _loadedModerationActorId != actingUserId) {
        return;
      }

      setState(() {
        _error = AppLocalizations.of(context)!.moderationLoadFailed;
        _isLoading = false;
      });
    }
  }

  Future<void> _runAction(
    String actionKey,
    Future<void> Function(String actingUserId) action,
  ) async {
    if (_pendingActionKey != null) {
      return;
    }

    final actorId = _moderationActorId(context.read<AuthSessionCubit>().state);
    if (actorId == null) {
      return;
    }

    setState(() => _pendingActionKey = actionKey);

    try {
      await action(actorId);
      if (!mounted) {
        return;
      }

      await _loadQueue(actorId);
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() => _pendingActionKey = null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.moderationActionFailed),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authState = context.watch<AuthSessionCubit>().state;
    final canModerate = _canModerate(authState);
    final canModerateArtPieces =
        authState.role == AppUserRole.moderator ||
        authState.role == AppUserRole.admin;

    return PageShell(
      title: l10n.moderationTitle,
      actions: [
        IconButton(
          tooltip: l10n.refreshAction,
          onPressed: _isLoading
              ? null
              : () {
                  final actorId = _moderationActorId(authState);
                  if (actorId != null) {
                    _loadQueue(actorId);
                  }
                },
          icon: const Icon(Icons.refresh),
        ),
      ],
      body: !canModerate
          ? Center(child: Text(l10n.moderationRestricted))
          : _isLoading
          ? Center(child: Text(l10n.loadingData))
          : _error != null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_error!),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () {
                      final actorId = _moderationActorId(authState);
                      if (actorId != null) {
                        _loadQueue(actorId);
                      }
                    },
                    child: Text(l10n.retryButton),
                  ),
                ],
              ),
            )
          : _queue == null
          ? Center(child: Text(l10n.moderationLoadFailed))
          : _ModerationContent(
              l10n: l10n,
              queue: _queue!,
              showArtPieceReports: canModerateArtPieces,
              pendingActionKey: _pendingActionKey,
              onHideComment: (comment) => _runAction(
                "comment-hide-${comment.id}",
                (actorId) => _apiClient.hideReportedComment(
                  comment.id,
                  actingUserId: actorId,
                ),
              ),
              onDismissComment: (comment) => _runAction(
                "comment-dismiss-${comment.id}",
                (actorId) => _apiClient.dismissReportedComment(
                  comment.id,
                  actingUserId: actorId,
                ),
              ),
              onDepublishArtPiece: (artPiece) => _runAction(
                "artpiece-depublish-${artPiece.id}",
                (actorId) => _apiClient.depublishReportedArtPiece(
                  artPiece.id,
                  actingUserId: actorId,
                ),
              ),
              onDismissArtPiece: (artPiece) => _runAction(
                "artpiece-dismiss-${artPiece.id}",
                (actorId) => _apiClient.dismissReportedArtPiece(
                  artPiece.id,
                  actingUserId: actorId,
                ),
              ),
            ),
    );
  }
}

class _ModerationContent extends StatelessWidget {
  const _ModerationContent({
    required this.l10n,
    required this.queue,
    required this.showArtPieceReports,
    required this.pendingActionKey,
    required this.onHideComment,
    required this.onDismissComment,
    required this.onDepublishArtPiece,
    required this.onDismissArtPiece,
  });

  final AppLocalizations l10n;
  final ModerationQueueModel queue;
  final bool showArtPieceReports;
  final String? pendingActionKey;
  final Future<void> Function(ReportedCommentModel comment) onHideComment;
  final Future<void> Function(ReportedCommentModel comment) onDismissComment;
  final Future<void> Function(ReportedArtPieceModel artPiece)
  onDepublishArtPiece;
  final Future<void> Function(ReportedArtPieceModel artPiece) onDismissArtPiece;

  @override
  Widget build(BuildContext context) {
    final hasItems = queue.comments.isNotEmpty || queue.artPieces.isNotEmpty;

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        if (!hasItems)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(l10n.moderationEmpty),
            ),
          ),
        if (queue.comments.isNotEmpty) ...[
          Text(
            l10n.moderationCommentSectionTitle,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          ...queue.comments.map(
            (comment) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ReportedCommentCard(
                l10n: l10n,
                comment: comment,
                isHiding: pendingActionKey == "comment-hide-${comment.id}",
                isDismissing:
                    pendingActionKey == "comment-dismiss-${comment.id}",
                onHide: () => onHideComment(comment),
                onDismiss: () => onDismissComment(comment),
              ),
            ),
          ),
        ],
        if (showArtPieceReports && queue.artPieces.isNotEmpty) ...[
          if (queue.comments.isNotEmpty) const SizedBox(height: 12),
          Text(
            l10n.moderationArtPieceSectionTitle,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          ...queue.artPieces.map(
            (artPiece) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ReportedArtPieceCard(
                l10n: l10n,
                artPiece: artPiece,
                isDepublishing:
                    pendingActionKey == "artpiece-depublish-${artPiece.id}",
                isDismissing:
                    pendingActionKey == "artpiece-dismiss-${artPiece.id}",
                onDepublish: () => onDepublishArtPiece(artPiece),
                onDismiss: () => onDismissArtPiece(artPiece),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _ReportedCommentCard extends StatelessWidget {
  const _ReportedCommentCard({
    required this.l10n,
    required this.comment,
    required this.isHiding,
    required this.isDismissing,
    required this.onHide,
    required this.onDismiss,
  });

  final AppLocalizations l10n;
  final ReportedCommentModel comment;
  final bool isHiding;
  final bool isDismissing;
  final Future<void> Function() onHide;
  final Future<void> Function() onDismiss;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              comment.dropTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(l10n.moderationReportedBy(comment.authorDisplayName)),
            const SizedBox(height: 4),
            Text(
              l10n.moderationReportedAt(_formatDateTime(comment.reportedAtUtc)),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Text(comment.content),
            const SizedBox(height: 12),
            Text(
              l10n.moderationReportReason(
                _normalizeReason(comment.reportReason, l10n),
              ),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () =>
                      context.go("/hunter/drops/${comment.dropId}"),
                  icon: const Icon(Icons.open_in_new_outlined),
                  label: Text(l10n.moderationOpenDropAction),
                ),
                FilledButton.icon(
                  onPressed: isHiding || isDismissing ? null : onHide,
                  icon: isHiding
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.visibility_off_outlined),
                  label: Text(l10n.moderationHideCommentAction),
                ),
                TextButton(
                  onPressed: isHiding || isDismissing ? null : onDismiss,
                  child: isDismissing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n.moderationDismissReportAction),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportedArtPieceCard extends StatelessWidget {
  const _ReportedArtPieceCard({
    required this.l10n,
    required this.artPiece,
    required this.isDepublishing,
    required this.isDismissing,
    required this.onDepublish,
    required this.onDismiss,
  });

  final AppLocalizations l10n;
  final ReportedArtPieceModel artPiece;
  final bool isDepublishing;
  final bool isDismissing;
  final Future<void> Function() onDepublish;
  final Future<void> Function() onDismiss;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SourceImage(
                    source: artPiece.previewImageUrl,
                    width: 96,
                    height: 96,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        artPiece.title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        l10n.moderationArtistLabel(artPiece.artistDisplayName),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        artPiece.isPublished
                            ? l10n.statusPublished
                            : l10n.statusUnpublished,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.moderationReportedAt(
                          _formatDateTime(artPiece.reportedAtUtc),
                        ),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              l10n.moderationReportReason(
                _normalizeReason(artPiece.reportReason, l10n),
              ),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: isDepublishing || isDismissing
                      ? null
                      : onDepublish,
                  icon: isDepublishing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.unpublished_outlined),
                  label: Text(l10n.moderationDepublishArtPieceAction),
                ),
                TextButton(
                  onPressed: isDepublishing || isDismissing ? null : onDismiss,
                  child: isDismissing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n.moderationDismissReportAction),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

String _formatDateTime(DateTime? value) {
  if (value == null) {
    return "-";
  }

  final local = value.toLocal();
  final day = local.day.toString().padLeft(2, "0");
  final month = local.month.toString().padLeft(2, "0");
  final year = local.year.toString().padLeft(4, "0");
  final hour = local.hour.toString().padLeft(2, "0");
  final minute = local.minute.toString().padLeft(2, "0");
  return "$day.$month.$year $hour:$minute";
}

String _normalizeReason(String? reason, AppLocalizations l10n) {
  final normalized = reason?.trim() ?? "";
  if (normalized.isEmpty) {
    return l10n.moderationNoReasonProvided;
  }

  return normalized;
}
