import 'dart:convert';
import 'package:http/http.dart' as http;
import '../secrets.dart';

class GeminiService {
  static Future<Map<String, dynamic>> checkWriting({
    required String module,
    required String question,
    required String answer,
    String imageUrl = '',
    String chartType = '',
  }) async {
    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=${AppSecrets.geminiApiKey}',
    );

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

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': prompt}
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.2,
          'responseMimeType': 'application/json',
        }
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw Exception('Gemini API error: ${response.body}');
    }

    final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'];

    if (text == null || text.toString().trim().isEmpty) {
      throw Exception('Gemini returned empty feedback: ${response.body}');
    }

    final cleanText =
        text.toString().replaceAll('```json', '').replaceAll('```', '').trim();

    try {
      final decoded = jsonDecode(cleanText);

      return {
        'band_score': decoded['band_score']?.toString() ?? '0.0',
        'overall_feedback':
            decoded['overall_feedback']?.toString() ?? 'No overall feedback.',
        'grammar_feedback':
            decoded['grammar_feedback']?.toString() ?? 'No grammar feedback.',
        'vocabulary_feedback':
            decoded['vocabulary_feedback']?.toString() ?? 'No vocabulary feedback.',
        'coherence_feedback':
            decoded['coherence_feedback']?.toString() ?? 'No coherence feedback.',
        'improvement_tips': decoded['improvement_tips'] is List
            ? decoded['improvement_tips']
            : <String>[],
      };
    } catch (e) {
      throw Exception('Failed to parse Gemini JSON: $cleanText');
    }
  }

  static Future<Map<String, dynamic>> checkSpeaking({
    required String part,
    required String topic,
    required String cuePoints,
    required String transcript,
  }) async {
    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=${AppSecrets.geminiApiKey}',
    );

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

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': prompt}
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.2,
          'responseMimeType': 'application/json',
        }
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw Exception('Gemini API error: ${response.body}');
    }

    final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'];

    if (text == null || text.toString().trim().isEmpty) {
      throw Exception('Gemini returned empty speaking feedback');
    }

    final cleanText =
        text.toString().replaceAll('```json', '').replaceAll('```', '').trim();

    try {
      final decoded = jsonDecode(cleanText);

      return {
        'band_score': decoded['band_score']?.toString() ?? '0.0',
        'fluency': decoded['fluency']?.toString() ?? 'No fluency feedback.',
        'vocabulary': decoded['vocabulary']?.toString() ?? 'No vocabulary feedback.',
        'grammar': decoded['grammar']?.toString() ?? 'No grammar feedback.',
        'pronunciation':
            decoded['pronunciation']?.toString() ?? 'No pronunciation feedback.',
        'overall_feedback':
            decoded['overall_feedback']?.toString() ?? 'No overall feedback.',
        'improvement_tips': decoded['improvement_tips'] is List
            ? decoded['improvement_tips']
            : <String>[],
      };
    } catch (e) {
      throw Exception('Failed to parse Gemini speaking JSON: $cleanText');
    }
  }

  static Future<Map<String, dynamic>> generateReadingQuestions({
    required String passageText,
  }) async {
    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=${AppSecrets.geminiApiKey}',
    );

    final prompt = '''
You are an IELTS Academic Reading question creator.

Generate IELTS Academic Reading questions from the passage below.

Return ONLY valid JSON.
Do not use markdown.
Do not wrap the JSON in ```json.
Do not add explanation outside JSON.

Use exactly this JSON structure:

{
  "questions": []
}

Passage:
$passageText
''';

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': prompt}
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.2,
          'responseMimeType': 'application/json',
        }
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw Exception('Gemini API error: ${response.body}');
    }

    final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'];

    if (text == null || text.toString().trim().isEmpty) {
      throw Exception('Gemini returned empty reading response');
    }

    final cleanText =
        text.toString().replaceAll('```json', '').replaceAll('```', '').trim();

    final decoded = jsonDecode(cleanText);

    return {
      'questions': decoded['questions'] is List ? decoded['questions'] : [],
    };
  }
}