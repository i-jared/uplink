import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:uplink/models/model_api.dart';

class ApiService {
  Future<Stream<String>> streamResponse(ModelApi api, String transcription) async {
    try {
      final response = await http.post(
        Uri.parse(api.endpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${api.apiKey}',
        },
        body: jsonEncode({
          'prompt': transcription,
          'stream': true,
        }),
      );

      if (response.statusCode == 200) {
        return Stream.fromIterable(response.body.split('\n'))
            .where((line) => line.isNotEmpty)
            .map((line) {
          final jsonData = jsonDecode(line);
          return jsonData['choices'][0]['text'];
        });
      } else {
        throw Exception('Failed to send transcription to API: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error sending transcription to API: $e');
      throw Exception('Error sending transcription to API: $e');
    }
  }
}
