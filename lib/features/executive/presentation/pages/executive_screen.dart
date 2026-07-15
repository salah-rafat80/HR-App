import 'package:flutter/material.dart';
import 'package:hr_app_demo/core/widgets/app_custom_bar.dart';
import 'package:hr_app_demo/core/theme/app_icons.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/di/injection.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_routes.dart';
import '../bloc/executive_cubit.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/animated_glow_card.dart';

class ExecutiveScreen extends StatelessWidget {
  const ExecutiveScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ExecutiveCubit>()..loadDashboard(),
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppCustomBar(
          automaticallyImplyLeading: false,
          title: Text('executive_dashboard'.tr(), style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
          actions: [
            IconButton(
              icon: Icon(AppIcons.back, color: AppColors.error),
              onPressed: () {
                context.go(AppRoutes.login);
              },
            ),
          ],
        ),
        body: BlocBuilder<ExecutiveCubit, ExecutiveState>(
          builder: (context, state) {
            if (state is ExecutiveLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is ExecutiveLoaded) {
              return SingleChildScrollView(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeadlineMetrics(state),
                    SizedBox(height: 24.h),
                    _buildChartCard('Attendance Trend (7 Days)', _buildLineChart(state.attendanceTrend)),
                    SizedBox(height: 24.h),
                    _buildKpiHeatmap(state),
                    SizedBox(height: 24.h),
                    _buildChartCard('Department Headcount', _buildBarChart(state.deptHeadcount)),
                    SizedBox(height: 24.h),
                    _buildRecruitmentCard(state),
                    SizedBox(height: 24.h),
                    _buildPayrollCard(state),
                    SizedBox(height: 24.h),
                    _buildChartCard('Turnover Forecast (AI Projection)', _buildLineChart(state.turnoverForecast)),
                    SizedBox(height: 40.h),
                  ],
                ),
              );
            } else if (state is ExecutiveError) {
              return Center(child: Text(state.message, style: const TextStyle(color: Colors.red)));
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildHeadlineMetrics(ExecutiveLoaded state) {
    return Wrap(
      spacing: 16.w,
      runSpacing: 16.h,
      children: [
        _buildStatCard('Employees', state.summary.totalEmployees.toString()),
        _buildStatCard('Present', '${(state.summary.presentPercent * 100).toInt()}%'),
        _buildStatCard('On Leave', '${(state.summary.onLeavePercent * 100).toInt()}%'),
        _buildStatCard('Turnover', '${(state.summary.turnoverPercent * 100).toInt()}%'),
        _buildStatCard('Avg KPI', '${(state.summary.avgKpiScorePercent * 100).toInt()}%'),
        _buildStatCard('Engagement', '${(state.summary.engagementScorePercent * 100).toInt()}%'),
      ],
    );
  }

  Widget _buildStatCard(String title, String value) {
    return AnimatedGlowCard(
      color: AppColors.primary,
      child: SizedBox(
        width: 100.w,
        child: Column(
          children: [
            Text(title, style: TextStyle(fontSize: 12.sp, color: AppColors.textSecondary)),
            SizedBox(height: 8.h),
            Text(value, style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: AppColors.primary)),
          ],
        ),
      ),
    );
  }

  Widget _buildChartCard(String title, Widget chart) {
    return AppCard(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
          SizedBox(height: 16.h),
          SizedBox(height: 200.h, child: chart),
        ],
      ),
    );
  }

  Widget _buildLineChart(List<dynamic> data) {
    if (data.isEmpty) return const Center(child: Text('No data'));
    return LineChart(
      LineChartData(
        gridData: FlGridData(show: false),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30, interval: 1, getTitlesWidget: (val, meta) {
            if (val != val.toInt()) return const SizedBox.shrink();
            if (val.toInt() >= 0 && val.toInt() < data.length) {
              return Padding(padding: const EdgeInsets.only(top: 8.0), child: Text(data[val.toInt()].label, style: TextStyle(fontSize: 10.sp)));
            }
            return const Text('');
          })),
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: data.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.value)).toList(),
            isCurved: true,
            color: AppColors.primary,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(show: true, color: AppColors.primary.withValues(alpha: 0.2)),
          ),
        ],
      ),
      duration: const Duration(milliseconds: 1500),
      curve: Curves.easeInOut,
    );
  }

  Widget _buildBarChart(List<dynamic> data) {
    if (data.isEmpty) return const Center(child: Text('No data'));
    return BarChart(
      BarChartData(
        gridData: FlGridData(show: false),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40, interval: 1, getTitlesWidget: (val, meta) {
            if (val != val.toInt()) return const SizedBox.shrink();
            if (val.toInt() >= 0 && val.toInt() < data.length) {
              final dept = data[val.toInt()].department;
              final displayDept = dept.length > 3 ? dept.substring(0, 3) : dept;
              return Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(displayDept, style: TextStyle(fontSize: 10.sp)),
              );
            }
            return const Text('');
          })),
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        barGroups: data.asMap().entries.map((e) {
          return BarChartGroupData(
            x: e.key,
            barRods: [
              BarChartRodData(
                toY: e.value.count.toDouble(),
                color: AppColors.secondary,
                width: 16.w,
                borderRadius: BorderRadius.circular(4.r),
              ),
            ],
          );
        }).toList(),
      ),
      duration: const Duration(milliseconds: 1500),
      curve: Curves.easeInOut,
    );
  }

  Widget _buildKpiHeatmap(ExecutiveLoaded state) {
    return AppCard(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('KPI Heatmap', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
          SizedBox(height: 16.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: state.kpiHeatmap.entries.map((e) {
              final score = e.value;
              final color = score >= 0.85 ? Colors.green : (score >= 0.75 ? Colors.orange : Colors.red);
              return Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8.r), border: Border.all(color: color)),
                child: Text('${e.key}: ${(score * 100).toInt()}%', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildRecruitmentCard(ExecutiveLoaded state) {
    return AppCard(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Recruitment Pipeline', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
          SizedBox(height: 16.h),
          Wrap(
            spacing: 12.w,
            runSpacing: 12.h,
            children: state.recruitmentSummary.entries.map((e) => Chip(
              label: Text('${e.key.name}: ${e.value}'),
              backgroundColor: AppColors.background,
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPayrollCard(ExecutiveLoaded state) {
    return AppCard(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Payroll Summary', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
          SizedBox(height: 16.h),
          Wrap(
            spacing: 12.w,
            runSpacing: 12.h,
            children: state.payrollSummary.entries.map((e) => Chip(
              label: Text('${e.key.name}: \$${e.value.toStringAsFixed(0)}'),
              backgroundColor: AppColors.background,
            )).toList(),
          ),
        ],
      ),
    );
  }
}
