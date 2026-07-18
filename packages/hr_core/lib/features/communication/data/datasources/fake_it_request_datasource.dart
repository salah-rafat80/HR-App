import '../../domain/entities/it_request_entities.dart';

class FakeItRequestDataSource {
  final List<ItRequest> _requests = [
    ItRequest(
      id: 'REQ-1024',
      category: ItRequestCategory.hardware,
      description: 'Need a secondary monitor for development.',
      status: ItRequestStatus.resolved,
      submittedDate: DateTime.now().subtract(const Duration(days: 15)),
    ),
    ItRequest(
      id: 'REQ-1088',
      category: ItRequestCategory.access,
      description: 'Requesting access to the AWS production environment logs.',
      status: ItRequestStatus.inProgress,
      submittedDate: DateTime.now().subtract(const Duration(days: 2)),
    ),
  ];

  Future<List<ItRequest>> getMyItRequests() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return _requests;
  }

  Future<void> submitItRequest(ItRequestCategory category, String description) async {
    await Future.delayed(const Duration(milliseconds: 600));
    _requests.insert(0, ItRequest(
      id: 'REQ-${DateTime.now().millisecondsSinceEpoch.toString().substring(9)}',
      category: category,
      description: description,
      status: ItRequestStatus.open,
      submittedDate: DateTime.now(),
    ));
  }
}
