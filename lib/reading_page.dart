import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'home_page.dart';
import 'analytics_page.dart';
import 'profile_page.dart';

class ReadingPage extends StatefulWidget {
  const ReadingPage({super.key});

  @override
  State<ReadingPage> createState() => _ReadingPageState();
}

class _ReadingPageState extends State<ReadingPage> {
  bool submitted = false;
  bool isSaving = false;

  List<int?> selectedAnswers = [null, null, null];

  final Set<int> bookmarkedQuestions = {};
  final TextEditingController noteController = TextEditingController();

  Timer? countdownTimer;
  Duration duration = const Duration(minutes: 60);

  final List<Map<String, dynamic>> questions = [
    {
      "question": "What is the main purpose of the passage?",
      "type": "Main Idea",
      "options": [
        "To explain how technology is changing education",
        "To criticize students for using online tools",
        "To describe the history of schools",
        "To prove that teachers are no longer needed",
      ],
      "answer": 0,
    },
    {
      "question": "According to paragraph 2, what role do teachers still play?",
      "type": "Detail",
      "options": [
        "They completely stop students from using technology",
        "They guide students and explain ideas clearly",
        "They only check exam papers",
        "They make learning slower",
      ],
      "answer": 1,
    },
    {
      "question": "What does the passage suggest about future education?",
      "type": "Inference",
      "options": [
        "All students will study the same lessons",
        "Books will disappear completely",
        "Learning may become more personalized",
        "Teachers will be replaced immediately",
      ],
      "answer": 2,
    },
  ];

  @override
  void initState() {
    super.initState();
    startTimer();
  }

