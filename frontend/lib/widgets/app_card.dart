import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

/// Styled container card for LAST SIGNAL AI
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final Gradient? gradient;
  final Color? borderColor;
  final double borderWidth;
  final double borderRadius;
  final VoidCallback? onTap;
  final bool isInteractive;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.backgroundColor,
    this.gradient,
    this.borderColor,
    this.borderWidth = 1.0,
    this.borderRadius = 16.0,
    this.onTap,
    this.isInteractive = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBorderColor = borderColor ?? AppColors.borderNavy;
    final effectiveBackground = backgroundColor ?? AppColors.darkOceanBlue;

    Widget cardContent = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: gradient == null ? effectiveBackground : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: effectiveBorderColor,
          width: borderWidth,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );

    if (onTap != null || isInteractive) {
      cardContent = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          splashColor: AppColors.icyBlue.withOpacity(0.12),
          highlightColor: AppColors.teal.withOpacity(0.08),
          child: cardContent,
        ),
      );
    }

    if (margin != null) {
      return Padding(
        padding: margin!,
        child: cardContent,
      );
    }

    return cardContent;
  }
}
