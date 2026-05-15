import 'dart:async';
import 'package:flutter/material.dart';
import 'writing_task1_page.dart';

class WritingAnswerPage extends StatefulWidget {
  final String title;
  final String question;
  final String chartType;

  const WritingAnswerPage({
    super.key,
    required this.title,
    required this.question,
    required this.chartType,
  });

  @override
  State<WritingAnswerPage> createState() => _WritingAnswerPageState();
}

class _WritingAnswerPageState extends State<WritingAnswerPage> {
  final TextEditingController answerController = TextEditingController();

  Timer? timer;
  int secondsSpent = 0;
  bool submitted = false;

  @override
  void initState() {
    super.initState();

    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        secondsSpent++;
      });
    });
  }

  String formatTime(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

  int get wordCount {
    final text = answerController.text.trim();
    if (text.isEmpty) return 0;
    return text.split(RegExp(r'\s+')).length;
  }

  void submitWriting() {
    timer?.cancel();

    setState(() {
      submitted = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Writing submitted successfully")),
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    answerController.dispose();
    super.dispose();
  }

  Widget _chart() {
    if (widget.chartType == "bar") {
      return CustomPaint(
        size: const Size(double.infinity, 200),
        painter: BarChartPainter(),
      );
    }

    if (widget.chartType == "pie") {
      return CustomPaint(
        size: const Size(double.infinity, 200),
        painter: PieChartPainter(),
      );
    }

    if (widget.chartType == "line") {
      return CustomPaint(
        size: const Size(double.infinity, 200),
        painter: LineGraphPainter(),
      );
    }

    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    final hasChart = widget.chartType.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFFDF7F9),
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasChart)
              Container(
                height: 230,
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.red.shade100),
                ),
                child: _chart(),
              ),

            if (hasChart) const SizedBox(height: 18),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.red.shade100),
              ),
              child: Text(
                widget.question,
                style: const TextStyle(fontSize: 16, height: 1.5),
              ),
            ),

            const SizedBox(height: 18),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Time Spent: ${formatTime(secondsSpent)}",
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "Words: $wordCount",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),

            const SizedBox(height: 14),

            TextField(
              controller: answerController,
              enabled: !submitted,
              maxLines: 16,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: "Write your answer here...",
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: submitted ? null : submitWriting,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  disabledBackgroundColor: Colors.grey,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: Text(
                  submitted ? "Submitted" : "Submit Writing",
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
      color: const Color.fromARGB(255, 209, 4, 4),
      borderRadius: BorderRadius.circular(18),
    ),

    child: const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Writing Feedback",
          style: TextStyle(
            color: Color.fromARGB(255, 246, 245, 248),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),

        SizedBox(height: 10),

        Text(
          "Feedback from API will appear here after submission.",
          style: TextStyle(
            color: Colors.white70,
            height: 1.5,
          ),
        ),
      ],
    ),
  ),
],
          ],
        ),
      ),
    );
  }
}