import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class TranscriptionService {
  final String apiKey;
  final Dio _dio = Dio();

  TranscriptionService(this.apiKey);

  Future<String?> transcribe(String audioUrl) async {
    if (apiKey.isEmpty) {
      return "Ошибка: Не настроен API ключ Deepgram";
    }

    try {
      debugPrint(
        'TranscriptionService (Deepgram): Sending request for $audioUrl',
      );

      final response = await _dio.post(
        'https://api.deepgram.com/v1/listen',
        data: {'url': audioUrl},
        queryParameters: {
          'model': 'nova-2',
          'language': 'ru',
          'smart_format': 'true',
          'diarize': 'false',
        },
        options: Options(
          headers: {
            'Authorization': 'Token $apiKey',
            'Content-Type': 'application/json',
          },
          sendTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

      if (response.statusCode == 200) {
        final results = response.data['results'];
        if (results == null) throw Exception("Deepgram returned empty results");

        final channels = results['channels'] as List?;
        if (channels == null || channels.isEmpty) {
          throw Exception("No channels in Deepgram response");
        }

        final alternatives = channels[0]['alternatives'] as List?;
        if (alternatives == null || alternatives.isEmpty) {
          throw Exception("No alternatives in Deepgram response");
        }

        final transcript = alternatives[0]['transcript'] as String?;
        debugPrint('TranscriptionService: Success! Text: $transcript');
        return transcript;
      } else {
        throw Exception(
          "Deepgram API error: ${response.statusCode} ${response.data}",
        );
      }
    } catch (e) {
      debugPrint('TranscriptionService error: $e');
      if (e is DioException) {
        final errorMsg = e.response?.data?['err_msg'] ?? e.message;
        return "Ошибка Deepgram: $errorMsg";
      }
      return "Ошибка при расшифровке: $e";
    }
  }
}
