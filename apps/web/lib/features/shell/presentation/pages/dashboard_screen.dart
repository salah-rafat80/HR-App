import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:hr_core/core/enums/role_enums.dart';
import 'package:hr_core/features/leave/domain/entities/leave_enums.dart';
import 'package:hr_core/features/leave/domain/repositories/leave_repository.dart';
import 'package:hr_core/features/communication/domain/repositories/communication_repository.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../../core/bloc/session_cubit.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/router/app_routes.dart';
import '../bloc/dashboard_cubit.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionCubit>().state;
    final role = session.role ?? UserRole.employee;

    return BlocProvider(
      create: (_) => DashboardCubit(
        getIt<LeaveRepository>(),
        getIt<CommunicationRepository>(),
      )..loadDashboard(role),
      child: _DashboardView(role: role),
    );
  }
}

class _DashboardView extends StatelessWidget {
  final UserRole role;

  const _DashboardView({required this.role});

  Color _getStatusColor(LeaveStatus status) {
    switch (status) {
      case LeaveStatus.approved:
        return Colors.green;
      case LeaveStatus.rejected:
        return Colors.red;
      case LeaveStatus.pending:
        return Colors.orange;
    }
  }

  void _showCreateAnnouncementDialog(
    BuildContext context,
    DashboardCubit cubit,
  ) {
    final titleController = TextEditingController();
    final bodyController = TextEditingController();
    String? selectedDept;
    final formKey = GlobalKey<FormState>();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Row(
                children: [
                  Icon(Iconsax.notification, color: Color(0xFF0B6E64)),
                  SizedBox(width: 12),
                  Text(
                    'إضافة إعلان جديد',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              content: SizedBox(
                width: 500,
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: titleController,
                        decoration: InputDecoration(
                          labelText: 'عنوان الإعلان',
                          hintText: 'مثال: اجتماع التخطيط الاستراتيجي',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'يرجى إدخال العنوان'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: bodyController,
                        maxLines: 4,
                        decoration: InputDecoration(
                          labelText: 'محتوى الإعلان',
                          hintText: 'اكتب تفاصيل الإعلان هنا...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'يرجى إدخال محتوى الإعلان'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String?>(
                        value: selectedDept,
                        decoration: InputDecoration(
                          labelText: 'الجمهور المستهدف',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: null,
                            child: Text('عام لكافة الموظفين'),
                          ),
                          DropdownMenuItem(
                            value: 'Engineering',
                            child: Text('قسم الهندسية'),
                          ),
                          DropdownMenuItem(
                            value: 'HR',
                            child: Text('قسم الموارد البشرية'),
                          ),
                          DropdownMenuItem(
                            value: 'Finance',
                            child: Text('قسم المالية'),
                          ),
                          DropdownMenuItem(
                            value: 'Sales',
                            child: Text('قسم المبيعات'),
                          ),
                        ],
                        onChanged: (v) {
                          setDialogState(() {
                            selectedDept = v;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text('إلغاء'),
                ),
                ElevatedButton.icon(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;
                          setDialogState(() {
                            isSubmitting = true;
                          });
                          await cubit.createAnnouncement(
                            titleController.text.trim(),
                            bodyController.text.trim(),
                            department: selectedDept,
                          );
                          if (dialogCtx.mounted) {
                            Navigator.pop(dialogCtx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('تم نشر الإعلان بنجاح'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0B6E64),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  icon: isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Iconsax.send_1, size: 18),
                  label: Text(isSubmitting ? 'جاري النشر...' : 'نشر الإعلان'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final canManageAnnouncements =
        role == UserRole.superAdmin || role == UserRole.hrAdmin;

    return Scaffold(
      body: BlocBuilder<DashboardCubit, DashboardState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Iconsax.warning_2, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'error'.tr(),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.errorMessage!,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () =>
                        context.read<DashboardCubit>().loadDashboard(role),
                    icon: const Icon(Iconsax.refresh),
                    label: Text('retry'.tr()),
                  ),
                ],
              ),
            );
          }

          final showApprovalsCard = role != UserRole.employee;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'dashboard'.tr(),
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'welcome_back'.tr(),
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        if (canManageAnnouncements)
                          ElevatedButton.icon(
                            onPressed: () => _showCreateAnnouncementDialog(
                              context,
                              context.read<DashboardCubit>(),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0B6E64),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                            ),
                            icon: const Icon(Iconsax.add, size: 18),
                            label: const Text(
                              'إضافة إعلان جديد',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        if (canManageAnnouncements) const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: () =>
                              context.read<DashboardCubit>().loadDashboard(role),
                          icon: const Icon(Iconsax.refresh, size: 18),
                          label: Text('refresh'.tr()),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Company Announcements Card on Web Dashboard
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: isDark
                          ? Colors.grey.shade800
                          : Colors.grey.shade200,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(
                                  Iconsax.notification,
                                  color: Color(0xFF0B6E64),
                                  size: 24,
                                ),
                                SizedBox(width: 12),
                                Text(
                                  'الإعلانات العامة للشركة',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            if (canManageAnnouncements)
                              OutlinedButton.icon(
                                onPressed: () => _showCreateAnnouncementDialog(
                                  context,
                                  context.read<DashboardCubit>(),
                                ),
                                icon: const Icon(Iconsax.add_square, size: 16),
                                label: const Text('نشر إعلان'),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (state.announcements.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Text(
                              'لا توجد إعلانات حالياً',
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: state.announcements.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 24),
                            itemBuilder: (context, index) {
                              final a = state.announcements[index];
                              final dateStr = DateFormat(
                                'dd MMM yyyy',
                                context.locale.languageCode,
                              ).format(a.date);

                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: a.department != null
                                          ? Colors.orange.withValues(alpha: 0.1)
                                          : const Color(
                                              0xFF0B6E64,
                                            ).withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      a.department ?? 'عام لكافة الموظفين',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: a.department != null
                                            ? Colors.orange
                                            : const Color(0xFF0B6E64),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          a.title,
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          a.body,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: isDark
                                                ? Colors.grey.shade400
                                                : Colors.grey.shade700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    dateStr,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                if (showApprovalsCard) ...[
                  Row(
                    children: [
                      Expanded(
                        child: Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: isDark
                                  ? Colors.grey.shade800
                                  : Colors.grey.shade200,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Iconsax.tick_circle,
                                    color: Colors.orange,
                                    size: 32,
                                  ),
                                ),
                                const SizedBox(width: 24),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'pending_approvals'.tr(),
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        '${state.pendingApprovals.length}',
                                        style: const TextStyle(
                                          fontSize: 32,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                ElevatedButton.icon(
                                  onPressed: () =>
                                      context.go(AppRoutes.approvals),
                                  icon: const Icon(Iconsax.arrow_right_3),
                                  label: Text('view_all'.tr()),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                ],
                if (state.balances.isNotEmpty) ...[
                  Text(
                    'my_balances'.tr(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 280,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 1.6,
                        ),
                    itemCount: state.balances.length,
                    itemBuilder: (context, index) {
                      final bal = state.balances[index];
                      final available = bal.availableDays;
                      final used = bal.usedDays ?? bal.daysUsed.toDouble();

                      return Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: isDark
                                ? Colors.grey.shade800
                                : Colors.grey.shade200,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                bal.type.name.tr(),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'available'.tr(),
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey.shade500,
                                        ),
                                      ),
                                      Text(
                                        '$available',
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        'used'.tr(),
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey.shade500,
                                        ),
                                      ),
                                      Text(
                                        '$used',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 32),
                ],
                if (state.myRequests.isNotEmpty) ...[
                  Text(
                    'my_recent_requests'.tr(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: isDark
                            ? Colors.grey.shade800
                            : Colors.grey.shade200,
                      ),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: state.myRequests.length > 5
                          ? 5
                          : state.myRequests.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final req = state.myRequests[index];
                        final startStr = DateFormat(
                          'yyyy-MM-dd',
                        ).format(req.startDate);
                        final endStr = DateFormat(
                          'yyyy-MM-dd',
                        ).format(req.endDate);
                        final color = _getStatusColor(req.overallStatus);

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 8,
                          ),
                          title: Text(
                            req.type.name.tr(),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              '$startStr ${'to'.tr()} $endStr (${req.workingDays ?? 0} ${'days'.tr()})',
                            ),
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              req.overallStatus.name.tr(),
                              style: TextStyle(
                                color: color,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
