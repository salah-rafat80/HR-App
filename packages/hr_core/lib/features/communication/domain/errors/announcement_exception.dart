class AnnouncementException implements Exception {
  final String code;
  final String messageKey;

  const AnnouncementException(this.code, this.messageKey);

  @override
  String toString() => 'AnnouncementException($code): $messageKey';
}
