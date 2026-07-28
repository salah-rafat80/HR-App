import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../../core/theme/app_colors.dart';

class AnimatedClockButton extends StatefulWidget {
  final bool isClockedIn;
  final bool isActionable;
  final bool justClockedIn;
  final DateTime? clockInTime;
  final VoidCallback onTap;

  const AnimatedClockButton({
    super.key,
    required this.isClockedIn,
    required this.isActionable,
    required this.justClockedIn,
    this.clockInTime,
    required this.onTap,
  });

  @override
  State<AnimatedClockButton> createState() => _AnimatedClockButtonState();
}

class _AnimatedClockButtonState extends State<AnimatedClockButton> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _pressController;
  late AnimationController _burstController;
  
  late Animation<double> _pulseScale;
  late Animation<double> _pressScale;
  late Animation<double> _burstScale;
  late Animation<double> _burstOpacity;

  Timer? _progressTimer;
  double _workProgress = 0.0;

  @override
  void initState() {
    super.initState();
    
    // Breathing pulse
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _pulseScale = Tween<double>(begin: 1.0, end: 1.05).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOutSine));
    
    // Press scale
    _pressController = AnimationController(vsync: this, duration: const Duration(milliseconds: 150));
    _pressScale = Tween<double>(begin: 1.0, end: 0.92).animate(CurvedAnimation(parent: _pressController, curve: Curves.easeInOut));
    
    // Burst animation
    _burstController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _burstScale = Tween<double>(begin: 1.0, end: 1.8).animate(CurvedAnimation(parent: _burstController, curve: Curves.easeOutQuart));
    _burstOpacity = Tween<double>(begin: 0.6, end: 0.0).animate(CurvedAnimation(parent: _burstController, curve: Curves.easeOut));

    _updateAnimationStates();
    if (widget.isClockedIn) _startProgressTimer();
  }

  @override
  void didUpdateWidget(covariant AnimatedClockButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateAnimationStates();
    
    if (!oldWidget.isClockedIn && widget.isClockedIn) {
      _startProgressTimer();
    } else if (oldWidget.isClockedIn && !widget.isClockedIn) {
      _progressTimer?.cancel();
      _workProgress = 0.0;
    }

    if (widget.justClockedIn && !oldWidget.justClockedIn) {
      HapticFeedback.heavyImpact();
      _burstController.forward(from: 0.0);
    }
  }

  void _updateAnimationStates() {
    if (widget.isActionable && !widget.isClockedIn) {
      if (!_pulseController.isAnimating) _pulseController.repeat(reverse: true);
    } else {
      _pulseController.stop();
      _pulseController.value = 0.0;
    }
  }

  void _startProgressTimer() {
    _progressTimer?.cancel();
    _updateProgress();
    _progressTimer = Timer.periodic(const Duration(minutes: 1), (_) => _updateProgress());
  }

  void _updateProgress() {
    if (widget.clockInTime == null) return;
    final elapsed = DateTime.now().difference(widget.clockInTime!);
    // Assume 8 hour workday = 28800 seconds
    final progress = elapsed.inSeconds / 28800;
    if (mounted) {
      setState(() {
        _workProgress = progress.clamp(0.0, 1.0);
      });
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _pressController.dispose();
    _burstController.dispose();
    _progressTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        HapticFeedback.selectionClick();
        _pressController.forward();
      },
      onTapUp: (_) {
        _pressController.reverse();
        widget.onTap();
      },
      onTapCancel: () => _pressController.reverse(),
      child: AnimatedBuilder(
        animation: Listenable.merge([_pulseController, _pressController, _burstController]),
        builder: (context, child) {
          final scale = _pulseScale.value * _pressScale.value;
          return Transform.scale(
            scale: scale,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Burst effect
                if (widget.justClockedIn)
                  Transform.scale(
                    scale: _burstScale.value,
                    child: Opacity(
                      opacity: _burstOpacity.value,
                      child: Container(
                        width: 140.w,
                        height: 140.w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                        ),
                      ),
                    ),
                  ),

                // Main Button
                Container(
                  width: 140.w,
                  height: 140.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.isClockedIn ? Colors.black26 : Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: widget.isClockedIn ? 0.1 : 0.15),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Progress Ring
                      if (widget.isClockedIn)
                        SizedBox(
                          width: 140.w,
                          height: 140.w,
                          child: CircularProgressIndicator(
                            value: _workProgress,
                            strokeWidth: 4.w,
                            color: const Color(0xFFFF6B4A),
                            backgroundColor: Colors.white12,
                          ),
                        ),
                      
                      // Content
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 400),
                            transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
                            child: widget.justClockedIn
                                ? Icon(Icons.check_circle_outline, color: const Color(0xFFFF6B4A), size: 40.sp, key: const ValueKey('check'))
                                : Icon(
                                    widget.isClockedIn ? Icons.logout_rounded : Icons.fingerprint,
                                    color: widget.isClockedIn ? Colors.white : AppColors.primary,
                                    size: 40.sp,
                                    key: ValueKey(widget.isClockedIn),
                                  ),
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            widget.isClockedIn ? 'clock_out'.tr() : 'clock_in'.tr(),
                            style: TextStyle(
                              color: widget.isClockedIn ? Colors.white : AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 16.sp,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
