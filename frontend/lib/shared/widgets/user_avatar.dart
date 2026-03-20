import "package:flutter/material.dart";

import "source_image.dart";

class UserAvatar extends StatelessWidget {
  const UserAvatar({
    required this.displayName,
    this.imageUrl,
    this.radius = 14,
    super.key,
  });

  final String displayName;
  final String? imageUrl;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final diameter = radius * 2;
    final normalizedImageUrl = imageUrl?.trim() ?? "";

    return SizedBox(
      width: diameter,
      height: diameter,
      child: ClipOval(
        child: normalizedImageUrl.isEmpty
            ? DecoratedBox(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    _initials(displayName),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              )
            : SourceImage(
                source: normalizedImageUrl,
                fit: BoxFit.cover,
                width: diameter,
                height: diameter,
                fallback: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      _initials(displayName),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSecondaryContainer,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

class UserIdentityChip extends StatelessWidget {
  const UserIdentityChip({
    required this.label,
    required this.displayName,
    this.imageUrl,
    super.key,
  });

  final String label;
  final String displayName;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: UserAvatar(displayName: displayName, imageUrl: imageUrl),
      label: Text("$label: $displayName"),
    );
  }
}

String _initials(String value) {
  final parts = value
      .trim()
      .split(RegExp(r"\s+"))
      .where((part) => part.isNotEmpty)
      .toList(growable: false);

  if (parts.isEmpty) {
    return "?";
  }

  final first = parts.first.substring(0, 1).toUpperCase();
  if (parts.length == 1) {
    return first;
  }

  final last = parts.last.substring(0, 1).toUpperCase();
  return "$first$last";
}
