import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../theme/app_colors.dart';

class AnimatedGlowCard extends StatefulWidget {
  final Widget child;
  final Color color;

  const AnimatedGlowCard({super.key, required this.child, required this.color});

  @override
  State<AnimatedGlowCard> createState() => _AnimatedGlowCardState();
}

class _AnimatedGlowCardState extends State<AnimatedGlowCard> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.05, end: 0.15).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: _animation.value),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: widget.child,
        );
      },
    );
  }
}
