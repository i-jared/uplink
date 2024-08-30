import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:uplink/models/chat.dart';
import 'package:uplink/models/model_api.dart';
import 'package:uplink/services/api_service.dart';
import 'package:uplink/services/audio_service.dart';
import 'package:uplink/models/chat_entry.dart';
import 'package:uplink/services/db_service.dart';
import 'package:uuid/uuid.dart';

class CallBloc extends Bloc<CallEvent, CallState> {
  final audioService = AudioService();
  Chat currentChat;
  ModelApi modelApi;
  FlutterTts flutterTts = FlutterTts();

  CallBloc({required this.modelApi, Chat? chat})
      : currentChat = chat ??
            Chat(
                id: const Uuid().v4(),
                entries: [],
                timestamp: DateTime.now().millisecondsSinceEpoch,
                modelApiId: modelApi.id),
        super(const CallState()) {
    on<InitializeEvent>(_onInitialize);
    on<InitiateRecordingEvent>(_onInitiateRecording);
    on<StartRecordingEvent>(_onStartRecording);
    on<StopRecordingEvent>(_onStopRecording);
    on<StartLoadingEvent>(_onStartLoading);
    on<StopLoadingEvent>(_onStopLoading);
    on<TogglePauseEvent>(_onTogglePause);
    on<ToggleSpeakerEvent>(_onToggleSpeaker);
    on<AddTranscriptionEvent>(_onAddTranscription);
    on<HangUpEvent>(_onHangUp);
    on<ErrorEvent>(_onError);
    on<AddResponseEvent>(_onAddResponse);
    on<DoneRespondingEvent>(_onDoneResponding);
    if (chat == null) {
      DbService.addChat(currentChat);
    }

    add(InitializeEvent());
  }

  void _onInitialize(InitializeEvent event, Emitter<CallState> emit) async {
    emit(state.copyWith(chatEntries: currentChat.entries));

    // (await flutterTts.getVoices).forEach((element) {
      // debugPrint(element?.toString());
    // });
    await flutterTts.setVoice({'name': 'Fred', 'locale': 'en-US'});
    await flutterTts.setSpeechRate(0.5);
  }

  void _onError(ErrorEvent event, Emitter<CallState> emit) {
    emit(ErrorState.fromState(state, event.error));
  }

  void _onInitiateRecording(
      InitiateRecordingEvent event, Emitter<CallState> emit) async {
    debugPrint('onInitiateRecording');
    await audioService.startTranscribing(this);
  }

  void _onStartRecording(
      StartRecordingEvent event, Emitter<CallState> emit) async {
    debugPrint('onStartRecording');
    var newEntry = ChatEntry(
        type: ChatEntryType.transcription,
        content: '',
        chatId: currentChat.id,
        timestamp: DateTime.now().millisecondsSinceEpoch);
    emit(state.copyWith(
        isLoading: false,
        isRecording: true,
        chatEntries: [...state.chatEntries, newEntry]));
  }

  void _onStopRecording(
      StopRecordingEvent event, Emitter<CallState> emit) async {
    emit(state.copyWith(isLoading: true));
    await audioService.stopTranscribing(this);
  }

  void _onStartLoading(StartLoadingEvent event, Emitter<CallState> emit) {
    emit(state.copyWith(isLoading: true));
  }

  void _onStopLoading(StopLoadingEvent event, Emitter<CallState> emit) {
    emit(state.copyWith(isLoading: false));
  }

  void _onTogglePause(TogglePauseEvent event, Emitter<CallState> emit) {
    emit(state.copyWith(isPaused: !state.isPaused));
  }

  void _onToggleSpeaker(ToggleSpeakerEvent event, Emitter<CallState> emit) {
    emit(state.copyWith(isSpeakerOn: !state.isSpeakerOn));
  }

  void _onHangUp(HangUpEvent event, Emitter<CallState> emit) {
    emit(EndCallState());
  }

  void _onAddResponse(AddResponseEvent event, Emitter<CallState> emit) {
    var lastEntry = state.chatEntries.last;
    ChatEntry newEntry =
        lastEntry.copyWith(content: '${lastEntry.content}${event.response}');
    var updatedEntries = List<ChatEntry>.from(state.chatEntries);
    updatedEntries[updatedEntries.length - 1] = newEntry;
    emit(ResponseState.fromState(state.copyWith(chatEntries: updatedEntries)));
  }

  void _onDoneResponding(DoneRespondingEvent event, Emitter<CallState> emit) {
    emit(state.copyWith(isResponding: false, isLoading: false));
    _saveChat();
    flutterTts.speak(state.chatEntries.last.content);
  }

