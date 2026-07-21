import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hr_core/features/admin/domain/entities/recruitment_entities.dart';
import 'package:hr_core/features/admin/domain/entities/payroll_run.dart';
import 'package:hr_core/features/executive/domain/entities/executive_entities.dart';
import 'package:hr_core/features/executive/domain/repositories/executive_repository.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../../core/bloc/web_cubits.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../bloc/executive_cubit.dart';

class ExecutiveScreen extends StatelessWidget {
  const ExecutiveScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ExecutiveCubit(getIt<ExecutiveRepository>()),
      child: const _ExecutiveView(),
    );
  }
}

class _ExecutiveView extends StatelessWidget {
  const _ExecutiveView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: BlocBuilder<ExecutiveCubit, WebState<ExecutiveDashboardData>>(
          builder: (context, state) {
            if (state is WebLoading || state is WebInitial) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is WebError<ExecutiveDashboardData>) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Iconsax.warning_2, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('Error: ${state.message}'),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      icon: const Icon(Iconsax.refresh),
                      label: const Text('Retry'),
                      onPressed: () => context.read<ExecutiveCubit>().load(),
                    ),
                  ],
                ),
              );
            }
            if (state is WebSuccess<ExecutiveDashboardData>) {
              return _ExecutiveBody(data: state.data);
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}

class _ExecutiveBody extends StatefulWidget {
  final ExecutiveDashboardData data;
  const _ExecutiveBody({required this.data});

  @override
  State<_ExecutiveBody> createState() => _ExecutiveBodyState();
}

