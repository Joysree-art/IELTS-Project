import 'dart:convert';
import 'package:http/http.dart' as http;
import '../secrets.dart';

class GroqService {
  static const String _model = 'llama-3.1-8b-instant';

  static Uri get _url => Uri.parse(
        'https://api.groq.com/openai/v1/chat/completions',
      );

  static Future<String> _sendPrompt(String prompt) async {
    final response = await http.post(
      _url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${AppSecrets.groqApiKey}',
      },
      body: jsonEncode({
        'model': _model,
        'messages': [
          {'role': 'user', 'content': prompt}
        ],
        'temperature': 0.2,
        'response_format': {'type': 'json_object'},
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw Exception('Groq API error: ${response.body}');
    }

    final text = data['choices']?[0]?['message']?['content'];

    if (text == null || text.toString().trim().isEmpty) {
      throw Exception('Groq returned empty response: ${response.body}');
    }

    return text.toString().trim();
  }

  static Future<String> testConnection() async {
    final response = await http.post(
      _url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${AppSecrets.groqApiKey}',
      },
      body: jsonEncode({
        'model': _model,
        'messages': [
          {
            'role': 'user',
            'content': 'Reply with only: Groq Connected Successfully'
          }
        ],
        'temperature': 0.2,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw Exception(response.body);
    }

    return data['choices'][0]['message']['content'];
  }

  static Future<Map<String, dynamic>> checkWriting({
    required String module,
    required String question,
    required String answer,
    String imageUrl = '',
    String chartType = '',
  }) async {
    final prompt = '''
You are an IELTS examiner.

Module: $module
Chart Type: $chartType
Image URL: $imageUrl

Question:
$question

Student Answer:
$answer

Evaluate the writing and return ONLY valid JSON.
Do not use markdown.
Do not wrap the JSON in ```json.
Do not add any explanation outside JSON.

Use exactly this JSON structure:

{
  "band_score": "6.5",
  "overall_feedback": "",
  "grammar_feedback": "",
  "vocabulary_feedback": "",
  "coherence_feedback": "",
  "improvement_tips": []
}
''';

    final cleanText = await _sendPrompt(prompt);

    try {
      final decoded = jsonDecode(
        cleanText.replaceAll('```json', '').replaceAll('```', '').trim(),
      );

      return {
        'band_score': decoded['band_score']?.toString() ?? '0.0',
        'overall_feedback':
            decoded['overall_feedback']?.toString() ?? 'No overall feedback.',
        'grammar_feedback':
            decoded['grammar_feedback']?.toString() ?? 'No grammar feedback.',
        'vocabulary_feedback': decoded['vocabulary_feedback']?.toString() ??
            'No vocabulary feedback.',
        'coherence_feedback': decoded['coherence_feedback']?.toString() ??
            'No coherence feedback.',
        'improvement_tips': decoded['improvement_tips'] is List
            ? decoded['improvement_tips']
            : <String>[],
      };
    } catch (e) {
      throw Exception('Failed to parse Groq writing JSON: $cleanText');
    }
  }

  static Future<Map<String, dynamic>> checkSpeaking({
    required String part,
    required String topic,
    required String cuePoints,
    required String transcript,
  }) async {
    final prompt = '''
You are an IELTS Speaking examiner.

Speaking Part: $part

Topic:
$topic

Cue Points:
$cuePoints

Candidate Transcript:
$transcript

Evaluate the speaking answer and return ONLY valid JSON.
Do not use markdown.
Do not wrap JSON in ```json.
Do not add explanation outside JSON.

Use exactly this JSON structure:

{
  "band_score": "6.5",
  "fluency": "",
  "vocabulary": "",
  "grammar": "",
  "pronunciation": "",
  "overall_feedback": "",
  "improvement_tips": []
}
''';

    final cleanText = await _sendPrompt(prompt);

    try {
      final decoded = jsonDecode(
        cleanText.replaceAll('```json', '').replaceAll('```', '').trim(),
      );

      return {
        'band_score': decoded['band_score']?.toString() ?? '0.0',
        'fluency': decoded['fluency']?.toString() ?? 'No fluency feedback.',
        'vocabulary':
            decoded['vocabulary']?.toString() ?? 'No vocabulary feedback.',
        'grammar': decoded['grammar']?.toString() ?? 'No grammar feedback.',
        'pronunciation': decoded['pronunciation']?.toString() ??
            'No pronunciation feedback.',
        'overall_feedback':
            decoded['overall_feedback']?.toString() ?? 'No overall feedback.',
        'improvement_tips': decoded['improvement_tips'] is List
            ? decoded['improvement_tips']
            : <String>[],
      };
    } catch (e) {
      throw Exception('Failed to parse Groq speaking JSON: $cleanText');
    }
  }

  static Future<Map<String, dynamic>> generateReadingQuestions({
    required String passageText,
  }) async {
    final prompt = '''
You are an IELTS Academic Reading question creator.

Create 13 IELTS Academic Reading questions from the passage below.

Return ONLY valid JSON.
Do not use markdown.
Do not wrap the JSON in ```json.
Do not add explanation outside JSON.

Use exactly this JSON structure:

{
  "questions": [
    {
      "question_text": "",
      "question_type": "MCQ",
      "correct_answer": "",
      "explanation": "",
      "options": ["", "", "", ""]
    }
  ]
}

Rules:
- Use mixed types: MCQ, fill_blank, true_false_not_given, matching_heading, matching_information, short_answer.
- For MCQ, matching_heading, and matching_information, include options array.
- For MCQ, correct_answer must exactly match one option text.
- For matching_heading, correct_answer must exactly match one heading option.
- For matching_information, correct_answer must exactly match one paragraph option.
- For true_false_not_given, correct_answer must be only: True, False, or Not Given.
- For fill_blank and short_answer, use one short answer only.
- Questions must be based only on the passage.

Passage:
$passageText
''';

    final cleanText = await _sendPrompt(prompt);

    try {
      final decoded = jsonDecode(
        cleanText.replaceAll('```json', '').replaceAll('```', '').trim(),
      );

      return {
        'questions': decoded['questions'] is List ? decoded['questions'] : [],
      };
    } catch (e) {
      throw Exception('Failed to parse Groq reading JSON: $cleanText');
    }
  }
}
