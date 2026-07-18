import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class PulsingPendingChip extends StatefulWidget {
  final String label;

  const PulsingPendingChip({super.key, required this.label});

  @override
  State<PulsingPendingChip> createState() => _PulsingPendingChipState();
}

class _PulsingPendingChipState extends State<PulsingPendingChip> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.4, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
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
        return Opacity(
          opacity: _animation.value,
          child: Chip(
            label: Text(widget.label, style: const TextStyle(color: Colors.white)),
            backgroundColor: AppColors.warning,
          ),
        );
      },
    );
  }
}
