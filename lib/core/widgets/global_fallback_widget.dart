import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

class GlobalFallbackWidget extends StatelessWidget {
  final FlutterErrorDetails? details;

  const GlobalFallbackWidget({super.key, this.details});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.background,
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: AppColors.error, size: 64.w),
              AppSpacing.verticalLg,
              Text(
                'Oops! Something went wrong.',
                style: AppTextStyles.h2,
                textAlign: TextAlign.center,
              ),
              AppSpacing.verticalMd,
              Text(
                'We apologize for the inconvenience. Please return to the home screen.',
                style: AppTextStyles.bodyMedium,
                textAlign: TextAlign.center,
              ),
              AppSpacing.verticalXl,
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (context.mounted) {
                      context.go('/');
                    }
                  },
                  icon: const Icon(Icons.home),
                  label: const Text('Go to Home'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
