import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:uplink/state/call_bloc.dart';

class AudioService {

  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  bool? _available;

  Future<void> startTranscribing(CallBloc callBloc) async {
    debugPrint('Starting to load, ${_speech.isAvailable}');
    callBloc.add(StartLoadingEvent());
    _available = await _speech.initialize(onStatus: (status) {
      debugPrint('status: $status');
      if (status == 'listening') {
        debugPrint('starting to listen. stop loading');
        callBloc.add(StartRecordingEvent());
        callBloc.add(StopLoadingEvent());
      } else if (status == 'done') {
        debugPrint('Done');
      }
      debugPrint('Speech recognition status: $status');
    }, onError: (errorNotification) {
      callBloc.add(ErrorEvent(error: errorNotification.errorMsg));
    });

    debugPrint('${_speech.isAvailable}, $_available');
    if (_available ?? false) {
      _isListening = true;

      // callBloc.add(StartRecordingEvent());
      await _speech.listen(
        onResult: (result) {
          debugPrint('Speech recognition result: $result');
          callBloc.add(AddTranscriptionEvent(
              transcription: result.recognizedWords,
              finalResult: result.finalResult));
          if (result.finalResult) {
            stopTranscribing(callBloc);
          }
        },
        listenFor: const Duration(seconds: 120),
        pauseFor: const Duration(seconds: 10),
        listenOptions: stt.SpeechListenOptions(
          autoPunctuation: true,
          partialResults: false,
          onDevice: true,
          listenMode: stt.ListenMode.dictation,
        ),
      );
    }
  }

  Future<void> stopTranscribing(CallBloc callBloc) async {
    if (_isListening) {
      await _speech.stop();
      _isListening = false;
    }
  }

  // Stream<String> generateResponse(ModelApi api, String transcription) async* {
  //   try {
  //     final apiService = ApiService();
  //     final stream = await apiService.streamResponse(api, transcription);
  //     await for (final chunk in stream) {
  //       if (chunk.isNotEmpty) {
  //         yield chunk;
  //       }
  //     }
  //   } catch (e) {
  //     debugPrint('Error generating response: $e');
  //     yield 'Error: Failed to generate response. Please try again.';
  //   }
  // }

  bool get isListening => _isListening;
}
