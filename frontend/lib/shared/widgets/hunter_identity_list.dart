import "package:flutter/material.dart";

import "../models/hunter_identity.dart";
import "user_avatar.dart";

class HunterIdentityList extends StatelessWidget {
  const HunterIdentityList({
    required this.hunters,
    required this.emptyLabel,
    this.avatarRadius = 12,
    super.key,
  });

  final List<HunterIdentity> hunters;
  final String emptyLabel;
  final double avatarRadius;

  @override
  Widget build(BuildContext context) {
    if (hunters.isEmpty) {
      return Text(emptyLabel);
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: hunters
          .map(
            (hunter) => Chip(
              avatar: UserAvatar(
                displayName: hunter.name,
                imageUrl: hunter.imageUrl,
                radius: avatarRadius,
              ),
              label: Text(hunter.name),
            ),
          )
          .toList(growable: false),
    );
  }
}
