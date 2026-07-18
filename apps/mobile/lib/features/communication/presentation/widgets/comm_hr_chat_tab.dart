import 'package:flutter/material.dart';
import 'package:hr_app_demo/core/theme/app_icons.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_colors.dart';
import 'package:hr_core/features/communication/domain/entities/communication_entities.dart';
import '../bloc/communication_cubit.dart';
import '../bloc/communication_state.dart';
import 'package:hr_app_demo/core/widgets/app_loader.dart';


class CommHrChatTab extends StatefulWidget {
  const CommHrChatTab({super.key});

  @override
  State<CommHrChatTab> createState() => _CommHrChatTabState();
}

class _CommHrChatTabState extends State<CommHrChatTab> {
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CommunicationCubit, CommunicationState>(
      builder: (context, state) {
        if (state is! CommunicationLoaded) return const AppLoader();

        return Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.all(16.w),
                itemCount: state.chatMessages.length,
                itemBuilder: (context, index) {
                  final msg = state.chatMessages[index];
                  final isMe = msg.sender == ChatSender.me;
                  return Align(
                    alignment: isMe ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
                    child: Container(
                      margin: EdgeInsets.only(bottom: 8.h),
                      padding: EdgeInsets.all(12.w),
                      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
                      decoration: BoxDecoration(
                        color: isMe ? AppColors.primary : AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: isMe ? null : Border.all(color: AppColors.background),
                      ),
                      child: Text(
                        msg.text,
                        style: TextStyle(color: isMe ? Colors.white : AppColors.textPrimary, fontSize: 14.sp),
                      ),
                    ),
                  );
                },
              ),
            ),
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(color: AppColors.background, border: Border(top: BorderSide(color: AppColors.background))),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(hintText: 'type_message'.tr(), border: OutlineInputBorder(borderRadius: BorderRadius.circular(24))),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  IconButton(
                    icon: state.isSendingMessage ? const SizedBox(width: 24, height: 24, child: AppLoader()) : Icon(AppIcons.communication, color: AppColors.primary),
                    onPressed: state.isSendingMessage ? null : () {
                      if (_controller.text.trim().isNotEmpty) {
                        context.read<CommunicationCubit>().sendChatMessage(_controller.text.trim());
                        _controller.clear();
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
