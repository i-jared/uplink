enum ChatEntryType { transcription, response }

class ChatEntry {
  final ChatEntryType type;
  final String chatId;
  String content;
  final int timestamp;

  ChatEntry({required this.type, required this.chatId, required this.content, required this.timestamp});

  Map<String, dynamic> toMap() {
    return {
      'type': type.toString(),
      'chatId': chatId,
      'content': content,
      'timestamp': timestamp,
    };
  }
  
  
  factory ChatEntry.fromMap(Map<String, dynamic> map) {
    return ChatEntry(
      type: ChatEntryType.values.byName(map['type']),
      chatId: map['chatId'],
      content: map['content'],
      timestamp: map['timestamp'],
    );
  }
}
