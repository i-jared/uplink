import 'package:uplink/models/chat_entry.dart';

class Chat {
  final List<ChatEntry> entries;
  final String id;
  final String modelApiId;
  final int timestamp;

  Chat({required this.entries, required this.id, required this.modelApiId, required this.timestamp});

  Map<String, dynamic> toMap() {
    return {
      'entries': entries.map((entry) => entry.toMap()).toList(),
      'chatId': id,
      'modelApiId': modelApiId,
      'timestamp': timestamp,
    };
  }

  factory Chat.fromMap(Map<String, dynamic> map) {
    return Chat(
      entries: map['entries'].map((entry) => ChatEntry.fromMap(entry)).toList(),
      id: map['chatId'],
      modelApiId: map['modelApiId'],
      timestamp: map['timestamp'],
    );
  }
}
