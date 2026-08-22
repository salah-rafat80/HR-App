import 'package:dio/dio.dart';

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
      return 'سياسة الإجازة غير موجودة أو غير نشطة حالياً.';
    }
    if (clean.contains('START_DATE_BEFORE_TODAY')) {
      return 'تاريخ بدء الإجازة لا يمكن أن يكون في الماضي.';
    }
    if (clean.contains('MINIMUM_NOTICE_NOT_MET')) {
      return 'لم يتم استيفاء الحد الأدنى لأيام الإشعار المسبق المطلوبة لهذه الإجازة.';
    }
    if (clean.contains('REASON_REQUIRED')) {
      return 'سبب الإجازة مطلوب ولا يمكن تركه فارغاً.';
    }
    if (clean.contains('HALFDAY_NOT_ALLOWED')) {
      return 'إجازة نصف اليوم غير مسموح بها لهذا النوع من الإجازات.';
    }
    if (clean.contains('HALFDAY_MUST_SPAN_ONE_DAY')) {
      return 'طلب نصف يوم يجب أن يبدأ وينتهي في نفس التاريخ.';
    }
    if (clean.contains('HALFDAY_PERIOD_REQUIRED')) {
      return 'يرجى تحديد الفترة المطلوبة لنصف اليوم (صباحية/مسائية).';
    }
    if (clean.contains('NO_WORKING_DAYS_IN_RANGE')) {
      return 'النطاق المحدد يحتوي على عطلات رسمية أو أسبوعية فقط.';
    }
    if (clean.contains('LEAVE_OVERLAP')) {
      return 'توجد إجازة أخرى معلقة أو معتمدة متداخلة مع هذه التواريخ.';
    }
    if (clean.contains('ATTENDANCE_CONFLICT')) {
      return 'يوجد سجل حضور مسجل بالفعل في أحد أيام العمل المحددة.';
    }
    if (clean.contains('LEAVE_BALANCE_NOT_FOUND')) {
      return 'لا يوجد رصيد إجازات مهيأ لهذا المستخدم لهذا العام.';
    }
    if (clean.contains('INSUFFICIENT_LEAVE_BALANCE')) {
      return 'رصيد الإجازات المتاح غير كافٍ لإتمام الطلب.';
    }
    if (clean.contains('LEAVE_APPROVAL_CHAIN_NOT_CONFIGURED')) {
      return 'سلسلة الموافقات غير مهيأة (يرجى التأكد من تعيين المدير المباشر، مدير الإدارة، وتعيين مسؤول HR المعتمد للشركة).';
    }
    if (clean.contains('APPROVED_LEAVE_ACTIVE')) {
      return 'لا يمكنك تسجيل الحضور اليوم نظراً لوجود إجازة معتمدة ونشطة.';
    }
    if (clean.contains('REJECTION_REASON_REQUIRED')) {
      return 'سبب الرفض مطلوب وإلزامي لإتمام العملية.';
    }
    if (clean.contains('INVALID_BALANCE_STATE') ||
        clean.contains('INVALID_BALANCE')) {
      return 'فشلت العملية: ستؤدي إلى حالة رصيد غير صالحة أو رصيد سالب.';
    }

    if (errorString.contains('DioException') ||
        errorString.contains('status code of 400')) {
      return 'تعذر تنفيذ المعاينة: يرجى التأكد من اختيار نوع إجازة متاح وتاريخ جديد بدون تداخل.';
    }

    return errorString;
  }
}
