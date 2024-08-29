import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:uplink/models/model_api.dart';
import 'package:uplink/services/api_service.dart';

class AudioService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;

  Future<void> startTranscribing(Function(String) onTranscriptionUpdate) async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (status) => debugPrint('Speech recognition status: $status'),
        onError: (errorNotification) =>
            debugPrint('Speech recognition error: $errorNotification'),
      );

      if (available) {
        _isListening = true;
        await _speech.listen(
          onResult: (result) {
            debugPrint('Speech recognition result: $result');
            onTranscriptionUpdate(result.recognizedWords);
            if (result.finalResult) {
              stopTranscribing();
            }
          },
          listenFor: const Duration(seconds: 120),
          pauseFor: const Duration(seconds: 3),
          listenOptions: stt.SpeechListenOptions(
            autoPunctuation: true,
            partialResults: true,
            onDevice: true,
            listenMode: stt.ListenMode.dictation,
          ),
        );
      } else {
        debugPrint('Speech recognition not available');
      }
    }
  }

  Future<void> stopTranscribing() async {
    if (_isListening) {
      await _speech.stop();
      _isListening = false;
    }
  }

  Stream<String> generateResponse(ModelApi api, String transcription) async* {
    try {
      final apiService = ApiService();
      final stream = await apiService.streamResponse(api, transcription);
      await for (final chunk in stream) {
        if (chunk.isNotEmpty) {
          yield chunk;
        }
      }
    } catch (e) {
      debugPrint('Error generating response: $e');
      yield 'Error: Failed to generate response. Please try again.';
    }
  }

  bool get isListening => _isListening;
}
