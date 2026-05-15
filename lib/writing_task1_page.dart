import 'dart:math';
import 'package:flutter/material.dart';
import 'writing_answer_page.dart';

class WritingTask1Page extends StatelessWidget {
  const WritingTask1Page({super.key});

  @override
  Widget build(BuildContext context) {
    final questions = [
      {
        "title": "Bar Chart Question",
        "type": "bar",
        "question":
            "The bar chart below shows the number of students studying English in four countries. Summarize the information by selecting and reporting the main features.",
      },
      {
        "title": "Pie Chart Question",
        "type": "pie",
        "question":
            "The pie chart below shows household spending in different categories. Summarize the information by selecting and reporting the main features.",
      },
      {
        "title": "Line Graph Question",
        "type": "line",
        "question":
            "The line graph below shows changes in internet usage from 2019 to 2023. Summarize the main trends.",
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFFDF7F9),
      appBar: AppBar(
        title: const Text("Writing Task 1"),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(18),
        itemCount: questions.length,
        itemBuilder: (context, index) {
          final q = questions[index];

          return Card(
            margin: const EdgeInsets.only(bottom: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => WritingAnswerPage(
                      title: "Writing Task 1",
                      question: q["question"]!,
                      chartType: q["type"]!,
                    ),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      q["title"]!,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      height: 180,
                      child: _ChartPreview(type: q["type"]!),
                    ),
                    const SizedBox(height: 12),
                    Text(q["question"]!),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ChartPreview extends StatelessWidget {
  final String type;

  const _ChartPreview({required this.type});

  @override
  Widget build(BuildContext context) {
    if (type == "pie") {
      return CustomPaint(
        size: const Size(double.infinity, 180),
        painter: PieChartPainter(),
      );
    }

    if (type == "line") {
      return CustomPaint(
        size: const Size(double.infinity, 180),
        painter: LineGraphPainter(),
      );
    }

    return CustomPaint(
      size: const Size(double.infinity, 180),
      painter: BarChartPainter(),
    );
  }
}

class BarChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final values = [70, 55, 85, 40];
    final labels = ["UK", "USA", "BD", "CA"];

    final barPaint = Paint()..color = Colors.red;
    final gridPaint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 1;

    final left = 35.0;
    final bottom = size.height - 25;
    final top = 10.0;
    final barWidth = 35.0;
    final gap = (size.width - left - 30 - barWidth * 4) / 3;

    for (int i = 0; i < 4; i++) {
      final y = top + i * ((bottom - top) / 3);
      canvas.drawLine(Offset(left, y), Offset(size.width - 10, y), gridPaint);
    }

    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (int i = 0; i < values.length; i++) {
      final x = left + i * (barWidth + gap);
      final h = (values[i] / 100) * (bottom - top);

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, bottom - h, barWidth, h),
          const Radius.circular(8),
        ),
        barPaint,
      );

      textPainter.text = TextSpan(
        text: labels[i],
        style: const TextStyle(color: Colors.black54, fontSize: 12),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x + barWidth / 2 - textPainter.width / 2, bottom + 6),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class PieChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final values = [35.0, 25.0, 20.0, 20.0];
    final colors = [
      Colors.red,
      Colors.pink,
      Colors.orange,
      Colors.deepOrange,
    ];

    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 20;

    double startAngle = -pi / 2;

    for (int i = 0; i < values.length; i++) {
      final sweep = values[i] / 100 * 2 * pi;
      final paint = Paint()..color = colors[i];

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweep,
        true,
        paint,
      );

      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class LineGraphPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final values = [30, 45, 60, 75, 90];
    final labels = ["2019", "2020", "2021", "2022", "2023"];

    final left = 35.0;
    final bottom = size.height - 25;
    final top = 10.0;
    final right = size.width - 15;

    final gridPaint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 1;

    final linePaint = Paint()
      ..color = Colors.red
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < 4; i++) {
      final y = top + i * ((bottom - top) / 3);
      canvas.drawLine(Offset(left, y), Offset(right, y), gridPaint);
    }

    final points = <Offset>[];

    for (int i = 0; i < values.length; i++) {
      final x = left + i * ((right - left) / (values.length - 1));
      final y = bottom - (values[i] / 100) * (bottom - top);
      points.add(Offset(x, y));
    }

    final path = Path()..moveTo(points.first.dx, points.first.dy);

    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    canvas.drawPath(path, linePaint);

    for (final point in points) {
      canvas.drawCircle(point, 5, Paint()..color = Colors.red);
    }

    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (int i = 0; i < labels.length; i++) {
      textPainter.text = TextSpan(
        text: labels[i],
        style: const TextStyle(color: Colors.black54, fontSize: 11),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(points[i].dx - textPainter.width / 2, bottom + 6),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}