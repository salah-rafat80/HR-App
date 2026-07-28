import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:flutter/material.dart';

class MetricCard extends StatelessWidget {
  final String label;
  final double finalValue;
  final String unit;
  final String trend;
  final bool positive;
  final Color color;
  final IconData icon;
  final Animation<double> animation;

  const MetricCard({super.key, required this.label, required this.finalValue, required this.unit, required this.trend, required this.positive, required this.color, required this.icon, required this.animation});

  @override
  Widget build(BuildContext context) {
    final trendColor = positive ? const Color(0xFF22C55E) : const Color(0xFFEF4444);
    final trendIcon = positive ? Iconsax.arrow_up_3 : Iconsax.arrow_down_2;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5)),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.06), blurRadius: 16, offset: const Offset(0, 6))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                  child: Icon(icon, size: 18, color: color),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: trendColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(trendIcon, size: 12, color: trendColor),
                    const SizedBox(width: 2),
                    Text(trend, style: TextStyle(fontSize: 11, color: trendColor, fontWeight: FontWeight.bold)),
                  ]),
                ),
              ],
            ),
            const SizedBox(height: 16),
            AnimatedBuilder(
              animation: animation,
              builder: (context, _) {
                final val = finalValue * animation.value;
                final display = unit == '' ? val.toStringAsFixed(0) : val.toStringAsFixed(0);
                return Text('$display$unit', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: color));
              },
            ),
            const SizedBox(height: 4),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

