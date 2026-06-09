import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/groq_service.dart';

class AdminReadingPage extends StatefulWidget {
  const AdminReadingPage({super.key});

  @override
  State<AdminReadingPage> createState() => _AdminReadingPageState();
}

class _AdminReadingPageState extends State<AdminReadingPage> {
  final supabase = Supabase.instance.client;

  final titleController = TextEditingController();
  final passageController = TextEditingController();
  final sourceController = TextEditingController(text: 'Admin / AI');

  final questionController = TextEditingController();
  final answerController = TextEditingController();
  final explanationController = TextEditingController();

  final option1Controller = TextEditingController();
  final option2Controller = TextEditingController();
  final option3Controller = TextEditingController();
  final option4Controller = TextEditingController();

  String difficulty = 'medium';
  String questionType = 'MCQ';
  bool isLoading = false;

  String? savedPassageId;
  List<Map<String, dynamic>> generatedQuestions = [];
  List<Map<String, dynamic>> savedQuestions = [];

  final questionTypes = const [
    'MCQ',
    'fill_blank',
    'true_false_not_given',
    'matching_heading',
    'matching_information',
    'short_answer',
  ];

  @override
  void dispose() {
    titleController.dispose();
    passageController.dispose();
    sourceController.dispose();
    questionController.dispose();
    answerController.dispose();
    explanationController.dispose();
    option1Controller.dispose();
    option2Controller.dispose();
    option3Controller.dispose();
    option4Controller.dispose();
    super.dispose();
  }

