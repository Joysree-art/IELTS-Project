import 'dart:math';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'home_page.dart';
import 'profile_page.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  bool isLoading = true;

  double readingScore = 7.5;
  double previousReadingScore = 6.0;
  double improvement = 1.5;

  final double writingScore = 6.5;
  final double speakingScore = 7.0;
  final double listeningScore = 6.0;

  List<double> readingTrend = [6.0, 6.0, 6.5, 6.5];

  @override
  void initState() {
    super.initState();
    _fetchReadingScore();
  }

  Future<void> _fetchReadingScore() async {
    try {
      final data = await Supabase.instance.client
          .from('reading_scores')
          .select()
          .order('created_at', ascending: false)
          .limit(4);

      if (data.isNotEmpty) {
        final latest = (data[0]['band_score'] as num).toDouble();

        double previous = previousReadingScore;
        if (data.length > 1) {
          previous = (data[1]['band_score'] as num).toDouble();
        }

        final trend = data
            .map<double>((item) => (item['band_score'] as num).toDouble())
            .toList()
            .reversed
            .toList();

        setState(() {
          readingScore = latest;
          previousReadingScore = previous;
          improvement = readingScore - previousReadingScore;
          readingTrend = trend;
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to load reading score: $e")),
      );
    }
  }

  String _improvementText() {
    if (improvement >= 0) {
      return "+${improvement.toStringAsFixed(1)}";
    }
    return improvement.toStringAsFixed(1);
  }

  void _goToPage(int index) {
    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HomePage()),
      );
    } else if (index == 1) {
      _fetchReadingScore();
    } else if (index == 2) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => ProfilePage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final moduleScores = [
      writingScore,
      speakingScore,
      readingScore,
      listeningScore,
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFFFF7F8),
      body: SafeArea(
        child: Column(
          children: [
            _topBar(context),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _fetchReadingScore,
                child: isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: Colors.red),
                      )
                    : SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(18, 20, 18, 95),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _GradientCard(
                                    title: "Band Estimate",
                                    value: readingScore.toStringAsFixed(1),
                                    subtitle: "↗ Target: 7",
                                    colors: const [
                                      Color(0xFFFF2A2A),
                                      Color(0xFFE9001E),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: _GradientCard(
                                    title: "Improvement",
                                    value: _improvementText(),
                                    subtitle: "Last 4 weeks",
                                    colors: const [
                                      Color(0xFFFF2A2A),
                                      Color(0xFFF00058),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            _ChartCard(
                              title: "Performance Trends",
                              height: 320,
                              child: CustomPaint(
                                size: const Size(double.infinity, 230),
                                painter: LineChartPainter(values: readingTrend),
                              ),
                            ),
                            const SizedBox(height: 24),
                            _ChartCard(
                              title: "Current Module Scores",
                              height: 320,
                              child: CustomPaint(
                                size: const Size(double.infinity, 230),
                                painter: BarChartPainter(scores: moduleScores),
                              ),
                            ),
                            const SizedBox(height: 24),
                            _ChartCard(
                              title: "Weakness Detection",
                              height: 470,
                              child: SingleChildScrollView(
                                physics: const NeverScrollableScrollPhysics(),
                                child: Column(
                                  children: [
                                    SizedBox(
                                      height: 230,
                                      width: 230,
                                      child: CustomPaint(
                                        painter: DonutChartPainter(),
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    const _LegendGrid(),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _bottomNav(),
    );
  }

  Widget _topBar(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 12, 18, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFEAEAEA))),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, size: 26),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 4),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Analytics Dashboard",
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF071323),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  "Performance insights & trends",
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 15, color: Colors.grey),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _fetchReadingScore,
            icon: const Icon(Icons.refresh, color: Colors.red),
          ),
        ],
      ),
    );
  }

  Widget _bottomNav() {
    return BottomNavigationBar(
      currentIndex: 1,
      onTap: _goToPage,
      selectedItemColor: Colors.red,
      unselectedItemColor: Colors.grey,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: "Home"),
        BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart), label: "Analytics"),
        BottomNavigationBarItem(
            icon: Icon(Icons.person_outline), label: "Profile"),
      ],
    );
  }
}

class _GradientCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final List<Color> colors;

  const _GradientCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 165,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: colors.first.withOpacity(0.25),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontSize: 16)),
            const SizedBox(height: 10),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 42,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(subtitle,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontSize: 15)),
          ],
        ),
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  final String title;
  final double height;
  final Widget child;

  const _ChartCard({
    required this.title,
    required this.height,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFFFD9DE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF071323),
              )),
          const SizedBox(height: 18),
          Expanded(child: Center(child: child)),
        ],
      ),
    );
  }
}

class LineChartPainter extends CustomPainter {
  final List<double> values;

