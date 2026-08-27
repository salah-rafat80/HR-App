import '../../domain/entities/communication_entities.dart';

abstract class CommunicationDataSource {
  Future<List<ChatMessage>> getChatMessages();
  Future<void> sendChatMessage(String text);
  Future<void> addAutoReply();
  Future<List<HandbookSection>> getHandbookSections();
  Future<List<Poll>> getPolls();
  Future<void> voteInPoll(String pollId, String optionId);
}
