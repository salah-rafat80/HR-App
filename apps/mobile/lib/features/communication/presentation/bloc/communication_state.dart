import 'package:equatable/equatable.dart';
import 'package:hr_core/features/communication/domain/entities/communication_entities.dart';
import 'package:hr_core/features/communication/domain/entities/it_request_entities.dart';

sealed class CommunicationState extends Equatable {
  const CommunicationState();
  @override
  List<Object?> get props => [];
}

class CommunicationInitial extends CommunicationState {}
class CommunicationLoading extends CommunicationState {}

class CommunicationLoaded extends CommunicationState {
  final List<Announcement> announcements;
  final List<ChatMessage> chatMessages;
  final List<Poll> polls;
  final List<HandbookSection> handbook;
  final List<ItRequest> itRequests;
  final bool isSendingMessage;
  final bool isVoting;
  final bool isSubmittingItRequest;

  const CommunicationLoaded({
    required this.announcements,
    required this.chatMessages,
    required this.polls,
    required this.handbook,
    required this.itRequests,
    this.isSendingMessage = false,
    this.isVoting = false,
    this.isSubmittingItRequest = false,
  });

  CommunicationLoaded copyWith({
    List<Announcement>? announcements,
    List<ChatMessage>? chatMessages,
    List<Poll>? polls,
    List<HandbookSection>? handbook,
    List<ItRequest>? itRequests,
    bool? isSendingMessage,
    bool? isVoting,
    bool? isSubmittingItRequest,
  }) {
    return CommunicationLoaded(
      announcements: announcements ?? this.announcements,
      chatMessages: chatMessages ?? this.chatMessages,
      polls: polls ?? this.polls,
      handbook: handbook ?? this.handbook,
      itRequests: itRequests ?? this.itRequests,
      isSendingMessage: isSendingMessage ?? this.isSendingMessage,
      isVoting: isVoting ?? this.isVoting,
      isSubmittingItRequest: isSubmittingItRequest ?? this.isSubmittingItRequest,
    );
  }

  @override
  List<Object?> get props => [
        announcements,
        chatMessages,
        polls,
        handbook,
        itRequests,
        isSendingMessage,
        isVoting,
        isSubmittingItRequest,
      ];
}

class CommunicationError extends CommunicationState {
  final String message;
  const CommunicationError(this.message);
  @override
  List<Object?> get props => [message];
}
