import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hr_core/core/enums/role_enums.dart';
import 'package:hr_core/features/attendance/domain/entities/overtime_request.dart';
import 'package:hr_core/features/attendance/domain/repositories/attendance_repository.dart';

import '../../../../core/bloc/session_cubit.dart';
import '../../../../core/di/injection.dart';

class OvertimeApprovalsScreen extends StatefulWidget {
  const OvertimeApprovalsScreen({super.key});

  @override
  State<OvertimeApprovalsScreen> createState() =>
      _OvertimeApprovalsScreenState();
}

class _OvertimeApprovalsScreenState extends State<OvertimeApprovalsScreen> {
  final AttendanceRepository _repository = getIt<AttendanceRepository>();
  late Future<List<OvertimeRequest>> _requests;
  String? _error;

  @override
  void initState() {
    super.initState();
    _requests = _load();
  }

  Future<List<OvertimeRequest>> _load() async {
    try {
      return await _repository.getPendingOvertimeApprovals();
    } catch (error) {
      _error = error.toString();
      rethrow;
    }
  }

  void _refresh() {
    setState(() {
      _error = null;
      _requests = _load();
    });
  }

  Future<void> _decide(OvertimeRequest request, bool approved) async {
    final commentController = TextEditingController();
    final comment = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          approved ? 'Approve overtime request' : 'Reject overtime request',
        ),
        content: TextField(
          controller: commentController,
          maxLength: 1000,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Comment (optional)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(context, commentController.text.trim()),
            style: approved
                ? null
                : FilledButton.styleFrom(backgroundColor: Colors.red),
            child: Text(approved ? 'Approve' : 'Reject'),
          ),
        ],
      ),
    );
    commentController.dispose();
    if (comment == null || !mounted) return;

    final role = context.read<SessionCubit>().state.role;
    try {
      if (role == UserRole.teamLead) {
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
      } else if (role == UserRole.hrAdmin || role == UserRole.superAdmin) {
        if (approved) {
          await _repository.approveOvertimeAsHr(request.id, comment: comment);
        } else {
          await _repository.rejectOvertimeAsHr(request.id, comment: comment);
        }
      } else {
        throw StateError('This role cannot decide overtime requests.');
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(approved ? 'Request approved.' : 'Request rejected.'),
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

  @override
  Widget build(BuildContext context) {
    final role = context.watch<SessionCubit>().state.role;
    final canApprove =
        role == UserRole.teamLead ||
        role == UserRole.hrAdmin ||
        role == UserRole.superAdmin;
    if (!canApprove) {
      return const Center(
        child: Text('You do not have overtime approval access.'),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Overtime approvals',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Only requests in your current approval stage are shown.',
                    ),
                  ],
                ),
              ),
              IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh)),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: FutureBuilder<List<OvertimeRequest>>(
              future: _requests,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text(_error ?? 'Unable to load overtime approvals.'),
                  );
                }
                final requests = snapshot.data ?? const <OvertimeRequest>[];
                if (requests.isEmpty) {
                  return const Center(
                    child: Text('No pending overtime requests.'),
                  );
                }
                return ListView.separated(
                  itemCount: requests.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final request = requests[index];
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    request.employeeName ??
                                        request.employeeCode ??
                                        request.userId,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(request.department ?? 'No department'),
                                  const SizedBox(height: 10),
                                  Text(request.reason),
                                  const SizedBox(height: 6),
                                  Text(
                                    '${request.requestedHours.toStringAsFixed(1)} hours · ${request.requestedStartAt?.toLocal().toString() ?? request.submittedAt.toLocal().toString()}',
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            OutlinedButton(
                              onPressed: () => _decide(request, false),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                              ),
                              child: const Text('Reject'),
                            ),
                            const SizedBox(width: 8),
                            FilledButton(
                              onPressed: () => _decide(request, true),
                              child: const Text('Approve'),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
