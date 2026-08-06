import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../theme/app_colors.dart';
import '../theme/app_icons.dart';

class InAppNotification {
  static OverlayEntry? _currentEntry;
  static Timer? _dismissTimer;

  static void show(
    BuildContext context, {
    required String title,
    required String body,
    Map<String, dynamic>? data,
    VoidCallback? onTap,
  }) {
    // Dismiss any existing notification first
    dismiss();

    final overlayState = Overlay.of(context);
    final entry = OverlayEntry(
      builder: (context) => _InAppNotificationWidget(
        title: title,
        body: body,
        data: data,
        onTap: () {
          dismiss();
          if (onTap != null) onTap();
        },
        onDismiss: () => dismiss(),
      ),
    );

    _currentEntry = entry;
    overlayState.insert(entry);

    _dismissTimer = Timer(const Duration(seconds: 5), () {
      dismiss();
    });
  }

  static void dismiss() {
    _dismissTimer?.cancel();
    _dismissTimer = null;
    if (_currentEntry != null) {
      _currentEntry!.remove();
      _currentEntry = null;
    }
  }
}

class _InAppNotificationWidget extends StatefulWidget {
  final String title;
  final String body;
  final Map<String, dynamic>? data;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _InAppNotificationWidget({
    required this.title,
    required this.body,
    this.data,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  State<_InAppNotificationWidget> createState() => _InAppNotificationWidgetState();
}

class _InAppNotificationWidgetState extends State<_InAppNotificationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0.0, -1.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleDismiss() async {
    await _controller.reverse();
    widget.onDismiss();
  }

  @override
  Widget build(BuildContext context) {
    // Determine icon and color based on notification type
    IconData icon = AppIcons.notifications;
    Color statusColor = AppColors.primary;
    
    final type = widget.data?['type'];
    if (type != null) {
      if (type.toString().startsWith('leave')) {
        icon = AppIcons.leave;
        if (type == 'leave_approved') {
          statusColor = AppColors.success;
        } else if (type == 'leave_rejected') {
          statusColor = AppColors.error;
        } else {
          statusColor = AppColors.primary;
        }
      } else if (type == 'kpi_updated') {
        icon = AppIcons.kpi;
        statusColor = AppColors.accent;
      } else if (type == 'overtime_approved') {
        icon = AppIcons.attendance;
        statusColor = AppColors.success;
      }
    }

    // Determine directionality for absolute placement (RTL Arabic support)
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _offsetAnimation,
              child: Dismissible(
                key: UniqueKey(),
                direction: DismissDirection.up,
                onDismissed: (_) => widget.onDismiss(),
                child: GestureDetector(
                  onTap: widget.onTap,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20.r),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                      child: Container(
                        decoration: BoxDecoration(
                          // Glassmorphic translucent surface
                          color: AppColors.surface.withValues(alpha: AppColors.isDarkMode ? 0.85 : 0.9),
                          borderRadius: BorderRadius.circular(20.r),
                          boxShadow: [
                            BoxShadow(
                              color: statusColor.withValues(alpha: 0.15),
                              blurRadius: 25,
                              spreadRadius: -5,
                              offset: const Offset(0, 10),
                            ),
                          ],
                          border: Border.all(
                            color: statusColor.withValues(alpha: 0.15),
                            width: 1.5,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20.r),
                          child: Stack(
                            children: [
                              // Decorative Left/Right status bar
                              Positioned(
                                top: 0,
                                bottom: 0,
                                right: isRtl ? 0 : null,
                                left: isRtl ? null : 0,
                                child: Container(
                                  width: 6.w,
                                  decoration: BoxDecoration(
                                    color: statusColor,
                                    borderRadius: BorderRadius.only(
                                      topRight: isRtl ? Radius.circular(20.r) : Radius.zero,
                                      bottomRight: isRtl ? Radius.circular(20.r) : Radius.zero,
                                      topLeft: isRtl ? Radius.zero : Radius.circular(20.r),
                                      bottomLeft: isRtl ? Radius.zero : Radius.circular(20.r),
                                    ),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.only(
                                  top: 14.h,
                                  bottom: 14.h,
                                  right: isRtl ? 20.w : 14.w,
                                  left: isRtl ? 14.w : 20.w,
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    // Elegant pulsing status icon container
                                    Container(
                                      padding: EdgeInsets.all(10.r),
                                      decoration: BoxDecoration(
                                        color: statusColor.withValues(alpha: 0.12),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: statusColor.withValues(alpha: 0.2),
                                          width: 1,
                                        ),
                                      ),
                                      child: Icon(
                                        icon,
                                        color: statusColor,
                                        size: 22.sp,
                                      ),
                                    ),
                                    SizedBox(width: 14.w),
                                    Expanded(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  widget.title,
                                                  style: TextStyle(
                                                    fontFamily: 'Cairo',
                                                    fontSize: 14.sp,
                                                    fontWeight: FontWeight.w800,
                                                    color: AppColors.textPrimary,
                                                    height: 1.2,
                                                  ),
                                                ),
                                              ),
                                              SizedBox(width: 6.w),
                                              // Subtle "Now" / "الآن" tag
                                              Text(
                                                'الآن',
                                                style: TextStyle(
                                                  fontFamily: 'Cairo',
                                                  fontSize: 10.sp,
                                                  fontWeight: FontWeight.bold,
                                                  color: statusColor,
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: 6.h),
                                          Text(
                                            widget.body,
                                            style: TextStyle(
                                              fontFamily: 'Cairo',
                                              fontSize: 12.sp,
                                              color: AppColors.textSecondary,
                                              height: 1.3,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(width: 8.w),
                                    // Soft close button
                                    Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: _handleDismiss,
                                        borderRadius: BorderRadius.circular(10.r),
                                        child: Padding(
                                          padding: EdgeInsets.all(6.r),
                                          child: Icon(
                                            AppIcons.reject,
                                            color: AppColors.textSecondary.withValues(alpha: 0.4),
                                            size: 18.sp,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
