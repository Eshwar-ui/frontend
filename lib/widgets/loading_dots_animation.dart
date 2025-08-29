import 'package:flutter/material.dart';
import 'dart:math';

class LoadingDotsAnimation extends StatefulWidget {
  @override
  _LoadingDotsAnimationState createState() => _LoadingDotsAnimationState();
}

class _LoadingDotsAnimationState extends State<LoadingDotsAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final phaseShift = index * 0.2; // Stagger the dots
            final sineValue = sin(2 * pi * (_controller.value + phaseShift));
            final yOffset = sineValue * 5.0; // Control the animation height

            return Transform.translate(
              offset: Offset(0, yOffset),
              child: child,
            );
          },
          child: _buildDot(),
        );
      }),
    );
  }

  Widget _buildDot() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 3.0),
      width: 8.0,
      height: 8.0,
      decoration: BoxDecoration(
        color: Colors.blue, // You can customize the color
        shape: BoxShape.circle,
      ),
    );
  }
}