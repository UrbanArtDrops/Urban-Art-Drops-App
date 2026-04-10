import "dart:ui";

import "package:flutter/material.dart";

class AppSurfacePanel extends StatelessWidget {
  const AppSurfacePanel({
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.margin,
    this.backgroundColor,
    this.radius = 24,
    this.withAmbientShadow = false,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final double radius;
  final bool withAmbientShadow;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: backgroundColor ?? colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: withAmbientShadow
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.42),
                  blurRadius: 40,
                  offset: const Offset(0, 20),
                ),
              ]
            : null,
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

class AppGlassPanel extends StatelessWidget {
  const AppGlassPanel({
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.margin,
    this.radius = 24,
    this.opacity = 0.74,
    this.blur = 20,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double radius;
  final double opacity;
  final double blur;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.26),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(
                alpha: opacity,
              ),
            ),
            child: Padding(padding: padding, child: child),
          ),
        ),
      ),
    );
  }
}

class AppScreenHeader extends StatelessWidget {
  const AppScreenHeader({
    required this.title,
    required this.technicalLabel,
    this.supportingText,
    super.key,
  });

  final String title;
  final String technicalLabel;
  final String? supportingText;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(technicalLabel, style: textTheme.labelSmall),
          const SizedBox(height: 8),
          Text(title, style: textTheme.displayMedium),
          if (supportingText != null && supportingText!.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 820),
              child: Text(supportingText!, style: textTheme.bodyLarge),
            ),
          ],
        ],
      ),
    );
  }
}

class AppSectionHeading extends StatelessWidget {
  const AppSectionHeading({
    required this.title,
    this.technicalLabel,
    this.trailing,
    super.key,
  });

  final String title;
  final String? technicalLabel;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (technicalLabel != null && technicalLabel!.trim().isNotEmpty)
                Text(technicalLabel!, style: textTheme.labelSmall),
              if (technicalLabel != null && technicalLabel!.trim().isNotEmpty)
                const SizedBox(height: 6),
              Text(title, style: textTheme.headlineMedium),
            ],
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: 12), trailing!],
      ],
    );
  }
}
