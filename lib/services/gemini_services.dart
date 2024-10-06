import 'dart:convert';
import 'package:http/http.dart' as http;
import 'context_manager.dart';

class GeminiService {
  final String apiKey;
  final String baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent';
  final ContextManager contextManager = ContextManager();

  GeminiService() : apiKey = 'AIzaSyB7rzPt_ROjdmEbLx7FFVnckNoXKZpTqxs';

  Future<String> getResponse(String prompt, {String section = ''}) async {
    final context = contextManager.getCurrentContext(section);
    final fullPrompt = '$context\n\nUser Query: $prompt';
    final response = await http.post(
      Uri.parse('$baseUrl?key=$apiKey'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'contents': [
          {
            'parts': [
              {'text': fullPrompt}
            ]
          }
        ]
      }),
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      return responseData['candidates'][0]['content']['parts'][0]['text'];
    } else {
      throw Exception('Failed to get response from Gemini API');
    }
  }
}
