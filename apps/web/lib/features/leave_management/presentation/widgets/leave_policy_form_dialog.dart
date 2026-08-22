import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:hr_core/features/leave/domain/entities/leave_enums.dart';
import 'package:hr_core/features/leave/domain/entities/leave_policy.dart';
import '../bloc/leave_management_cubit.dart';

class LeavePolicyFormDialog extends StatefulWidget {
  final LeavePolicy? existingPolicy;
  final LeaveManagementCubit cubit;

  const LeavePolicyFormDialog({
    super.key,
    this.existingPolicy,
    required this.cubit,
  });

  @override
  State<LeavePolicyFormDialog> createState() => _LeavePolicyFormDialogState();
}

class _LeavePolicyFormDialogState extends State<LeavePolicyFormDialog> {
  late LeaveType _selectedType;
  late TextEditingController _nameCtrl;
  late TextEditingController _entitlementCtrl;
  late TextEditingController _noticeCtrl;
  late bool _isPaid;
  late bool _requiresBalance;
  late bool _allowHalfDay;
  late bool _requiresReason;
  late bool _isActive;

  String? _nameError;
  String? _entitlementError;
  String? _noticeError;
  String? _serverError;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.existingPolicy;
    _selectedType = p?.type ?? LeaveType.annual;
    _nameCtrl = TextEditingController(text: p?.displayNameAr ?? '');
    _entitlementCtrl = TextEditingController(
      text: p != null ? p.annualEntitlement.toString() : '',
    );
    _noticeCtrl = TextEditingController(
      text: p != null ? p.minimumNoticeDays.toString() : '',
    );
    _isPaid = p?.isPaid ?? true;
    _requiresBalance = p?.requiresBalance ?? true;
    _allowHalfDay = p?.allowHalfDay ?? true;
    _requiresReason = p?.requiresReason ?? true;
    _isActive = p?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _entitlementCtrl.dispose();
    _noticeCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final nameStr = _nameCtrl.text.trim();
    final ent = double.tryParse(_entitlementCtrl.text.trim());
    final notice = int.tryParse(_noticeCtrl.text.trim());

    String? nameErr;
    String? entErr;
    String? noticeErr;

    if (nameStr.isEmpty) {
      nameErr = 'display_name_required'.tr();
    }
    if (ent == null || ent <= 0) {
      entErr = 'invalid_entitlement'.tr();
    }
    if (notice == null || notice < 0) {
      noticeErr = 'invalid_notice_days'.tr();
    }

    if (nameErr != null || entErr != null || noticeErr != null) {
      setState(() {
        _nameError = nameErr;
        _entitlementError = entErr;
        _noticeError = noticeErr;
        _serverError = null;
      });
      return;
    }

    setState(() {
      _nameError = null;
      _entitlementError = null;
      _noticeError = null;
      _serverError = null;
      _isSaving = true;
    });

    bool ok = false;
    if (widget.existingPolicy == null) {
      final policy = LeavePolicy(
        id: '',
        type: _selectedType,
        displayNameAr: nameStr,
        annualEntitlement: ent!,
        isPaid: _isPaid,
        requiresBalance: _requiresBalance,
        allowHalfDay: _allowHalfDay,
        minimumNoticeDays: notice!,
        requiresReason: _requiresReason,
        isActive: _isActive,
      );
      ok = await widget.cubit.createPolicy(policy);
    } else {
      ok = await widget.cubit.updatePolicy(widget.existingPolicy!.type, {
        'displayNameAr': nameStr,
        'annualEntitlement': ent!,
        'isPaid': _isPaid,
        'requiresBalance': _requiresBalance,
        'allowHalfDay': _allowHalfDay,
        'minimumNoticeDays': notice!,
        'requiresReason': _requiresReason,
        'isActive': _isActive,
      });
    }

    if (!mounted) return;

    if (ok) {
      Navigator.pop(context);
    } else {
      final state = widget.cubit.state;
      String? err;
      if (state is LeaveManagementLoaded) {
        err = state.actionError;
      }
      setState(() {
        _isSaving = false;
        _serverError = err ?? 'Failed to save policy';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existingPolicy != null;

    return AlertDialog(
      title: Text(
        isEdit ? 'edit_leave_policy'.tr() : 'create_leave_policy'.tr(),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_serverError != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Text(
                  _serverError!,
                  style: const TextStyle(color: Colors.red, fontSize: 13),
                ),
              ),
            ],
            if (!isEdit)
              DropdownButtonFormField<LeaveType>(
                value: _selectedType,
                decoration: InputDecoration(labelText: 'leave_type'.tr()),
                items: LeaveType.values
                    .map(
                      (t) =>
                          DropdownMenuItem(value: t, child: Text(t.name.tr())),
                    )
                    .toList(),
                onChanged: _isSaving
                    ? null
                    : (val) {
                        if (val != null) {
                          setState(() => _selectedType = val);
                        }
                      },
              )
            else
              Text(
                '${'leave_type'.tr()}: ${widget.existingPolicy!.type.name.tr()}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            const SizedBox(height: 12),
            TextField(
              controller: _nameCtrl,
              enabled: !_isSaving,
              decoration: InputDecoration(
                labelText: 'displayNameAr'.tr(),
                errorText: _nameError,
              ),
              onChanged: (_) {
                if (_nameError != null) setState(() => _nameError = null);
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _entitlementCtrl,
              enabled: !_isSaving,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: 'annualEntitlement'.tr(),
                errorText: _entitlementError,
              ),
              onChanged: (_) {
                if (_entitlementError != null)
                  setState(() => _entitlementError = null);
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _noticeCtrl,
              enabled: !_isSaving,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'minimumNoticeDays'.tr(),
                errorText: _noticeError,
              ),
              onChanged: (_) {
                if (_noticeError != null) setState(() => _noticeError = null);
              },
            ),
            const SizedBox(height: 12),
            CheckboxListTile(
              title: Text('isPaid'.tr()),
              value: _isPaid,
              onChanged: _isSaving
                  ? null
                  : (v) => setState(() => _isPaid = v ?? true),
            ),
            CheckboxListTile(
              title: Text('requiresBalance'.tr()),
              value: _requiresBalance,
              onChanged: _isSaving
                  ? null
                  : (v) => setState(() => _requiresBalance = v ?? true),
            ),
            CheckboxListTile(
              title: Text('allowHalfDay'.tr()),
              value: _allowHalfDay,
              onChanged: _isSaving
                  ? null
                  : (v) => setState(() => _allowHalfDay = v ?? false),
            ),
            CheckboxListTile(
              title: Text('requiresReason'.tr()),
              value: _requiresReason,
              onChanged: _isSaving
                  ? null
                  : (v) => setState(() => _requiresReason = v ?? true),
            ),
            CheckboxListTile(
              title: Text('isActive'.tr()),
              value: _isActive,
              onChanged: _isSaving
                  ? null
                  : (v) => setState(() => _isActive = v ?? true),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: Text('cancel'.tr()),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _handleSave,
          child: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text('save'.tr()),
        ),
      ],
    );
  }
}
