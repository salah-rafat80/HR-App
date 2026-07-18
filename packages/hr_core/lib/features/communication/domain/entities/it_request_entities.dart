enum ItRequestCategory { hardware, software, access, other }
enum ItRequestStatus { open, inProgress, resolved }

class ItRequest {
  final String id;
  final ItRequestCategory category;
  final String description;
  final ItRequestStatus status;
  final DateTime submittedDate;

  const ItRequest({
    required this.id,
    required this.category,
    required this.description,
    required this.status,
    required this.submittedDate,
  });
}
