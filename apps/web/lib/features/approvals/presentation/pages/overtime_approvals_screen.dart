import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hr_core/core/enums/role_enums.dart';
import '../bloc/overtime_approvals_cubit.dart';

class OvertimeApprovalsScreen extends StatefulWidget {
  final UserRole userRole;

  const OvertimeApprovalsScreen({super.key, required this.userRole});

  @override
  State<OvertimeApprovalsScreen> createState() => _OvertimeApprovalsScreenState();
}

class _OvertimeApprovalsScreenState extends State<OvertimeApprovalsScreen> {
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    context.read<OvertimeApprovalsCubit>().loadPendingRequests();
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  TextEditingController _getController(String id) {
    return _controllers.putIfAbsent(id, () => TextEditingController());
  }

  bool get _isHr =>
      widget.userRole == UserRole.hrAdmin ||
      widget.userRole == UserRole.superAdmin;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Overtime Request Approvals'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<OvertimeApprovalsCubit>().loadPendingRequests(),
          ),
        ],
      ),
      body: BlocConsumer<OvertimeApprovalsCubit, OvertimeApprovalsState>(
        listener: (context, state) {
          if (state is OvertimeApprovalsActionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.green),
            );
          } else if (state is OvertimeApprovalsError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.red),
            );
          }
        },
        builder: (context, state) {
          if (state is OvertimeApprovalsLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is OvertimeApprovalsLoaded) {
            final requests = state.requests;

            if (requests.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.assignment_turned_in_outlined, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'No pending overtime requests',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: requests.length,
              itemBuilder: (context, index) {
                final req = requests[index];
                final controller = _getController(req.id);

                final hours = req.requestedHours;

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              req.employeeName ?? req.userId,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                req.status.name.toUpperCase(),
                                style: TextStyle(
                                  color: Colors.orange.shade900,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Department: ${req.department ?? "N/A"} | Code: ${req.employeeCode ?? req.userId}',
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(Icons.access_time, size: 16, color: Colors.blue),
                            const SizedBox(width: 6),
                            Text(
                              'Requested Range: ${req.requestedStartAt?.toIso8601String().substring(0, 16) ?? "N/A"} to ${req.requestedEndAt?.toIso8601String().substring(0, 16) ?? "N/A"} (${hours.toStringAsFixed(1)} hrs)',
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Reason: ${req.reason}',
                          style: const TextStyle(fontStyle: FontStyle.italic),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: controller,
                          decoration: const InputDecoration(
                            labelText: 'Decision Comment (optional)',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton.icon(
                              icon: const Icon(Icons.close, color: Colors.red),
                              label: const Text('Reject', style: TextStyle(color: Colors.red)),
                              onPressed: () {
                                context.read<OvertimeApprovalsCubit>().rejectRequest(
                                      requestId: req.id,
                                      isHr: _isHr,
                                      comment: controller.text.trim(),
                                    );
                              },
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.check),
                              label: const Text('Approve'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () {
                                context.read<OvertimeApprovalsCubit>().approveRequest(
                                      requestId: req.id,
                                      isHr: _isHr,
                                      comment: controller.text.trim(),
                                    );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}
