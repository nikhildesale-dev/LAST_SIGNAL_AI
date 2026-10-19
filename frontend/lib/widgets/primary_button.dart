import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';

enum ButtonVariant {
  primary,
  emergency,
  outlined,
  secondary,
  ghost,
}

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final ButtonVariant variant;
  final double height;
  final double? width;
  final double borderRadius;

  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.variant = ButtonVariant.primary,
    this.height = 50,
    this.width,
    this.borderRadius = 12,
  });

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color foregroundColor;
    BorderSide borderSide = BorderSide.none;

    switch (variant) {
      case ButtonVariant.primary:
        backgroundColor = AppColors.teal;
        foregroundColor = AppColors.white;
        break;
      case ButtonVariant.emergency:
        backgroundColor = AppColors.emergencyRed;
        foregroundColor = AppColors.white;
        break;
      case ButtonVariant.secondary:
        backgroundColor = AppColors.darkOceanBlue;
        foregroundColor = AppColors.icyBlue;
        borderSide = const BorderSide(color: AppColors.mutedBlue, width: 1.2);
        break;
      case ButtonVariant.outlined:
        backgroundColor = Colors.transparent;
        foregroundColor = AppColors.icyBlue;
        borderSide = const BorderSide(color: AppColors.icyBlue, width: 1.4);
        break;
      case ButtonVariant.ghost:
        backgroundColor = Colors.transparent;
        foregroundColor = AppColors.lightMutedText;
        break;
    }

    final isInteractive = onPressed != null && !isLoading;

    return SizedBox(
      height: height,
      width: width ?? double.infinity,
      child: ElevatedButton(
        onPressed: isInteractive ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          disabledBackgroundColor: backgroundColor.withOpacity(0.4),
          disabledForegroundColor: foregroundColor.withOpacity(0.5),
          elevation: variant == ButtonVariant.emergency ? 4 : 0,
          shadowColor: variant == ButtonVariant.emergency
              ? AppColors.emergencyRed.withOpacity(0.5)
              : Colors.transparent,
          side: borderSide,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 18, color: foregroundColor),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    label,
                    style: AppTypography.labelLarge.copyWith(
                      color: foregroundColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
