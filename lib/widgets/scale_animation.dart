import 'package:flutter/material.dart';

class ScaleAnimation extends AnimatedWidget {
  final Widget? child;

  const ScaleAnimation({
    super.key,
    required super.listenable,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final animation = listenable as Animation<double>;
    final scale = 0.95 + (animation.value * 0.05);
    return Transform.scale(
      scale: scale,
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(8),
        child: child,
      ),
    );
  }
}
