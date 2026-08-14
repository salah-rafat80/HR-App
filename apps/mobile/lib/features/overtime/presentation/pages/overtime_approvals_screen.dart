import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hr_app_demo/core/bloc/session_cubit.dart';
import 'package:hr_app_demo/core/di/injection.dart';
import 'package:hr_core/features/attendance/domain/entities/overtime_request.dart';
import 'package:hr_core/features/attendance/domain/repositories/attendance_repository.dart';

class OvertimeApprovalsScreen extends StatefulWidget {
  const OvertimeApprovalsScreen({super.key});

  @override
  State<OvertimeApprovalsScreen> createState() =>
      _OvertimeApprovalsScreenState();
}

class _OvertimeApprovalsScreenState extends State<OvertimeApprovalsScreen> {
  final AttendanceRepository _repository = getIt<AttendanceRepository>();
  late Future<List<OvertimeRequest>> _requests;

  @override
  void initState() {
    super.initState();
    _requests = _repository.getPendingOvertimeApprovals();
  }

  void _refresh() {
    setState(() => _requests = _repository.getPendingOvertimeApprovals());
  }

  Future<void> _decide(OvertimeRequest request, bool approved) async {
    final comment = await _askForComment(approved);
    if (comment == null || !mounted) return;
    final role = context.read<SessionCubit>().state.role;
    try {
      if (role == 'team_lead') {
        if (approved) {
          await _repository.approveOvertimeAsTeamLead(
            request.id,
            comment: comment,
          );
        } else {
          await _repository.rejectOvertimeAsTeamLead(
            request.id,
            comment: comment,
          );
        }
      } else if (role == 'hr' || role == 'hrAdmin' || role == 'superAdmin') {
        if (approved) {
          await _repository.approveOvertimeAsHr(request.id, comment: comment);
        } else {
          await _repository.rejectOvertimeAsHr(request.id, comment: comment);
        }
      } else {
        throw StateError('Current role cannot approve overtime.');
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(approved ? 'Overtime approved.' : 'Overtime rejected.'),
        ),
      );
      _refresh();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'The server rejected this action. Refresh and try again.',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<String?> _askForComment(bool approved) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(approved ? 'Approve overtime' : 'Reject overtime'),
        content: TextField(
          controller: controller,
          maxLength: 1000,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Comment (optional)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, controller.text.trim()),
            style: approved
                ? null
                : FilledButton.styleFrom(backgroundColor: Colors.red),
            child: Text(approved ? 'Approve' : 'Reject'),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final role = context.watch<SessionCubit>().state.role;
    final allowed =
        role == 'team_lead' ||
        role == 'hr' ||
        role == 'hrAdmin' ||
        role == 'superAdmin';
    if (!allowed) {
      return const Scaffold(
        body: Center(child: Text('You do not have overtime approval access.')),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Overtime approvals'),
        actions: [
          IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: FutureBuilder<List<OvertimeRequest>>(
        future: _requests,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Unable to load approvals.'));
          }
          final requests = snapshot.data ?? const <OvertimeRequest>[];
          if (requests.isEmpty) {
            return const Center(child: Text('No pending overtime requests.'));
          }
          return RefreshIndicator(
            onRefresh: () async => _refresh(),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: requests.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final request = requests[index];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          request.employeeName ??
                              request.employeeCode ??
                              request.userId,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        if (request.department != null)
                          Text(request.department!),
                        const SizedBox(height: 8),
                        Text(request.reason),
                        const SizedBox(height: 8),
                        Text(
                          '${request.requestedHours.toStringAsFixed(1)} hours',
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => _decide(request, false),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red,
                                ),
                                child: const Text('Reject'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: FilledButton(
                                onPressed: () => _decide(request, true),
                                child: const Text('Approve'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
