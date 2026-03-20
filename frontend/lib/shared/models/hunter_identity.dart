import "app_models.dart";

class HunterIdentity {
  const HunterIdentity({required this.name, this.imageUrl});

  final String name;
  final String? imageUrl;
}

List<HunterIdentity> buildClaimedHunterIdentities({
  required Iterable<DropItemModel> items,
  required Map<String, ManagedUser> usersById,
}) {
  final identities = <HunterIdentity>[];
  final seen = <String>{};

  for (final item in items) {
    final userId = item.claimedByUserId?.trim();
    if (userId != null && userId.isNotEmpty) {
      final user = usersById[userId];
      if (!seen.add("user:${userId.toLowerCase()}")) {
        continue;
      }

      identities.add(
        HunterIdentity(
          name: user?.userName ?? userId,
          imageUrl: user?.profileImageUrl,
        ),
      );
      continue;
    }

    final anonymousNickname = item.claimedByAnonymousNickname?.trim();
    if (anonymousNickname == null || anonymousNickname.isEmpty) {
      continue;
    }

    if (!seen.add("anon:${anonymousNickname.toLowerCase()}")) {
      continue;
    }

    identities.add(HunterIdentity(name: anonymousNickname));
  }

  return identities;
}