  void _msg(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  String _normalType(String type) {
    final t = type.trim().toLowerCase();
    if (t.contains('mcq')) return 'MCQ';
    if (t == 'fill_blank') return 'fill_blank';
    if (t == 'true_false_not_given') return 'true_false_not_given';
    if (t == 'matching_heading') return 'matching_heading';
    if (t == 'matching_information') return 'matching_information';
    if (t == 'short_answer') return 'short_answer';
    return type.trim();
  }

  bool _hasOptions(String type) {
    final t = type.trim().toLowerCase();
    return t.contains('mcq') ||
        t == 'matching_heading' ||
        t == 'matching_information';
  }

  Future<void> _savePassage() async {
    if (titleController.text.trim().isEmpty ||
        passageController.text.trim().isEmpty) {
      _msg('Title and passage required');
      return;
    }

    setState(() => isLoading = true);

    try {
      // ===== GET NEXT PASSAGE NUMBER =====
      final lastPassage = await supabase
          .from('reading_passages')
          .select('passage_number')
          .order('passage_number', ascending: false)
          .limit(1);

      final nextPassageNumber = lastPassage.isEmpty
          ? 1
          : (lastPassage[0]['passage_number'] as int) + 1;

      // ===== INSERT PASSAGE =====
      final inserted = await supabase
          .from('reading_passages')
          .insert({
            'title': titleController.text.trim(),
            'passage_text': passageController.text.trim(),
            'test_type': 'academic',
            'passage_number': nextPassageNumber,
            'difficulty': difficulty,
            'target_band': 6.5,
            'source': sourceController.text.trim(),
            'is_published': true,
            'created_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      savedPassageId = inserted['id'].toString();

      await _fetchSavedQuestions();
      _msg('Passage saved');
    } catch (e) {
      _msg('Passage save failed: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _ensurePassageSaved() async {
    if (savedPassageId == null) {
      await _savePassage();
    }
  }

  Future<void> _generateQuestions() async {
    if (passageController.text.trim().isEmpty) {
      _msg('Enter passage first');
      return;
    }

    setState(() => isLoading = true);

    try {
      final result = await GroqService.generateReadingQuestions(
        passageText: passageController.text.trim(),
      );

      setState(() {
        generatedQuestions =
            List<Map<String, dynamic>>.from(result['questions'] ?? []);
      });

      _msg('AI questions generated');
    } catch (e) {
      _msg('AI generation failed: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _saveGeneratedQuestions() async {
    await _ensurePassageSaved();

    if (savedPassageId == null) {
      _msg('Passage not saved');
      return;
    }

    if (generatedQuestions.isEmpty) {
      _msg('Generate questions first');
      return;
    }

    setState(() => isLoading = true);

    try {
      for (int i = 0; i < generatedQuestions.length; i++) {
        final q = generatedQuestions[i];
        await _insertQuestion(
          questionText: q['question_text']?.toString() ?? '',
          type: _normalType(q['question_type']?.toString() ?? ''),
          correctAnswer: q['correct_answer']?.toString() ?? '',
          explanation: q['explanation']?.toString() ?? '',
          order: savedQuestions.length + i + 1,
          options: q['options'] is List ? List<String>.from(q['options']) : [],
        );
      }

      generatedQuestions.clear();
      await _fetchSavedQuestions();
      _msg('AI questions saved');
    } catch (e) {
      _msg('Save AI questions failed: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _addManualQuestion() async {
    await _ensurePassageSaved();

    if (savedPassageId == null) {
      _msg('Passage not saved');
      return;
    }

    if (questionController.text.trim().isEmpty ||
        answerController.text.trim().isEmpty) {
      _msg('Question and answer required');
      return;
    }

    final options = _hasOptions(questionType)
        ? [
            option1Controller.text.trim(),
            option2Controller.text.trim(),
            option3Controller.text.trim(),
            option4Controller.text.trim(),
          ].where((e) => e.isNotEmpty).toList()
        : <String>[];

    if (_hasOptions(questionType) && options.length < 2) {
      _msg('This question type needs options');
      return;
    }

    setState(() => isLoading = true);

    try {
      await _insertQuestion(
        questionText: questionController.text.trim(),
        type: _normalType(questionType),
        correctAnswer: answerController.text.trim(),
        explanation: explanationController.text.trim(),
        order: savedQuestions.length + 1,
        options: options,
      );

      questionController.clear();
      answerController.clear();
      explanationController.clear();
      option1Controller.clear();
      option2Controller.clear();
      option3Controller.clear();
      option4Controller.clear();

      await _fetchSavedQuestions();
      _msg('Manual question added');
    } catch (e) {
      _msg('Manual question save failed: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _insertQuestion({
    required String questionText,
    required String type,
    required String correctAnswer,
    required String explanation,
    required int order,
    required List<String> options,
  }) async {
    if (questionText.trim().isEmpty || correctAnswer.trim().isEmpty) return;

    final inserted = await supabase
        .from('reading_questions')
        .insert({
          'passage_id': savedPassageId,
          'question_text': questionText.trim(),
          'question_type': _normalType(type),
          'question_order': order,
          'correct_answer': correctAnswer.trim(),
          'explanation': explanation.trim(),
          'created_at': DateTime.now().toIso8601String(),
        })
        .select()
        .single();

    final questionId = inserted['id'].toString();

    if (_hasOptions(type)) {
      final cleanOptions = options.where((e) => e.trim().isNotEmpty).toList();

      if (cleanOptions.isNotEmpty) {
        await supabase.from('reading_options').insert(
              List.generate(cleanOptions.length, (index) {
                return {
                  'question_id': questionId,
                  'option_text': cleanOptions[index],
                  'option_order': index + 1,
                };
              }),
            );
      }
    }
  }

  Future<void> _fetchSavedQuestions() async {
    if (savedPassageId == null) return;

    final data = await supabase
        .from('reading_questions')
        .select()
        .eq('passage_id', savedPassageId!)
        .order('question_order', ascending: true);

    setState(() {
      savedQuestions = List<Map<String, dynamic>>.from(data);
    });
  }

  Future<void> _deleteQuestion(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Question'),
        content: const Text('Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => isLoading = true);

    try {
      await supabase.from('reading_options').delete().eq('question_id', id);
      await supabase.from('reading_questions').delete().eq('id', id);
      await _fetchSavedQuestions();
      _msg('Question deleted');
    } catch (e) {
      _msg('Delete failed: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  Widget _title(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 12),
      child: Text(
        text,
        style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _generatedPreview() {
    if (generatedQuestions.isEmpty) {
      return const Text(
        'No AI questions generated yet.',
        style: TextStyle(color: Colors.grey),
      );
    }

    return Column(
      children: generatedQuestions.asMap().entries.map((entry) {
        final index = entry.key;
        final q = entry.value;
        final options = q['options'];

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Q${index + 1}. ${q['question_text'] ?? ''}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                    'Type: ${_normalType(q['question_type']?.toString() ?? '')}'),
                Text('Answer: ${q['correct_answer'] ?? ''}'),
                if (options is List) ...[
                  const SizedBox(height: 6),
                  const Text('Options:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  ...options.map((o) => Text('- $o')),
                ],
                if ((q['explanation'] ?? '').toString().trim().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      'Explanation: ${q['explanation']}',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _savedList() {
    if (savedQuestions.isEmpty) {
      return const Text(
        'No saved questions yet.',
        style: TextStyle(color: Colors.grey),
      );
    }

    return Column(
      children: savedQuestions.map((q) {
        return Card(
          child: ListTile(
            title: Text(q['question_text']?.toString() ?? ''),
            subtitle: Text(
              'Type: ${q['question_type']} | Answer: ${q['correct_answer']}',
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () => _deleteQuestion(q['id'].toString()),
            ),
          ),
        );
      }).toList(),
    );
  }

  void _clearAll() {
    titleController.clear();
    passageController.clear();
    sourceController.text = 'Admin / AI';

    questionController.clear();
    answerController.clear();
    explanationController.clear();

    option1Controller.clear();
    option2Controller.clear();
    option3Controller.clear();
    option4Controller.clear();

    savedPassageId = null;

    generatedQuestions.clear();
    savedQuestions.clear();

    difficulty = 'medium';
    questionType = 'MCQ';

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final showOptions = _hasOptions(questionType);

    return Scaffold(
      backgroundColor: const Color(0xFFFDF7F9),
      appBar: AppBar(
        title: const Text('Admin Reading Page'),
        backgroundColor: const Color(0xFFDB2777),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            tooltip: 'Clear Form',
            icon: const Icon(Icons.refresh),
            onPressed: isLoading ? null : _clearAll,
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _title('1. Passage'),
                _field(titleController, 'Passage Title'),
                _field(passageController, 'Passage Text', maxLines: 9),
                DropdownButtonFormField<String>(
                  value: difficulty,
                  decoration: const InputDecoration(
                    labelText: 'Difficulty',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'easy', child: Text('Easy')),
                    DropdownMenuItem(value: 'medium', child: Text('Medium')),
                    DropdownMenuItem(value: 'hard', child: Text('Hard')),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => difficulty = v);
                  },
                ),
                const SizedBox(height: 12),
                _field(sourceController, 'Source'),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: isLoading ? null : _savePassage,
                    icon: const Icon(Icons.save),
                    label: Text(savedPassageId == null
                        ? 'Save Passage'
                        : 'Passage Saved'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDB2777),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                _title('2. Generate Questions with AI'),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: isLoading ? null : _generateQuestions,
                        icon: const Icon(Icons.auto_awesome),
                        label: const Text('Generate AI'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF111827),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: isLoading ? null : _saveGeneratedQuestions,
                        icon: const Icon(Icons.cloud_upload),
                        label: const Text('Save AI Qs'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _generatedPreview(),
                _title('3. Add Question Manually'),
                _field(questionController, 'Question Text', maxLines: 3),
                DropdownButtonFormField<String>(
                  value: questionType,
                  decoration: const InputDecoration(
                    labelText: 'Question Type',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(),
                  ),
                  items: questionTypes
                      .map(
                        (type) => DropdownMenuItem(
                          value: type,
                          child: Text(type),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => questionType = v);
                  },
                ),
                const SizedBox(height: 12),
                if (questionType == 'true_false_not_given')
                  DropdownButtonFormField<String>(
                    value: answerController.text.isEmpty
                        ? null
                        : answerController.text,
                    decoration: const InputDecoration(
                      labelText: 'Correct Answer',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'True', child: Text('True')),
                      DropdownMenuItem(value: 'False', child: Text('False')),
                      DropdownMenuItem(
                        value: 'Not Given',
                        child: Text('Not Given'),
                      ),
                    ],
                    onChanged: (v) {
                      if (v != null) answerController.text = v;
                    },
                  )
                else
                  _field(answerController, 'Correct Answer'),
                const SizedBox(height: 12),
                _field(explanationController, 'Explanation', maxLines: 2),
                if (showOptions) ...[
                  _field(option1Controller, 'Option 1'),
                  _field(option2Controller, 'Option 2'),
                  _field(option3Controller, 'Option 3'),
                  _field(option4Controller, 'Option 4'),
                ],
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: isLoading ? null : _addManualQuestion,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Manual Question'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDB2777),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                _title('4. Saved Questions'),
                _savedList(),
                const SizedBox(height: 60),
              ],
            ),
          ),
          if (isLoading)
            Container(
              color: Colors.black.withOpacity(0.15),
              child: const Center(
                child: CircularProgressIndicator(color: Color(0xFFDB2777)),
              ),
            ),
        ],
      ),
    );
  }
}