  void startTimer() {
    countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final seconds = duration.inSeconds - 1;

      if (seconds < 0) {
        countdownTimer?.cancel();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Time is up!")),
        );
      } else {
        setState(() {
          duration = Duration(seconds: seconds);
        });
      }
    });
  }

  String formatTime(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  int get answeredCount => selectedAnswers.where((e) => e != null).length;

  int get correctCount {
    int count = 0;

    for (int i = 0; i < questions.length; i++) {
      if (selectedAnswers[i] == questions[i]["answer"]) {
        count++;
      }
    }

    return count;
  }

  double get progress => answeredCount / questions.length;

  int get percentage {
    return ((correctCount / questions.length) * 100).round();
  }

  double get bandScore {
    return _bandScoreFromPercentage(percentage);
  }

  double _bandScoreFromPercentage(int percentage) {
    if (percentage >= 85) return 8.0;
    if (percentage >= 70) return 7.0;
    if (percentage >= 55) return 6.0;
    if (percentage >= 40) return 5.0;
    return 4.5;
  }

  String _bandPrediction(int percentage) {
    return _bandScoreFromPercentage(percentage).toStringAsFixed(1);
  }

  Future<void> _saveReadingScoreToSupabase() async {
    setState(() {
      isSaving = true;
    });

    try {
      await Supabase.instance.client.from('reading_scores').insert({
        'module': 'reading',
        'correct_answers': correctCount,
        'total_questions': questions.length,
        'percentage': percentage,
        'band_score': bandScore,
        'created_at': DateTime.now().toIso8601String(),
      });

      print("Reading score saved: $bandScore");

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Reading score saved successfully")),
      );
    } catch (e) {
      print("SAVE ERROR: $e");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to save score: $e")),
      );
    } finally {
      setState(() {
        isSaving = false;
      });
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
    return Scaffold(
      backgroundColor: const Color(0xFFFDF7F9),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildProgressBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildPassageCard(),
                    const SizedBox(height: 20),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Questions",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    ...List.generate(
                      questions.length,
                      (index) => _buildQuestionCard(index),
                    ),
                    const SizedBox(height: 20),
                    _buildSubmitButton(),
                    if (submitted) _buildAnalyticsCard(),
                    const SizedBox(height: 80),
                  ],
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
          const CircleAvatar(
            backgroundColor: Color(0xFFFCE7F3),
            child: Icon(
              Icons.menu_book_rounded,
              color: Color(0xFFDB2777),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "IELTS Reading",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "Academic Passage 1",
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF1F2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.timer_outlined,
                  color: Colors.red,
                  size: 18,
                ),
                const SizedBox(width: 5),
                Text(
                  formatTime(duration),
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
            "Progress: $answeredCount/${questions.length}",
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.pink.shade100,
              valueColor: const AlwaysStoppedAnimation(
                Color(0xFFDB2777),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPassageCard() {
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
          const Text(
            "Reading Passage",
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            "Modern education has changed significantly with the growth of technology.",
            style: TextStyle(
              color: Colors.white70,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _showFullPassage,
                  icon: const Icon(Icons.visibility),
                  label: const Text("View Passage"),
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
                  label: const Text("Take Notes"),
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

  void _showNoteDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text("Take Notes"),
          content: TextField(
            controller: noteController,
            maxLines: 8,
            decoration: InputDecoration(
              hintText: "Write your notes here...",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Notes saved successfully"),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDB2777),
                foregroundColor: Colors.white,
              ),
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  void _showFullPassage() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(25),
        ),
      ),
      builder: (sheetContext) {
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
                children: const [
                  Text(
                    "The Future of Education",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    "Modern education has changed significantly with the growth of technology. "
                    "Students now use digital platforms, online resources, and artificial intelligence "
                    "tools to improve their learning. These tools help students understand difficult "
                    "topics, track their progress, and receive feedback more quickly.\n\n"
                    "However, technology cannot replace the role of teachers completely. Teachers guide "
                    "students, explain ideas clearly, and support emotional development. The best learning "
                    "environment combines technology with human guidance.\n\n"
                    "In the future, education is likely to become more personalized. Students may receive "
                    "lessons based on their strengths and weaknesses. This can help learners improve faster "
                    "and become more confident.",
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.7,
                    ),
                  ),
                ],
              ),
            );
          },
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
        border: Border.all(
          color: Colors.pink.shade100,
        ),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFFFCE7F3),
                child: Text(
                  "${index + 1}",
                  style: const TextStyle(
                    color: Color(0xFFDB2777),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  question["question"],
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
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFFDF2F8),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                question["type"],
                style: const TextStyle(
                  color: Color(0xFFDB2777),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          ...List.generate(
            question["options"].length,
            (optionIndex) => _buildOption(index, optionIndex),
          ),
        ],
      ),
    );
  }

  Widget _buildOption(int questionIndex, int optionIndex) {
    final isSelected = selectedAnswers[questionIndex] == optionIndex;
    final correctAnswer = questions[questionIndex]["answer"];
    final correctAnswerText =
        questions[questionIndex]["options"][correctAnswer];

    final isCorrect = submitted && optionIndex == correctAnswer;
    final isWrong = submitted && isSelected && optionIndex != correctAnswer;

    Color borderColor = Colors.pink.shade100;
    Color bgColor = Colors.white;

    if (isSelected) {
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
                selectedAnswers[questionIndex] = optionIndex;
              });
            },
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(
          left: 56,
          bottom: 12,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    questions[questionIndex]["options"][optionIndex],
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (isSelected && !submitted)
                  const Icon(
                    Icons.check_circle,
                    color: Color(0xFFDB2777),
                  ),
                if (isCorrect)
                  const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                  ),
                if (isWrong)
                  const Icon(
                    Icons.cancel,
                    color: Colors.red,
                  ),
              ],
            ),
            if (isWrong)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  "Correct answer: $correctAnswerText",
                  style: const TextStyle(
                    color: Colors.green,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: answeredCount == questions.length && !isSaving
            ? () async {
                countdownTimer?.cancel();

                setState(() {
                  submitted = true;
                });

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
              ? "Saving..."
              : submitted
                  ? "Submitted"
                  : "Submit Answers",
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
            "AI Reading Analytics",
            style: TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _analyticsBox(
                "Score",
                "$correctCount/${questions.length}",
              ),
              const SizedBox(width: 10),
              _analyticsBox(
                "Accuracy",
                "$percentage%",
              ),
              const SizedBox(width: 10),
              _analyticsBox(
                "Band",
                _bandPrediction(percentage),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            "AI Insight",
            style: TextStyle(
              color: Color(0xFF38BDF8),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _aiInsight(percentage),
            style: const TextStyle(
              color: Colors.white70,
              height: 1.5,
            ),
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
            Text(
              title,
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }

  String _aiInsight(int percentage) {
    if (percentage >= 85) {
      return "Excellent work! Your reading accuracy is strong. Now practice harder IELTS passages and focus on time management.";
    } else if (percentage >= 70) {
      return "Good performance. You understand the passage well, but review detail-based and inference questions to improve your band.";
    } else if (percentage >= 55) {
      return "Average performance. Focus on identifying keywords, scanning for details, and understanding paragraph meaning.";
    } else if (percentage >= 40) {
      return "You need more practice. Try reading the passage slowly first, underline keywords, and avoid guessing too quickly.";
    } else {
      return "Basic understanding needs improvement. Start with short passages, learn common IELTS question types, and practice vocabulary daily.";
    }
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: 0,
      onTap: _goToPage,
      selectedItemColor: const Color(0xFFDB2777),
      unselectedItemColor: Colors.grey,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: "Home",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.bar_chart),
          label: "Analytics",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: "Profile",
        ),
      ],
    );
  }
}
