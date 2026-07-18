import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../../core/theme/app_colors.dart';

class ExecutiveScreen extends StatefulWidget {
  const ExecutiveScreen({super.key});

  @override
  State<ExecutiveScreen> createState() => _ExecutiveScreenState();
}

class _ExecutiveScreenState extends State<ExecutiveScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  final _metrics = [
    {'label': 'Total Headcount', 'value': 142.0, 'unit': '', 'trend': '+3%', 'positive': true, 'color': const Color(0xFF3B82F6), 'icon': Iconsax.people},
    {'label': 'Present Today', 'value': 92.0, 'unit': '%', 'trend': '+2%', 'positive': true, 'color': const Color(0xFF22C55E), 'icon': Iconsax.verify},
    {'label': 'Avg KPI Score', 'value': 86.0, 'unit': '/100', 'trend': '+1.2', 'positive': true, 'color': const Color(0xFFF59E0B), 'icon': Iconsax.chart_2},
    {'label': 'Engagement', 'value': 78.0, 'unit': '%', 'trend': '+5%', 'positive': true, 'color': const Color(0xFF8B5CF6), 'icon': Iconsax.heart},
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Executive Dashboard', style: Theme.of(context).textTheme.displaySmall),
            const SizedBox(height: 8),
            Text('Company-wide performance overview', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
            const SizedBox(height: 28),
            // Metric cards row
            Row(
              children: _metrics.map((m) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: _MetricCard(
                    label: m['label'] as String,
                    finalValue: m['value'] as double,
                    unit: m['unit'] as String,
                    trend: m['trend'] as String,
                    positive: m['positive'] as bool,
                    color: m['color'] as Color,
                    icon: m['icon'] as IconData,
                    animation: _animation,
                  ),
                ),
              )).toList()
                ..last = Expanded(
                  child: _MetricCard(
                    label: _metrics.last['label'] as String,
                    finalValue: _metrics.last['value'] as double,
                    unit: _metrics.last['unit'] as String,
                    trend: _metrics.last['trend'] as String,
                    positive: _metrics.last['positive'] as bool,
                    color: _metrics.last['color'] as Color,
                    icon: _metrics.last['icon'] as IconData,
                    animation: _animation,
                  ),
                ),
            ),
            const SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: _buildChartCard(
                    context,
                    'Attendance Trend (Last 6 Months)',
                    Iconsax.chart_2,
                    _buildAttendanceChart(),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: _buildChartCard(
                    context,
                    'Headcount by Department',
                    Iconsax.people,
                    _buildPieChart(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildChartCard(
                    context,
                    'Monthly Turnover',
                    Iconsax.arrow_swap_horizontal,
                    _buildBarChart(context),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildChartCard(
                    context,
                    'Engagement Dimensions',
                    Iconsax.heart,
                    _buildRadarChart(context),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartCard(BuildContext context, String title, IconData icon, Widget chart) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5)),
        boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.04), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.primary),
              const SizedBox(width: 10),
              Text(title, style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(height: 240, child: chart),
        ],
      ),
    );
  }

  Widget _buildAttendanceChart() {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        final spots = [
          FlSpot(0, 85 * _animation.value),
          FlSpot(1, 88 * _animation.value),
          FlSpot(2, 86 * _animation.value),
          FlSpot(3, 91 * _animation.value),
          FlSpot(4, 89 * _animation.value),
          FlSpot(5, 92 * _animation.value),
        ];
        return LineChart(
          LineChartData(
            minY: 70,
            maxY: 100,
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (v) => FlLine(color: Colors.grey.withValues(alpha: 0.1), strokeWidth: 1),
            ),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 36, getTitlesWidget: (v, _) => Text('${v.toInt()}%', style: const TextStyle(fontSize: 11, color: Colors.grey)))),
              bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, _) {
                const months = ['Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul'];
                if (v.toInt() >= 0 && v.toInt() < months.length) return Text(months[v.toInt()], style: const TextStyle(fontSize: 11, color: Colors.grey));
                return const SizedBox.shrink();
              })),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                color: AppColors.primary,
                barWidth: 3,
                isStrokeCapRound: true,
                dotData: FlDotData(getDotPainter: (spot, pct, bar, idx) => FlDotCirclePainter(radius: 5, color: Colors.white, strokeWidth: 2.5, strokeColor: AppColors.primary)),
                belowBarData: BarAreaData(show: true, gradient: LinearGradient(colors: [AppColors.primary.withValues(alpha: 0.2), AppColors.primary.withValues(alpha: 0.0)], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPieChart(BuildContext context) {
    final colors = [const Color(0xFF3B82F6), const Color(0xFFF59E0B), const Color(0xFF8B5CF6), const Color(0xFF22C55E), const Color(0xFFEF4444)];
    final vals = [40.0, 28.0, 14.0, 12.0, 6.0];
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        return PieChart(
          PieChartData(
            sectionsSpace: 3,
            centerSpaceRadius: 50,
            startDegreeOffset: -90,
            sections: List.generate(vals.length, (i) => PieChartSectionData(
              color: colors[i],
              value: vals[i] * _animation.value,
              title: _animation.value > 0.95 ? '${vals[i].toInt()}%' : '',
              titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
              radius: 60,
            )),
          ),
        );
      },
    );
  }

  Widget _buildBarChart(BuildContext context) {
    final months = ['Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul'];
    final vals = [3.0, 5.0, 4.0, 7.0, 5.0, 4.0];
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        return BarChart(
          BarChartData(
            gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (v) => FlLine(color: Colors.grey.withValues(alpha: 0.1), strokeWidth: 1)),
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, _) {
                if (v.toInt() >= 0 && v.toInt() < months.length) return Padding(padding: const EdgeInsets.only(top: 6), child: Text(months[v.toInt()], style: const TextStyle(fontSize: 11, color: Colors.grey)));
                return const SizedBox.shrink();
              })),
              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28, getTitlesWidget: (v, _) => Text('${v.toInt()}%', style: const TextStyle(fontSize: 10, color: Colors.grey)))),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false),
            maxY: 10,
            barGroups: List.generate(vals.length, (i) => BarChartGroupData(x: i, barRods: [
              BarChartRodData(
                toY: vals[i] * _animation.value,
                color: const Color(0xFFFF6B4A),
                width: 28,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
              ),
            ])),
          ),
        );
      },
    );
  }

  Widget _buildRadarChart(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        return RadarChart(
          RadarChartData(
            radarShape: RadarShape.polygon,
            tickCount: 4,
            ticksTextStyle: const TextStyle(color: Colors.transparent),
            gridBorderData: BorderSide(color: Colors.grey.withValues(alpha: 0.2), width: 1),
            radarBorderData: BorderSide(color: Colors.grey.withValues(alpha: 0.2), width: 1),
            tickBorderData: BorderSide(color: Colors.grey.withValues(alpha: 0.1), width: 1),
            getTitle: (index, _) {
              const labels = ['Wellbeing', 'Growth', 'Team', 'Culture', 'Purpose'];
              return RadarChartTitle(text: labels[index], angle: 0);
            },
            dataSets: [
              RadarDataSet(
                fillColor: Color(0xFF8B5CF6).withValues(alpha: 0.2),
                borderColor: const Color(0xFF8B5CF6),
                entryRadius: 4,
                borderWidth: 2.5,
                dataEntries: [
                  RadarEntry(value: 80 * _animation.value),
                  RadarEntry(value: 90 * _animation.value),
                  RadarEntry(value: 70 * _animation.value),
                  RadarEntry(value: 85 * _animation.value),
                  RadarEntry(value: 75 * _animation.value),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final double finalValue;
  final String unit;
  final String trend;
  final bool positive;
  final Color color;
  final IconData icon;
  final Animation<double> animation;

  const _MetricCard({
    required this.label,
    required this.finalValue,
    required this.unit,
    required this.trend,
    required this.positive,
    required this.color,
    required this.icon,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    final trendColor = positive ? const Color(0xFF22C55E) : const Color(0xFFEF4444);
    final trendIcon = positive ? Iconsax.arrow_up_3 : Iconsax.arrow_down_2;

    return Container(
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
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(trendIcon, size: 12, color: trendColor),
                    const SizedBox(width: 2),
                    Text(trend, style: TextStyle(fontSize: 11, color: trendColor, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          AnimatedBuilder(
            animation: animation,
            builder: (context, _) {
              final val = finalValue * animation.value;
              final display = unit == '' ? val.toStringAsFixed(0) : val.toStringAsFixed(0);
              return Text(
                '$display$unit',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: color),
              );
            },
          ),
          const SizedBox(height: 4),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
