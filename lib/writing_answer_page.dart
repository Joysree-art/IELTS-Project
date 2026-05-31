import 'dart:async';
import 'package:flutter/material.dart';

class WritingAnswerPage extends StatefulWidget {
  final String title;
  final String question;
  final String chartType;
  final String imageUrl;

  const WritingAnswerPage({
    super.key,
    required this.title,
    required this.question,
    required this.chartType,
    required this.imageUrl,
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
      setState(() => secondsSpent++);
    });
  }

  String formatTime(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  int get wordCount {
    final text = answerController.text.trim();
    if (text.isEmpty) return 0;
    return text.split(RegExp(r'\s+')).length;
  }

  bool get hasChart =>
      widget.chartType.isNotEmpty && widget.imageUrl.isNotEmpty;

  void submitWriting() {
    timer?.cancel();
    setState(() => submitted = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Writing submitted successfully')),
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    answerController.dispose();
    super.dispose();
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
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Chart image from Supabase bucket
            if (hasChart) ...[
              Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxHeight: 1000),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Image.network(
                    widget.imageUrl,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const SizedBox(
                        height: 140,
                        child: Center(
                          child: CircularProgressIndicator(color: Colors.red),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) => const SizedBox(
                      height: 100,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.broken_image,
                                color: Colors.grey, size: 36),
                            SizedBox(height: 6),
                            Text(
                              'Chart image could not be loaded',
                              style: TextStyle(color: Colors.grey, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
            ],

            // Question text box
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
                style: const TextStyle(fontSize: 16, height: 1.6),
              ),
            ),

            const SizedBox(height: 18),

            // Timer + word count row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.timer_outlined, color: Colors.red, size: 18),
                    const SizedBox(width: 5),
                    Text(
                      formatTime(secondsSpent),
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Icon(Icons.text_fields, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      'Words: $wordCount',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF374151),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Answer text field
            TextField(
              controller: answerController,
              enabled: !submitted,
              maxLines: 16,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Write your answer here...',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide(color: Colors.red.shade100),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide(color: Colors.red.shade100),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: const BorderSide(color: Colors.red, width: 2),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Submit button
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: submitted ? null : submitWriting,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  disabledBackgroundColor: Colors.grey.shade300,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: Text(
                  submitted ? 'Submitted' : 'Submit Writing',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            // Feedback placeholder after submission
            if (submitted) ...[
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFF111827),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Writing Feedback',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _StatBox(title: 'Words', value: '$wordCount'),
                        const SizedBox(width: 10),
                        _StatBox(title: 'Time', value: formatTime(secondsSpent)),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'AI feedback from the API will appear here after submission.',
                      style: TextStyle(color: Colors.white70, height: 1.5),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String title;
  final String value;

  const _StatBox({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1F2937),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Color(0xFF38BDF8),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}