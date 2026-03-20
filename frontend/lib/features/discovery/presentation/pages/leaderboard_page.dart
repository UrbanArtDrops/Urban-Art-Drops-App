import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:go_router/go_router.dart";
import "package:urban_art_drops_app/l10n/app_localizations.dart";

import "../../../authentication/presentation/bloc/auth_session_cubit.dart";
import "../../../../shared/models/app_models.dart";
import "../../../../shared/services/app_api_client.dart";
import "../../../../shared/widgets/page_shell.dart";
import "../../../../shared/widgets/user_avatar.dart";

class LeaderboardPage extends StatefulWidget {
  const LeaderboardPage({super.key, AppApiClient? apiClient})
    : _apiClient = apiClient;

  final AppApiClient? _apiClient;

  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
  static const double _estimatedLeaderboardEntryExtent = 104;

  late final AppApiClient _apiClient = widget._apiClient ?? AppApiClient();
  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _entryKeys = <String, GlobalKey>{};
  List<_LeaderboardViewModel> _entries = const [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadLeaderboard();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadLeaderboard() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _apiClient.getDrops(),
        _apiClient.getArtPieces(),
        _apiClient.getUserDirectory(),
      ]);
      if (!mounted) {
        return;
      }

      final drops = results[0] as List<DropModel>;
      final artPieces = results[1] as List<ArtPieceModel>;
      final users = results[2] as List<ManagedUser>;

      final l10n = AppLocalizations.of(context)!;
      final authSession = context.read<AuthSessionCubit>().state;
      final currentHunterKey =
          authSession.isAuthenticated && authSession.userId != null
          ? "user:${authSession.userId!}"
          : null;
      final artById = {for (final art in artPieces) art.id: art};
      final usersById = {for (final user in users) user.id: user};
      final aggregates = <String, _HunterAggregate>{};

      for (final drop in drops) {
        final artPiece = artById[drop.artPieceId];
        final dropTitle = artPiece?.title ?? l10n.dropFallbackTitle(drop.id);
        final previewImageUrl = _resolveDropPreviewImage(
          artPiece: artPiece,
          drop: drop,
        );
        for (final item in drop.claimedItems) {
          final hunterKey = _resolveHunterKey(item);
          if (hunterKey == null) {
            continue;
          }

          final hunterDisplayName = _resolveHunterDisplayName(
            item: item,
            usersById: usersById,
            l10n: l10n,
          );

          final aggregate = aggregates.putIfAbsent(
            hunterKey,
            () => _HunterAggregate(
              hunterKey: hunterKey,
              displayName: hunterDisplayName,
              profileImageUrl: _resolveHunterProfileImageUrl(
                item: item,
                usersById: usersById,
              ),
            ),
          );
          aggregate.totalClaims += 1;
          aggregate.claimedDrops.update(
            drop.id,
            (existing) =>
                existing.copyWith(claimedItems: existing.claimedItems + 1),
            ifAbsent: () => _ClaimedDropSummary(
              dropId: drop.id,
              dropTitle: dropTitle,
              previewImageUrl: previewImageUrl,
              claimedItems: 1,
            ),
          );
        }
      }

      final entries =
          aggregates.values
              .map(
                (aggregate) => _LeaderboardViewModel(
                  hunterKey: aggregate.hunterKey,
                  hunterName: aggregate.displayName,
                  hunterProfileImageUrl: aggregate.profileImageUrl,
                  claims: aggregate.totalClaims,
                  isCurrentUser: aggregate.hunterKey == currentHunterKey,
                  claimedDrops:
                      aggregate.claimedDrops.values.toList(growable: false)
                        ..sort(
                          (a, b) =>
                              b.claimedItems.compareTo(a.claimedItems) != 0
                              ? b.claimedItems.compareTo(a.claimedItems)
                              : a.dropTitle.toLowerCase().compareTo(
                                  b.dropTitle.toLowerCase(),
                                ),
                        ),
                ),
              )
              .toList(growable: false)
            ..sort(
              (a, b) => b.claims.compareTo(a.claims) != 0
                  ? b.claims.compareTo(a.claims)
                  : a.hunterName.toLowerCase().compareTo(
                      b.hunterName.toLowerCase(),
                    ),
            );

      setState(() {
        _entries = entries;
        _isLoading = false;
      });
      _centerCurrentUserEntry();
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error = AppLocalizations.of(context)!.leaderboardLoadFailed;
        _isLoading = false;
      });
    }
  }

  void _centerCurrentUserEntry() {
    final currentIndex = _entries.indexWhere((entry) => entry.isCurrentUser);
    if (currentIndex < 0) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) {
        return;
      }

      final viewportExtent = _scrollController.position.viewportDimension;
      final estimatedOffset =
          (currentIndex * _estimatedLeaderboardEntryExtent) -
          (viewportExtent / 2) +
          (_estimatedLeaderboardEntryExtent / 2);
      final clampedOffset = estimatedOffset.clamp(
        0.0,
        _scrollController.position.maxScrollExtent,
      );
      _scrollController.jumpTo(clampedOffset);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }

        final targetContext =
            _entryKeys[_entries[currentIndex].hunterKey]?.currentContext;
        if (targetContext != null) {
          Scrollable.ensureVisible(
            targetContext,
            alignment: 0.5,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
          );
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return PageShell(
      title: l10n.navLeaderboard,
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
                    onPressed: _loadLeaderboard,
                    child: Text(l10n.retryButton),
                  ),
                ],
              ),
            )
          : _entries.isEmpty
          ? Center(child: Text(l10n.leaderboardEmpty))
          : RefreshIndicator(
              onRefresh: _loadLeaderboard,
              child: ListView.separated(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                itemCount: _entries.length,
                separatorBuilder: (context, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final entry = _entries[index];
                  final rank = index + 1;
                  final borderColor = entry.isCurrentUser
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outlineVariant;

                  return KeyedSubtree(
                    key: _entryKeys.putIfAbsent(entry.hunterKey, GlobalKey.new),
                    child: Card(
                      key: ValueKey("leaderboard-entry-${entry.hunterKey}"),
                      color: entry.isCurrentUser
                          ? theme.colorScheme.primaryContainer
                          : null,
                      surfaceTintColor: entry.isCurrentUser
                          ? theme.colorScheme.primary
                          : null,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: borderColor, width: 1.5),
                      ),
                      child: ExpansionTile(
                        key: PageStorageKey(
                          "leaderboard-tile-${entry.hunterKey}",
                        ),
                        leading: _RankBadge(rank: rank),
                        initiallyExpanded: entry.isCurrentUser,
                        tilePadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 2,
                        ),
                        title: Row(
                          children: [
                            UserAvatar(
                              key: ValueKey(
                                "leaderboard-avatar-${entry.hunterKey}",
                              ),
                              displayName: entry.hunterName,
                              imageUrl: entry.hunterProfileImageUrl,
                              radius: 18,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                l10n.rankEntry("$rank", entry.hunterName),
                                style: entry.isCurrentUser
                                    ? theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w700,
                                      )
                                    : null,
                              ),
                            ),
                          ],
                        ),
                        subtitle: Text(
                          l10n.leaderboardClaimCount("${entry.claims}"),
                        ),
                        childrenPadding: const EdgeInsets.fromLTRB(
                          12,
                          0,
                          12,
                          12,
                        ),
                        children: entry.claimedDrops.isEmpty
                            ? [Text(l10n.leaderboardNoClaimedDrops)]
                            : entry.claimedDrops
                                  .map(
                                    (claimedDrop) => ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      leading: _LeaderboardDropImage(
                                        imageUrl: claimedDrop.previewImageUrl,
                                      ),
                                      title: Text(claimedDrop.dropTitle),
                                      subtitle: Text(
                                        l10n.leaderboardDropClaimCount(
                                          "${claimedDrop.claimedItems}",
                                        ),
                                      ),
                                      trailing: const Icon(Icons.chevron_right),
                                      onTap: () => context.go(
                                        "/hunter/drops/${claimedDrop.dropId}",
                                      ),
                                    ),
                                  )
                                  .toList(growable: false),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}

