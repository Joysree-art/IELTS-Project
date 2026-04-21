import 'package:flutter/material.dart';

class WritingPage extends StatelessWidget {
  const WritingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Writing"),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text(
          "Writing Page",
<<<<<<< HEAD
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
=======
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
>>>>>>> 6933b38 (Initial Flutter project)
        ),
      ),
    );
  }
<<<<<<< HEAD
}
=======
}
>>>>>>> 6933b38 (Initial Flutter project)
