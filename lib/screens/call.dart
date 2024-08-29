import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uplink/models/chat_entry.dart';
import 'package:uplink/state/call_bloc.dart';

class CallScreen extends StatefulWidget {
  final String callerName;

  const CallScreen({super.key, required this.callerName});

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen>
    with SingleTickerProviderStateMixin {
  List<ChatEntry> chatEntries = [];
  final ScrollController _scrollController = ScrollController();
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0, end: 1).animate(_controller);
    _controller.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String getLoadingText() {
    double value = _animation.value;
    if (value < 0.25) {
      return 'AI: ';
    } else if (value < 0.5) {
      return 'AI: .';
    } else if (value < 0.75) {
      return 'AI: ..';
    } else {
      return 'AI: ...';
    }
  }

  Future<void> _handleRecording() async {
    final chatBloc = context.read<CallBloc>();
    final chatState = chatBloc.state;
    if (!chatState.isRecording) {
      chatBloc.add(StartRecordingEvent());
      _scrollToBottom();
    } else {
      chatBloc.add(StartRecordingEvent());
    }
  }

  void _scrollToBottom() {
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final callBloc = context.watch<CallBloc>();
    final callState = callBloc.state;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.callerName),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            flex: 7,
            child: ListView.builder(
              controller: _scrollController,
              itemCount: chatEntries.length,
              itemBuilder: (context, index) {
                final entry = chatEntries[index];
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    '${entry.type == ChatEntryType.transcription ? "You: " : "AI: "}${entry.content}${callState.isRecording || callState.isResponding ? getLoadingText() : ''}',
                    style: TextStyle(
                      fontWeight: entry.type == ChatEntryType.transcription
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                );
              },
            ),
          ),
          Flexible(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: Icon(callState.isSpeakerOn
                        ? Icons.volume_up_rounded
                        : Icons.volume_off_rounded),
                    onPressed: () => callBloc.add(ToggleSpeakerEvent()),
                    iconSize: 48,
                    color: callState.isSpeakerOn ? null : Colors.grey,
                  ),
                  IconButton(
                    icon: Icon(callState.isPaused
                        ? Icons.play_arrow_rounded
                        : Icons.pause_rounded),
                    onPressed: () => callBloc.add(TogglePauseEvent()),
                    iconSize: 48,
                  ),
                  IconButton(
                    icon: const Icon(Icons.call_end_rounded),
                    color: Colors.red,
                    onPressed: () => callBloc.add(HangUpEvent()),
                    iconSize: 48,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.large(
        backgroundColor: callState.isRecording ? Colors.grey : Colors.red,
        onPressed: _handleRecording,
        child: Icon(callState.isRecording ? Icons.stop : Icons.fiber_manual_record),
      ),
    );
  }
}
