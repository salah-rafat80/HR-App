import 'package:hr_app_demo/core/utils/safe_cubit.dart';
import 'communication_state.dart';
import 'package:hr_core/features/communication/domain/entities/communication_entities.dart';
import 'package:hr_core/features/communication/domain/entities/it_request_entities.dart';
import 'package:hr_core/features/communication/domain/repositories/announcement_repository.dart';
import 'package:hr_core/features/communication/domain/repositories/communication_repository.dart';
import 'package:hr_core/features/communication/domain/repositories/it_request_repository.dart';

import '../../../../core/di/injection.dart';

class CommunicationCubit extends SafeCubit<CommunicationState> {
  final CommunicationRepository _repository;
  final AnnouncementRepository _announcementRepository;
  final ItRequestRepository _itRepo;

  CommunicationCubit(this._repository, this._announcementRepository, this._itRepo) : super(CommunicationInitial());

  Future<void> loadData() async {
    if (!isClosed) { emit(CommunicationLoading()); }
    try {
      final results = await Future.wait([
        _repository.getChatMessages(),
        _repository.getPolls(),
        _repository.getHandbookSections(),
        _itRepo.getMyItRequests(),
      ]);

      if (!isClosed) { emit(CommunicationLoaded(
        announcements: const [],
        isLoadingAnnouncements: true,
        chatMessages: results[0] as List<ChatMessage>,
        polls: results[1] as List<Poll>,
        handbook: results[2] as List<HandbookSection>,
        itRequests: results[3] as List<ItRequest>,
      )); }

      await loadAnnouncements();
    } catch (e) {
      if (!isClosed) { emit(CommunicationError(e.toString())); }
    }
  }

  Future<void> loadAnnouncements() async {
    if (state is! CommunicationLoaded) return;
    final currentState = state as CommunicationLoaded;
    emit(currentState.copyWith(isLoadingAnnouncements: true, announcementsError: null));
    try {
      final announcements = await _announcementRepository.getAnnouncements();
      if (!isClosed) {
        emit((state as CommunicationLoaded).copyWith(
          isLoadingAnnouncements: false,
          announcements: announcements,
          announcementsError: null,
        ));
      }
    } catch (e) {
      if (!isClosed) {
        emit((state as CommunicationLoaded).copyWith(
          isLoadingAnnouncements: false,
          announcementsError: 'error_communication_failed',
        ));
      }
    }
  }

  Future<void> createAnnouncement(String title, String body) async {
    try {
      final newAnnouncement = await _announcementRepository.createAnnouncement(title, body);
      if (state is CommunicationLoaded && !isClosed) {
        final currentState = state as CommunicationLoaded;
        emit(currentState.copyWith(
          announcements: [newAnnouncement, ...currentState.announcements],
        ));
      }

      try {
        await loadAnnouncements(); // refresh to ensure consistency
      } catch (_) {}
    } catch (e) {
      rethrow;
    }
  }

  Future<void> sendChatMessage(String text) async {
    if (state is! CommunicationLoaded) return;
    final currentState = state as CommunicationLoaded;

    if (!isClosed) { emit(currentState.copyWith(isSendingMessage: true)); }
    try {
      await _repository.sendChatMessage(text);
      final messages = await _repository.getChatMessages();
      if (!isClosed) { emit(currentState.copyWith(isSendingMessage: false, chatMessages: messages)); }

      // The FakeDataSource simulates an auto-reply asynchronously.
      // We will refresh messages again after a delay to pick it up.
      Future.delayed(const Duration(seconds: 3), () async {
        if (state is CommunicationLoaded) {
          final newMsgs = await _repository.getChatMessages();
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
      await _repository.voteInPoll(pollId, optionId);
      final polls = await _repository.getPolls();
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
