import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hr_app_demo/core/di/injection.dart';
import 'package:hr_app_demo/core/services/biometric_service.dart';
import 'package:hr_app_demo/core/services/location_service.dart';
import 'package:hr_app_demo/core/theme/app_colors.dart';
import 'package:hr_app_demo/core/widgets/app_card.dart';
import 'package:hr_app_demo/core/widgets/app_loader.dart';
import 'package:hr_core/features/attendance/domain/entities/overtime_request.dart';

import '../bloc/attendance_cubit.dart';
import '../bloc/attendance_state.dart';

class AttendanceRequestsTab extends StatefulWidget {
  const AttendanceRequestsTab({super.key});

  @override
  State<AttendanceRequestsTab> createState() => _AttendanceRequestsTabState();
}

class _AttendanceRequestsTabState extends State<AttendanceRequestsTab> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  late DateTime _requestedStartAt;
  late DateTime _requestedEndAt;
  bool _isSessionActionRunning = false;

  BiometricService get _biometric => getIt<BiometricService>();
  LocationService get _location => getIt<LocationService>();

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _requestedStartAt = DateTime(now.year, now.month, now.day, now.hour);
    _requestedEndAt = _requestedStartAt.add(const Duration(hours: 1));
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  bool get _isArabic => context.locale.languageCode == 'ar';

  String get _requestTitle => _isArabic ? 'طلب أوفر تايم' : 'Overtime request';

  Future<void> _pickTime({required bool isStart}) async {
    final current = isStart ? _requestedStartAt : _requestedEndAt;
    final selected = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current),
    );
    if (selected == null || !mounted) return;
    final next = DateTime(
      current.year,
      current.month,
      current.day,
      selected.hour,
      selected.minute,
    );
    setState(() {
      if (isStart) {
        _requestedStartAt = next;
      } else {
        _requestedEndAt = next;
      }
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (!_requestedEndAt.isAfter(_requestedStartAt)) {
      _showMessage(
        _isArabic
            ? 'وقت النهاية يجب أن يكون بعد وقت البداية.'
            : 'End time must be after start time.',
        error: true,
      );
      return;
    }
    context.read<AttendanceCubit>().submitOvertime(
      requestedStartAt: _requestedStartAt,
      requestedEndAt: _requestedEndAt,
      reason: _reasonController.text.trim(),
    );
  }

  Future<void> _runSessionAction(
    OvertimeRequest request, {
    required bool start,
  }) async {
    if (_isSessionActionRunning) return;
    setState(() => _isSessionActionRunning = true);
    final cubit = context.read<AttendanceCubit>();
    try {
      if (!await _location.isLocationServiceEnabled()) {
        _showMessage(
          _isArabic ? 'فعّل خدمة الموقع أولاً.' : 'Enable GPS first.',
          error: true,
        );
        return;
      }
      if (!await _location.requestPermission()) {
        _showMessage(
          _isArabic ? 'تم رفض صلاحية الموقع.' : 'Location permission denied.',
          error: true,
        );
        return;
      }
      final location = await _location.getCurrentPosition();
      if (location == null || location.accuracy > 50) {
        _showMessage(
          _isArabic
              ? 'تعذر الحصول على موقع حديث ودقيق (≤ 50 متر).'
              : 'A fresh GPS fix with ≤ 50m accuracy is required.',
          error: true,
        );
        return;
      }
      final preflight = await cubit.preflightGeofence(
        lat: location.lat,
        lng: location.lng,
        accuracy: location.accuracy,
      );
      if (preflight.outcome != PreflightOutcome.inRange) {
        _showMessage(
          _isArabic
              ? 'أنت خارج نطاق الفرع المسموح.'
              : 'You are outside the allowed branch range.',
          error: true,
        );
        return;
      }
      if (!await _biometric.isBiometricAvailable()) {
        _showMessage(
          _isArabic
              ? 'البصمة غير متاحة على هذا الجهاز.'
              : 'Biometric is unavailable.',
          error: true,
        );
        return;
      }
      final authenticated = await _biometric.authenticateBiometricOnly(
        start
            ? (_isArabic
                  ? 'أكد بصمتك لبدء الأوفر تايم'
                  : 'Authenticate to start overtime')
            : (_isArabic
                  ? 'أكد بصمتك لإنهاء الأوفر تايم'
                  : 'Authenticate to end overtime'),
      );
      if (!authenticated || !mounted) return;

      final session = start
          ? await cubit.startOvertimeSession(
              requestId: request.id,
              lat: location.lat,
              lng: location.lng,
              accuracy: location.accuracy,
            )
          : await cubit.endOvertimeSession(
              sessionId: request.session!.id,
              lat: location.lat,
              lng: location.lng,
              accuracy: location.accuracy,
            );
      if (session != null && mounted) {
        _showMessage(
          start
              ? (_isArabic
                    ? 'تم بدء جلسة الأوفر تايم.'
                    : 'Overtime session started.')
              : (_isArabic
                    ? 'تم إنهاء جلسة الأوفر تايم.'
                    : 'Overtime session ended.'),
        );
      }
    } finally {
      if (mounted) setState(() => _isSessionActionRunning = false);
    }
  }

  void _showMessage(String message, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? AppColors.error : AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AttendanceCubit, AttendanceState>(
      listenWhen: (previous, current) =>
          current is AttendanceError ||
          (previous is AttendanceLoaded &&
              current is AttendanceLoaded &&
              previous.overtimeRequests.length <
                  current.overtimeRequests.length),
      listener: (context, state) {
        if (state is AttendanceError) {
          _showMessage(
            _isArabic
                ? 'تعذر تنفيذ عملية الأوفر تايم.'
                : 'Overtime action failed.',
            error: true,
          );
        } else if (state is AttendanceLoaded) {
          _reasonController.clear();
          _showMessage(
            _isArabic
                ? 'تم إرسال الطلب للموافقة.'
                : 'Request sent for approval.',
          );
        }
      },
      builder: (context, state) {
        if (state is! AttendanceLoaded) return const AppLoader();
        return SingleChildScrollView(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _requestForm(state),
              SizedBox(height: 24.h),
              Text(
                _isArabic ? 'طلباتي' : 'My overtime requests',
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12.h),
              if (state.overtimeRequests.isEmpty)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 24.h),
                  child: Center(
                    child: Text(
                      _isArabic
                          ? 'لا توجد طلبات أوفر تايم.'
                          : 'No overtime requests.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                )
              else
                ...state.overtimeRequests.map(
                  (request) => _OvertimeRequestCard(
                    request: request,
                    isArabic: _isArabic,
                    sessionBusy: _isSessionActionRunning,
                    onStart: request.isApproved
                        ? () => _runSessionAction(request, start: true)
                        : null,
                    onEnd: request.hasActiveSession
                        ? () => _runSessionAction(request, start: false)
                        : null,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _requestForm(AttendanceLoaded state) {
    final timeFormat = DateFormat('HH:mm', context.locale.languageCode);
    return AppCard(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _requestTitle,
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8.h),
              Text(
                _isArabic
                    ? 'الطلب يمر بقائد الفريق ثم HR. لن يتاح البدء إلا بعد الانصراف الأساسي.'
                    : 'Team Lead then HR approval is required; start is enabled only after normal clock-out.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              SizedBox(height: 16.h),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickTime(isStart: true),
                      icon: const Icon(Icons.play_circle_outline),
                      label: Text(
                        '${_isArabic ? 'البداية' : 'Start'}: ${timeFormat.format(_requestedStartAt)}',
                      ),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickTime(isStart: false),
                      icon: const Icon(Icons.stop_circle_outlined),
                      label: Text(
                        '${_isArabic ? 'النهاية' : 'End'}: ${timeFormat.format(_requestedEndAt)}',
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              TextFormField(
                controller: _reasonController,
                maxLines: 3,
                maxLength: 1000,
                decoration: InputDecoration(
                  labelText: _isArabic ? 'السبب' : 'Reason',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.notes_outlined),
                ),
                validator: (value) {
                  if (value == null || value.trim().length < 5) {
                    return _isArabic
                        ? 'اكتب سببًا واضحًا (5 أحرف على الأقل).'
                        : 'Enter a clear reason (at least 5 characters).';
                  }
                  return null;
                },
              ),
              SizedBox(height: 12.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: state.isSubmittingOvertime ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                  ),
                  child: state.isSubmittingOvertime
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(_isArabic ? 'إرسال الطلب' : 'Submit request'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OvertimeRequestCard extends StatelessWidget {
  final OvertimeRequest request;
  final bool isArabic;
  final bool sessionBusy;
  final VoidCallback? onStart;
  final VoidCallback? onEnd;

  const _OvertimeRequestCard({
    required this.request,
    required this.isArabic,
    required this.sessionBusy,
    this.onStart,
    this.onEnd,
  });

  @override
  Widget build(BuildContext context) {
    final (statusColor, statusLabel) = _statusPresentation(
      request.status,
      isArabic,
    );
    final dateFormat = DateFormat(
      'dd MMM · HH:mm',
      context.locale.languageCode,
    );
    return AppCard(
      margin: EdgeInsets.only(bottom: 10.h),
      child: Padding(
        padding: EdgeInsets.all(14.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    request.reason,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                _StatusChip(label: statusLabel, color: statusColor),
              ],
            ),
            SizedBox(height: 8.h),
            Text(
              request.requestedStartAt == null || request.requestedEndAt == null
                  ? dateFormat.format(request.submittedAt)
                  : '${dateFormat.format(request.requestedStartAt!)} → ${DateFormat('HH:mm').format(request.requestedEndAt!)} · ${request.requestedHours.toStringAsFixed(1)} ${isArabic ? 'ساعة' : 'hours'}',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            if (request.teamLeadComment?.isNotEmpty ?? false) ...[
              SizedBox(height: 6.h),
              Text(
                '${isArabic ? 'تعليق قائد الفريق' : 'Team Lead'}: ${request.teamLeadComment}',
              ),
            ],
            if (request.hrComment?.isNotEmpty ?? false) ...[
              SizedBox(height: 4.h),
              Text('${isArabic ? 'تعليق HR' : 'HR'}: ${request.hrComment}'),
            ],
            if (onStart != null || onEnd != null) ...[
              SizedBox(height: 12.h),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: sessionBusy ? null : (onEnd ?? onStart),
                  icon: Icon(
                    onEnd != null ? Icons.stop_circle : Icons.play_circle,
                  ),
                  label: Text(
                    onEnd != null
                        ? (isArabic ? 'إنهاء الأوفر تايم' : 'End overtime')
                        : (isArabic ? 'بدء الأوفر تايم' : 'Start overtime'),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withValues(alpha: 0.4)),
    ),
    child: Text(
      label,
      style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11),
    ),
  );
}

(Color, String) _statusPresentation(OvertimeStatus status, bool isArabic) {
  return switch (status) {
    OvertimeStatus.pendingTeamLead => (
      AppColors.warning,
      isArabic ? 'بانتظار قائد الفريق' : 'Pending Team Lead',
    ),
    OvertimeStatus.pendingHr => (
      AppColors.warning,
      isArabic ? 'بانتظار HR' : 'Pending HR',
    ),
    OvertimeStatus.approved => (
      AppColors.success,
      isArabic ? 'معتمد' : 'Approved',
    ),
    OvertimeStatus.completed => (
      AppColors.success,
      isArabic ? 'مكتمل' : 'Completed',
    ),
    OvertimeStatus.rejected ||
    OvertimeStatus.rejectedByTeamLead ||
    OvertimeStatus.rejectedByHr => (
      AppColors.error,
      isArabic ? 'مرفوض' : 'Rejected',
    ),
    OvertimeStatus.cancelled || OvertimeStatus.expired => (
      AppColors.textSecondary,
      isArabic ? 'مغلق' : 'Closed',
    ),
    OvertimeStatus.pending => (
      AppColors.warning,
      isArabic ? 'قيد المراجعة' : 'Pending',
    ),
  };
}
