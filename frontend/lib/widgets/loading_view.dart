import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import 'app_logo.dart';

class LoadingView extends StatelessWidget {
  final String message;

  const LoadingView({
    super.key,
    this.message = 'Initializing Emergency Intelligence...',
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AppLogo(size: 64, animate: true),
          const SizedBox(height: 24),
          const SizedBox(
            width: 140,
            child: LinearProgressIndicator(
              backgroundColor: AppColors.borderNavy,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.icyBlue),
              minHeight: 2.5,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.lightMutedText,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
