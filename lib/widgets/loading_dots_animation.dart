import 'package:flutter/material.dart';
import 'dart:math';

class LoadingDotsAnimation extends StatefulWidget {
  final Color? color;
  final double? size;
  final int? dotCount;
  final Duration? duration;

  const LoadingDotsAnimation({
    Key? key,
    this.color,
    this.size,
    this.dotCount,
    this.duration,
  }) : super(key: key);

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
      duration: widget.duration ?? const Duration(milliseconds: 1000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dotCount = widget.dotCount ?? 3;
    final dotSize = widget.size ?? 6.0;
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(dotCount, (index) {
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
          child: _buildDot(dotSize),
        );
      }),
    );
  }

  Widget _buildDot(double size) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 3.0),
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: widget.color ?? Colors.blue,
        shape: BoxShape.circle,
      ),
    );
  }
}