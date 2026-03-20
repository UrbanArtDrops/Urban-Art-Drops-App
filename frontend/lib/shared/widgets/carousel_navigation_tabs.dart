import "package:flutter/material.dart";

class CarouselNavigationTabs extends StatelessWidget {
  const CarouselNavigationTabs({
    required this.canGoPrevious,
    required this.canGoNext,
    required this.onPrevious,
    required this.onNext,
    super.key,
  });

  final bool canGoPrevious;
  final bool canGoNext;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        ignoring: false,
        child: Row(
          children: [
            _CarouselTabButton(
              key: const ValueKey("carousel-tab-previous"),
              icon: Icons.chevron_left,
              alignment: Alignment.centerLeft,
              onPressed: canGoPrevious ? onPrevious : null,
            ),
            const Spacer(),
            _CarouselTabButton(
              key: const ValueKey("carousel-tab-next"),
              icon: Icons.chevron_right,
              alignment: Alignment.centerRight,
              onPressed: canGoNext ? onNext : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _CarouselTabButton extends StatelessWidget {
  const _CarouselTabButton({
    required this.icon,
    required this.alignment,
    required this.onPressed,
    super.key,
  });

  final IconData icon;
  final Alignment alignment;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final isLeft = alignment == Alignment.centerLeft;
    final borderRadius = BorderRadius.only(
      topRight: Radius.circular(isLeft ? 10 : 0),
      bottomRight: Radius.circular(isLeft ? 10 : 0),
      topLeft: Radius.circular(isLeft ? 0 : 10),
      bottomLeft: Radius.circular(isLeft ? 0 : 10),
    );

    return Align(
      alignment: alignment,
      child: Material(
        color: Colors.black54,
        borderRadius: borderRadius,
        child: InkWell(
          onTap: onPressed,
          borderRadius: borderRadius,
          child: SizedBox(
            width: 26,
            height: 56,
            child: Icon(
              icon,
              size: 20,
              color: onPressed == null ? Colors.white38 : Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
