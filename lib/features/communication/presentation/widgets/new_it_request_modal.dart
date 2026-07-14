import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../domain/entities/it_request_entities.dart';
import '../bloc/communication_cubit.dart';
import '../bloc/communication_state.dart';
import 'package:hr_app_demo/core/widgets/app_loader.dart';


class NewItRequestModal extends StatefulWidget {
  const NewItRequestModal({super.key});

  @override
  State<NewItRequestModal> createState() => _NewItRequestModalState();
}

class _NewItRequestModalState extends State<NewItRequestModal> {
  ItRequestCategory _selectedCategory = ItRequestCategory.hardware;
  final _descController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24.w,
        right: 24.w,
        top: 24.w,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24.h,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('new_it_request'.tr(), style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold)),
          SizedBox(height: 16.h),
          DropdownButtonFormField<ItRequestCategory>(
            value: _selectedCategory,
            decoration: InputDecoration(labelText: 'category'.tr(), border: const OutlineInputBorder()),
            items: ItRequestCategory.values.map((cat) {
              return DropdownMenuItem(value: cat, child: Text(cat.name.tr())); // Requires category enum translation
            }).toList(),
            onChanged: (val) {
              if (val != null) setState(() => _selectedCategory = val);
            },
          ),
          SizedBox(height: 16.h),
          TextField(
            controller: _descController,
            decoration: InputDecoration(labelText: 'description'.tr(), border: const OutlineInputBorder()),
            maxLines: 3,
          ),
          SizedBox(height: 24.h),
          BlocBuilder<CommunicationCubit, CommunicationState>(
            builder: (context, state) {
              final isSubmitting = state is CommunicationLoaded && state.isSubmittingItRequest;
              return ElevatedButton(
                onPressed: isSubmitting ? null : () {
                  if (_descController.text.trim().isNotEmpty) {
                    context.read<CommunicationCubit>().submitItRequest(_selectedCategory, _descController.text.trim());
                    Navigator.pop(context);
                  }
                },
                child: isSubmitting ? const AppLoader(size: 24) : Text('submit_request'.tr()),
              );
            },
          ),
        ],
      ),
    );
  }
}
