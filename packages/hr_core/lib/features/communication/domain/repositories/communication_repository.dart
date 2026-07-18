import '../entities/communication_entities.dart';

abstract class CommunicationRepository {
  Future<List<Announcement>> getAnnouncements();
  Future<List<ChatMessage>> getChatMessages();
  Future<void> sendChatMessage(String text);
  Future<List<Poll>> getPolls();
  Future<void> voteInPoll(String pollId, String optionId);
  Future<List<HandbookSection>> getHandbookSections();
}