class _ExecutiveBodyState extends State<_ExecutiveBody> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();
  }

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    final summary = d.summary;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Executive Dashboard', style: Theme.of(context).textTheme.displaySmall),
          const SizedBox(height: 8),
          Text('Company-wide performance overview', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          const SizedBox(height: 28),
          Row(
            children: [
              _MetricCard(label: 'Total Headcount', finalValue: summary.totalEmployees.toDouble(), unit: '', trend: '+3%', positive: true, color: const Color(0xFF3B82F6), icon: Iconsax.people, animation: _animation),
              const SizedBox(width: 16),
              _MetricCard(label: 'Present Today', finalValue: summary.presentPercent * 100, unit: '%', trend: '+2%', positive: true, color: const Color(0xFF22C55E), icon: Iconsax.verify, animation: _animation),
              const SizedBox(width: 16),
              _MetricCard(label: 'Avg KPI Score', finalValue: summary.avgKpiScorePercent * 100, unit: '', trend: '+1.2', positive: true, color: const Color(0xFFF59E0B), icon: Iconsax.chart_2, animation: _animation),
              const SizedBox(width: 16),
              _MetricCard(label: 'Engagement', finalValue: summary.engagementScorePercent * 100, unit: '%', trend: '+5%', positive: true, color: const Color(0xFF8B5CF6), icon: Iconsax.heart, animation: _animation),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 3, child: _buildChartCard(context, 'Attendance Trend', Iconsax.chart_2, _buildAttendanceChart(d.attendanceTrend))),
              const SizedBox(width: 16),
              Expanded(flex: 2, child: _buildChartCard(context, 'Headcount by Department', Iconsax.people, _buildPieChart(context, d.deptHeadcount))),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildChartCard(context, 'Monthly Turnover', Iconsax.arrow_swap_horizontal, _buildBarChart(context, d.turnoverForecast))),
              const SizedBox(width: 16),
              Expanded(child: _buildChartCard(context, 'Engagement Dimensions', Iconsax.heart, _buildRadarChart(context))),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildChartCard(context, 'Recruitment Pipeline', Iconsax.user_add, _buildRecruitmentPipelineChart(context, d.recruitmentPipeline))),
              const SizedBox(width: 16),
              Expanded(child: _buildChartCard(context, 'Payroll Summary', Iconsax.money, _buildPayrollChart(context, d.payrollSummary))),
            ],
          ),
        ],
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
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 10),
          Text(title, style: Theme.of(context).textTheme.titleMedium),
        ]),
        const SizedBox(height: 24),
        SizedBox(height: 240, child: chart),
      ]),
    );
  }

  Widget _buildAttendanceChart(List<TrendPoint> trend) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        final spots = trend.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.value * 100 * _animation.value)).toList();
        return LineChart(
          LineChartData(
            minY: 70, maxY: 100,
            gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (v) => FlLine(color: Colors.grey.withValues(alpha: 0.1), strokeWidth: 1)),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 36, getTitlesWidget: (v, _) => Text('${v.toInt()}%', style: const TextStyle(fontSize: 11, color: Colors.grey)))),
              bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, _) {
                if (v.toInt() >= 0 && v.toInt() < trend.length) return Text(trend[v.toInt()].label, style: const TextStyle(fontSize: 11, color: Colors.grey));
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

  Widget _buildPieChart(BuildContext context, List<DeptHeadcount> depts) {
    final colors = [const Color(0xFF3B82F6), const Color(0xFFF59E0B), const Color(0xFF8B5CF6), const Color(0xFF22C55E), const Color(0xFFEF4444)];
    final total = depts.fold<int>(0, (sum, d) => sum + d.count);
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        return PieChart(
          PieChartData(
            sectionsSpace: 3,
            centerSpaceRadius: 50,
            startDegreeOffset: -90,
            sections: depts.asMap().entries.map((e) {
              final pct = total > 0 ? (e.value.count / total * 100) : 0.0;
              return PieChartSectionData(
                color: colors[e.key % colors.length],
                value: pct * _animation.value,
                title: _animation.value > 0.95 ? '${pct.toStringAsFixed(0)}%' : '',
                titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                radius: 60,
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildBarChart(BuildContext context, List<TrendPoint> trend) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        return BarChart(
          BarChartData(
            gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (v) => FlLine(color: Colors.grey.withValues(alpha: 0.1), strokeWidth: 1)),
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, _) {
                if (v.toInt() >= 0 && v.toInt() < trend.length) return Padding(padding: const EdgeInsets.only(top: 6), child: Text(trend[v.toInt()].label, style: const TextStyle(fontSize: 11, color: Colors.grey)));
                return const SizedBox.shrink();
              })),
              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28, getTitlesWidget: (v, _) => Text('${v.toStringAsFixed(1)}%', style: const TextStyle(fontSize: 10, color: Colors.grey)))),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false),
            maxY: 5,
            barGroups: trend.asMap().entries.map((e) => BarChartGroupData(x: e.key, barRods: [
              BarChartRodData(toY: e.value.value * _animation.value, color: const Color(0xFFFF6B4A), width: 28, borderRadius: const BorderRadius.vertical(top: Radius.circular(6))),
            ])).toList(),
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
                fillColor: const Color(0xFF8B5CF6).withValues(alpha: 0.2),
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

  Widget _buildRecruitmentPipelineChart(BuildContext context, Map<CandidateStage, int> pipeline) {
    final stages = [CandidateStage.applied, CandidateStage.screening, CandidateStage.interview, CandidateStage.offer, CandidateStage.hired];
    final stageLabels = ['Applied', 'Screening', 'Interview', 'Offer', 'Hired'];
    final colors = [Colors.blue, Colors.orange, Colors.purple, Colors.teal, Colors.green];
    final total = pipeline.values.fold<int>(0, (a, b) => a + b);
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        return Row(
          children: stages.asMap().entries.map((e) {
            final count = pipeline[e.value] ?? 0;
            final pct = total > 0 ? count / total : 0.0;
            return Expanded(
              child: Column(
                children: [
                  Text('${(pct * 100 * _animation.value).toStringAsFixed(0)}%', style: TextStyle(fontWeight: FontWeight.bold, color: colors[e.key])),
                  const SizedBox(height: 8),
                  Container(
                    height: 160,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(color: colors[e.key].withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          height: (160 * pct * _animation.value).clamp(0.0, 160.0),
                          decoration: BoxDecoration(color: colors[e.key], borderRadius: BorderRadius.circular(8)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(stageLabels[e.key], style: const TextStyle(fontSize: 11)),
                  Text('$count', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildPayrollChart(BuildContext context, Map<PayrollStatus, double> payroll) {
    final statusLabels = {PayrollStatus.draft: 'Draft', PayrollStatus.processing: 'Processing', PayrollStatus.paid: 'Paid', PayrollStatus.pendingApproval: 'Pending'};
    final colors = {PayrollStatus.draft: Colors.grey, PayrollStatus.processing: Colors.orange, PayrollStatus.paid: Colors.green, PayrollStatus.pendingApproval: Colors.blue};
    final total = payroll.values.fold<double>(0, (a, b) => a + b);
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        return Column(
          children: PayrollStatus.values.where((s) => payroll[s] != null && payroll[s]! > 0).map((status) {
            final amount = payroll[status] ?? 0;
            final pct = total > 0 ? amount / total : 0.0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  SizedBox(width: 80, child: Text(statusLabels[status] ?? status.name, style: const TextStyle(fontSize: 12))),
                  Expanded(
                    child: Container(
                      height: 24,
                      decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: (pct * _animation.value).clamp(0.0, 1.0),
                        child: Container(decoration: BoxDecoration(color: colors[status], borderRadius: BorderRadius.circular(6))),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(width: 60, child: Text('\$${amount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 11), textAlign: TextAlign.right)),
                ],
              ),
            );
          }).toList(),
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

  const _MetricCard({required this.label, required this.finalValue, required this.unit, required this.trend, required this.positive, required this.color, required this.icon, required this.animation});

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
