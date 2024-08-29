import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uplink/state/chat_bloc.dart';
import 'package:uplink/models/chat.dart';
import 'package:uplink/screens/chat_details.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chat History')),
      body: BlocBuilder<ChatBloc, ChatState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          return ListView.builder(
            itemCount: state.chats.length,
            itemBuilder: (context, index) {
              final chat = state.chats[index];
              return ListTile(
                title: Text(chat.modelApiId),
                subtitle: Text(_getFirstMessage(chat)),
                trailing: Text(_formatDate(chat)),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatDetailsScreen(chat: chat),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  String _getFirstMessage(Chat chat) {
    if (chat.entries.isNotEmpty) {
      return chat.entries.first.content.length > 50
          ? '${chat.entries.first.content.substring(0, 50)}...'
          : chat.entries.first.content;
    }
    return 'No messages';
  }

  String _formatDate(Chat chat) {
    if (chat.entries.isNotEmpty) {
      final date = DateTime.fromMillisecondsSinceEpoch(chat.entries.first.timestamp);
      return '${date.day}/${date.month}/${date.year}';
    }
    return 'N/A';
  }
}