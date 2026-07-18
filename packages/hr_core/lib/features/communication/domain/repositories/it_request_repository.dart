import '../entities/it_request_entities.dart';

abstract class ItRequestRepository {
  Future<List<ItRequest>> getMyItRequests();
  Future<void> submitItRequest(ItRequestCategory category, String description);
}
