import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:urban_art_drops_app/l10n/app_localizations.dart";

import "../../../../shared/models/app_models.dart";
import "../../../../shared/services/app_api_client.dart";
import "../../../../shared/widgets/page_shell.dart";

class LeaderboardPage extends StatefulWidget {
  const LeaderboardPage({super.key});

  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
  final AppApiClient _apiClient = AppApiClient();
  List<_LeaderboardViewModel> _entries = const [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadLeaderboard();
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
        _apiClient.getUsers(),
      ]);
      if (!mounted) {
        return;
      }

      final drops = results[0] as List<DropModel>;
      final artPieces = results[1] as List<ArtPieceModel>;
      final users = results[2] as List<ManagedUser>;

      final l10n = AppLocalizations.of(context)!;
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
            () => _HunterAggregate(displayName: hunterDisplayName),
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
                  hunterName: aggregate.displayName,
                  claims: aggregate.totalClaims,
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

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
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                itemCount: _entries.length,
                separatorBuilder: (context, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final entry = _entries[index];
                  final rank = index + 1;

                  return Card(
                    child: ExpansionTile(
                      tilePadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 2,
                      ),
                      title: Text(l10n.rankEntry("$rank", entry.hunterName)),
                      subtitle: Text(
                        l10n.leaderboardClaimCount("${entry.claims}"),
                      ),
                      childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
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

class _LeaderboardViewModel {
  const _LeaderboardViewModel({
    required this.hunterName,
    required this.claims,
    required this.claimedDrops,
  });

  final String hunterName;
  final int claims;
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
  _HunterAggregate({required this.displayName});

  final String displayName;
  int totalClaims = 0;
  final Map<String, _ClaimedDropSummary> claimedDrops = {};
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
