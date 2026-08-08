import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:hr_core/features/leave/domain/repositories/leave_repository.dart';
import '../di/injection.dart';
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
    
    // Determine duration based on whether there are pending actions
    final type = data?['type']?.toString();
    final hasActions = type == 'leave_pending' && data?['id'] != null;
    final duration = hasActions ? const Duration(seconds: 15) : const Duration(seconds: 6);

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

    _dismissTimer = Timer(duration, () {
      dismiss();
    });
  }

  static void pauseTimer() {
    _dismissTimer?.cancel();
    _dismissTimer = null;
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
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _pulseController;
  late Animation<Offset> _offsetAnimation;
  late Animation<double> _fadeAnimation;

  String? _loadingAction; // 'approve' or 'reject'
  String? _actionResult; // 'approved' or 'rejected'

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0.0, -1.3),
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
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _handleDismiss() async {
    await _controller.reverse();
    widget.onDismiss();
  }

  Future<void> _handleLeaveAction(bool approve) async {
    final requestId = widget.data?['id']?.toString();
    if (requestId == null) return;

    InAppNotification.pauseTimer();

    setState(() {
      _loadingAction = approve ? 'approve' : 'reject';
    });

    try {
      final leaveRepo = getIt<LeaveRepository>();
      if (approve) {
        await leaveRepo.approveRequest(requestId);
        setState(() {
          _actionResult = 'approved';
        });
      } else {
        await leaveRepo.rejectRequest(requestId);
        setState(() {
          _actionResult = 'rejected';
        });
      }
      
      // Hold success/error status for 1.5 seconds, then animate dismiss
      await Future.delayed(const Duration(milliseconds: 1500));
      _handleDismiss();
    } catch (e) {
      setState(() {
        _loadingAction = null;
      });
      if (mounted) {
        final isAr = EasyLocalization.of(context)?.locale.languageCode == 'ar';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isAr 
                  ? 'عذراً، فشل تنفيذ الإجراء. يرجى المحاولة لاحقاً.' 
                  : 'Failed to process request. Please try again.',
              style: const TextStyle(fontFamily: 'Cairo'),
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Widget _buildActionButtons(Color statusColor) {
    final isAr = EasyLocalization.of(context)?.locale.languageCode == 'ar';
    final approveText = isAr ? 'موافقة' : 'Approve';
    final rejectText = isAr ? 'رفض' : 'Reject';
    final approvedText = isAr ? 'تم قبول الطلب بنجاح ✓' : 'Request Approved ✓';
    final rejectedText = isAr ? 'تم رفض الطلب ✕' : 'Request Rejected ✕';

    if (_actionResult == 'approved') {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 8.h),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, color: AppColors.success, size: 18.sp),
            SizedBox(width: 8.w),
            Text(
              approvedText,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 12.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.success,
              ),
            ),
          ],
        ),
      );
    }

    if (_actionResult == 'rejected') {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 8.h),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cancel_outlined, color: AppColors.error, size: 18.sp),
            SizedBox(width: 8.w),
            Text(
              rejectedText,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 12.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.error,
              ),
            ),
          ],
        ),
      );
    }

    return Row(
      children: [
        // Approve Button
        Expanded(
          child: ElevatedButton(
            onPressed: _loadingAction != null ? null : () => _handleLeaveAction(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: EdgeInsets.symmetric(vertical: 10.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
            child: _loadingAction == 'approve'
                ? SizedBox(
                    width: 16.r,
                    height: 16.r,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_rounded, size: 16.sp),
                      SizedBox(width: 6.w),
                      Text(
                        approveText,
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        SizedBox(width: 10.w),
        // Reject Button
        Expanded(
          child: OutlinedButton(
            onPressed: _loadingAction != null ? null : () => _handleLeaveAction(false),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: BorderSide(color: AppColors.error.withValues(alpha: 0.4)),
              backgroundColor: AppColors.error.withValues(alpha: 0.06),
              padding: EdgeInsets.symmetric(vertical: 10.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
            child: _loadingAction == 'reject'
                ? SizedBox(
                    width: 16.r,
                    height: 16.r,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.error,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.close_rounded, size: 16.sp),
                      SizedBox(width: 6.w),
                      Text(
                        rejectText,
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildViewDetailsButton(Color statusColor, bool isRtl) {
    final isAr = EasyLocalization.of(context)?.locale.languageCode == 'ar';
    final viewText = isAr ? 'عرض التفاصيل' : 'View Details';

    return Center(
      child: Padding(
        padding: EdgeInsets.only(top: 8.h),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(10.r),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(color: statusColor.withValues(alpha: 0.18)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  viewText,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 11.sp,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
                SizedBox(width: 4.w),
                Icon(
                  isRtl ? Icons.arrow_left_rounded : Icons.arrow_right_rounded,
                  color: statusColor,
                  size: 16.sp,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    IconData icon = AppIcons.notifications;
    Color statusColor = AppColors.primary;
    
    final type = widget.data?['type']?.toString();
    final hasId = widget.data?['id'] != null;
    final hasActions = type == 'leave_pending' && hasId;

    if (type != null) {
      if (type.startsWith('leave')) {
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

    final isRtl = Directionality.of(context) == ui.TextDirection.rtl;

    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
          child: Container(
            constraints: BoxConstraints(maxWidth: 420.w),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _offsetAnimation,
                child: Dismissible(
                  key: UniqueKey(),
                  direction: DismissDirection.up,
                  onDismissed: (_) => widget.onDismiss(),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24.r),
                    child: BackdropFilter(
                      filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.surface.withValues(alpha: AppColors.isDarkMode ? 0.8 : 0.85),
                          borderRadius: BorderRadius.circular(24.r),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 30,
                              offset: const Offset(0, 15),
                            ),
                            BoxShadow(
                              color: statusColor.withValues(alpha: 0.12),
                              blurRadius: 20,
                              spreadRadius: -2,
                              offset: const Offset(0, 8),
                            ),
                          ],
                          border: Border.all(
                            color: statusColor.withValues(alpha: 0.2),
                            width: 1.5,
                          ),
                        ),
                        child: Stack(
                          children: [
                            // Status stripe at the side
                            Positioned(
                              top: 0,
                              bottom: 0,
                              right: isRtl ? 0 : null,
                              left: isRtl ? null : 0,
                              child: Container(
                                width: 5.w,
                                decoration: BoxDecoration(
                                  color: statusColor,
                                  borderRadius: BorderRadius.only(
                                    topRight: isRtl ? Radius.circular(24.r) : Radius.zero,
                                    bottomRight: isRtl ? Radius.circular(24.r) : Radius.zero,
                                    topLeft: isRtl ? Radius.zero : Radius.circular(24.r),
                                    bottomLeft: isRtl ? Radius.zero : Radius.circular(24.r),
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.only(
                                top: 16.h,
                                bottom: 16.h,
                                right: isRtl ? 22.w : 16.w,
                                left: isRtl ? 16.w : 22.w,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: widget.onTap,
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        // Pulse-animated status icon container
                                        Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            // Pulsing ring behind the icon
                                            ScaleTransition(
                                              scale: Tween<double>(begin: 1.0, end: 1.6).animate(
                                                CurvedAnimation(
                                                  parent: _pulseController,
                                                  curve: Curves.easeOut,
                                                ),
                                              ),
                                            ),
                                            FadeTransition(
                                              opacity: Tween<double>(begin: 0.5, end: 0.0).animate(
                                                CurvedAnimation(
                                                  parent: _pulseController,
                                                  curve: Curves.easeOut,
                                                ),
                                              ),
                                              child: Container(
                                                width: 44.r,
                                                height: 44.r,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                    color: statusColor.withValues(alpha: 0.3),
                                                    width: 2.r,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            // Core icon container
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
                                          ],
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
                                              SizedBox(height: 5.h),
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
                                        SizedBox(width: 4.w),
                                        // Soft dismiss cross
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
                                  
                                  // Separator & Action Buttons (if pending approval)
                                  if (hasActions) ...[
                                    Divider(
                                      color: statusColor.withValues(alpha: 0.12),
                                      height: 24.h,
                                      thickness: 1,
                                    ),
                                    _buildActionButtons(statusColor),
                                  ] else if (hasId && !hasActions) ...[
                                    _buildViewDetailsButton(statusColor, isRtl),
                                  ],
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
    );
  }
}
