import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:uplink/models/chat_entry.dart';
import 'package:uplink/models/model_api.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiService {
  final String apiKey;

  ApiService({String? apiKey}) 
    : apiKey = apiKey ?? dotenv.env['API_KEY'] ?? '';

  final StreamController<String> _streamController =
      StreamController<String>.broadcast();

  Stream<String> get responseStream => _streamController.stream;

  Future<void> streamResponse(ModelApi api, List<ChatEntry> messages) async {
    try {
      final client = http.Client();
      final request = http.Request(
          'POST', Uri.parse('https://api.anthropic.com/v1/messages'));
      request.headers.addAll({
        'Content-Type': 'application/json',
        'anthropic-version': '2023-06-01',
        'x-api-key': apiKey,
      });
      request.body = jsonEncode({
        "model": "claude-3-5-sonnet-20240620",
        "temperature": 0.5,
        "system":
            "You are my very knowledgeable friend. You answer my questions succinctly in a friendly way. We occasionally banter as friends do. Most importantly, answer with short, concise responses. Do not hallucinate.",
        "messages": messages
            .map((m) => {
                  "role": m.type == ChatEntryType.transcription
                      ? "user"
                      : "assistant",
                  "content": m.content
                })
            .toList(),
        "max_tokens": 256,
        "stream": true
      });

      final streamedResponse = await client.send(request);

      if (streamedResponse.statusCode == 200) {
        streamedResponse.stream.transform(utf8.decoder).listen((chunk) {
          chunk.split('\n').forEach((line) {
            if (line.startsWith('data: ')) {
              try {
                final jsonData = jsonDecode(line.substring(6));
                if (jsonData['type'] == 'content_block_delta') {
                  debugPrint('Received chunk: ${jsonData['delta']['text']}');
                  _streamController.add(jsonData['delta']['text']);
                }
              } catch (e) {
                debugPrint('Error parsing JSON: $e');
              }
            }
          });
        }, onDone: () {
          _streamController.close();
          client.close();
        }, onError: (error) {
          _streamController.addError(error);
          _streamController.close();
          client.close();
        });
      } else {
        throw Exception(
            'Failed to send transcription to API: ${streamedResponse.statusCode}');
      }
    } catch (e) {
      debugPrint('Error sending transcription to API: $e');
      _streamController
          .addError(Exception('Error sending transcription to API: $e'));
      _streamController.close();
    }
  }

  void dispose() {
    _streamController.close();
  }
}