String? _resolveHunterKey(DropItemModel item) {
  if (item.claimedByUserId != null && item.claimedByUserId!.isNotEmpty) {
    return "user:${item.claimedByUserId}";
  }
  if (item.claimedByAnonymousNickname != null &&
      item.claimedByAnonymousNickname!.trim().isNotEmpty) {
    return "anon:${item.claimedByAnonymousNickname!.trim().toLowerCase()}";
  }

  return null;
}

String _resolveHunterDisplayName({
  required DropItemModel item,
  required Map<String, ManagedUser> usersById,
  required AppLocalizations l10n,
}) {
  if (item.claimedByUserId != null) {
    final user = usersById[item.claimedByUserId!];
    return user?.userName ?? item.claimedByUserId!;
  }

  final anonymous = item.claimedByAnonymousNickname?.trim();
  if (anonymous != null && anonymous.isNotEmpty) {
    return anonymous;
  }

  return l10n.leaderboardAnonymousFallback;
}

String? _resolveHunterProfileImageUrl({
  required DropItemModel item,
  required Map<String, ManagedUser> usersById,
}) {
  final claimedByUserId = item.claimedByUserId;
  if (claimedByUserId == null || claimedByUserId.isEmpty) {
    return null;
  }

  return usersById[claimedByUserId]?.profileImageUrl;
}

