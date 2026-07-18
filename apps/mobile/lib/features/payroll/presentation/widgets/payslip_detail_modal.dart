import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/theme/app_colors.dart';
import 'package:hr_core/features/payroll/domain/entities/payroll_entities.dart';

class PayslipDetailModal extends StatelessWidget {
  final Payslip payslip;
  const PayslipDetailModal({super.key, required this.payslip});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: context.locale.languageCode, symbol: 'sar'.tr());

    return FractionallySizedBox(
      heightFactor: 0.9,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16.w),
            color: AppColors.primary,
            width: double.infinity,
            child: Text(payslip.monthLabel, style: TextStyle(color: Colors.white, fontSize: 20.sp, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.all(24.w),
              children: [
                SizedBox(
                  height: 200.h,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                      sections: [
                        PieChartSectionData(value: payslip.baseSalary, color: AppColors.primary, title: 'base_salary'.tr(), radius: 50, titleStyle: const TextStyle(fontSize: 10, color: Colors.white)),
                        PieChartSectionData(value: payslip.totalAllowances, color: AppColors.success, title: 'allowances'.tr(), radius: 50, titleStyle: const TextStyle(fontSize: 10, color: Colors.white)),
                        PieChartSectionData(value: payslip.totalDeductions, color: AppColors.error, title: 'deductions'.tr(), radius: 50, titleStyle: const TextStyle(fontSize: 10, color: Colors.white)),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 24.h),
                _buildRow('base_salary'.tr(), payslip.baseSalary, currencyFormat, isBold: true),
                const Divider(),
                Text('allowances'.tr(), style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: AppColors.success)),
                ...payslip.allowances.map((a) => _buildRow(a.label.tr(), a.amount, currencyFormat)),
                const Divider(),
                Text('deductions'.tr(), style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: AppColors.error)),
                ...payslip.deductions.map((d) => _buildRow(d.label.tr(), d.amount, currencyFormat)),
                const Divider(thickness: 2),
                _buildRow('net_pay'.tr(), payslip.netPay, currencyFormat, isBold: true, color: AppColors.primary),
                SizedBox(height: 24.h),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(String label, double amount, NumberFormat format, {bool isBold = false, Color? color}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 14.sp, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(format.format(amount), style: TextStyle(fontSize: 14.sp, fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: color)),
        ],
      ),
    );
  }
}
