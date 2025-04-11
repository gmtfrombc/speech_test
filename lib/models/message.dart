class Message {
  String content;
  final bool isUser;
  final DateTime timestamp;
  final bool isPartial;

  Message({
    required this.content,
    required this.isUser,
    DateTime? timestamp,
    this.isPartial = false,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {'role': isUser ? 'user' : 'assistant', 'content': content};
  }
}