  void _onAddTranscription(
      AddTranscriptionEvent event, Emitter<CallState> emit) {
    var lastEntry = state.chatEntries.last;
    ChatEntry newEntry;
    if (lastEntry.content.split(' ').length >
        event.transcription.split(' ').length) {
      newEntry = lastEntry.copyWith(
          content: '${lastEntry.content} ${event.transcription}');
    } else {
      newEntry = lastEntry.copyWith(content: event.transcription);
    }
    var updatedEntries = List<ChatEntry>.from(state.chatEntries);
    updatedEntries[updatedEntries.length - 1] = newEntry;
    emit(ResponseState.fromState(state.copyWith(chatEntries: updatedEntries)));

    if (event.finalResult) {
      var respondEntry = ChatEntry(
          type: ChatEntryType.response,
          content: '',
          chatId: currentChat.id,
          timestamp: DateTime.now().millisecondsSinceEpoch);

      emit(ResponseState.fromState(state.copyWith(
          isRecording: false,
          isLoading: false,
          isResponding: true,
          chatEntries: [...state.chatEntries, respondEntry])));
      listenToResponse();
    }
    _saveChat();
  }

  Future<void> listenToResponse() async {
    final apiService = ApiService();
    apiService.responseStream.listen(
        (response) => add(AddResponseEvent(response: response)),
        onDone: () => add(DoneRespondingEvent()),
        onError: (error) => add(ErrorEvent(error: error.toString())));
    apiService.streamResponse(modelApi, state.chatEntries);
  }

  Future<void> _saveChat() async {
    await DbService.updateChat(
        currentChat.copyWith(entries: state.chatEntries));
  }
}

// Events
abstract class CallEvent {}

class InitializeEvent extends CallEvent {}

class InitiateRecordingEvent extends CallEvent {}

class StartRecordingEvent extends CallEvent {}

class StopRecordingEvent extends CallEvent {}

class StartLoadingEvent extends CallEvent {}

class StopLoadingEvent extends CallEvent {}

class ToggleSpeakerEvent extends CallEvent {}

class TogglePauseEvent extends CallEvent {}

class HangUpEvent extends CallEvent {}

class DoneRespondingEvent extends CallEvent {}

class ErrorEvent extends CallEvent {
  final String error;

  ErrorEvent({required this.error});
}

class AddTranscriptionEvent extends CallEvent {
  final String transcription;
  final bool finalResult;

  AddTranscriptionEvent(
      {required this.transcription, required this.finalResult});
}

class AddResponseEvent extends CallEvent {
  final String response;

  AddResponseEvent({required this.response});
}

// State
class CallState extends Equatable {
  final bool isResponding;
  final bool isPaused;
  final bool isLoading;
  final bool isRecording;
  final bool isSpeakerOn;
  final List<ChatEntry> chatEntries;

  const CallState({
    this.isResponding = false,
    this.isRecording = false,
    this.isLoading = false,
    this.isPaused = false,
    this.isSpeakerOn = true,
    this.chatEntries = const [],
  });

  CallState copyWith({
    bool? isResponding,
    bool? isLoading,
    bool? isRecording,
    bool? isPaused,
    bool? isSpeakerOn,
    List<ChatEntry>? chatEntries,
  }) {
    return CallState(
      isResponding: isResponding ?? this.isResponding,
      isLoading: isLoading ?? this.isLoading,
      isRecording: isRecording ?? this.isRecording,
      isPaused: isPaused ?? this.isPaused,
      isSpeakerOn: isSpeakerOn ?? this.isSpeakerOn,
      chatEntries: chatEntries ?? this.chatEntries,
    );
  }

  @override
  List<Object?> get props => [
        isResponding,
        isRecording,
        isPaused,
        isSpeakerOn,
        chatEntries,
        isLoading
      ];
}

class ResponseState extends CallState {
  const ResponseState(
      {super.chatEntries,
      super.isLoading,
      super.isPaused,
      super.isRecording,
      super.isSpeakerOn,
      super.isResponding});

  factory ResponseState.fromState(CallState state) {
    return ResponseState(
        chatEntries: state.chatEntries,
        isLoading: state.isLoading,
        isPaused: state.isPaused,
        isRecording: state.isRecording,
        isSpeakerOn: state.isSpeakerOn,
        isResponding: state.isResponding);
  }
}

class ErrorState extends CallState {
  final String error;

  const ErrorState(
      {required this.error,
      super.chatEntries,
      super.isLoading,
      super.isPaused,
      super.isRecording,
      super.isSpeakerOn,
      super.isResponding});

  factory ErrorState.fromState(CallState state, String error) {
    return ErrorState(
        error: error,
        chatEntries: state.chatEntries,
        isLoading: state.isLoading,
        isPaused: state.isPaused,
        isRecording: state.isRecording,
        isSpeakerOn: state.isSpeakerOn,
        isResponding: state.isResponding);
  }

  @override
  List<Object?> get props => [error, ...super.props];
}

class EndCallState extends CallState {}
