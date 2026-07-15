import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../theme/app_colors.dart';

class AppCard extends StatelessWidget {
  final Widget? child;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final List<BoxShadow>? boxShadow;
  final double? borderRadius;
  final VoidCallback? onTap;

  const AppCard({
    super.key,
    this.child,
    this.margin,
    this.padding,
    this.color,
    this.boxShadow,
    this.borderRadius,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Widget container = Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? AppColors.surface,
        borderRadius: BorderRadius.circular(borderRadius ?? 16.r),
        boxShadow: boxShadow ?? AppShadows.soft,
      ),
      child: child,
    );
    
    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: container,
      );
    }
    return container;
  }
}
