import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:hr_core/core/enums/role_enums.dart';
import 'package:hr_core/features/leave/domain/repositories/leave_repository.dart';
import '../../../../core/bloc/session_cubit.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../bloc/leave_management_cubit.dart';
import '../widgets/policies_tab.dart';
import '../widgets/balances_tab.dart';
import '../widgets/pending_requests_tab.dart';

class LeaveManagementScreen extends StatefulWidget {
  const LeaveManagementScreen({super.key});

  @override
  State<LeaveManagementScreen> createState() => _LeaveManagementScreenState();
}

class _LeaveManagementScreenState extends State<LeaveManagementScreen> {
  final _searchController = TextEditingController();
  String? _selectedDept;
  int? _selectedYear = DateTime.now().year;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionCubit>().state;
    final userRole = session.role ?? UserRole.employee;

    final isAllowed =
        userRole == UserRole.hr ||
        userRole == UserRole.hrAdmin ||
        userRole == UserRole.superAdmin;

    if (!isAllowed) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'access_denied'.tr(),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text('only_hr_allowed'.tr()),
            ],
          ),
        ),
      );
    }

    return BlocProvider(
      create: (context) =>
          LeaveManagementCubit(getIt<LeaveRepository>())
            ..loadDashboard(year: _selectedYear),
      child: DefaultTabController(
        length: 3,
        child: Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: Text(
              'leave_management_dashboard'.tr(),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            bottom: TabBar(
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primary,
              tabs: [
                Tab(text: 'leave_policies'.tr()),
                Tab(text: 'balances_and_adjustments'.tr()),
                Tab(text: 'pending_requests'.tr()),
              ],
            ),
          ),
          body: BlocConsumer<LeaveManagementCubit, LeaveManagementState>(
            listener: (context, state) {
              if (state is LeaveManagementLoaded && state.actionError != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.actionError!),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            builder: (context, state) {
              if (state is LeaveManagementInitial ||
                  state is LeaveManagementLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (state is LeaveManagementError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(state.message),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => context
                            .read<LeaveManagementCubit>()
                            .loadDashboard(year: _selectedYear),
                        child: Text('retry'.tr()),
                      ),
                    ],
                  ),
                );
              }

              if (state is LeaveManagementLoaded) {
                return TabBarView(
                  children: [
                    PoliciesTab(
                      policies: state.policies,
                      policiesError: state.policiesError,
                      isSubmitting: state.isSubmitting,
                    ),
                    BalancesTab(
                      balances: state.balances,
                      balancesError: state.balancesError,
                      selectedYear: _selectedYear,
                      searchController: _searchController,
                      selectedDept: _selectedDept,
                      onFilterChanged: (targetPage, year, dept, search) {
                        setState(() {
                          _selectedYear = year;
                          _selectedDept = dept;
                        });
                        context.read<LeaveManagementCubit>().refreshBalances(
                          page: targetPage,
                          year: year,
                          department: dept,
                          employeeId: search.isEmpty ? null : search,
                        );
                      },
                      config: state.config,
                      employees: state.employees,
                      userRole: userRole,
                      currentPage: state.currentBalancesPage,
                      totalPages: state.totalBalancesPages,
                      totalBalances: state.totalBalances,
                      isSubmitting: state.isSubmitting,
                    ),
                    PendingRequestsTab(
                      requests: state.pendingRequests,
                      pendingRequestsError: state.pendingRequestsError,
                      isSubmitting: state.isSubmitting,
                    ),
                  ],
                );
              }

              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }
}