  LineChartPainter({required this.values});

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFFE5E7EB)
      ..strokeWidth = 1;

    final linePaint = Paint()
      ..color = const Color(0xFFFF6B1A)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    final left = 42.0;
    final top = 10.0;
    final bottom = size.height - 55;
    final right = size.width - 15;

    for (int i = 0; i < 4; i++) {
      final y = top + i * ((bottom - top) / 3);
      canvas.drawLine(Offset(left, y), Offset(right, y), gridPaint);
    }

    for (int i = 0; i < 4; i++) {
      final x = left + i * ((right - left) / 3);
      canvas.drawLine(Offset(x, top), Offset(x, bottom), gridPaint);
    }

    final displayValues =
        values.length == 1 ? [values.first, values.first] : values;

    final points = <Offset>[];

    for (int i = 0; i < displayValues.length; i++) {
      final x = left + i * ((right - left) / max(1, displayValues.length - 1));
      final y = bottom - ((displayValues[i] - 5) / 3) * (bottom - top);
      points.add(Offset(x, y));
    }

    final path = Path()..moveTo(points[0].dx, points[0].dy);

    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    canvas.drawPath(path, linePaint);

    final dotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = const Color(0xFFFF6B1A)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    for (final p in points) {
      canvas.drawCircle(p, 5, dotPaint);
      canvas.drawCircle(p, 5, borderPaint);
    }

    final weekLabels = ["Week 1", "Week 2", "Week 3", "Week 4"];

    for (int i = 0; i < displayValues.length; i++) {
      textPainter.text = TextSpan(
        text: weekLabels[i],
        style: const TextStyle(color: Colors.grey, fontSize: 12),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(points[i].dx - textPainter.width / 2, bottom + 10),
      );
    }

    final yLabels = ["8", "7.25", "6.5", "5.75", "5"];

    for (int i = 0; i < yLabels.length; i++) {
      final y = top + i * ((bottom - top) / 4);
      textPainter.text = TextSpan(
        text: yLabels[i],
        style: const TextStyle(color: Colors.grey, fontSize: 12),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(5, y - 8));
    }

    final legends = [
      ["writing", const Color(0xFFE82429)],
      ["speaking", const Color(0xFFF23863)],
      ["reading", const Color(0xFFE6459B)],
      ["listening", const Color(0xFFFF6B16)],
    ];

    double legendX = left;
    final legendY = size.height - 22;

    for (final item in legends) {
      final label = item[0] as String;
      final color = item[1] as Color;

      final p = Paint()
        ..color = color
        ..strokeWidth = 2;

      canvas.drawLine(
          Offset(legendX, legendY), Offset(legendX + 12, legendY), p);
      canvas.drawCircle(
          Offset(legendX + 6, legendY), 3, Paint()..color = Colors.white);
      canvas.drawCircle(
        Offset(legendX + 6, legendY),
        3,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );

      textPainter.text = TextSpan(
        text: label,
        style: TextStyle(color: color, fontSize: 13),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(legendX + 16, legendY - 8));

      legendX += textPainter.width + 38;
    }
  }

  @override
  bool shouldRepaint(covariant LineChartPainter oldDelegate) {
    return oldDelegate.values != values;
  }
}

class BarChartPainter extends CustomPainter {
  final List<double> scores;

  BarChartPainter({required this.scores});

  @override
  void paint(Canvas canvas, Size size) {
    final left = 42.0;
    final bottom = size.height - 38;
    final top = 5.0;
    final right = size.width - 15;

    final gridPaint = Paint()
      ..color = const Color(0xFFE5E7EB)
      ..strokeWidth = 1;

    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (int i = 0; i < 4; i++) {
      final y = top + i * ((bottom - top) / 3);
      canvas.drawLine(Offset(left, y), Offset(right, y), gridPaint);
    }

    final labels = ["Writing", "Speaking", "Reading", "Listening"];
    final colors = [
      const Color(0xFFE82429),
      const Color(0xFFF23863),
      const Color(0xFFE6459B),
      const Color(0xFFFF6B16),
    ];

    final barWidth = 48.0;
    final gap = (right - left - barWidth * 4) / 3;

    for (int i = 0; i < 4; i++) {
      final x = left + i * (barWidth + gap);
      final h = (scores[i] / 9) * (bottom - top);

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, bottom - h, barWidth, h),
        const Radius.circular(8),
      );

      canvas.drawRRect(rect, Paint()..color = colors[i]);

      textPainter.text = TextSpan(
        text: labels[i],
        style: const TextStyle(color: Colors.grey, fontSize: 12),
      );

      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x + barWidth / 2 - textPainter.width / 2, bottom + 10),
      );
    }

    final yLabels = ["9", "6", "3", "0"];

    for (int i = 0; i < yLabels.length; i++) {
      final y = top + i * ((bottom - top) / 3);

      textPainter.text = TextSpan(
        text: yLabels[i],
        style: const TextStyle(color: Colors.grey, fontSize: 12),
      );

      textPainter.layout();
      textPainter.paint(canvas, Offset(15, y - 8));
    }
  }

  @override
  bool shouldRepaint(covariant BarChartPainter oldDelegate) {
    return oldDelegate.scores != scores;
  }
}

class DonutChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 25;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 48
      ..strokeCap = StrokeCap.butt;

    final values = [25.0, 20.0, 15.0, 40.0];

    final colors = [
      const Color(0xFFE82429),
      const Color(0xFFF23863),
      const Color(0xFFE6459B),
      const Color(0xFFFF6B16),
    ];

    double start = -pi / 2;

    for (int i = 0; i < values.length; i++) {
      final sweep = (values[i] / 100) * 2 * pi;
      paint.color = colors[i];

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start,
        sweep - 0.04,
        false,
        paint,
      );

      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _LegendGrid extends StatelessWidget {
  const _LegendGrid();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _LegendItem(
                color: Color(0xFFE82429),
                text: "Grammar",
              ),
            ),
            Expanded(
              child: _LegendItem(
                color: Color(0xFFF23863),
                text: "Vocabulary",
              ),
            ),
          ],
        ),
        SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _LegendItem(
                color: Color(0xFFE6459B),
                text: "Fluency",
              ),
            ),
            Expanded(
              child: _LegendItem(
                color: Color(0xFFFF6B16),
                text: "Comprehension",
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String text;

  const _LegendItem({
    required this.color,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(radius: 7, backgroundColor: color),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF374151),
            ),
          ),
        ),
      ],
    );
  }
}
