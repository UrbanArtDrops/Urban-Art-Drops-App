import "dart:convert";
import "dart:typed_data";

import "package:flutter/material.dart";

class SourceImage extends StatelessWidget {
  const SourceImage({
    required this.source,
    required this.fit,
    this.width,
    this.height,
    this.borderRadius,
    this.fallback,
    super.key,
  });

  final String? source;
  final BoxFit fit;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final Widget? fallback;

  @override
  Widget build(BuildContext context) {
    Widget image = _buildImage(context);

    if (borderRadius != null) {
      image = ClipRRect(borderRadius: borderRadius!, child: image);
    }

    return SizedBox(width: width, height: height, child: image);
  }

  Widget _buildImage(BuildContext context) {
    final normalizedSource = source?.trim() ?? "";
    if (normalizedSource.isEmpty) {
      return _fallback(context);
    }

    final dataUrlBytes = _tryDecodeDataUrl(normalizedSource);
    if (dataUrlBytes != null) {
      return Image.memory(
        dataUrlBytes,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => _fallback(context),
      );
    }

    return Image.network(
      normalizedSource,
      fit: fit,
      errorBuilder: (context, error, stackTrace) => _fallback(context),
    );
  }

  Widget _fallback(BuildContext context) {
    return fallback ??
        DecoratedBox(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
          child: Icon(
            Icons.image_not_supported_outlined,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        );
  }
}

Uint8List? _tryDecodeDataUrl(String source) {
  if (!source.startsWith("data:")) {
    return null;
  }

  final separatorIndex = source.indexOf(",");
  if (separatorIndex <= 0 || separatorIndex == source.length - 1) {
    return null;
  }

  try {
    return Uint8List.fromList(
      base64Decode(source.substring(separatorIndex + 1)),
    );
  } catch (_) {
    return null;
  }
}
