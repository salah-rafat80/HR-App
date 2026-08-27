import '../../domain/entities/communication_entities.dart';
import '../../domain/repositories/communication_repository.dart';
import '../datasources/communication_datasource.dart';

class CommunicationRepositoryImpl implements CommunicationRepository {
  final CommunicationDataSource _dataSource;

  CommunicationRepositoryImpl(this._dataSource);

  @override
  Future<List<ChatMessage>> getChatMessages() => _dataSource.getChatMessages();

  @override
  Future<List<HandbookSection>> getHandbookSections() => _dataSource.getHandbookSections();

  @override
  Future<List<Poll>> getPolls() => _dataSource.getPolls();

  @override
  Future<void> sendChatMessage(String text) async {
    await _dataSource.sendChatMessage(text);
    // Simulate auto-reply asynchronously without awaiting it
    _dataSource.addAutoReply();
  }

  @override
  Future<void> voteInPoll(String pollId, String optionId) => _dataSource.voteInPoll(pollId, optionId);
}
