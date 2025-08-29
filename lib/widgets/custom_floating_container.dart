import 'package:flutter/material.dart';

class CustomFloatingContainer extends StatelessWidget {
  final double? width;
  final double? height;
  final Color? bg;
  final Widget? child;
  const CustomFloatingContainer({
    super.key,
    this.width,
    this.height,
    this.bg,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      clipBehavior: Clip.antiAlias,
      decoration: ShapeDecoration(
        color: bg ?? Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        shadows: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.25),
            blurRadius: 20,
            offset: Offset(0, 0),
            spreadRadius: 0,
          ),
        ],
      ),
      child: child ?? const SizedBox.shrink(),
    );
  }
}