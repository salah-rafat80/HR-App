import '../../domain/entities/communication_entities.dart';

class FakeCommunicationDataSource {
  final List<Announcement> _announcements = [
    Announcement(id: 'a1', title: 'Q3 Townhall Meeting', body: 'Join us for the upcoming Q3 Townhall where the CEO will share our progress and vision.', date: DateTime.now().subtract(const Duration(days: 1))),
    Announcement(id: 'a2', title: 'New Leave Policy', body: 'Please review the updated leave policy handbook for 2026.', date: DateTime.now().subtract(const Duration(days: 3))),
    Announcement(id: 'a3', title: 'Engineering All-Hands', body: 'Engineering team, don\'t forget our all-hands meeting this Friday.', date: DateTime.now().subtract(const Duration(days: 4)), department: 'Engineering'),
    Announcement(id: 'a4', title: 'Office Renovation Updates', body: 'The 3rd-floor renovation is complete. Feel free to use the new collaboration spaces.', date: DateTime.now().subtract(const Duration(days: 10))),
  ];

  final List<ChatMessage> _messages = [
    ChatMessage(sender: ChatSender.hr, text: 'Hello! How can we assist you today?', timestamp: DateTime.now().subtract(const Duration(hours: 24))),
    ChatMessage(sender: ChatSender.me, text: 'I have a question about my health insurance coverage.', timestamp: DateTime.now().subtract(const Duration(hours: 23))),
    ChatMessage(sender: ChatSender.hr, text: 'Sure! Please provide your employee ID and I will check your policy.', timestamp: DateTime.now().subtract(const Duration(hours: 22))),
  ];

  final List<Poll> _polls = [
    const Poll(
      id: 'p1',
      question: 'What should be the theme for the next team building event?',
      options: [
        PollOption(id: 'o1', label: 'Beach Retreat', voteCount: 45),
        PollOption(id: 'o2', label: 'Escape Room', voteCount: 22),
        PollOption(id: 'o3', label: 'Cooking Class', voteCount: 15),
      ],
    ),
    const Poll(
      id: 'p2',
      question: 'How do you prefer to receive company updates?',
      hasVoted: true,
      selectedOptionId: 'o2',
      options: [
        PollOption(id: 'o1', label: 'Email', voteCount: 120),
        PollOption(id: 'o2', label: 'App Notifications', voteCount: 85),
      ],
    ),
  ];

  final List<HandbookSection> _handbook = [
    const HandbookSection(id: 'h1', title: 'Leave Policy', content: 'Employees are entitled to 21 days of annual leave. Sick leave requires a medical certificate if it exceeds 2 consecutive days.'),
    const HandbookSection(id: 'h2', title: 'Code of Conduct', content: 'We foster a culture of respect, inclusion, and integrity. Harassment of any kind is strictly prohibited.'),
    const HandbookSection(id: 'h3', title: 'Remote Work Guidelines', content: 'Eligible employees may work remotely up to 2 days a week. Core hours are 10 AM to 3 PM.'),
    const HandbookSection(id: 'h4', title: 'Benefits Overview', content: 'We offer comprehensive health insurance, retirement matching, and a yearly wellness stipend.'),
  ];

  Future<List<Announcement>> getAnnouncements() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _announcements;
  }

  Future<List<ChatMessage>> getChatMessages() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _messages;
  }

  Future<void> sendChatMessage(String text) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _messages.add(ChatMessage(sender: ChatSender.me, text: text, timestamp: DateTime.now()));
  }

  Future<void> addAutoReply() async {
    await Future.delayed(const Duration(seconds: 2));
    _messages.add(ChatMessage(sender: ChatSender.hr, text: 'Thanks, HR will follow up on this shortly.', timestamp: DateTime.now()));
  }

  Future<List<Poll>> getPolls() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return _polls;
  }

  Future<void> voteInPoll(String pollId, String optionId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _polls.indexWhere((p) => p.id == pollId);
    if (index != -1 && !_polls[index].hasVoted) {
      final oldPoll = _polls[index];
      final newOptions = oldPoll.options.map((o) {
        if (o.id == optionId) return PollOption(id: o.id, label: o.label, voteCount: o.voteCount + 1);
        return o;
      }).toList();
      _polls[index] = oldPoll.copyWith(options: newOptions, hasVoted: true, selectedOptionId: optionId);
    }
  }

  Future<List<HandbookSection>> getHandbookSections() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _handbook;
  }
}
