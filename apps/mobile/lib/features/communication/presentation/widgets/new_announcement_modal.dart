import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_loader.dart';
import '../bloc/communication_cubit.dart';

class NewAnnouncementModal extends StatefulWidget {
  const NewAnnouncementModal({super.key});

  @override
  State<NewAnnouncementModal> createState() => _NewAnnouncementModalState();
}

class _NewAnnouncementModalState extends State<NewAnnouncementModal> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  String? _selectedDepartment;
  bool _isSubmitting = false;

  final List<String> _departments = [
    'Engineering',
    'HR',
    'Finance',
    'Sales',
    'Marketing',
    'Operations',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      await context.read<CommunicationCubit>().createAnnouncement(
            _titleController.text.trim(),
            _bodyController.text.trim(),
            department: _selectedDepartment,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم نشر الإعلان بنجاح'.tr()),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ أثناء نشر الإعلان: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24.h,
        left: 20.w,
        right: 20.w,
        top: 24.h,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'إضافة إعلان جديد',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: AppColors.textSecondary),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              SizedBox(height: 16.h),

              // Title input
              TextFormField(
                controller: _titleController,
                style: TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'عنوان الإعلان',
                  hintText: 'مثال: اجتماع الإدارة القادم',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'يرجى إدخال عنوان الإعلان';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16.h),

              // Body input
              TextFormField(
                controller: _bodyController,
                maxLines: 4,
                style: TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'محتوى الإعلان',
                  hintText: 'اكتب تفاصيل الإعلان هنا...',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'يرجى إدخال محتوى الإعلان';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16.h),

              // Target audience / Department dropdown
              DropdownButtonFormField<String?>(
                value: _selectedDepartment,
                style: TextStyle(color: AppColors.textPrimary, fontSize: 14.sp),
                dropdownColor: Theme.of(context).cardColor,
                decoration: InputDecoration(
                  labelText: 'الجمهور المستهدف',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                items: [
                  DropdownMenuItem<String?>(
                    value: null,
                    child: Text(
                      'عام لكافة الموظفين',
                      style: TextStyle(color: AppColors.textPrimary),
                    ),
                  ),
                  ..._departments.map(
                    (d) => DropdownMenuItem<String?>(
                      value: d,
                      child: Text(
                        'قسم $d',
                        style: TextStyle(color: AppColors.textPrimary),
                      ),
                    ),
                  ),
                ],
                onChanged: (val) {
                  setState(() {
                    _selectedDepartment = val;
                  });
                },
              ),
              SizedBox(height: 24.h),

              // Submit Button
              ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                icon: _isSubmitting
                    ? const AppLoader(size: 20)
                    : const Icon(Icons.send_rounded, color: Colors.white),
                label: Text(
                  _isSubmitting ? 'جاري النشر...' : 'نشر الإعلان',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
