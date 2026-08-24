import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hr_core/features/leave/domain/entities/leave_enums.dart';
import 'package:hr_core/features/leave/domain/entities/leave_policy.dart';
import '../bloc/leave_cubit.dart';
import '../bloc/leave_state.dart';
import 'package:hr_app_demo/core/widgets/app_loader.dart';
import '../../../../core/theme/app_colors.dart';

class LeaveApplyModal extends StatefulWidget {
  const LeaveApplyModal({super.key});

  @override
  State<LeaveApplyModal> createState() => _LeaveApplyModalState();
}

class _LeaveApplyModalState extends State<LeaveApplyModal> {
  LeaveType _type = LeaveType.annual;
  DateTime _start = DateTime.now();
  DateTime _end = DateTime.now();
  bool _isHalfDay = false;
  String _halfDayPeriod = 'morning';
  final _reason = TextEditingController();

  double? _previewWorkingDays;
  String? _previewError;
  bool _isLoadingPreview = false;

  Timer? _debounceTimer;
  int _previewRequestId = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _schedulePreview();
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _reason.dispose();
    super.dispose();
  }

  void _schedulePreview() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _loadPreview();
    });
  }

  void _loadPreview() async {
    if (!mounted) return;

    if (_end.isBefore(_start)) {
      setState(() {
        _previewError = 'تاريخ الانتهاء يجب أن يكون بعد أو يساوي تاريخ البدء.';
        _isLoadingPreview = false;
        _previewWorkingDays = null;
      });
      return;
    }

    final requestId = ++_previewRequestId;

    setState(() {
      _isLoadingPreview = true;
      _previewError = null;
      _previewWorkingDays = null;
    });

    final cubit = context.read<LeaveCubit>();
    final res = await cubit.previewLeave(
      type: _type,
      startDate: _start,
      endDate: _end,
      isHalfDay: _isHalfDay,
      halfDayPeriod: _isHalfDay ? _halfDayPeriod : null,
      reason: _reason.text.trim().isEmpty
          ? 'Leave request'
          : _reason.text.trim(),
    );

    if (!mounted || requestId != _previewRequestId) return;

    if (res.containsKey('error')) {
      setState(() {
        _previewError = res['error'] as String;
        _isLoadingPreview = false;
      });
    } else {
      setState(() {
        _previewWorkingDays = double.tryParse(
          res['workingDays']?.toString() ?? '',
        );
        _isLoadingPreview = false;
      });
    }
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _start,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _start) {
      setState(() {
        _start = picked;
        if (_end.isBefore(_start)) {
          _end = _start;
        }
      });
      _schedulePreview();
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _end,
      firstDate: _start,
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _end) {
      setState(() {
        _end = picked;
      });
      _schedulePreview();
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy-MM-dd');

    return BlocListener<LeaveCubit, LeaveState>(
      listener: (context, state) {
        if (state is LeaveLoaded && state.applySuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('leave_apply_success'.tr()),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      },
      child: Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 24.h,
          left: 16.w,
          right: 16.w,
          top: 24.h,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'apply_leave'.tr(),
                style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16.h),

              // Policy Fetching and Dropdown
              BlocBuilder<LeaveCubit, LeaveState>(
                builder: (context, state) {
                  List<LeavePolicy> policies = [];
                  if (state is LeaveLoaded) {
                    policies = state.policies.where((p) => p.isActive).toList();
                  }

                  final availableTypes = policies.isNotEmpty
                      ? policies.map((p) => p.type).toList()
                      : LeaveType.values;

                  final currentType = availableTypes.contains(_type)
                      ? _type
                      : availableTypes.first;

                  return DropdownButtonFormField<LeaveType>(
                    value: currentType,
                    items: availableTypes.map((t) {
                      final policy = policies.firstWhere(
                        (p) => p.type == t,
                        orElse: () => LeavePolicy(
                          id: '',
                          type: t,
                          displayNameAr: t.name.tr(),
                          annualEntitlement: 0,
                          isPaid: true,
                          requiresBalance: true,
                          allowHalfDay: true,
                          minimumNoticeDays: 0,
                          requiresReason: true,
                          isActive: true,
                        ),
                      );
                      return DropdownMenuItem(
                        value: t,
                        child: Text(policy.displayNameAr),
                      );
                    }).toList(),
                    onChanged: (v) {
                      if (v != null) {
                        setState(() {
                          _type = v;
                        });
                        _schedulePreview();
                      }
                    },
                    decoration: InputDecoration(
                      labelText: 'leave_type'.tr(),
                      border: const OutlineInputBorder(),
                    ),
                  );
                },
              ),
              SizedBox(height: 16.h),

              // Date pickers
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _selectStartDate(context),
                      icon: const Icon(Icons.calendar_today),
                      label: Text(
                        '${'start_date'.tr()}:\n${dateFormat.format(_start)}',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _selectEndDate(context),
                      icon: const Icon(Icons.calendar_today),
                      label: Text(
                        '${'end_date'.tr()}:\n${dateFormat.format(_end)}',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),

              // Half Day Options
              CheckboxListTile(
                title: Text('half_day'.tr()),
                value: _isHalfDay,
                onChanged: (val) {
                  setState(() {
                    _isHalfDay = val ?? false;
                    if (_isHalfDay) {
                      _end = _start;
                    }
                  });
                  _schedulePreview();
                },
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: AppColors.primary,
              ),
              if (_isHalfDay) ...[
                SizedBox(height: 8.h),
                DropdownButtonFormField<String>(
                  value: _halfDayPeriod,
                  items: [
                    DropdownMenuItem(
                      value: 'morning',
                      child: Text('morning'.tr()),
                    ),
                    DropdownMenuItem(
                      value: 'afternoon',
                      child: Text('afternoon'.tr()),
                    ),
                  ],
                  onChanged: (val) {
                    setState(() {
                      _halfDayPeriod = val!;
                    });
                    _schedulePreview();
                  },
                  decoration: InputDecoration(
                    labelText: 'period'.tr(),
                    border: const OutlineInputBorder(),
                  ),
                ),
              ],
              SizedBox(height: 16.h),

              TextField(
                controller: _reason,
                decoration: InputDecoration(
                  labelText: 'reason'.tr(),
                  border: const OutlineInputBorder(),
                ),
                onChanged: (_) {
                  _schedulePreview();
                },
              ),
              SizedBox(height: 16.h),

              // Preview Section
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'preflight_preview'.tr(),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13.sp,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    if (_isLoadingPreview)
                      const Center(child: AppLoader(size: 20))
                    else if (_previewError != null)
                      Text(
                        _previewError!,
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      )
                    else
                      Text(
                        '${'calculated_working_days'.tr()}: ${_previewWorkingDays ?? 0} ${'days'.tr()}',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14.sp,
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(height: 24.h),

              BlocBuilder<LeaveCubit, LeaveState>(
                builder: (context, state) {
                  final isApplying = state is LeaveLoaded && state.isApplying;
                  final applyError = state is LeaveLoaded
                      ? state.applyError
                      : null;

                  return Column(
                    children: [
                      if (applyError != null) ...[
                        Text(
                          applyError,
                          style: TextStyle(color: Colors.red, fontSize: 13.sp),
                        ),
                        SizedBox(height: 12.h),
                      ],
                      ElevatedButton(
                        onPressed: isApplying
                            ? null
                            : () {
                                if (_reason.text.trim().isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('reason_required'.tr()),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  return;
                                }

                                context.read<LeaveCubit>().applyLeave(
                                  type: _type,
                                  start: _start,
                                  end: _end,
                                  isHalfDay: _isHalfDay,
                                  halfDayPeriod: _isHalfDay
                                      ? _halfDayPeriod
                                      : null,
                                  reason: _reason.text.trim(),
                                );
                              },
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                          backgroundColor: AppColors.primary,
                        ),
                        child: isApplying
                            ? const AppLoader(size: 20)
                            : Text(
                                'submit_request'.tr(),
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  color: Colors.white,
                                ),
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
    );
  }
}