class _LeaderboardViewModel {
  const _LeaderboardViewModel({
    required this.hunterKey,
    required this.hunterName,
    required this.hunterProfileImageUrl,
    required this.claims,
    required this.isCurrentUser,
    required this.claimedDrops,
  });

  final String hunterKey;
  final String hunterName;
  final String? hunterProfileImageUrl;
  final int claims;
  final bool isCurrentUser;
  final List<_ClaimedDropSummary> claimedDrops;
}

class _ClaimedDropSummary {
  const _ClaimedDropSummary({
    required this.dropId,
    required this.dropTitle,
    required this.previewImageUrl,
    required this.claimedItems,
  });

  final String dropId;
  final String dropTitle;
  final String previewImageUrl;
  final int claimedItems;

  _ClaimedDropSummary copyWith({int? claimedItems}) {
    return _ClaimedDropSummary(
      dropId: dropId,
      dropTitle: dropTitle,
      previewImageUrl: previewImageUrl,
      claimedItems: claimedItems ?? this.claimedItems,
    );
  }
}

class _HunterAggregate {
  _HunterAggregate({
    required this.hunterKey,
    required this.displayName,
    required this.profileImageUrl,
  });

  final String hunterKey;
  final String displayName;
  final String? profileImageUrl;
  int totalClaims = 0;
  final Map<String, _ClaimedDropSummary> claimedDrops = {};
}

class _RankBadge extends StatelessWidget {
  const _RankBadge({required this.rank});

  final int rank;

  @override
  Widget build(BuildContext context) {
    if (rank > 50) {
      return CircleAvatar(
        key: ValueKey("leaderboard-rank-badge-$rank"),
        radius: 20,
        child: Text("$rank"),
      );
    }

    final medalColor = switch (rank) {
      1 => const Color(0xFFD4AF37),
      <= 20 => const Color(0xFFC0C0C0),
      _ => const Color(0xFFCD7F32),
    };

    return CircleAvatar(
      key: ValueKey("leaderboard-rank-badge-$rank"),
      radius: 20,
      backgroundColor: medalColor.withValues(alpha: 0.18),
      child: Icon(Icons.military_tech_rounded, color: medalColor),
    );
  }
}

String _resolveDropPreviewImage({
  required ArtPieceModel? artPiece,
  required DropModel drop,
}) {
  if (artPiece != null && artPiece.photoUrls.isNotEmpty) {
    return artPiece.photoUrls.first;
  }
  if (drop.locationPhotoUrls.isNotEmpty) {
    return drop.locationPhotoUrls.first;
  }

  return "";
}

class _LeaderboardDropImage extends StatelessWidget {
  const _LeaderboardDropImage({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) {
      return const CircleAvatar(
        child: Icon(Icons.image_not_supported_outlined, size: 18),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        imageUrl,
        width: 48,
        height: 48,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => const CircleAvatar(
          child: Icon(Icons.image_not_supported_outlined, size: 18),
        ),
      ),
    );
  }
}
