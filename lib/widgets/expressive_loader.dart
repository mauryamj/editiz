import 'dart:math' as math;

import 'package:flutter/material.dart';

// Class: a loading animation widget that keeps animation state.
class ExpressiveLoader extends StatefulWidget {
  // Field: the width and height of the shape.
  final double size;

  // Constructor: size defaults to 48.
  const ExpressiveLoader({super.key, this.size = 48});

  // Override: creates the State object for this widget.
  @override
  State<ExpressiveLoader> createState() => _ExpressiveLoaderState();
}

// Class: the State object; the mixin gives us a ticker for animations.
class _ExpressiveLoaderState extends State<ExpressiveLoader>
    with SingleTickerProviderStateMixin {
  // Field: animation controller that loops forever (0.0 to 1.0).
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  // Override: frees the controller when the widget is removed.
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Override: draws the spinning, morphing shape.
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Local variable: goes 0 -> 1 -> 0 once per loop (smooth morph).
        final morph = math.sin(_controller.value * math.pi);
        // Local variable: radius from half the size (circle) down to 20% (rounded square).
        final radius = widget.size * (0.5 - 0.3 * morph);
        return Transform.rotate(
          angle: _controller.value * 2 * math.pi, // one full turn per loop
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(radius),
            ),
          ),
        );
      },
    );
  }
}
