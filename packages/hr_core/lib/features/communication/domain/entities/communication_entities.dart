enum ChatSender { me, hr }

class Announcement {
  final String id;
  final String title;
  final String body;
  final DateTime date;
  final String? department;

  const Announcement({
    required this.id,
    required this.title,
    required this.body,
    required this.date,
    this.department,
  });
}

class ChatMessage {
  final ChatSender sender;
  final String text;
  final DateTime timestamp;

  const ChatMessage({
    required this.sender,
    required this.text,
    required this.timestamp,
  });
}

class PollOption {
  final String id;
  final String label;
  final int voteCount;

  const PollOption({
    required this.id,
    required this.label,
    required this.voteCount,
  });
}

class Poll {
  final String id;
  final String question;
  final List<PollOption> options;
  final bool hasVoted;
  final String? selectedOptionId;

  const Poll({
    required this.id,
    required this.question,
    required this.options,
    this.hasVoted = false,
    this.selectedOptionId,
  });

  Poll copyWith({
    List<PollOption>? options,
    bool? hasVoted,
    String? selectedOptionId,
  }) {
    return Poll(
      id: id,
      question: question,
      options: options ?? this.options,
      hasVoted: hasVoted ?? this.hasVoted,
      selectedOptionId: selectedOptionId ?? this.selectedOptionId,
    );
  }
}

class HandbookSection {
  final String id;
  final String title;
  final String content;

  const HandbookSection({
    required this.id,
    required this.title,
    required this.content,
  });
}
