import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';

class LeaveErrorMapper {
  static String map(dynamic error) {
    if (error == null) return '';

    String errorString = '';
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map) {
        final msg = data['message'];
        if (msg is List) {
          errorString = msg.join(', ');
        } else if (msg != null) {
          errorString = msg.toString();
        } else {
          errorString = (data['error'] ?? error.message ?? '').toString();
        }
      } else if (data is String) {
        errorString = data;
      } else {
        errorString = error.message ?? '';
      }
    } else {
      errorString = error.toString();
    }
    return mapError(errorString);
  }

  static String mapError(String errorString) {
    final clean = errorString.toUpperCase();

    if (clean.contains('POLICY_NOT_FOUND_OR_INACTIVE')) {
      return 'error_policy_not_found'.tr();
    }
    if (clean.contains('START_DATE_BEFORE_TODAY')) {
      return 'error_start_date_past'.tr();
    }
    if (clean.contains('MINIMUM_NOTICE_NOT_MET')) {
      return 'error_minimum_notice'.tr();
    }
    if (clean.contains('REASON_REQUIRED')) {
      return 'error_reason_required'.tr();
    }
    if (clean.contains('HALFDAY_NOT_ALLOWED')) {
      return 'error_halfday_not_allowed'.tr();
    }
    if (clean.contains('HALFDAY_MUST_SPAN_ONE_DAY')) {
      return 'error_halfday_must_span_one_day'.tr();
    }
    if (clean.contains('HALFDAY_PERIOD_REQUIRED')) {
      return 'error_halfday_period_required'.tr();
    }
    if (clean.contains('NO_WORKING_DAYS_IN_RANGE')) {
      return 'error_no_working_days'.tr();
    }
    if (clean.contains('LEAVE_OVERLAP')) {
      return 'error_leave_overlap'.tr();
    }
    if (clean.contains('ATTENDANCE_CONFLICT')) {
      return 'error_attendance_conflict'.tr();
    }
    if (clean.contains('LEAVE_BALANCE_NOT_FOUND')) {
      return 'error_leave_balance_not_found'.tr();
    }
    if (clean.contains('INSUFFICIENT_LEAVE_BALANCE')) {
      return 'error_insufficient_leave_balance'.tr();
    }
    if (clean.contains('MISSING_TEAM_LEAD_APPROVER')) {
      return 'error_missing_team_lead_approver'.tr();
    }
    if (clean.contains('MISSING_MANAGER_APPROVER')) {
      return 'error_missing_manager_approver'.tr();
    }
    if (clean.contains('MISSING_FINAL_HR_APPROVER')) {
      return 'error_missing_final_hr_approver'.tr();
    }
    if (clean.contains('LEAVE_APPROVAL_CHAIN_NOT_CONFIGURED')) {
      return 'error_leave_approval_chain_not_configured'.tr();
    }
    if (clean.contains('APPROVED_LEAVE_ACTIVE')) {
      return 'error_approved_leave_active'.tr();
    }
    if (clean.contains('REJECTION_REASON_REQUIRED')) {
      return 'error_rejection_reason_required'.tr();
    }
    if (clean.contains('USER_NOT_FOUND')) {
      return 'error_user_not_found'.tr();
    }
    if (clean.contains('USER_ALREADY_EXISTS')) {
      return 'error_user_already_exists'.tr();
    }
    if (clean.contains('UNAUTHORIZED')) {
      return 'error_unauthorized'.tr();
    }
    if (clean.contains('FORBIDDEN')) {
      return 'error_forbidden'.tr();
    }
    if (clean.contains('BAD_REQUEST')) {
      return 'error_bad_request'.tr();
    }
    if (clean.contains('INTERNAL_SERVER_ERROR')) {
      return 'error_internal_server'.tr();
    }
    if (clean.contains('SOCKET') || clean.contains('NETWORK') || clean.contains('CONNECTION')) {
      return 'error_network_connection'.tr();
    }
    if (clean.contains('INVALID_BALANCE_STATE') ||
        clean.contains('INVALID_BALANCE')) {
      return 'error_invalid_balance'.tr();
    }

    if (clean.contains('THROTTLEREXCEPTION') ||
        clean.contains('TOO MANY REQUESTS') ||
        errorString.contains('429')) {
      return 'error_too_many_requests'.tr();
    }

    if (errorString.contains('DioException') ||
        errorString.contains('status code of 400')) {
      return 'error_bad_request'.tr();
    }

    return errorString;
  }
}
