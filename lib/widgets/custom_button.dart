import 'package:flutter/material.dart';
import 'package:quantum_dashboard/utils/text_styles.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final double? Width;
  final Color? backgroundColor;
  final bool enabled;
  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.Width = double.infinity,
    this.backgroundColor,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onPressed : null,
      child: Container(
        width: Width,
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 12),
        decoration: ShapeDecoration(
          color: enabled
              ? backgroundColor ?? Theme.of(context).colorScheme.primary
              : Colors.grey,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (icon != null) Icon(icon, color: Colors.white),

            SizedBox(width: icon != null ? 10 : 0),

            Text(text, style: AppTextStyles.button),
          ],
        ),
      ),
    );
  }
}
