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
  "questions": [
    {
      "question_text": "Question here",
      "question_type": "MCQ",
      "correct_answer": "Correct option text here",
      "explanation": "Short explanation here",
      "options": ["Option 1", "Option 2", "Option 3", "Option 4"]
    },
    {
      "question_text": "Question with ______ blank",
      "question_type": "fill_blank",
      "correct_answer": "answer",
      "explanation": "Short explanation here"
    },
    {
      "question_text": "Statement here",
      "question_type": "true_false_not_given",
      "correct_answer": "True",
      "explanation": "Short explanation here"
    },
    {
      "question_text": "Choose the correct heading for Paragraph A",
      "question_type": "matching_heading",
      "correct_answer": "Correct heading text",
      "explanation": "Short explanation here",
      "options": ["Heading 1", "Heading 2", "Heading 3", "Heading 4"]
    },
    {
      "question_text": "Which paragraph mentions government support?",
      "question_type": "matching_information",
      "correct_answer": "Paragraph C",
      "explanation": "Short explanation here",
      "options": ["Paragraph A", "Paragraph B", "Paragraph C", "Paragraph D"]
    },
    {
      "question_text": "Short answer question here",
      "question_type": "short_answer",
      "correct_answer": "answer",
      "explanation": "Short explanation here"
    }
  ]
}

Rules:
- Generate 13 to 14 IELTS Reading questions.
- Include a natural mix of:
  MCQ, fill_blank, true_false_not_given, matching_heading, matching_information, short_answer.
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
