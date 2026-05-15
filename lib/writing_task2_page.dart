import 'package:flutter/material.dart';
import 'writing_answer_page.dart';

class WritingTask2Page extends StatelessWidget {
  const WritingTask2Page({super.key});

  @override
  Widget build(BuildContext context) {
    final questions = [
      "Some people think online learning is better than classroom learning. To what extent do you agree or disagree?",
      "Many students prefer studying abroad. What are the advantages and disadvantages?",
      "Technology is changing the way people communicate. Is this a positive or negative development?",
      "Some people believe that governments should spend more money on education than entertainment. Discuss both views and give your opinion.",
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFFDF7F9),
      appBar: AppBar(
        title: const Text("Writing Task 2"),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(18),
        itemCount: questions.length,
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.only(bottom: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(18),
              leading: CircleAvatar(
                backgroundColor: Colors.red.shade100,
                child: Text("${index + 1}"),
              ),
              title: Text(
                questions[index],
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 18),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => WritingAnswerPage(
                      title: "Writing Task 2",
                      question: questions[index],
                      chartType: "",
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}