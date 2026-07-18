import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:ui' as ui;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_colors.dart';
import '../bloc/kpi_cubit.dart';
import '../bloc/kpi_state.dart';
import 'package:hr_app_demo/core/widgets/app_loader.dart';


class KpiHistoryTab extends StatelessWidget {
  const KpiHistoryTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<KpiCubit, KpiState>(
      builder: (context, state) {
        if (state is! KpiLoaded) return const AppLoader();
        if (state.history.isEmpty) return const SizedBox.shrink();

        final maxY = 100.0;
        final spots = state.history.asMap().entries.map((e) {
          return FlSpot(e.key.toDouble(), e.value.averageScorePercent * 100);
        }).toList();

        final isRtl = context.locale.languageCode == 'ar';

        return Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('quarter_score'.tr(), style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
              SizedBox(height: 32.h),
              Expanded(
                child: Directionality(
                  textDirection: ui.TextDirection.ltr,
                  child: LineChart(
                    LineChartData(
                      minX: 0,
                      maxX: (state.history.length - 1).toDouble(),
                      minY: 0,
                      maxY: maxY,
                      titlesData: FlTitlesData(
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: 1,
                            reservedSize: 32,
                            getTitlesWidget: (value, meta) {
                              if (value != value.toInt()) return const SizedBox.shrink();
                              final intValue = value.toInt();
                              if (intValue >= 0 && intValue < state.history.length) {
                                final labelIndex = isRtl ? (state.history.length - 1 - intValue) : intValue;
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(state.history[labelIndex].quarterLabel, style: TextStyle(fontSize: 10.sp)),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ),
                      ),
                      gridData: const FlGridData(show: true, drawVerticalLine: false),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: isRtl ? spots.reversed.toList() : spots,
                          isCurved: true,
                          color: AppColors.primary,
                          barWidth: 4,
                          isStrokeCapRound: true,
                          dotData: const FlDotData(show: true),
                          belowBarData: BarAreaData(show: true, color: AppColors.primary.withValues(alpha: 0.2)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
