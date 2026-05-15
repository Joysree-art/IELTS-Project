import 'package:flutter/material.dart';
import 'home_page.dart';

class ListeningPage extends StatelessWidget {
  const ListeningPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF7F9),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const HomePage()),
            );
          },
        ),
        title: const Text("Listening"),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Choose Listening Option",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            _OptionCard(
              title: "Listening Practice Task 1",
              subtitle: "Conversation based questions",
              icon: Icons.looks_one,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ListeningPracticePage(
                      title: "Listening Task 1",
                      questions: listeningTask1Questions,
                    ),
                  ),
                );
              },
            ),

            _OptionCard(
              title: "Listening Practice Task 2",
              subtitle: "Monologue based questions",
              icon: Icons.looks_two,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ListeningPracticePage(
                      title: "Listening Task 2",
                      questions: listeningTask2Questions,
                    ),
                  ),
                );
              },
            ),

            _OptionCard(
              title: "Listening Practice Task 3",
              subtitle: "Academic discussion questions",
              icon: Icons.looks_3,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ListeningPracticePage(
                      title: "Listening Task 3",
                      questions: listeningTask3Questions,
                    ),
                  ),
                );
              },
            ),

            _OptionCard(
              title: "Listening Practice Task 4",
              subtitle: "Lecture based questions",
              icon: Icons.looks_4,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ListeningPracticePage(
                      title: "Listening Task 4",
                      questions: listeningTask4Questions,
                    ),
                  ),
                );
              },
            ),

            _OptionCard(
              title: "Give a Test",
              subtitle: "Full listening test practice",
              icon: Icons.assignment,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ListeningPracticePage(
                      title: "Full Listening Test",
                      questions: [
                        ...listeningTask1Questions,
                        ...listeningTask2Questions,
                        ...listeningTask3Questions,
                        ...listeningTask4Questions,
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class ListeningPracticePage extends StatefulWidget {
  final String title;
  final List<Map<String, dynamic>> questions;

  const ListeningPracticePage({
    super.key,
    required this.title,
    required this.questions,
  });

  @override
  State<ListeningPracticePage> createState() => _ListeningPracticePageState();
}

class _ListeningPracticePageState extends State<ListeningPracticePage> {
  late List<int?> selectedAnswers;
  bool submitted = false;

  @override
  void initState() {
    super.initState();
    selectedAnswers = List<int?>.filled(widget.questions.length, null);
  }

  int get answeredCount => selectedAnswers.where((e) => e != null).length;

  int get correctCount {
    int count = 0;

    for (int i = 0; i < widget.questions.length; i++) {
      if (selectedAnswers[i] == widget.questions[i]["answer"]) {
        count++;
      }
    }

    return count;
  }

  int get percentage {
    return ((correctCount / widget.questions.length) * 100).round();
  }

  double get bandScore {
    if (percentage >= 90) return 8.5;
    if (percentage >= 80) return 7.5;
    if (percentage >= 70) return 7.0;
    if (percentage >= 60) return 6.5;
    if (percentage >= 50) return 6.0;
    if (percentage >= 40) return 5.5;
    return 5.0;
  }

  String get feedback {
    if (percentage >= 85) {
      return "Excellent listening performance. You can understand main ideas, details, and speaker attitude well. Now focus on difficult accents and faster recordings.";
    } else if (percentage >= 70) {
      return "Good performance. You understand most information, but you should practice detail questions and note-taking.";
    } else if (percentage >= 55) {
      return "Average performance. Focus on keywords, synonyms, and predicting answers before listening.";
    } else if (percentage >= 40) {
      return "You need more practice. Focus on understanding basic information, numbers, names, dates, and common IELTS listening vocabulary.";
    } else {
      return "Your listening foundation needs improvement. Start with short conversations, repeat recordings, and practice spelling common answers.";
    }
  }

  String get focusArea {
    if (percentage >= 85) {
      return "Focus on: advanced accents, fast speech, map questions, and multiple choice traps.";
    } else if (percentage >= 70) {
      return "Focus on: synonyms, distractors, speaker opinions, and matching questions.";
    } else if (percentage >= 55) {
      return "Focus on: note completion, short answer questions, and identifying keywords.";
    } else {
      return "Focus on: basic vocabulary, spelling, numbers, dates, places, and slow listening practice.";
    }
  }

  void submitAnswers() {
    setState(() {
      submitted = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Listening answers submitted")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF7F9),
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 90),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _RecorderBox(title: widget.title),

            const SizedBox(height: 22),

            Text(
              "Questions: $answeredCount/${widget.questions.length}",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 12),

            ...List.generate(
              widget.questions.length,
              (index) => _QuestionCard(
                questionNumber: index + 1,
                question: widget.questions[index],
                selectedAnswer: selectedAnswers[index],
                submitted: submitted,
                onSelected: (optionIndex) {
                  setState(() {
                    selectedAnswers[index] = optionIndex;
                  });
                },
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed:
                    answeredCount == widget.questions.length && !submitted
                        ? submitAnswers
                        : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  disabledBackgroundColor: Colors.grey.shade300,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: Text(
                  submitted ? "Submitted" : "Submit Answers",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            if (submitted) ...[
              const SizedBox(height: 22),
              _ResultBox(
                correct: correctCount,
                total: widget.questions.length,
                percentage: percentage,
                bandScore: bandScore,
                feedback: feedback,
                focusArea: focusArea,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RecorderBox extends StatelessWidget {
  final String title;

  const _RecorderBox({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.headphones,
            size: 55,
            color: Colors.white,
          ),
          const SizedBox(height: 12),
          Text(
            "$title Audio",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Audio recorder/player will be added here later.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 18),
          Container(
            height: 55,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF1F2937),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.play_circle_fill, color: Colors.red, size: 34),
                SizedBox(width: 12),
                Text(
                  "Recorder UI Placeholder",
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  final int questionNumber;
  final Map<String, dynamic> question;
  final int? selectedAnswer;
  final bool submitted;
  final Function(int) onSelected;

  const _QuestionCard({
    required this.questionNumber,
    required this.question,
    required this.selectedAnswer,
    required this.submitted,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final options = question["options"] as List<String>;
    final correctAnswer = question["answer"] as int;

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.red.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Q$questionNumber. ${question["question"]}",
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              height: 1.4,
            ),
          ),

          const SizedBox(height: 14),

          ...List.generate(options.length, (index) {
            final isSelected = selectedAnswer == index;
            final isCorrect = submitted && index == correctAnswer;
            final isWrong = submitted && isSelected && index != correctAnswer;

            Color bgColor = Colors.white;
            Color borderColor = Colors.grey.shade300;

            if (isSelected) {
              bgColor = const Color(0xFFFFF1F2);
              borderColor = Colors.red;
            }

            if (isCorrect) {
              bgColor = const Color(0xFFDCFCE7);
              borderColor = Colors.green;
            }

            if (isWrong) {
              bgColor = const Color(0xFFFEE2E2);
              borderColor = Colors.red;
            }

            return GestureDetector(
              onTap: submitted ? null : () => onSelected(index),
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        options[index],
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    if (isSelected && !submitted)
                      const Icon(Icons.check_circle, color: Colors.red),
                    if (isCorrect)
                      const Icon(Icons.check_circle, color: Colors.green),
                    if (isWrong)
                      const Icon(Icons.cancel, color: Colors.red),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _ResultBox extends StatelessWidget {
  final int correct;
  final int total;
  final int percentage;
  final double bandScore;
  final String feedback;
  final String focusArea;

  const _ResultBox({
    required this.correct,
    required this.total,
    required this.percentage,
    required this.bandScore,
    required this.feedback,
    required this.focusArea,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Listening Result",
            style: TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              _SmallResultBox(title: "Score", value: "$correct/$total"),
              const SizedBox(width: 10),
              _SmallResultBox(title: "Accuracy", value: "$percentage%"),
              const SizedBox(width: 10),
              _SmallResultBox(
                title: "Band",
                value: bandScore.toStringAsFixed(1),
              ),
            ],
          ),

          const SizedBox(height: 18),

          const Text(
            "Feedback",
            style: TextStyle(
              color: Color(0xFF38BDF8),
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            feedback,
            style: const TextStyle(color: Colors.white70, height: 1.5),
          ),

          const SizedBox(height: 16),

          const Text(
            "Focus Area",
            style: TextStyle(
              color: Color(0xFF38BDF8),
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            focusArea,
            style: const TextStyle(color: Colors.white70, height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _SmallResultBox extends StatelessWidget {
  final String title;
  final String value;

  const _SmallResultBox({
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF1F2937),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Color(0xFF38BDF8),
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _OptionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: Colors.red.shade100,
                child: Icon(icon, color: Colors.red),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(subtitle, style: const TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

final List<Map<String, dynamic>> listeningTask1Questions = [
  {
    "question": "What is the woman trying to book?",
    "options": ["A hotel room", "A train ticket", "A language course", "A library card"],
    "answer": 2,
  },
  {
    "question": "When does the course begin?",
    "options": ["Monday", "Tuesday", "Wednesday", "Friday"],
    "answer": 0,
  },
  {
    "question": "What information does the man ask for?",
    "options": ["Passport number", "Email address", "Bank details", "Student ID"],
    "answer": 1,
  },
];

final List<Map<String, dynamic>> listeningTask2Questions = [
  {
    "question": "What is the speaker mainly describing?",
    "options": ["A museum tour", "A shopping centre", "A city festival", "A sports event"],
    "answer": 0,
  },
  {
    "question": "Where should visitors meet?",
    "options": ["At the main gate", "Near the café", "Beside the information desk", "In the car park"],
    "answer": 2,
  },
  {
    "question": "What is not allowed inside?",
    "options": ["Taking photos", "Using headphones", "Bringing large bags", "Buying tickets"],
    "answer": 2,
  },
];

final List<Map<String, dynamic>> listeningTask3Questions = [
  {
    "question": "What are the students discussing?",
    "options": ["A research project", "A holiday plan", "A job interview", "A library fine"],
    "answer": 0,
  },
  {
    "question": "What problem does the female student mention?",
    "options": ["Lack of sources", "Too many interviews", "A broken laptop", "No internet connection"],
    "answer": 0,
  },
  {
    "question": "What does the tutor suggest?",
    "options": ["Changing the topic", "Adding survey data", "Working alone", "Cancelling the project"],
    "answer": 1,
  },
];

final List<Map<String, dynamic>> listeningTask4Questions = [
  {
    "question": "What is the lecture mainly about?",
    "options": ["Climate change", "Ancient farming", "Ocean pollution", "Modern architecture"],
    "answer": 1,
  },
  {
    "question": "Why were early farmers successful?",
    "options": ["They used machines", "They understood seasons", "They lived near cities", "They avoided animals"],
    "answer": 1,
  },
  {
    "question": "What does the lecturer say about tools?",
    "options": ["They were simple but useful", "They were imported", "They were mostly decorative", "They were made of glass"],
    "answer": 0,
  },
];