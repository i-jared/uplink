import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uplink/models/chat.dart';
import 'package:uplink/models/model_api.dart';
import 'package:uplink/services/audio_service.dart';
import 'package:uplink/models/chat_entry.dart';
import 'package:uuid/uuid.dart';

class CallBloc extends Bloc<CallEvent, CallState> {
  final audioService = AudioService();
  Chat currentChat;
  ModelApi modelApi;

  CallBloc({required this.modelApi, Chat? chat})
      : currentChat = chat ??
            Chat(
                id: const Uuid().v4(),
                entries: [],
                timestamp: DateTime.now().millisecondsSinceEpoch,
                modelApiId: modelApi.id),
        super(CallState()) {
    on<InitializeEvent>(_onInitialize);
    on<StartRecordingEvent>(_onStartRecording);
    on<StopRecordingEvent>(_onStopRecording);
    on<TogglePauseEvent>(_onTogglePause);
    on<ToggleSpeakerEvent>(_onToggleSpeaker);
    on<HangUpEvent>(_onHangUp);
    add(InitializeEvent());
  }

  void _onInitialize(InitializeEvent event, Emitter<CallState> emit) async {
    emit(state.copyWith(chatEntries: currentChat.entries));
  }

  void _onStartRecording(
      StartRecordingEvent event, Emitter<CallState> emit) async {
    await audioService.startTranscribing((String text) {
      emit(state.copyWith(chatEntries: [
        ...state.chatEntries,
        ChatEntry(
            type: ChatEntryType.transcription,
            content: text,
            chatId: '',
            timestamp: DateTime.now().millisecondsSinceEpoch)
      ]));
    });
    emit(state.copyWith(isRecording: true));
  }

  void _onStopRecording(
      StopRecordingEvent event, Emitter<CallState> emit) async {
    await audioService.stopTranscribing();
    emit(state.copyWith(isRecording: false));
  }

  void _onTogglePause(TogglePauseEvent event, Emitter<CallState> emit) {
    emit(state.copyWith(isPaused: !state.isPaused));
  }

  void _onToggleSpeaker(ToggleSpeakerEvent event, Emitter<CallState> emit) {
    emit(state.copyWith(isSpeakerOn: !state.isSpeakerOn));
  }

  void _onHangUp(HangUpEvent event, Emitter<CallState> emit) {
    // TODO: play a sound or something
    emit(EndCallState());
  }
}

// Events
abstract class CallEvent {}

class InitializeEvent extends CallEvent {}

class StartRecordingEvent extends CallEvent {}

class StopRecordingEvent extends CallEvent {}

class TogglePauseEvent extends CallEvent {}

class ToggleSpeakerEvent extends CallEvent {}

class HangUpEvent extends CallEvent {}

// State
class CallState extends Equatable {
  final bool isResponding;
  final bool isPaused;
  final bool isRecording;
  final bool isSpeakerOn;
  final List<ChatEntry> chatEntries;

  CallState({
    this.isResponding = false,
    this.isRecording = false,
    this.isPaused = false,
    this.isSpeakerOn = true,
    this.chatEntries = const [],
  });

  CallState copyWith({
    bool? isLoading,
    bool? isRecording,
    bool? isPaused,
    bool? isSpeakerOn,
    List<ChatEntry>? chatEntries,
  }) {
    return CallState(
      isResponding: isLoading ?? this.isResponding,
      isRecording: isRecording ?? this.isRecording,
      isPaused: isPaused ?? this.isPaused,
      isSpeakerOn: isSpeakerOn ?? this.isSpeakerOn,
      chatEntries: chatEntries ?? this.chatEntries,
    );
  }

  @override
  List<Object?> get props =>
      [isResponding, isRecording, isPaused, isSpeakerOn, chatEntries];
}

class EndCallState extends CallState {}
