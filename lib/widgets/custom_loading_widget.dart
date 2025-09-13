import 'package:flutter/material.dart';
import 'package:quantum_dashboard/widgets/loading_dots_animation.dart';

class CustomLoadingWidget extends StatelessWidget {
  final Color? color;
  final double? size;
  final String? message;
  final bool showMessage;

  const CustomLoadingWidget({
    Key? key,
    this.color,
    this.size,
    this.message,
    this.showMessage = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LoadingDotsAnimation(
            color: color ?? Color(0xFF1976D2),
            size: size ?? 10,
          ),
          if (showMessage && message != null) ...[
            SizedBox(height: 16),
            Text(
              message!,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  // Convenience constructors for common use cases
  static Widget small({Color? color}) {
    return CustomLoadingWidget(
      color: color,
      size: 6,
    );
  }

  static Widget medium({Color? color}) {
    return CustomLoadingWidget(
      color: color,
      size: 10,
    );
  }

  static Widget large({Color? color}) {
    return CustomLoadingWidget(
      color: color,
      size: 14,
    );
  }

  static Widget withMessage(String message, {Color? color, double? size}) {
    return CustomLoadingWidget(
      color: color,
      size: size,
      message: message,
      showMessage: true,
    );
  }
}
