import 'package:equatable/equatable.dart';

enum ChatEntryType { transcription, response }

class ChatEntry extends Equatable {
  final ChatEntryType type;
  final String chatId;
  final String content;
  final int timestamp;

  const ChatEntry({required this.type, required this.chatId, required this.content, required this.timestamp});

  Map<String, dynamic> toMap() {
    return {
      'type': type.name,
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

  ChatEntry copyWith({String? content}) {
    return ChatEntry(
      type: type,
      chatId: chatId,
      content: content ?? this.content,
      timestamp: timestamp,
    );
  }

  @override
  List<Object?> get props => [type, chatId, content, timestamp];
}
