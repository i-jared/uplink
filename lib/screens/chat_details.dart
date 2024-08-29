import 'package:flutter/material.dart';
import 'package:uplink/models/chat.dart';
import 'package:uplink/models/chat_entry.dart';

class ChatDetailsScreen extends StatelessWidget {
  final Chat chat;

  const ChatDetailsScreen({super.key, required this.chat});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(chat.modelApiId)),
      body: ListView.builder(
        itemCount: chat.entries.length,
        itemBuilder: (context, index) {
          final entry = chat.entries[index];
          return ListTile(
            title: Text(entry.type == ChatEntryType.transcription ? 'User' : 'AI'),
            subtitle: Text(entry.content),
          );
        },
      ),
    );
  }
}