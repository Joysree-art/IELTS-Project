import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'home_page.dart';
import 'analytics_page.dart';
import 'profile_page.dart';

class ReadingPage extends StatefulWidget {
  final String? selectedPassageId;

  const ReadingPage({
    super.key,
    this.selectedPassageId,
  });

  @override
  State<ReadingPage> createState() => _ReadingPageState();
}

class _ReadingPageState extends State<ReadingPage> {
  final supabase = Supabase.instance.client;

  bool isLoading = true;
  bool submitted = false;
  bool isSaving = false;

  String passageId = '';
  String passageTitle = '';
  String passageText = '';
  String difficulty = '';

  String currentTitle = 'IELTS Reading';
  String? currentPracticeType;
  List<String>? currentQuestionTypes;

  List<Map<String, dynamic>> allQuestions = [];
  List<Map<String, dynamic>> questions = [];
  List<String?> selectedAnswers = [];

  final Set<int> bookmarkedQuestions = {};
  final TextEditingController noteController = TextEditingController();

  Timer? countdownTimer;
  Duration duration = const Duration(minutes: 60);

  @override
  void initState() {
    super.initState();
    _fetchReadingTest();
    _startTimer();
  }

  Future<void> _fetchReadingTest() async {
    setState(() {
      isLoading = true;
      submitted = false;
      questions = [];
      allQuestions = [];
      selectedAnswers = [];
      duration = const Duration(minutes: 60);
    });

    try {
      final passage = widget.selectedPassageId != null
          ? await supabase
              .from('reading_passages')
              .select()
              .eq('id', widget.selectedPassageId!)
              .single()
          : await supabase
              .from('reading_passages')
              .select()
              .eq('is_published', true)
              .order('created_at', ascending: false)
              .limit(1)
              .single();

      final questionData = await supabase
          .from('reading_questions')
          .select()
          .eq('passage_id', passage['id'])
          .order('question_order', ascending: true);

      final optionData = await supabase
          .from('reading_options')
          .select()
          .order('option_order', ascending: true);

      final questionList = List<Map<String, dynamic>>.from(questionData);
      final optionList = List<Map<String, dynamic>>.from(optionData);

      for (final q in questionList) {
        q['reading_options'] = optionList
            .where((option) => option['question_id'] == q['id'])
            .toList();
      }

      setState(() {
        passageId = passage['id'].toString();
        passageTitle = passage['title']?.toString() ?? '';
        passageText = passage['passage_text']?.toString() ?? '';
        difficulty = passage['difficulty']?.toString() ?? '';
        allQuestions = questionList;
        _applyQuestionFilter();
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load reading test: $e')),
      );
    }
  }

  void _applyQuestionFilter() {
    if (currentPracticeType == null) {
      questions = [];
      selectedAnswers = [];
      submitted = false;
      bookmarkedQuestions.clear();
      return;
    }

    if (currentQuestionTypes == null || currentQuestionTypes!.isEmpty) {
      questions = List<Map<String, dynamic>>.from(allQuestions);
    } else {
      final allowed = currentQuestionTypes!.map((e) => _normalize(e)).toSet();

      questions = allQuestions.where((q) {
        final type = _normalize(q['question_type'].toString());
        return allowed.contains(type);
      }).toList();
    }

    selectedAnswers = List<String?>.filled(questions.length, null);
    submitted = false;
    bookmarkedQuestions.clear();
  }

  void _changeMode({
    required String title,
    required String practiceType,
    List<String>? questionTypes,
  }) {
    setState(() {
      currentTitle = title;
      currentPracticeType = practiceType;
      currentQuestionTypes = questionTypes;
      duration = const Duration(minutes: 60);
      _applyQuestionFilter();
    });

    _startTimer();
  }

  void _startTimer() {
    countdownTimer?.cancel();

    countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || submitted || isLoading || currentPracticeType == null) {
        return;
      }

      if (duration.inSeconds <= 0) {
        countdownTimer?.cancel();
        setState(() => submitted = true);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Time is up!')),
        );
        return;
      }

