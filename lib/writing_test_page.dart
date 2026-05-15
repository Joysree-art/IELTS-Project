import 'dart:async';
import 'package:flutter/material.dart';
import 'writing_task1_page.dart';

class WritingTestPage extends StatefulWidget {
  const WritingTestPage({super.key});

  @override
  State<WritingTestPage> createState() => _WritingTestPageState();
}

class _WritingTestPageState extends State<WritingTestPage> {
  final TextEditingController task1Controller = TextEditingController();
  final TextEditingController task2Controller = TextEditingController();

  Timer? timer;
  int secondsLeft = 3600;
  int secondsSpent = 0;

  bool canType = true;
  bool submitted = false;

  final String task1Question =
      "The bar chart below shows the number of students studying English in four countries. Summarize the information by selecting and reporting the main features.";

  final String task2Question =
      "Some people believe technology improves education, while others think it reduces students' creativity. Discuss both views and give your opinion.";

  @override
  void initState() {
    super.initState();

    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (secondsLeft <= 0) {
        timer?.cancel();

        setState(() {
          canType = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Time is over! Please submit your writing."),
          ),
        );
      } else {
        setState(() {
          secondsLeft--;
          secondsSpent++;
        });
      }
    });
  }

  String formatTime(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

  int wordCount(String text) {
    final cleanText = text.trim();
    if (cleanText.isEmpty) return 0;
    return cleanText.split(RegExp(r'\s+')).length;
  }

  void submitTest() {
    timer?.cancel();

    setState(() {
      submitted = true;
      canType = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Writing test submitted successfully")),
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    task1Controller.dispose();
    task2Controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final task1Words = wordCount(task1Controller.text);
    final task2Words = wordCount(task2Controller.text);

    return Scaffold(
      backgroundColor: const Color(0xFFFDF7F9),
      appBar: AppBar(
        title: const Text("Writing Test"),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 90),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Time Left: ${formatTime(secondsLeft)}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "Time Spent: ${formatTime(secondsSpent)}",
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            _TestBox(
              title: "Writing Task 1",
              question: task1Question,
              wordCount: task1Words,
              controller: task1Controller,
              canType: canType,
              showChart: true,
              onChanged: () => setState(() {}),
            ),

            const SizedBox(height: 22),

            _TestBox(
              title: "Writing Task 2",
              question: task2Question,
              wordCount: task2Words,
              controller: task2Controller,
              canType: canType,
              showChart: false,
              onChanged: () => setState(() {}),
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: submitted ? null : submitTest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  disabledBackgroundColor: Colors.grey,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: Text(
                  submitted ? "Submitted" : "Submit Full Test",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            if (submitted) ...[
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFF111827),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(
                  "Submitted Successfully\nTask 1 Words: $task1Words\nTask 2 Words: $task2Words\nTotal Time Spent: ${formatTime(secondsSpent)}",
                  style: const TextStyle(color: Colors.white, height: 1.6),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TestBox extends StatelessWidget {
  final String title;
  final String question;
  final int wordCount;
  final TextEditingController controller;
  final bool canType;
  final bool showChart;
  final VoidCallback onChanged;

  const _TestBox({
    required this.title,
    required this.question,
    required this.wordCount,
    required this.controller,
    required this.canType,
    required this.showChart,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
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
            title,
            style: const TextStyle(
              color: Colors.red,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 14),

          if (showChart)
            SizedBox(
              height: 210,
              width: double.infinity,
              child: CustomPaint(
                painter: BarChartPainter(),
              ),
            ),

          if (showChart) const SizedBox(height: 14),

          Text(
            question,
            style: const TextStyle(fontSize: 16, height: 1.5),
          ),

          const SizedBox(height: 12),

          Text(
            "Words: $wordCount",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 10),

          TextField(
            controller: controller,
            enabled: canType,
            maxLines: 12,
            onChanged: (_) => onChanged(),
            decoration: InputDecoration(
              hintText: canType
                  ? "Write your answer here..."
                  : "Time is over. You cannot type anymore.",
              filled: true,
              fillColor: const Color(0xFFF9FAFB),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}