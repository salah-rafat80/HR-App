import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../theme/app_colors.dart';

class NavItem {
  final IconData icon;
  final String label;
  NavItem(this.icon, this.label);
}

class FloatingNavBar extends StatelessWidget {
  final List<NavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;

  const FloatingNavBar({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(16.w),
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(32.r),
        boxShadow: AppShadows.medium,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(items.length, (index) {
          final isSelected = index == selectedIndex;
          return GestureDetector(
            onTap: () => onItemSelected(index),
            behavior: HitTestBehavior.opaque,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              padding: EdgeInsets.symmetric(horizontal: isSelected ? 16.w : 12.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.accent.withValues(alpha: 0.15) : Colors.transparent,
                borderRadius: BorderRadius.circular(24.r),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedScale(
                    scale: isSelected ? 1.1 : 1.0,
                    duration: const Duration(milliseconds: 300),
                    child: Icon(
                      items[index].icon,
                      color: isSelected ? AppColors.accent : AppColors.textSecondary,
                      size: 24.w,
                    ),
                  ),
                  if (isSelected) ...[
                    SizedBox(width: 6.w),
                    Text(
                      items[index].label,
                      style: TextStyle(
                        color: AppColors.accent,
                        fontWeight: FontWeight.bold,
                        fontSize: 12.sp,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
