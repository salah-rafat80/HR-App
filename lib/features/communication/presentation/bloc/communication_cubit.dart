import 'package:hr_app_demo/core/utils/safe_cubit.dart';
import 'communication_state.dart';
import '../../domain/entities/communication_entities.dart';
import '../../domain/entities/it_request_entities.dart';
import '../../domain/repositories/communication_repository.dart';
import '../../domain/repositories/it_request_repository.dart';

class CommunicationCubit extends SafeCubit<CommunicationState> {
  final CommunicationRepository _commRepo;
  final ItRequestRepository _itRepo;

  CommunicationCubit(this._commRepo, this._itRepo) : super(CommunicationInitial());

  Future<void> loadData() async {
    if (!isClosed) { emit(CommunicationLoading()); }
    try {
      final results = await Future.wait([
        _commRepo.getAnnouncements(),
        _commRepo.getChatMessages(),
        _commRepo.getPolls(),
        _commRepo.getHandbookSections(),
        _itRepo.getMyItRequests(),
      ]);

      if (!isClosed) { emit(CommunicationLoaded(
        announcements: results[0] as List<Announcement>,
        chatMessages: results[1] as List<ChatMessage>,
        polls: results[2] as List<Poll>,
        handbook: results[3] as List<HandbookSection>,
        itRequests: results[4] as List<ItRequest>,
      )); }
    } catch (e) {
      if (!isClosed) { emit(CommunicationError(e.toString())); }
    }
  }

  Future<void> sendChatMessage(String text) async {
    if (state is! CommunicationLoaded) return;
    final currentState = state as CommunicationLoaded;
    
    if (!isClosed) { emit(currentState.copyWith(isSendingMessage: true)); }
    try {
      await _commRepo.sendChatMessage(text);
      final messages = await _commRepo.getChatMessages();
      if (!isClosed) { emit(currentState.copyWith(isSendingMessage: false, chatMessages: messages)); }
      
      // The FakeDataSource simulates an auto-reply asynchronously.
      // We will refresh messages again after a delay to pick it up.
      Future.delayed(const Duration(seconds: 3), () async {
        if (state is CommunicationLoaded) {
          final newMsgs = await _commRepo.getChatMessages();
          if (!isClosed) { emit((state as CommunicationLoaded).copyWith(chatMessages: newMsgs)); }
        }
      });
    } catch (e) {
      if (!isClosed) { emit(currentState.copyWith(isSendingMessage: false)); }
    }
  }

  Future<void> voteInPoll(String pollId, String optionId) async {
    if (state is! CommunicationLoaded) return;
    final currentState = state as CommunicationLoaded;
    if (!isClosed) { emit(currentState.copyWith(isVoting: true)); }
    try {
      await _commRepo.voteInPoll(pollId, optionId);
      final polls = await _commRepo.getPolls();
      if (!isClosed) { emit(currentState.copyWith(isVoting: false, polls: polls)); }
    } catch (e) {
      if (!isClosed) { emit(currentState.copyWith(isVoting: false)); }
    }
  }

  Future<void> submitItRequest(ItRequestCategory category, String description) async {
    if (state is! CommunicationLoaded) return;
    final currentState = state as CommunicationLoaded;
    if (!isClosed) { emit(currentState.copyWith(isSubmittingItRequest: true)); }
    try {
      await _itRepo.submitItRequest(category, description);
      final requests = await _itRepo.getMyItRequests();
      if (!isClosed) { emit(currentState.copyWith(isSubmittingItRequest: false, itRequests: requests)); }
    } catch (e) {
      if (!isClosed) { emit(currentState.copyWith(isSubmittingItRequest: false)); }
    }
  }
}