      setState(() {
        duration = Duration(seconds: duration.inSeconds - 1);
      });
    });
  }

  String _formatTime(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return '${twoDigits(d.inMinutes.remainder(60))}:${twoDigits(d.inSeconds.remainder(60))}';
  }

  String _normalize(String value) {
    return value.trim().toLowerCase();
  }

  int get answeredCount {
    return selectedAnswers
        .where((answer) => answer != null && answer.trim().isNotEmpty)
        .length;
  }

  int get correctCount {
    int count = 0;

    for (int i = 0; i < questions.length; i++) {
      final userAnswer = _normalize(selectedAnswers[i] ?? '');
      final correctAnswer =
          _normalize(questions[i]['correct_answer'].toString());

      if (userAnswer.isNotEmpty && userAnswer == correctAnswer) {
        count++;
      }
    }

    return count;
  }

  double get progress {
    if (questions.isEmpty) return 0;
    return answeredCount / questions.length;
  }

  int get percentage {
    if (questions.isEmpty) return 0;
    return ((correctCount / questions.length) * 100).round();
  }

  double get bandScore {
    if (percentage >= 85) return 8.0;
    if (percentage >= 70) return 7.0;
    if (percentage >= 55) return 6.0;
    if (percentage >= 40) return 5.0;
    return 4.5;
  }

  Future<void> _saveReadingScoreToSupabase() async {
    setState(() => isSaving = true);

    try {
      final userId = supabase.auth.currentUser?.id;

      await supabase.from('reading_scores').insert({
        'user_id': userId,
        'module': 'reading',
        'practice_type': currentPracticeType ?? 'unknown',
        'passage_id': passageId,
        'correct_answers': correctCount,
        'total_questions': questions.length,
        'percentage': percentage,
        'band_score': bandScore,
        'created_at': DateTime.now().toIso8601String(),
      });
      await supabase.from('ielts_scores').insert({
        'user_id': userId,
        'module': 'reading',
        'band_score': bandScore,
        'created_at': DateTime.now().toIso8601String(),
      });

      if (currentPracticeType == 'mixed') {
      await supabase.from('homepage_scores').insert({
      'user_id': userId,
      'module': 'reading',
      'band_score': bandScore,
      'test_type': 'full_test',
      'created_at': DateTime.now().toIso8601String(),
     });
}

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reading score saved successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save score: $e')),
      );
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  @override
  void dispose() {
    countdownTimer?.cancel();
    noteController.dispose();
    super.dispose();
  }

  void _goToPage(int index) {
    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HomePage()),
      );
    } else if (index == 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AnalyticsPage()),
      );
    } else if (index == 2) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => ProfilePage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFFDF7F9),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFDB2777)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFDF7F9),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildProgressBar(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _fetchReadingTest,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildModeSelector(),
                      const SizedBox(height: 16),
                      if (currentPracticeType != null) _buildPassageCard(),
                      if (currentPracticeType != null)
                        const SizedBox(height: 20),
                      if (currentPracticeType == null)
                        const Padding(
                          padding: EdgeInsets.only(top: 30),
                          child: Text(
                            'Select a practice mode to start.',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      if (currentPracticeType != null)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Questions (${questions.length})',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      if (currentPracticeType != null)
                        const SizedBox(height: 15),
                      if (currentPracticeType != null && questions.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(20),
                          child: Text(
                            'No questions found for this practice mode.',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      else if (currentPracticeType != null)
                        ...List.generate(
                          questions.length,
                          (index) => _buildQuestionCard(index),
                        ),
                      const SizedBox(height: 20),
                      if (currentPracticeType != null && questions.isNotEmpty)
                        _buildSubmitButton(),
                      if (submitted) _buildAnalyticsCard(),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          InkWell(
            onTap: () {
              Navigator.pop(context);
            },
            borderRadius: BorderRadius.circular(30),
            child: const CircleAvatar(
              backgroundColor: Color(0xFFFCE7F3),
              child: Icon(Icons.arrow_back, color: Color(0xFFDB2777)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  currentTitle,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  currentPracticeType == null
                      ? 'Choose a practice mode'
                      : passageTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF1F2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.timer_outlined, color: Colors.red, size: 18),
                const SizedBox(width: 5),
                Text(
                  _formatTime(duration),
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            currentPracticeType == null
                ? 'Progress: 0/0'
                : 'Progress: $answeredCount/${questions.length}',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: currentPracticeType == null ? 0 : progress,
              minHeight: 8,
              backgroundColor: Colors.pink.shade100,
              valueColor: const AlwaysStoppedAnimation(Color(0xFFDB2777)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Choose Practice Mode',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 12),
        _modeCard(
          title: 'Full Mixed Test',
          subtitle: 'MCQ + Fill Blank + True/False',
          icon: Icons.menu_book_rounded,
          active: currentPracticeType == 'mixed',
          onTap: () => _changeMode(
            title: 'Full Mixed Reading Test',
            practiceType: 'mixed',
            questionTypes: null,
          ),
        ),
        _modeCard(
          title: 'MCQ Practice',
          subtitle: 'Only multiple choice questions',
          icon: Icons.check_circle_outline,
          active: currentPracticeType == 'mcq',
          onTap: () => _changeMode(
            title: 'MCQ Practice',
            practiceType: 'mcq',
            questionTypes: ['mcq'],
          ),
        ),
        _modeCard(
          title: 'Fill in the Blank',
          subtitle: 'Only written blank answers',
          icon: Icons.edit_note,
          active: currentPracticeType == 'fill_blank',
          onTap: () => _changeMode(
            title: 'Fill in the Blank',
            practiceType: 'fill_blank',
            questionTypes: ['fill_blank'],
          ),
        ),
        _modeCard(
          title: 'True / False / Not Given',
          subtitle: 'Only TFNG questions',
          icon: Icons.rule,
          active: currentPracticeType == 'true_false_not_given',
          onTap: () => _changeMode(
            title: 'True / False / Not Given',
            practiceType: 'true_false_not_given',
            questionTypes: ['true_false_not_given'],
          ),
        ),
      ],
    );
  }

  Widget _modeCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool active,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: active ? const Color(0xFFFCE7F3) : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: active ? const Color(0xFFDB2777) : Colors.pink.shade100,
              width: active ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor:
                    active ? const Color(0xFFDB2777) : const Color(0xFFFCE7F3),
                child: Icon(
                  icon,
                  color: active ? Colors.white : const Color(0xFFDB2777),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(subtitle,
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
              if (active)
                const Icon(Icons.check_circle, color: Color(0xFFDB2777)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPassageCard() {
    final preview = passageText.length > 150
        ? '${passageText.substring(0, 150)}...'
        : passageText;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            passageTitle,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (difficulty.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              difficulty.toUpperCase(),
              style: const TextStyle(
                color: Color(0xFF38BDF8),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Text(
            preview,
            style: const TextStyle(color: Colors.white70, height: 1.5),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _showFullPassage,
                  icon: const Icon(Icons.visibility),
                  label: const Text('View Passage'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1F2937),
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _showNoteDialog,
                  icon: const Icon(Icons.note_alt_outlined),
                  label: const Text('Take Notes'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1F2937),
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showFullPassage() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (_) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.85,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: ListView(
                controller: scrollController,
                children: [
                  Text(
                    passageTitle,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    passageText,
                    style: const TextStyle(fontSize: 16, height: 1.7),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showNoteDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Take Notes'),
          content: TextField(
            controller: noteController,
            maxLines: 8,
            decoration: InputDecoration(
              hintText: 'Write your notes here...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Notes saved successfully')),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDB2777),
                foregroundColor: Colors.white,
              ),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildQuestionCard(int index) {
    final question = questions[index];

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.pink.shade100),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFFFCE7F3),
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    color: Color(0xFFDB2777),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  question['question_text']?.toString() ?? '',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
              ),
              IconButton(
                onPressed: submitted
                    ? null
                    : () {
                        setState(() {
                          bookmarkedQuestions.contains(index)
                              ? bookmarkedQuestions.remove(index)
                              : bookmarkedQuestions.add(index);
                        });
                      },
                icon: Icon(
                  bookmarkedQuestions.contains(index)
                      ? Icons.bookmark
                      : Icons.bookmark_border,
                  color: const Color(0xFFDB2777),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              margin: const EdgeInsets.only(left: 56),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFDF2F8),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                question['question_type']?.toString() ?? '',
                style: const TextStyle(
                  color: Color(0xFFDB2777),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          _buildAnswerInput(index),
          if (submitted) _buildCorrectAnswerBox(index),
        ],
      ),
    );
  }

  Widget _buildAnswerInput(int questionIndex) {
    final question = questions[questionIndex];
    final type = _normalize(question['question_type'].toString());

    if (type.contains('mcq') ||
        type == 'matching_heading' ||
        type == 'matching_information') {
      final options = List<Map<String, dynamic>>.from(
        question['reading_options'] ?? [],
      );

      options.sort((a, b) {
        final aOrder = a['option_order'] ?? 0;
        final bOrder = b['option_order'] ?? 0;
        return aOrder.compareTo(bOrder);
      });

      if (options.isEmpty) {
        return const Padding(
          padding: EdgeInsets.only(left: 56),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'No options added for this question',
              style: TextStyle(color: Colors.red),
            ),
          ),
        );
      }

      return Column(
        children: options
            .map(
              (option) => _buildTextOption(
                questionIndex,
                option['option_text'].toString(),
              ),
            )
            .toList(),
      );
    }

    if (type == 'true_false_not_given') {
      return Column(
        children: ['True', 'False', 'Not Given']
            .map((option) => _buildTextOption(questionIndex, option))
            .toList(),
      );
    }

    if (type == 'yes_no_not_given') {
      return Column(
        children: ['Yes', 'No', 'Not Given']
            .map((option) => _buildTextOption(questionIndex, option))
            .toList(),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(left: 56),
      child: TextField(
        enabled: !submitted,
        onChanged: (value) {
          selectedAnswers[questionIndex] = value;
        },
        decoration: InputDecoration(
          hintText: 'Write your answer',
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFDB2777), width: 2),
          ),
        ),
      ),
    );
  }

  Widget _buildTextOption(int questionIndex, String optionText) {
    final selected = selectedAnswers[questionIndex] == optionText;
    final correctAnswer =
        questions[questionIndex]['correct_answer'].toString().trim();

    final isCorrect =
        submitted && _normalize(optionText) == _normalize(correctAnswer);

    final isWrong = submitted &&
        selected &&
        _normalize(optionText) != _normalize(correctAnswer);

    Color borderColor = Colors.pink.shade100;
    Color bgColor = Colors.white;

    if (selected) {
      borderColor = const Color(0xFFDB2777);
      bgColor = const Color(0xFFFDF2F8);
    }

    if (isCorrect) {
      borderColor = Colors.green;
      bgColor = const Color(0xFFDCFCE7);
    }

    if (isWrong) {
      borderColor = Colors.red;
      bgColor = const Color(0xFFFEE2E2);
    }

    return GestureDetector(
      onTap: submitted
          ? null
          : () {
              setState(() {
                selectedAnswers[questionIndex] = optionText;
              });
            },
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(left: 56, bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                optionText,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (selected && !submitted)
              const Icon(Icons.check_circle, color: Color(0xFFDB2777)),
            if (isCorrect) const Icon(Icons.check_circle, color: Colors.green),
            if (isWrong) const Icon(Icons.cancel, color: Colors.red),
          ],
        ),
      ),
    );
  }

  Widget _buildCorrectAnswerBox(int index) {
    final userAnswer = selectedAnswers[index]?.trim() ?? '';
    final correctAnswer = questions[index]['correct_answer'].toString().trim();
    final explanation = (questions[index]['explanation'] ?? '').toString();

    final isCorrect = _normalize(userAnswer) == _normalize(correctAnswer);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(left: 56, top: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isCorrect ? const Color(0xFFDCFCE7) : const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isCorrect ? Colors.green : Colors.orange,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isCorrect ? 'Correct' : 'Correct answer: $correctAnswer',
            style: TextStyle(
              color: isCorrect ? Colors.green : Colors.orange.shade900,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (userAnswer.isEmpty && !isCorrect)
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text(
                'You did not answer this question.',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          if (explanation.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'Explanation: $explanation',
                style: const TextStyle(color: Colors.grey, height: 1.4),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: currentPracticeType != null && !isSaving && !submitted
            ? () async {
                countdownTimer?.cancel();
                setState(() => submitted = true);
                await _saveReadingScoreToSupabase();
              }
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFDB2777),
          disabledBackgroundColor: Colors.grey.shade300,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: Text(
          isSaving
              ? 'Saving...'
              : submitted
                  ? 'Submitted'
                  : 'Submit Answers',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildAnalyticsCard() {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Reading Analytics',
            style: TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _analyticsBox('Score', '$correctCount/${questions.length}'),
              const SizedBox(width: 10),
              _analyticsBox('Accuracy', '$percentage%'),
              const SizedBox(width: 10),
              _analyticsBox('Band', bandScore.toStringAsFixed(1)),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Insight',
            style: TextStyle(
              color: Color(0xFF38BDF8),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _aiInsight(percentage),
            style: const TextStyle(color: Colors.white70, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _analyticsBox(String title, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Color(0xFF38BDF8),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(title, style: const TextStyle(color: Colors.white70)),
          ],
        ),
      ),
    );
  }

  String _aiInsight(int percentage) {
    if (percentage >= 85) {
      return 'Excellent work! Practice harder IELTS passages and focus on time management.';
    } else if (percentage >= 70) {
      return 'Good performance. Review detail-based and inference questions.';
    } else if (percentage >= 55) {
      return 'Average performance. Focus on keywords, scanning, and paragraph meaning.';
    } else if (percentage >= 40) {
      return 'You need more practice. Underline keywords and avoid guessing too quickly.';
    } else {
      return 'Basic understanding needs improvement. Start with short passages and vocabulary practice.';
    }
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: 0,
      onTap: _goToPage,
      selectedItemColor: const Color(0xFFDB2777),
      unselectedItemColor: Colors.grey,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(
          icon: Icon(Icons.bar_chart),
          label: 'Analytics',
        ),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ],
    );
  }
}
