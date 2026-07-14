import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../bloc/payroll_cubit.dart';
import '../bloc/payroll_state.dart';
import '../widgets/payslip_detail_modal.dart';
import 'package:hr_app_demo/core/widgets/app_loader.dart';


class PayrollScreen extends StatelessWidget {
  const PayrollScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: context.locale.languageCode, symbol: 'sar'.tr());

    return BlocProvider(
      create: (context) => getIt<PayrollCubit>()..loadData(),
      child: Scaffold(
        appBar: AppBar(title: Text('payroll_title'.tr())),
        body: BlocConsumer<PayrollCubit, PayrollState>(
          listener: (context, state) {
            if (state is PayrollLoaded && state.downloadTaxSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('download_success'.tr()), backgroundColor: AppColors.success));
            }
          },
          builder: (context, state) {
            if (state is! PayrollLoaded) return const AppLoader();
            return ListView(
              padding: EdgeInsets.all(16.w),
              children: [
                if (state.bonusNotice != null)
                  Container(
                    margin: EdgeInsets.only(bottom: 16.h),
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.success)),
                    child: Text('bonus_notice'.tr(namedArgs: {'message': state.bonusNotice!.message, 'amount': currencyFormat.format(state.bonusNotice!.amount)}), style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold)),
                  ),
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(16.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('ytd_summary'.tr(), style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
                        SizedBox(height: 16.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('total_earnings'.tr(), style: TextStyle(fontSize: 14.sp)),
                            Text(currencyFormat.format(state.ytdSummary.totalEarnings), style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: AppColors.success)),
                          ],
                        ),
                        SizedBox(height: 8.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('total_deductions'.tr(), style: TextStyle(fontSize: 14.sp)),
                            Text(currencyFormat.format(state.ytdSummary.totalDeductions), style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: AppColors.error)),
                          ],
                        ),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('net_pay'.tr(), style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
                            Text(currencyFormat.format(state.ytdSummary.netYtd), style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: AppColors.primary)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 16.h),
                ElevatedButton.icon(
                  onPressed: state.isDownloadingTax ? null : () => context.read<PayrollCubit>().downloadTaxCertificate(),
                  icon: state.isDownloadingTax ? const SizedBox(width: 16, height: 16, child: AppLoader(size: 24)) : const Icon(Icons.download),
                  label: Text(state.isDownloadingTax ? 'downloading'.tr() : 'download_tax_cert'.tr()),
                ),
                SizedBox(height: 24.h),
                Text('payslips'.tr(), style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
                SizedBox(height: 8.h),
                ...state.payslips.map((p) => Card(
                  margin: EdgeInsets.only(bottom: 8.h),
                  child: ListTile(
                    title: Text(p.monthLabel, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp)),
                    subtitle: Text(currencyFormat.format(p.netPay), style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => PayslipDetailModal(payslip: p),
                    ),
                  ),
                )),
              ],
            );
          },
        ),
      ),
    );
  }
}
