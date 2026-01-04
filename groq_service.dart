import 'dart:convert';
import 'package:http/http.dart' as http;

class GroqService {
  static late String _apiKey;

  static void init(String key) {
    _apiKey = key;
  }

  static Future<String> getAnswer(String prompt) async {
    final uri = Uri.parse(
      'https://api.groq.com/openai/v1/chat/completions',
    );

    final response = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer $_apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        "model": "llama-3.1-8b-instant",

        "messages": [
          {
            "role": "system",
            "content":
                "You are a careful assistant. Avoid speculation. Say when unsure."
          },
          {
            "role": "user",
            "content": prompt
          }
        ],
        "temperature": 0.3
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Groq API error (${response.statusCode}): ${response.body}',
      );
    }

    final decoded = jsonDecode(response.body);
    return decoded['choices'][0]['message']['content'];
  }
}
