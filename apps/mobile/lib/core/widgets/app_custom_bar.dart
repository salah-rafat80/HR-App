import 'dart:ui';
import 'package:hr_app_demo/core/theme/app_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class AppCustomBar extends StatefulWidget implements PreferredSizeWidget {
  final Widget title;
  final ScrollController? scrollController;
  final List<Widget>? actions;
  final bool automaticallyImplyLeading;
  final PreferredSizeWidget? bottom;
  final Widget? leading;

  const AppCustomBar({
    super.key,
    required this.title,
    this.scrollController,
    this.actions,
    this.automaticallyImplyLeading = true,
    this.bottom,
    this.leading,
  });

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0.0));

  @override
  State<AppCustomBar> createState() => _AppCustomBarState();
}

class _AppCustomBarState extends State<AppCustomBar> {
  double _scrollOffset = 0.0;

  @override
  void initState() {
    super.initState();
    widget.scrollController?.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(AppCustomBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scrollController != widget.scrollController) {
      oldWidget.scrollController?.removeListener(_onScroll);
      widget.scrollController?.addListener(_onScroll);
    }
  }

  @override
  void dispose() {
    widget.scrollController?.removeListener(_onScroll);
    super.dispose();
  }

  void _onScroll() {
    if (widget.scrollController == null) return;
    if (!widget.scrollController!.hasClients) return;
    final offset = widget.scrollController!.offset;
    if (offset != _scrollOffset) {
      setState(() {
        _scrollOffset = offset;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isScrolled = _scrollOffset > 10.0;
    final double opacity = (_scrollOffset / 50.0).clamp(0.0, 1.0);

    return Container(
      decoration: BoxDecoration(
        color: isScrolled ? AppColors.surface.withValues(alpha: opacity * 0.85) : AppColors.background,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24.r)),
        boxShadow: isScrolled ? AppShadows.soft : [],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24.r)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: opacity * 10, sigmaY: opacity * 10),
          child: SafeArea(
            bottom: false,
            child: SizedBox(
              height: kToolbarHeight + (widget.bottom?.preferredSize.height ?? 0.0),
              child: Column(
                children: [
                  SizedBox(
                    height: kToolbarHeight,
                    child: Row(
                      children: [
                        if (widget.leading != null)
                          widget.leading!
                        else if (widget.automaticallyImplyLeading && context.canPop())
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16.w),
                            child: CustomIconButton(
                              icon: AppIcons.back,
                              onTap: () => context.pop(),
                            ),
                          )
                        else
                          SizedBox(width: 16.w),
                        Expanded(
                          child: DefaultTextStyle(
                            style: AppTextStyles.h3.copyWith(fontFamily: 'Outfit'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            child: widget.title,
                          ),
                        ),
                        if (widget.actions != null)
                          Padding(
                            padding: EdgeInsets.only(right: 16.w),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: widget.actions!,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (widget.bottom != null) widget.bottom!,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class CustomIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;

  const CustomIconButton({super.key, required this.icon, required this.onTap});

  @override
  State<CustomIconButton> createState() => _CustomIconButtonState();
}

class _CustomIconButtonState extends State<CustomIconButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
    widget.onTap();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      behavior: HitTestBehavior.opaque,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(widget.icon, size: 24.w, color: AppColors.primary),
        ),
      ),
    );
  }
}
