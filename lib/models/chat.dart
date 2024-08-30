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
      entries: map['entries'].map<ChatEntry>((entry) => ChatEntry.fromMap(entry)).toList(),
      id: map['chatId'],
      modelApiId: map['modelApiId'],
      timestamp: map['timestamp'],
    );
  }

  Chat copyWith({List<ChatEntry>? entries, String? id, String? modelApiId, int? timestamp}) {
    return Chat(
      entries: entries ?? this.entries,
      id: id ?? this.id,
      modelApiId: modelApiId ?? this.modelApiId,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
