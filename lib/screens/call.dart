import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
      return '';
    } else if (value < 0.5) {
      return '.';
    } else if (value < 0.75) {
      return '..';
    } else {
      return '...';
    }
  }

  Future<void> _handleRecording() async {
    final chatBloc = context.read<CallBloc>();
    final chatState = chatBloc.state;
    if (!chatState.isRecording) {
      chatBloc.add(InitiateRecordingEvent());
      _scrollToBottom();
    } else {
      chatBloc.add(StopRecordingEvent());
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
    final chatEntries = callState.chatEntries;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.callerName),
        centerTitle: true,
      ),
      body: Column(
        children: [
          BlocListener<CallBloc, CallState>(
            listener: (context, state) {
              if (state is ErrorState) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(state.error)),
                );
              } else if (state is EndCallState) {
                Navigator.of(context).pop();
              } else if (state is ResponseState) {
                _scrollToBottom();
              }
            },
            child: const SizedBox.shrink(),
          ),
          Expanded(
            flex: 7,
            child: ListView.builder(
              padding: const EdgeInsets.only(
                  bottom: 100, top: 16, left: 16, right: 16),
              controller: _scrollController,
              itemCount: chatEntries.length,
              itemBuilder: (context, index) {
                final entry = chatEntries[index];
                final label = entry.type == ChatEntryType.transcription
                    ? "You: "
                    : "AI: ";
                final trailing =
                    (callState.isRecording || callState.isResponding) &&
                            index == chatEntries.length - 1
                        ? getLoadingText()
                        : '';
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    '$label${entry.content}$trailing',
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
                    onPressed: () => callBloc.add(StartLoadingEvent()),
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
        onPressed: callState.isLoading || callState.isResponding
            ? null
            : _handleRecording,
        child: callState.isLoading
            ? const CircularProgressIndicator()
            : Icon(
                callState.isRecording ? Icons.stop : Icons.fiber_manual_record),
      ),
    );
  }
}
